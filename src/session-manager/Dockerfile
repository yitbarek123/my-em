FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        sqlite3 \
        libsqlite3-dev \
        git \
        build-essential \
        python3.6 \
        python3.6-dev \
        python3-pip \
        python-setuptools \
        cmake \
        curl \
        libsm6 \
        libxext6 \ 
        libxrender-dev

COPY requirements.txt /tmp
RUN curl https://bootstrap.pypa.io/get-pip.py | python3.6
RUN python3.6 -m pip install -r /tmp/requirements.txt

ADD .  /virtual-assistant/session-manager
RUN mkdir -p /virtual-assistant/session-manager/data
WORKDIR /virtual-assistant/session-manager

# DB_FILE won't actually exist until user builds the db using create_db.py
# but this has to be done in a container (not during image build), so that
# the db is persisted in a docker volume.
ENV DB_FILE="data/sessions.db"
ENV SERVER_PORT="50000"

CMD python3.6 \
    session_manager_server.py \
        --db-file ${DB_FILE} \
        --port ${SERVER_PORT}
