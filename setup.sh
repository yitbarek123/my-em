#!/bin/bash

############################################
#    Containers, images, and dockerfiles   #
############################################

# containers
CONTAINER_AI_ENGINE="va_ai_server_container"
CONTAINER_OPENCOG_RELEX="va_opencog_relex_container"
CONTAINER_CONCEPTNET_SERVER="va_conceptnet_server_container"
CONTAINER_SUMO_SERVER="va_sumo_server_container"
CONTAINER_SESSION_MANAGER="va_session_manager_container"

# images
IMAGE_AI_ENGINE="va_ai"
IMAGE_OPENCOG_RELEX="va_opencog_relex"
IMAGE_CONCEPTNET_SERVER="va_conceptnet_server"
IMAGE_SUMO_SERVER="va_sumo_server"
IMAGE_SESSION_MANAGER="va_session_manager"
IMAGE_CPP_GRPC="va_cpp_grpc"
IMAGE_VA_OPENCOG="va_opencog"

# dockerfiles
DOCKERFILE_AI_ENGINE="./src/virtual-assistant/Dockerfile"
DOCKERFILE_CONCEPTNET_SERVER="./src/conceptnet-server/Dockerfile"
DOCKERFILE_SUMO_SERVER="./src/sumo-server/Dockerfile"
DOCKERFILE_SESSION_MANAGER="./src/session-manager/Dockerfile"
DOCKERFILE_CPP_GRPC="./dependencies/dockerfiles/BasicGRPCDockerfile"
DOCKERFILE_VA_OPENCOG="./dependencies/dockerfiles/VAOpencogDockerfile"

# environments
ENVIRONMENT_AI_ENGINE="./src/virtual-assistant"
ENVIRONMENT_CONCEPTNET_SERVER="./src/conceptnet-server"
ENVIRONMENT_SUMO_SERVER="./src/sumo-server"
ENVIRONMENT_SESSION_MANAGER="./src/session-manager"
ENVIRONMENT_OPENCOG_RELEX="./src/opencog-docker/opencog/relex"

# infra-network
NETWORK_VA="va-network"

# protofiles base folder to be created inside containers
PATH_PROTOS="/home/protos/"

# virtual-assistant libraries and extensions to be created inside containers
PATH_VA_LIBRARIES="/home/va-lib"

# virtual-assistant knowledge bases to be created inside containers
PATH_VA_KNOWLEDGE_BASES="/home/knowledge"

# build log file
BUILD_LOG="output.log"

# exposed infra-network ports
PORT_SESSION_MANAGER=7084
PORT_SUMO_SERVER=7083
PORT_CONCEPTNET_SERVER=7082
PORT_AI_ENGINE_SERVICES=7080
PORT_OPENCOG_RELEX=4444

# do not change the following values
INTERNAL_PORT_SESSION_MANAGER=50000
INTERNAL_PORT_SUMO_SERVER=9999
INTERNAL_PORT_AI_ENGINE_SERVICES=7032
INTERNAL_PORT_OPENCOG_RELEX=4444
INTERNAL_PORT_CONCEPTNET_SERVER=80

# control variables
BUILD_SESSION_MANAGER=false
BUILD_SUMO_SERVER=false
BUILD_CONCEPTNET_SERVER=false
BUILD_OPENCOG_RELEX=false
BUILD_AI_ENGINE=false

BUILD_CONCEPTNET_DATABASE=false

BUILD_DEPENDENCIES_OPENCOG=false
BUILD_DEPENDENCIES_CPPGRPC=false

DEPLOY_SESSION_MANAGER=false
DEPLOY_SUMO_SERVER=false
DEPLOY_CONCEPTNET_SERVER=false
DEPLOY_OPENCOG_RELEX=false
DEPLOY_AI_ENGINE=false

CACHE_OPTION=true
DOCKER_CACHE_FLAG=""

case $1 in
    all)
        BUILD_AI_ENGINE=true
        BUILD_OPENCOG_RELEX=true
        BUILD_CONCEPTNET_SERVER=true
        BUILD_SUMO_SERVER=true
        BUILD_SESSION_MANAGER=true
        BUILD_CONCEPTNET_DATABASE=true

        DEPLOY_AI_ENGINE=true
        DEPLOY_OPENCOG_RELEX=true
        DEPLOY_CONCEPTNET_SERVER=true
        DEPLOY_SUMO_SERVER=true
        DEPLOY_SESSION_MANAGER=true
    ;;
    build-all)
        BUILD_AI_ENGINE=true
        BUILD_OPENCOG_RELEX=true
        BUILD_CONCEPTNET_SERVER=true
        BUILD_SUMO_SERVER=true
        BUILD_SESSION_MANAGER=true
    ;;
    deploy-all)
        DEPLOY_AI_ENGINE=true
        DEPLOY_OPENCOG_RELEX=true
        DEPLOY_CONCEPTNET_SERVER=true
        DEPLOY_SUMO_SERVER=true
        DEPLOY_SESSION_MANAGER=true
    ;;
    build) 
        if [ "$3" = "no_cache" ] ; then
            CACHE_OPTION=false
        fi
        if [ "$2" = "dep_grpc" ] ; then
            BUILD_DEPENDENCIES_CPPGRPC=true
        fi
        if [ "$2" = "dep_opencog" ] ; then
            BUILD_DEPENDENCIES_OPENCOG=true
        fi
        if [ "$2" = "ai" ] ; then 
            BUILD_AI_ENGINE=true
            BUILD_OPENCOG_RELEX=true
        fi
        if [ "$2" = "conceptnet" ] ; then 
            BUILD_CONCEPTNET_SERVER=true 
        fi
        if [ "$2" = "sumo" ] ; then 
            BUILD_SUMO_SERVER=true 
        fi
        if [ "$2" = "session-manager" ] ; then 
            BUILD_SESSION_MANAGER=true 
        fi
        if [ "$2" = "conceptnet-database" ] ; then
            BUILD_CONCEPTNET_DATABASE=true
        fi
    ;;
    deploy) 
        if [ "$2" = "ai" ] ; then 
            DEPLOY_AI_ENGINE=true
            DEPLOY_OPENCOG_RELEX=true
        fi
        if [ "$2" = "conceptnet" ] ; then 
            DEPLOY_CONCEPTNET_SERVER=true 
        fi
        if [ "$2" = "sumo" ] ; then 
            DEPLOY_SUMO_SERVER=true 
        fi 
        if [ "$2" = "session-manager" ] ; then 
            DEPLOY_SESSION_MANAGER=true 
        fi
    ;;
    *) help ;;
esac

# set docker build cache option
if [ $CACHE_OPTION = false ] ; then
    DOCKER_CACHE_FLAG="--no-cache"
fi

# clear terminal for better visualization
reset

echo
echo -e "\e[96m############################################"
echo "#              Configuration               #"
echo -e "############################################\e[39m"
echo

if [ $CACHE_OPTION = false ] ; then
    echo
    echo -e "\e[96m DOCKER IMAGES WILL BE BUILT WITH --no-cache OPTION !!!"
fi

if [ $DEPLOY_OPENCOG_RELEX = true ] ||
    [ $DEPLOY_SUMO_SERVER = true ] ||
    [ $DEPLOY_CONCEPTNET_SERVER = true ] ||
    [ $DEPLOY_AI_ENGINE = true ] ||
    [ $DEPLOY_SESSION_MANAGER = true ] ; then

    echo
    echo "Containers to be created:"

    if [ $DEPLOY_AI_ENGINE = true ] ; then

        echo -e "\e[32m\t$CONTAINER_AI_ENGINE"

    fi

    if [ $DEPLOY_OPENCOG_RELEX = true ] ; then
        
        echo -e "\e[32m\t$CONTAINER_OPENCOG_RELEX"

    fi

    if [ $DEPLOY_CONCEPTNET_SERVER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_CONCEPTNET_SERVER"

    fi

    if [ $DEPLOY_SUMO_SERVER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_SUMO_SERVER"

    fi

    if [ $DEPLOY_SESSION_MANAGER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_SESSION_MANAGER"

    fi

    echo
    echo -e "\e[39mExposed network ports:"

    if [ $DEPLOY_AI_ENGINE = true ] ; then

        echo -e "\e[32m\t$CONTAINER_AI_ENGINE\e[93m -> \e[96m$PORT_AI_ENGINE_SERVICES"

    fi

    if [ $DEPLOY_OPENCOG_RELEX = true ] ; then
        
        echo -e "\e[32m\t$CONTAINER_OPENCOG_RELEX\e[93m -> \e[96m$PORT_OPENCOG_RELEX"

    fi

    if [ $DEPLOY_CONCEPTNET_SERVER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_CONCEPTNET_SERVER\e[93m -> \e[96m$PORT_CONCEPTNET_SERVER"

    fi

    if [ $DEPLOY_SUMO_SERVER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_SUMO_SERVER\e[93m -> \e[96m$PORT_SUMO_SERVER"

    fi

    if [ $DEPLOY_SESSION_MANAGER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_SESSION_MANAGER\e[93m -> \e[96m$PORT_SESSION_MANAGER"

    fi    
    
    echo
    echo -e "\e[39mInfra-network:"
    echo -e "\e[32m\t$NETWORK_VA"

    echo
    echo -e "\e[39mInternal $NETWORK_VA components listening ports:"

    if [ $DEPLOY_AI_ENGINE = true ] ; then

        echo -e "\e[32m\t$CONTAINER_AI_ENGINE\e[93m -> \e[96m$INTERNAL_PORT_AI_ENGINE_SERVICES"

    fi

    if [ $DEPLOY_OPENCOG_RELEX = true ] ; then
        
        echo -e "\e[32m\t$CONTAINER_OPENCOG_RELEX\e[93m -> \e[96m$INTERNAL_PORT_OPENCOG_RELEX"

    fi

    if [ $DEPLOY_CONCEPTNET_SERVER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_CONCEPTNET_SERVER\e[93m -> \e[96m$INTERNAL_PORT_CONCEPTNET_SERVER"

    fi

    if [ $DEPLOY_SUMO_SERVER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_SUMO_SERVER\e[93m -> \e[96m$INTERNAL_PORT_SUMO_SERVER"

    fi

    if [ $DEPLOY_SESSION_MANAGER = true ] ; then

        echo -e "\e[32m\t$CONTAINER_SESSION_MANAGER\e[93m -> \e[96m$INTERNAL_PORT_SESSION_MANAGER"

    fi
fi

if [ $BUILD_OPENCOG_RELEX = true ] || 
    [ $BUILD_SUMO_SERVER = true ] || 
    [ $BUILD_CONCEPTNET_SERVER = true ] || 
    [ $BUILD_AI_ENGINE = true ] ||
    [ $BUILD_SESSION_MANAGER = true ] ||
    [ $BUILD_DEPENDENCIES_OPENCOG = true ] ||
    [ $BUILD_DEPENDENCIES_CPPGRPC = true ]; then

    echo
    echo -e "\e[39mImages to be built:"

    if [ $BUILD_AI_ENGINE = true ] ; then

        echo -e "\e[32m\t$IMAGE_AI_ENGINE"

    fi

    if [ $BUILD_OPENCOG_RELEX = true ] ; then
        
        echo -e "\e[32m\t$IMAGE_OPENCOG_RELEX"

    fi

    if [ $BUILD_CONCEPTNET_SERVER = true ] ; then

        echo -e "\e[32m\t$IMAGE_CONCEPTNET_SERVER"

    fi

    if [ $BUILD_SUMO_SERVER = true ] ; then

        echo -e "\e[32m\t$IMAGE_SUMO_SERVER"

    fi

    if [ $BUILD_SESSION_MANAGER = true ] ; then

        echo -e "\e[32m\t$IMAGE_SESSION_MANAGER"

    fi

    if [ $BUILD_DEPENDENCIES_OPENCOG = true ] ; then

        echo -e "\e[32m\t$IMAGE_VA_OPENCOG"

    fi

    if [ $BUILD_DEPENDENCIES_CPPGRPC = true ] ; then

        echo -e "\e[32m\t$IMAGE_CPP_GRPC"

    fi

    echo
    echo -e "\e[39mDockerfiles used:"

    if [ $BUILD_AI_ENGINE = true ] ; then

        echo -e "\e[32m\t$DOCKERFILE_AI_ENGINE"

    fi

    if [ $BUILD_CONCEPTNET_SERVER = true ] ; then

        echo -e "\e[32m\t$DOCKERFILE_CONCEPTNET_SERVER"

    fi

    if [ $BUILD_SUMO_SERVER = true ] ; then

        echo -e "\e[32m\t$DOCKERFILE_SUMO_SERVER"

    fi

    if [ $BUILD_SESSION_MANAGER = true ] ; then

        echo -e "\e[32m\t$DOCKERFILE_SESSION_MANAGER"

    fi

    if [ $BUILD_DEPENDENCIES_OPENCOG = true ] ; then

        echo -e "\e[32m\t$DOCKERFILE_VA_OPENCOG"

    fi

    if [ $BUILD_DEPENDENCIES_CPPGRPC = true ] ; then

        echo -e "\e[32m\t$DOCKERFILE_CPP_GRPC"

    fi
fi

echo
echo -e "\e[39mProtobuffer files volume path:"
echo -e "\e[32m\t$PATH_PROTOS"

echo
echo -e "\e[39mLog file path:"
echo -e "\e[32m\t./$BUILD_LOG"

echo
echo -e "\e[96m############################################"
echo "#      Removing conflicting references     #"
echo -e "############################################\e[39m"

# clear log file
rm -rf $BUILD_LOG

if [ $DEPLOY_OPENCOG_RELEX = true ] ||
    [ $DEPLOY_SUMO_SERVER = true ] ||
    [ $DEPLOY_CONCEPTNET_SERVER = true ] ||
    [ $DEPLOY_AI_ENGINE = true ] ||
    [ $DEPLOY_SESSION_MANAGER = true ] ; then

    echo
    echo -e "\e[39mRemoving conflicting containers."

    if [ $DEPLOY_AI_ENGINE = true ] ; then

            docker stop $CONTAINER_AI_ENGINE &>> $BUILD_LOG || echo -e "\e[93m\tContainer $CONTAINER_AI_ENGINE does not exists."
            docker rm -f $CONTAINER_AI_ENGINE &>> $BUILD_LOG

    fi

    if [ $DEPLOY_OPENCOG_RELEX = true ] ; then

            docker stop $CONTAINER_OPENCOG_RELEX &>> $BUILD_LOG || echo -e "\e[93m\tContainer $CONTAINER_OPENCOG_RELEX does not exists."
            docker rm -f $CONTAINER_OPENCOG_RELEX &>> $BUILD_LOG

    fi

    if [ $DEPLOY_CONCEPTNET_SERVER = true ] ; then

            docker stop $CONTAINER_CONCEPTNET_SERVER &>> $BUILD_LOG || echo -e "\e[93m\tContainer $CONTAINER_CONCEPTNET_SERVER does not exists."
            docker rm -f $CONTAINER_CONCEPTNET_SERVER &>> $BUILD_LOG

    fi

    if [ $DEPLOY_SESSION_MANAGER = true ] ; then

            docker stop $CONTAINER_SESSION_MANAGER &>> $BUILD_LOG || echo -e "\e[93m\tContainer $CONTAINER_SESSION_MANAGER does not exists."
            docker rm -f $CONTAINER_SESSION_MANAGER &>> $BUILD_LOG

    fi

    if [ $DEPLOY_SUMO_SERVER = true ] ; then

            docker stop $CONTAINER_SUMO_SERVER &>> $BUILD_LOG || echo -e "\e[93m\tContainer $CONTAINER_SUMO_SERVER does not exists."
            docker rm -f $CONTAINER_SUMO_SERVER &>> $BUILD_LOG

    fi
fi

if [ $BUILD_OPENCOG_RELEX = true ] || 
    [ $BUILD_SUMO_SERVER = true ] || 
    [ $BUILD_CONCEPTNET_SERVER = true ] || 
    [ $BUILD_AI_ENGINE = true ] ||
    [ $BUILD_SESSION_MANAGER = true ] ||
    [ $BUILD_DEPENDENCIES_OPENCOG = true ] ||
    [ $BUILD_DEPENDENCIES_CPPGRPC = true ] ; then

    echo
    echo -e "\e[39mRemoving conflicting images."
    
    if [ $BUILD_AI_ENGINE = true ] ; then

            docker rmi $IMAGE_AI_ENGINE &>> $BUILD_LOG || echo -e "\e[93m\tImage $IMAGE_AI_ENGINE does not exists."

    fi

    if [ $BUILD_OPENCOG_RELEX = true ] ; then

            docker rmi $IMAGE_OPENCOG_RELEX &>> $BUILD_LOG || echo -e "\e[93m\tImage $IMAGE_OPENCOG_RELEX does not exists."

    fi

    if [ $BUILD_CONCEPTNET_SERVER = true ] ; then

            docker rmi $IMAGE_CONCEPTNET_SERVER &>> $BUILD_LOG || echo -e "\e[93m\tImage $IMAGE_CONCEPTNET_SERVER does not exists."

    fi

    if [ $BUILD_SESSION_MANAGER = true ] ; then

            docker rmi $IMAGE_SESSION_MANAGER &>> $BUILD_LOG || echo -e "\e[93m\tImage $IMAGE_SESSION_MANAGER does not exists."

    fi

    if [ $BUILD_SUMO_SERVER = true ] ; then

            docker rmi $IMAGE_SUMO_SERVER &>> $BUILD_LOG || echo -e "\e[93m\tImage $IMAGE_SUMO_SERVER does not exists."

    fi

    if [ $BUILD_DEPENDENCIES_CPPGRPC = true ] ; then

            docker rmi $IMAGE_CPP_GRPC &>> $BUILD_LOG || echo -e "\e[93m\tImage $IMAGE_CPP_GRPC does not exists."

    fi

    if [ $BUILD_DEPENDENCIES_OPENCOG = true ] ; then
      
            docker rmi $IMAGE_VA_OPENCOG &>> $BUILD_LOG || echo -e "\e[93m\tImage $IMAGE_VA_OPENCOG does not exists."
    
    fi
fi

# echo -e "\e[39mRemoving conflicting networks."
# docker network rm $NETWORK_VA &>> $BUILD_LOG || echo -e "\e[93m\tNo conflicting network was found."

echo -e "\e[39mCreating $NETWORK_VA network."
docker network create $NETWORK_VA &>> $BUILD_LOG

rm -rf sumo-server &>> $BUILD_LOG

if [ $BUILD_CONCEPTNET_SERVER = true  -o $BUILD_SUMO_SERVER = true ] ; then

    echo
    echo -e "\e[96m############################################"
    echo "#         Downloading dependencies         #"
    echo -e "############################################\e[39m"
    echo

fi

# for the conceptnet server
if [ $BUILD_CONCEPTNET_SERVER = true ] ; then

    rm -rf src/conceptnet-server &>> $BUILD_LOG

    echo "Downloading concepnet 5 scheme api."
    git clone https://github.com/singnet/conceptnet-server.git src/conceptnet-server &>> $BUILD_LOG

fi

# for the sumo server
if [ $BUILD_SUMO_SERVER = true ] ; then

    rm -rf src/sumo-server &>> $BUILD_LOG

    echo "Downloading sumo server scheme api."
    git clone https://github.com/singnet/sumo-server.git src/sumo-server &>> $BUILD_LOG

fi

if [ $BUILD_OPENCOG_RELEX = true ] || 
    [ $BUILD_SUMO_SERVER = true ] || 
    [ $BUILD_CONCEPTNET_SERVER = true ] || 
    [ $BUILD_AI_ENGINE = true ] ||
    [ $BUILD_SESSION_MANAGER = true ] ||
    [ $BUILD_DEPENDENCIES_CPPGRPC = true ] ||
    [ $BUILD_DEPENDENCIES_OPENCOG = true ] ; then

    echo
    echo -e "\e[96m############################################"
    echo "#           Building all images            #"
    echo -e "############################################\e[39m"
    echo

fi

# build the concept net 5 scheme api image
if [ $BUILD_CONCEPTNET_SERVER = true ] ; then
    echo "Building and configuring the conceptnet 5 scheme API docker image."
    docker build \
        ${DOCKER_CACHE_FLAG} \
        -f $DOCKERFILE_CONCEPTNET_SERVER \
        -t $IMAGE_CONCEPTNET_SERVER \
        $ENVIRONMENT_CONCEPTNET_SERVER &>> $BUILD_LOG || { echo -e "\e[31mUnable to build and configure the conceptnet 5 scheme API docker image." ; exit 1; }
fi

# build the sumo server api image
if [ $BUILD_SUMO_SERVER = true ] ; then
    echo "Building and configuring the sumo scheme API docker image."
    docker build \
        ${DOCKER_CACHE_FLAG} \
        -f $DOCKERFILE_SUMO_SERVER \
        -t $IMAGE_SUMO_SERVER \
        $ENVIRONMENT_SUMO_SERVER &>> $BUILD_LOG || { echo -e "\e[31mUnable to build and configure the sumo server scheme API docker image." ; exit 1; }
fi

# build the dependencies () docker images )
if [ $BUILD_DEPENDENCIES_CPPGRPC = true ] ; then
    echo "Building and configuring the cpp grpc docker image."
    docker build \
        ${DOCKER_CACHE_FLAG} \
        -f $DOCKERFILE_CPP_GRPC \
        -t $IMAGE_CPP_GRPC \
        . &>> $BUILD_LOG || { echo -e "\e[31mUnable to build the cpp GRPC docker image." ; exit 1; }
fi

if [ $BUILD_DEPENDENCIES_OPENCOG = true ] ; then
    echo "Building and configuring the opencog-dev docker image."
    docker build \
        ${DOCKER_CACHE_FLAG} \
        -f $DOCKERFILE_VA_OPENCOG \
        -t $IMAGE_VA_OPENCOG \
        . &>> $BUILD_LOG || { echo -e "\e[31mUnable to build the virtual assistant opencog docker image." ; exit 1; }
fi

# pull relex image and tag it properly
if [ $BUILD_OPENCOG_RELEX = true ] ; then
    echo "Downloading and configuring relex docker image."
    { docker pull opencog/relex; docker tag opencog/relex $IMAGE_OPENCOG_RELEX; docker rmi opencog/relex; } &>> $BUILD_LOG || { echo -e "\e[31mUnable pull the relex server docker image." ; exit 1; }
fi

# build the AI engine, opencog, relex, and opencog postgres images
if [ $BUILD_AI_ENGINE = true ] ; then
    echo "Building and configuring the AI engine docker image."
    docker build \
        ${DOCKER_CACHE_FLAG} \
        -f $DOCKERFILE_AI_ENGINE \
        -t $IMAGE_AI_ENGINE \
        $ENVIRONMENT_AI_ENGINE &>> $BUILD_LOG || { echo -e "\e[31mUnable to build the AI engine docker image." ; exit 1; }
fi

# build session manager image
if [ $BUILD_SESSION_MANAGER = true ] ; then
    echo "Building and configuring the session management server docker image."
    docker build \
        ${DOCKER_CACHE_FLAG} \
        -f $DOCKERFILE_SESSION_MANAGER \
        -t $IMAGE_SESSION_MANAGER \
        $ENVIRONMENT_SESSION_MANAGER &>> $BUILD_LOG || { echo -e "\e[31mUnable to build the session management server docker image." ; exit 1; }
fi



if [ $DEPLOY_OPENCOG_RELEX = true ] ||
    [ $DEPLOY_SUMO_SERVER = true ] ||
    [ $DEPLOY_CONCEPTNET_SERVER = true ] ||
    [ $DEPLOY_AI_ENGINE = true ] ||
    [ $DEPLOY_SESSION_MANAGER = true ] ; then

    echo
    echo -e "\e[96m############################################"
    echo "#   Creating and starting all containers   #"
    echo -e "############################################\e[39m"
    echo

fi

# up Opencog Relex container for the AI engine sentences parsing
if [ $DEPLOY_OPENCOG_RELEX = true ] ; then

    echo "Creating and running the relex server container."
    docker run -d \
        -p $PORT_OPENCOG_RELEX:$INTERNAL_PORT_OPENCOG_RELEX \
        --name $CONTAINER_OPENCOG_RELEX \
        --network=$NETWORK_VA \
        --restart unless-stopped \
        $IMAGE_OPENCOG_RELEX \
        tail -f /dev/null &>> $BUILD_LOG || { echo -e "\e[31mUnable to run the relex server container." ; exit 1; }

fi

# up the sumo server container for the AI engine context enrichment
if [ $DEPLOY_SUMO_SERVER = true ] ; then

    echo "Creating and running the sumo scheme API server container."
    docker run -d \
        -p $PORT_SUMO_SERVER:$INTERNAL_PORT_SUMO_SERVER \
        --rm \
        --network=$NETWORK_VA \
        --name=$CONTAINER_SUMO_SERVER \
        $IMAGE_SUMO_SERVER \
        tail -f /dev/null &>> $BUILD_LOG || { echo -e "\e[31mUnable to run the sumo scheme API server container." ; exit 1; }

fi

# up concepnet 5 container for the AI engine context enrichment
if [ $DEPLOY_CONCEPTNET_SERVER = true ] ; then

    echo "Creating and running the conceptnet 5 scheme API server container."
    docker run -d \
        -p $PORT_CONCEPTNET_SERVER:$INTERNAL_PORT_CONCEPTNET_SERVER \
        --rm \
        --privileged=true \
        --network=$NETWORK_VA \
        --name $CONTAINER_CONCEPTNET_SERVER \
        --stop-timeout 30 \
        --mount source="conceptnet-data",target=/home/conceptnet/ \
        --mount source="conceptnet-db",target=/var/lib/postgresql/10/main \
        $IMAGE_CONCEPTNET_SERVER \
        tail -f /dev/null &>> $BUILD_LOG || { echo -e "\e[31mUnable to run the conceptnet 5 scheme API server container." ; exit 1; }

fi

# up AI engine container to process information. This contains GHOST and OpenCog APIs.
if [ $DEPLOY_AI_ENGINE = true ] ; then

    echo "Creating and running the AI engine server container."
    docker run -d \
        -v $(pwd)/lib:$PATH_VA_LIBRARIES \
        -v $(pwd)/knowledge:$PATH_VA_KNOWLEDGE_BASES \
        -v "$(pwd)"/protos:$PATH_PROTOS \
        -p $PORT_AI_ENGINE_SERVICES:$INTERNAL_PORT_AI_ENGINE_SERVICES \
        --rm \
        --network=$NETWORK_VA \
	--env GUILE_AUTO_COMPILE=0 \
        --env LD_LIBRARY_PATH=/usr/local/lib/opencog:/usr/local/lib/opencog/modules \
        --env CONCEPTNET_HOSTNAME=$CONTAINER_CONCEPTNET_SERVER \
        --env CONTAINER_RELEX_HOSTNAME=$CONTAINER_OPENCOG_RELEX \
        --env OPENCOG_SERVER_PORT=$INTERNAL_PORT_AI_ENGINE_SERVICES \
        --env PORT_RELEX_SERVER=$PORT_OPENCOG_RELEX \
        --env PORT_CONCEPTNET_SERVER=$INTERNAL_PORT_CONCEPTNET_SERVER \
        --env PROTOS_PATH=$PATH_PROTOS \
        --name $CONTAINER_AI_ENGINE \
        $IMAGE_AI_ENGINE \
        tail -f /dev/null &>> $BUILD_LOG || { echo -e "\e[31mUnable to run the AI engine REST API server container." ; exit 1; }

fi

# up session manager to allow users and third-party applications to communicate with the AI engine
if [ $DEPLOY_SESSION_MANAGER = true ] ; then    

    echo "Creating and running the session management server container."
    docker run -d \
        -v "$(pwd)"/protos:$PATH_PROTOS \
        -p $PORT_SESSION_MANAGER:$INTERNAL_PORT_SESSION_MANAGER \
        --network=$NETWORK_VA \
        --rm \
        --env PROTOS_PATH=$PATH_PROTOS \
        --env INTERNAL_PORT_SESSION_MANAGER=$INTERNAL_PORT_SESSION_MANAGER \
        --name $CONTAINER_SESSION_MANAGER \
        $IMAGE_SESSION_MANAGER \
        tail -f /dev/null &>> $BUILD_LOG || { echo -e "\e[31mUnable to run the session management server container." ; exit 1; }

fi

if [ $BUILD_CONCEPTNET_DATABASE = true ] ; then

    echo
    echo -e "\e[96m############################################"
    echo "#      Building conceptnet 5 database      #"
    echo -e "#     \e[93mThis step can take several hours\e[96m     #"
    echo -e "############################################\e[39m"
    echo

docker exec $CONTAINER_CONCEPTNET_SERVER bash conceptnet.sh build &>> $BUILD_LOG || { echo -e "\e[31mUnable to build the conceptnet 5 database."; exit 1; }

fi

if [ $DEPLOY_OPENCOG_RELEX = true ] ||
    [ $DEPLOY_SUMO_SERVER = true ] ||
    [ $DEPLOY_CONCEPTNET_SERVER = true ] ||
    [ $DEPLOY_AI_ENGINE = true ] ||
    [ $DEPLOY_SESSION_MANAGER = true ] ; then

    echo
    echo -e "\e[96m############################################"
    echo "#     Starting all servers and services    #"
    echo -e "############################################\e[39m"
    echo

fi

# RUNS SUMO SERVER
# Used to enrich the context for the AI engine.
if [ $DEPLOY_SUMO_SERVER = true ] ; then

    echo "Starting the sumo scheme API server."
    docker exec -dt $CONTAINER_SUMO_SERVER bash run.sh &>> $BUILD_LOG || { echo -e "\e[31mCannot start the Sumo scheme API server." ; exit 1; }

fi

# RUNS CONCEPNET5 SERVER
# Used to enrich the context for the AI engine by providing semantic networks of concepts.
if [ $DEPLOY_CONCEPTNET_SERVER = true ] ; then
    
    echo "Starting the conceptnet5 scheme API server."
    docker exec -dt $CONTAINER_CONCEPTNET_SERVER bash conceptnet.sh start &>> $BUILD_LOG || { echo -e "\e[31mCannot start the Conceptnet5 scheme API server." ; exit 1; }

fi

# RUNS RELEX SERVER
# Used to allow the AI engine to parse english sentences.
if [ $DEPLOY_OPENCOG_RELEX = true ] ; then

    echo "Starting the relex server."
    docker exec -dt $CONTAINER_OPENCOG_RELEX bash opencog-server.sh &>> $BUILD_LOG || { echo -e "\e[31mCannot start the relex server." ; exit 1; }

fi

# RUNS AI ENGINE
# Runs AI engine REST API. It contains GHOST, OpenPsi, and OpenCog.
if [ $DEPLOY_AI_ENGINE = true ] ; then

    echo "Starting the AI engine server."    
    docker exec -dt $CONTAINER_AI_ENGINE ./bin/server &>> $BUILD_LOG || { echo -e "\e[31mCannot start the AI engine REST API server." ; exit 1; }

fi

# RUNS SESSION MANAGER
# Allows users to communicates with the AI engine.
if [ $DEPLOY_SESSION_MANAGER = true ] ; then

    echo "Starting the session management server."
    docker exec -dt $CONTAINER_SESSION_MANAGER bash run.sh &>> $BUILD_LOG || { echo -e "\e[31mCannot start the session management server." ; exit 1; }

fi

if [ $DEPLOY_OPENCOG_RELEX = true ] ||
    [ $DEPLOY_SUMO_SERVER = true ] ||
    [ $DEPLOY_CONCEPTNET_SERVER = true ] ||
    [ $DEPLOY_AI_ENGINE = true ] ||
    [ $DEPLOY_SESSION_MANAGER = true ] ; then

    echo
    echo -e "\e[32m############################################"
    echo "#                  finished                #"
    echo -e "############################################\e[39m"
    echo

fi

