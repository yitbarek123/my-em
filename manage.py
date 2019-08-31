#!/usr/bin/python

from __future__ import print_function
import argparse
import subprocess
import json
import time
import os
import sys
import tempfile
import copy
import signal

from subprocess import Popen, PIPE
from threading import Thread

try:
    from Queue import Queue, Empty
except ImportError:
    from queue import Queue, Empty # for Python 3.x

try:
    from colors import color
except ImportError:
    # dummy color function if people don't have ansicolors installed
    def color(text, *args, **kwargs):
        return text



class CommandException(Exception):
    pass


class DockerComponent:
    def __init__(self, name, dockerfile, context_dir=None, port_mapping=None, is_base=False,
                git_repo=None, privileged=False, cmd=None, pull_image=None, environ=None,
                options=None, volumes=None, prebuild=None, local_base_image=None, pre_cmd=None):
        self.name = name
        self.image = name
        self.dockerfile = dockerfile
        self.context_dir = context_dir
        self.port_mapping = port_mapping
        self.is_base = is_base
        self.git_repo = git_repo
        self.privileged = privileged
        self.pre_cmd = pre_cmd
        self.cmd = cmd
        self.pull_image = pull_image
        self.environ = environ or dict()
        self.volumes = volumes or dict()
        self.options = options or ""
        self.prebuild = prebuild
        self.local_base_image = local_base_image
        self.verbose = False
    
    @property
    def color_name(self):
        return color(self.name, fg=10)

    @property
    def container_name(self):
        return self.name + "_container"

    def remove_container(self):
        call(
            "docker rm -f {}".format(self.container_name),
            "removing container {}".format(self.container_name),
            "error removing container",
            verbose=self.verbose
            )

    def stop_container(self):
        call(
            "docker stop {}".format(self.container_name),
            "stopping container {}".format(self.container_name),
            "error stopping container",
            verbose=self.verbose
        )

    def launch_container(self, network_name):
        env_string = ""
        for k, v in self.environ.iteritems():
            env_string += " --env {}={}".format(k, v)
        volume_string = ""
        for k, v in self.volumes.iteritems():
            volume_string += " -v {}:{}".format(k, v)
        # hack to keep container around doing nothing
        dummy_cmd = "tail -f /dev/null"
        port_str = ""
        if self.port_mapping is not None:
            port_str = "-p " + self.port_mapping
        full_cmd = "docker run --init -d {} --network {} {} {} {} --name {} {} {}".format(
                port_str, network_name, env_string, volume_string, self.options, self.container_name, self.image, dummy_cmd
            )
        call(
            full_cmd,
            "running container {}".format(self.container_name),
            "error running container",
            verbose=self.verbose
        )

    def container_exists(self):
        try:
            self.inspect_container()
        except CommandException:
            return False
        return True

    def inspect_container(self):
        p, result = call(
            "docker inspect {}".format(self.container_name),
            capture_output=True
        )
        json_obj = json.loads(result)
        return json_obj[0]

    def image_exists(self):
        try:
            self.inspect_image()
        except CommandException:
            return False
        return True

    def inspect_image(self):
        p, result = call(
            "docker image inspect {}".format(self.image),
            capture_output=True
        )
        
        json_obj = json.loads(result)
        return json_obj[0]

    def exec_in_container(self, cmd):
        p = subprocess.call("docker exec -t {} bash -c '{}'".format(self.container_name, cmd), shell=True)
        if p != 0:
            raise(CommandException("Command {} failed".format(cmd)))
    
    
    def exec_component(self, output_q, oid):
        out_f, p = make_process(
            "docker exec -t {} {}".format(self.container_name, self.cmd),
            "running '{}' in {}".format(self.cmd, self.container_name)
        )

        def enqueue_output(out, queue, oid):
            for line in iter(out.readline, b''):
                queue.put((oid, line))
            out.close()

        t = Thread(target=enqueue_output, args=(p.stdout, output_q, oid))
        return out_f, t, p

    def remove_image(self):
        call(
            "docker rmi {}".format(self.image),
            "removing image {}".format(self.image),
            "error removing image",
            verbose=self.verbose
        )

    def build_image(self, no_cache=False, force_pull=False):
        if self.prebuild:
            call(
                "cd {} && {}".format(self.context_dir, self.prebuild),
                "running prebuild script for {}".format(self.image),
                "error running prebuild script",
                verbose=self.verbose
            )

        docker_build_opts = ""
        if no_cache:
            docker_build_opts += "--no-cache "
        if force_pull and self.local_base_image is None:
            docker_build_opts += "--pull "

        if self.context_dir:
            call(
                "docker build {} -f {} -t {} {}".format(docker_build_opts, self.dockerfile, self.image, self.context_dir),
                "building image {}".format(self.image),
                "error building image",
                capture_output=True,
                verbose=self.verbose
            )
        else:
            # Only way to have an empty context is to pipe dockerfile via stdin
            # See "Build with -" at https://docs.docker.com/engine/reference/commandline/build/
            call(
                "docker build {} -t {} - < {}".format(docker_build_opts, self.image, self.dockerfile),
                "building image {}".format(self.image),
                "error building image",
                capture_output=True,
                verbose=self.verbose
            )

    def pull(self):
        if self.pull_image:
            call(
                "docker pull {}".format(self.pull_image),
                "pull image {}".format(self.pull_image),
                "error pulling image",
                verbose=self.verbose
            )
            call(
                "docker tag {} {}".format(self.pull_image, self.image),
                "tagging image {} locally as {}".format(self.pull_image, self.image),
                "error tagging image",
                verbose=self.verbose
            )
        
    def git_update(self):
        if not self.git_repo:
            return
        if os.path.exists(self.context_dir):
            # TODO if someone changes the origin remote to point elsewhere,
            # this doesn't guarantee we are using self.git_repo anymore.
            call(
                "cd {} && git fetch --all && git rebase origin/master".format(self.context_dir),
                "fetch and rebase for {}".format(self.context_dir),
                "error updating repo",
                verbose=self.verbose
            )
        else:
            call(
                "git clone {} {}".format(self.git_repo, self.context_dir),
                "cloning {}".format(self.git_repo),
                "error cloning repo",
                verbose=self.verbose
            )

EXTERNAL_DEPS_DIR = './external'

# infra-network
NETWORK_VA="va-network"

# protofiles base folder to be mounted inside containers
PATH_PROTOS="/home/protos/"

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))

def P(rel_path):
    return os.path.join(PROJECT_ROOT, rel_path)

# The order the are presented here is the order they build and get served.
components = [
    DockerComponent("va_cpp_grpc",
        dockerfile=P("dependencies/dockerfiles/BasicGRPCDockerfile"),
        context_dir=None,
        is_base=True
    ),
    DockerComponent("va_opencog",
        dockerfile=P("dependencies/dockerfiles/VAOpencogDockerfile"),
        context_dir=None,
        is_base=True
    ),

    DockerComponent("va_conceptnet_server",
        dockerfile=P("{}/conceptnet-server/Dockerfile".format(EXTERNAL_DEPS_DIR)),
        context_dir=P("{}/conceptnet-server".format(EXTERNAL_DEPS_DIR)),
        port_mapping="7082:80",
        git_repo="https://github.com/singnet/conceptnet-server.git",
        privileged=True,
        options="--stop-timeout 30",
        volumes={
            "conceptnet-data":"/home/conceptnet/",
            "conceptnet-db":"/var/lib/postgresql/10/main",
        },
        cmd="bash conceptnet.sh start"
    ),
    DockerComponent("va_sumo_server",
        dockerfile=P("{}/sumo-server/Dockerfile".format(EXTERNAL_DEPS_DIR)),
        context_dir=P("{}/sumo-server".format(EXTERNAL_DEPS_DIR)),
        port_mapping="7083:9999",
        git_repo="https://github.com/singnet/sumo-server.git",
        cmd="guile --no-auto-compile sumo-server.scm"
    ),

    DockerComponent("va_opencog_relex",
        dockerfile=None,
        port_mapping="4444:4444",
        cmd="bash opencog-server.sh",
        pull_image="opencog/relex",
        options="--restart unless-stopped"
    ),
    DockerComponent("va_ai",
        dockerfile=P("src/virtual-assistant/Dockerfile"),
        context_dir=P("src/virtual-assistant"),
        port_mapping="7080:7032",
        environ=dict(
            GUILE_AUTO_COMPILE="0",
            LD_LIBRARY_PATH="/usr/local/lib/opencog:/usr/local/lib/opencog/modules",
            CONCEPTNET_HOSTNAME="va_conceptnet_server_container",
            CONTAINER_RELEX_HOSTNAME="va_opencog_relex_container",
            OPENCOG_SERVER_PORT="7032",
            PORT_RELEX_SERVER="4444",
            PORT_CONCEPTNET_SERVER="80",
            PROTOS_PATH=PATH_PROTOS
        ),
        volumes={
            P("lib"): "/home/va-lib",
            P("knowledge"): "/home/knowledge",
            P("protos"): PATH_PROTOS,
        },
        prebuild="sh ./prebuild.sh",
        local_base_image="va_opencog",
        cmd="./bin/server"
    ),
    DockerComponent("va_session_manager",
        dockerfile=P("src/session-manager/Dockerfile"),
        context_dir=P("src/session-manager"),
        port_mapping="7084:50000",
        volumes={
            P("protos"): PATH_PROTOS,
            "session-manager-db": '/virtual-assistant/session-manager/data'
        },
        environ=dict(
            PROTOS_PATH=PATH_PROTOS,
            INTERNAL_PORT_SESSION_MANAGER="50000"
        ),
        cmd="bash run.sh"
    ),
    DockerComponent("va_test",
        dockerfile=P("dependencies/dockerfiles/VATestDockerfile"),
        context_dir=None,
        is_base=True,
        local_base_image="va_cpp_grpc",
    ),
]


def component(name):
    for c in components:
        if c.name == name:
            return c
    raise Exception("No such component: {}".format(name))


def ensure_network_exists(network_name):
    # TODO: check if network exists first
    try:
        call(
            "docker network create {}".format(network_name)
        )
    except CommandException:
        pass


class VATest(object):
    """
    
    Tests need to be isolated, and specify what dependencies they have on external containers (even if they have none)
    
    We need test db fixtures, to populate different components with the correct data
    
    Test data needs to be kept separate from dev/prod data, can we use docker volumes to isolate state?

    """

    def __init__(self, test_name, test_component, dependencies, test_cmd, volumes=None, environ=None):
        self.name = test_name
        self.test_cmd = test_cmd
        self.test_component_name = test_component
        # make a copy because we want to differentiate ourselves from non-test containers
        self.t = copy.deepcopy(component(self.test_component_name))
        self.convert_to_test(self.t)
        self.dependencies = []
        
        if volumes:
            self.t.volumes.update(volumes)
        if environ:
            self.t.environ.update(environ)

        for dep in dependencies:
            if isinstance(dep, dict):
                d_component = copy.deepcopy(component(dep['component']))
                # TODO: this override code should be part of component.
                for k, v in dep.iteritems():
                    if k == 'environ':
                        d_component.environ.update(v)
                    elif k == 'volumes':
                        d_component.volumes.update(v)
                    elif k == 'pre_cmd':
                        d_component.pre_cmd = v
                    elif k == 'component':
                        pass
                    else:
                        raise Exception("unknown dependency override for", k)
            else:
                d_component = copy.deepcopy(component(dep))
            self.convert_to_test(d_component, is_dependency=True)
            self.dependencies.append(d_component)
    

    def set_verbose(self, verbose):
        for dep in self.dependencies:
            dep.verbose = verbose
        self.t.verbose = verbose


    def convert_to_test(self, component, is_dependency=False):
        if is_dependency:
            # image name will stay the same as it is stored in t.image,
            # but container name is generated from self.name
            component.name = "va_test_{}_{}".format(self.name, component.name)
        else:
            # the test itself doesn't need a long name
            component.name = self.name
            component.cmd = self.test_cmd

        # remove publishing ports as these may already be bound if serve is running
        if component.port_mapping is not None:
            parts = component.port_mapping.split(":")
            if len(parts) == 2:
                component.port_mapping = parts[1]
            component.port_mapping = None
        

    @property
    def network_name(self):
        return self.name + "_network"

    def _setup_dependencies(self):
        missing_images = []
        for d in self.dependencies:
            if not d.image_exists():
                missing_images.append(d.color_name)
        if len(missing_images) > 0:
            print("missing images: ", missing_images)
            raise Exception("Missing test dependencies")
        
        print(color("  Configure and run test dependencies...", fg='green'))
        ensure_network_exists(self.network_name)
        for d in self.dependencies:
            if d.container_exists():
                d.stop_container()
                d.remove_container()
            d.launch_container(self.network_name)
            
            if d.pre_cmd:
                d.exec_in_container(d.pre_cmd)

    def _cleanup_dependencies(self):
        for d in self.dependencies:
            if d.container_exists():
                d.stop_container()
                d.remove_container()

    def setup(self):
        t = self.t
        if t.pull_image:
            t.pull()
        else:
            t.git_update()
            t.build_image() # TODO add args: (no_cache=args.no_cache, force_pull=args.force_pull)
    
        if t.container_exists():
            t.stop_container()
            t.remove_container()

        self._setup_dependencies()

        t.launch_container(self.network_name)
        
    def cleanup(self):
        t = self.t
        if t.container_exists():
            t.stop_container()
            t.remove_container()

        self._cleanup_dependencies()

    def run(self):
        exit_codes = serve_impl(self.dependencies + [self.t])

        if exit_codes[-1] is None or exit_codes != 0:
            # None means something else failed
            # non-zero means test failed
            return False

        return True


tests = [
    VATest(
        test_name="session-manager",
        test_component="va_session_manager",
        dependencies=[],
        test_cmd="bash test.sh",
    ),
    VATest(
        test_name="integration",
        test_component="va_test",
        dependencies=[
            'va_conceptnet_server',
            'va_sumo_server',
            'va_opencog_relex',
            {
                'component': 'va_ai',
                'environ': dict(
                    CONCEPTNET_HOSTNAME="va_test_integration_va_conceptnet_server_container",
                    CONTAINER_RELEX_HOSTNAME="va_test_integration_va_opencog_relex_container",
                )
            },
            {
                'component': 'va_session_manager',
                'environ': dict(
                    DB_FILE="/tmp/test-sessions.db"
                ),
                'pre_cmd': "./build_proto.sh && python3.6 create_db.py --data test_fixtures_integration.json --out /tmp/test-sessions.db"
            }
        ],
        volumes={
            P("protos"): PATH_PROTOS,
            P("tests/integration"): "/test"
        },
        environ=dict(
            SESSION_MANAGER_HOST="va_test_integration_va_session_manager_container",
            SESSION_MANAGER_PORT="50000"
        ),
        test_cmd="bash run-all-tests.sh",
    ),
    VATest(
        test_name="intelligence",
        test_component="va_test",
        dependencies=[
            'va_conceptnet_server',
            'va_sumo_server',
            'va_opencog_relex',
            {
                'component': 'va_ai',
                'environ': dict(
                    CONCEPTNET_HOSTNAME="va_test_intelligence_va_conceptnet_server_container",
                    CONTAINER_RELEX_HOSTNAME="va_test_intelligence_va_opencog_relex_container",
                )
            },
            {
                'component': 'va_session_manager',
                'environ': dict(
                    DB_FILE="/tmp/test-sessions.db"
                ),
                'pre_cmd': "./build_proto.sh && python3.6 create_db.py --data test_fixtures_intelligence.json --out /tmp/test-sessions.db"
            }
        ],
        volumes={
            P("protos"): PATH_PROTOS,
            P("tests/intelligence"): "/test"
        },
        environ=dict(
            SESSION_MANAGER_HOST="va_test_intelligence_va_session_manager_container",
            SESSION_MANAGER_PORT="50000"
        ),
        test_cmd="bash run-all-tests.sh",
    ),    
]


def get_test(name):
    for t in tests:
        if t.name == name:
            return t
    raise Exception("No such test: {}".format(name))


def make_process(command, summary=None, log_file=None, verbose=False):
    indent = " "*4
    if summary is not None:
        print(indent + color("{:<60}".format(summary), fg=2), end="\t")
    
    if log_file is None:
        out_f = tempfile.NamedTemporaryFile(prefix='va_manage_', bufsize=0, delete=False)
    else:
        out_f = open(log_file, 'w')
    
    if verbose:
        print ("\n{}  ".format(indent) + "cmd: " + color("'{}'\n{} ".format(command,indent), fg=12), end='')
    if summary or verbose:
        print (color(" -> {}".format(out_f.name), fg='cyan'))

    result = ""

    process = Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    return out_f, process


def call(command, summary=None, error_string=None, log_file=None, verbose=False, capture_output=False):
    indent = " "*4
    if summary is not None:
        print(indent + color("{:<60}".format(summary), fg=2), end="\t")
    
    if log_file is None:
        out_f = tempfile.NamedTemporaryFile(prefix='va_manage_', bufsize=0, delete=False)
    else:
        out_f = open(log_file, 'w')
    
    if verbose:
        print ("\n{}  ".format(indent) + "cmd: " + color("'{}'\n{} ".format(command,indent), fg=12), end='')
    if summary or verbose:
        print (color(" -> {}".format(out_f.name), fg='cyan'))

    result = ""

    process = Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    with process.stdout:
        for line in iter(process.stdout.readline, b''): # b'\n'-separated lines
            out_f.write(line)
            if capture_output:
                result += line
            if verbose:
                print(line, end="")
    exitcode = process.wait() # 0 means success

    out_f.close()

    if process.returncode != 0:
        if error_string is not None:
            print(error_string)
            print(result)
        raise(CommandException(error_string))
    return process, result


def set_verbose(components, verbose=False):
    for c in components:
        c.verbose = verbose


def build(args):
    if len(args.components) == 0:
        args.components = [c.name for c in components]
    
    if args.no_cache and not args.force_pull:
        print(color("Warning:", fg='red') +  "Building with --no-cache, but without --force-pull enabled.")
        print("You may be using stale local base images. Use --force-pull to ensure you have the latest.")

    build_components = [component(c_name) for c_name in args.components]
    # build components
    print("We will build these components: ", end='')
    for i, c in enumerate(build_components):
        print(c.color_name, end='')
        if i != len(build_components) - 1:
            print(", ", end='')
        else:
            print()

    set_verbose(build_components, args.verbose)

    print("Building images")
    for c in build_components:
        print("  " + c.color_name)
        if c.pull_image:
            c.pull()
        else:
            c.git_update()
            c.build_image(no_cache=args.no_cache, force_pull=args.force_pull)

def stop_containers(components, remove=False):
    for c in components:
        print("  " + c.color_name)
        c.stop_container()
        # container might have been run with --rm
        if c.container_exists() and remove:
            c.remove_container()

def stop(args):
    if len(args.components) == 0:
        args.components = [c.name for c in components if not c.is_base]
    stop_components = [component(c_name) for c_name in args.components]
    
    print("Stopping and removing containers for the follow components: ", end='')
    for i, c in enumerate(stop_components):
        print(c.color_name, end='')
        if i != len(stop_components) - 1:
            print(", ", end='')
        else:
            print()

    set_verbose(stop_components, args.verbose)
    stop_containers(stop_components, args.remove)


def launch(args):
    if len(args.components) == 0:
        args.components = [c.name for c in components if not c.is_base]
    serve_components = [component(c_name) for c_name in args.components]
    set_verbose(serve_components, args.verbose)

    missing_components = [c for c in serve_components if not c.is_base and not c.image_exists()]
    if missing_components:
        print("The following components are missing docker images:")
        for c in missing_components:
            print("- {}: {}".format(c.color_name, c.image))
        raise Exception("Missing docker images for components")

    existing_containers = [c for c in serve_components if not c.is_base and c.container_exists()]
    if existing_containers:
        print("The following components already have containers:")
        for c in existing_containers:
            print("  {:<20}: {}".format(c.color_name, c.container_name))
        
        if args.force:
            # stop existing containers and ensure they are removed if --force
            print("--force is enabled, stopping and removing existing containers:")
            stop_containers(existing_containers, remove=True)
        else:
            raise Exception("Docker containers already exist for components, use --force to replace them")
    
    print("Launching component containers:")
    ensure_network_exists(NETWORK_VA)
    
    for c in serve_components:
        print("  " + c.color_name)
        c.launch_container(NETWORK_VA)

def clean_shutdown(serve_components, processes, exitcodes, output_fs):
    causes_of_exit = []
    for i, x in enumerate(exitcodes):
        if x is not None:
            print("{}{}".format(serve_components[i].color_name, color(" exited, killing other processes", fg='red')))
            causes_of_exit.append(i)

    #  Manually find pid of each process inside container to kill it. See:
    #  https://github.com/singnet/virtual-assistant/pull/171#issuecomment-514875975
    #  
    #  When docker 19.09 is released we can probably get rid of this.
    for i, c in enumerate(serve_components):
        try:
            p, result = call("docker exec -t {} ps a".format( c.container_name ), capture_output=True )
        except CommandException:
            print("    failed to exec ps for ", c.container_name)
            continue
        lines = iter(result.splitlines())
        header = lines.next()
        exec_pids = []
    
        for line in lines:
            parts = line.split(None, 4)
            if parts[4] == c.cmd:
                exec_pids.append((line, parts[0]))
        if exec_pids:
            for line, pid in exec_pids:
                print("    '{}' -> killing pid {} in {}".format(line.strip(), pid, c.container_name))
                try:
                    call("docker exec -t {} {}".format( c.container_name, "kill {}".format(pid) ))
                except CommandException:
                    print("      failed")
        else:
            print("    no component pid found for", c.color_name)

    print("Waiting for processes to exit...")
    if any([p.returncode is None for p in processes]):
        time.sleep(0.5)
    
    for cause in causes_of_exit:
        print("==== Log for", c.color_name, "====")
        with open(output_fs[cause].name, 'rb') as f:
            for line in f:
                print(line, end="")


def serve_impl(serve_components):
    # Make sure to catch KeyboardInterrupt even when running in background
    #  https://stackoverflow.com/a/40785230/272238
    signal.signal(signal.SIGINT, signal.default_int_handler)

    q = Queue()
    threads=[]
    processes=[]
    
    output_fs=[]
    counter = 0

    for c in serve_components:
        print("  " + c.color_name)
        out_f, t, p = c.exec_component(q, counter)
        counter += 1
        output_fs.append(out_f)
        threads.append(t)
        processes.append(p)
    
    try:
        for t in threads:
            t.daemon = True
            t.start()
        
        while True:
            # allow any started processes to exit and be reported as failures.
            time.sleep(1.0)

            while True:
                try:
                    oid, line = q.get_nowait()
                except Empty:
                    break
                else:
                    out_f = output_fs[oid]
                    
                    out_f.write(line)
                    out_f.flush()

            exitcodes = [p.poll() for p in processes]
            
            if any(x is not None for x in exitcodes):
                clean_shutdown(serve_components, processes, exitcodes, output_fs)
                return exitcodes
    except KeyboardInterrupt:
        clean_shutdown(serve_components, processes, exitcodes, output_fs)

    return exitcodes


def serve(args):
    if len(args.components) == 0:
        args.components = [c.name for c in components if not c.is_base]

    serve_components = [component(c_name) for c_name in args.components]
    set_verbose(serve_components, args.verbose)

    # check containers exist:
    missing_containers = []
    for c in serve_components:
        if not c.container_exists():
            missing_containers.append(c)
    if len(missing_containers) > 0:
        print("Containers missing for: ", [c.name for c in missing_containers])
        print("Try launching them with './manage.py launch ", ' '.join(missing_containers), "'")
        return 1

    # serve components locally
    print("serving {}".format(args.components))

    serve_impl(serve_components)


def time_ago(iso_time_str):
    import datetime
    def parse(dt_str):
        dt, _, us= dt_str.partition(".")
        dt= datetime.datetime.strptime(dt, "%Y-%m-%dT%H:%M:%S")
        # this removes timezone segment. incorrect
        if '+' in us:
            us, tz = us.split('+')
            tz = int(tz.split(':')[0])
        elif '-' in us:
            us, tz = us.split('-')
            tz = - int(tz.split(':')[0])
        elif 'Z' in us:
            us = us.rstrip("Z")
            tz = 0
        return dt - datetime.timedelta(hours=tz)

    def td_format(td_object):
        seconds = int(td_object.total_seconds())
        periods = [
            ('year',        60*60*24*365),
            ('month',       60*60*24*30),
            ('day',         60*60*24),
            ('hour',        60*60),
            ('minute',      60),
            ('second',      1)
        ]

        strings=[]
        parts = 0
        for period_name, period_seconds in periods:
            if parts >= 2: continue
            if seconds > period_seconds:
                parts += 1
                period_value , seconds = divmod(seconds, period_seconds)
                has_s = 's' if period_value > 1 else ''
                strings.append("%s %s%s" % (period_value, period_name, has_s))

        return ", ".join(strings)

    then_dt = parse(iso_time_str)
    now_dt = datetime.datetime.utcnow()
    duration = now_dt - then_dt
    return td_format(duration)

def status(args):
    print("Images present:")    
    # Check component images exist
    for c in components:
        print(color("{:>35}".format(c.image), fg=10), end="")
        if c.image_exists():
            print(" - Created {} ago (last tagged {} ago)".format(
                time_ago(c.inspect_image()['Created']),
                time_ago(c.inspect_image()['Metadata']['LastTagTime'])
                ))
        else:
            print(" - " + color("Missing", fg='red'))
        
    print("Container status:")
    # Check component containers are running
    for c in components:
        if c.is_base:
            continue
        print(color("{:>35}".format(c.container_name), fg=10), end="")
        if c.container_exists():
            details = c.inspect_container()
            details_str = ""
            if details["State"]["Running"]:
                details_str += "Running"
                if details["State"]["StartedAt"]:
                    details_str += " for {}".format(time_ago(details["State"]["StartedAt"]))
            else:
                details_str += "Stopped"
                if details["State"]["FinishedAt"]:
                    details_str += " for {}".format(time_ago(details["State"]["FinishedAt"]))
                details_str = color(details_str, fg="grey")
            print(" - {}".format(details_str))
        else:
            print(" - " + color("Missing", fg='red'))

def test(args):
    if len(args.tests) == 0:
        args.tests = [t.name for t in tests]

    tests_to_run = [get_test(t_name) for t_name in args.tests]
    for t in tests_to_run:
        t.set_verbose(args.verbose)

    # TODO - validation of test environment, are containers running and processing active?
    for t in tests_to_run:
        print("=== Starting test", t.name, "===")
        try:
            t.setup()

            if t.run():
                print("===", color("test " + t.name + " passed", fg='green'), "===")
            else:
                print("===", color("test " + t.name + " failed", fg='red'), "===")
        except Exception as e:
            print(str(e))
        
        t.cleanup()
    

def run():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command')

    build_parser = subparsers.add_parser('build', help='Build docker images for components')
    build_parser.add_argument('components', nargs='*', help='components to build')
    build_parser.add_argument('--no-cache', action='store_true', help='run docker build with --no-cache')
    build_parser.add_argument('--force-pull', action='store_true', help='always get most recent FROM base image')
    build_parser.add_argument('--verbose', action='store_true')

    launch_parser = subparsers.add_parser('launch', help='Start containers for these components')
    launch_parser.add_argument('components', nargs='*', help='Components to start containers for')
    launch_parser.add_argument('--force', action='store_true')
    launch_parser.add_argument('--verbose', action='store_true')

    stop_parser = subparsers.add_parser('stop', help='Stop containers for these components')
    stop_parser.add_argument('components', nargs='*', help='Components to stop containers for')
    stop_parser.add_argument('--remove', action='store_true', help='Also remove container after stopping')
    stop_parser.add_argument('--verbose', action='store_true')

    serve_parser = subparsers.add_parser('serve', help='Serve components inside of already started containers')
    serve_parser.add_argument('components', nargs='*', help='Components to serve')
    serve_parser.add_argument('--verbose', action='store_true')

    build_db_parser = subparsers.add_parser('build-conceptnet-db', help='Build the conceptnet db')
    build_db_parser.add_argument('--fresh', action='store_true', help='Do full rebuild instead of restoring from db dump')
    build_db_parser.add_argument('--verbose', action='store_true')

    test_parser = subparsers.add_parser('test', help='Run tests')
    test_parser.add_argument('tests', nargs='*', help='components to test')
    test_parser.add_argument('--verbose', action='store_true')

    status_parser = subparsers.add_parser('status', help='Report on the status of the system components')

    deploy_parser = subparsers.add_parser('deploy', help='Deploy the system remotely')

    tool_parser = subparsers.add_parser('tool', help='Various utilities')
    tool_parser.add_argument('--rm-unused-images', action='store_true', help='remove all untagged docker images')
    tool_parser.add_argument('--top', action='store_true', help='show processes in each container')

    args = parser.parse_args()

    if args.command == "build":
        build(args)
        
    elif args.command == "serve":
        serve(args)

    elif args.command == "launch":
        launch(args)
    
    elif args.command == "stop":
        stop(args)

    elif args.command == "test":
        test(args)

    elif args.command == "build-conceptnet-db":
        c = component("va_conceptnet_server")
        c.launch_container(NETWORK_VA)
        if args.fresh:
            c.exec_in_container("bash conceptnet.sh build")
        else:
            raise NotImplementedError("Restore from pg dump still to be implemented - see #178")

    elif args.command == "status":
        status(args)

    elif args.command == "deploy":
        raise NotImplementedError("Implement remote deployment")

    elif args.command == "tool":
        # I always forget this command:
        if args.rm_unused_images:
            call(
                "docker image prune",
                "pruning untagged images",
                "error removing untagged images"
            )
        
        if args.top:
            for c in components:
                if c.is_base: continue
                call(
                    "docker top {}".format(c.container_name),
                    "docker top {}".format(c.container_name),
                    "error removing running top",
                    verbose=True
                )

if __name__ == "__main__":
    run()
