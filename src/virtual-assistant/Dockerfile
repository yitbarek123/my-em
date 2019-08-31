FROM va_opencog:latest
    
WORKDIR /virtual-assistant

# add files for custom opencog build
ADD lib/node-types.txt lib/node-types.txt 
RUN cat lib/node-types.txt >> /opencog/opencog/nlp/types/atom_types.script
ADD lib/procedures.scm /opencog/opencog/ghost/procedures

# build opencog with the setup configuration
RUN cd /opencog && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN cd / && git clone https://github.com/singnet/opencog-services.git

# let the opencog services know the existence of the va-service
ADD va-opencog-service/OpencogSNETServiceFactory* /opencog-services/src/
ADD va-opencog-service/VirtualAssistant* /opencog-services/src/cpp-services/

# copy engine source to image
ADD . .

# compile source for the opencog services
RUN cd /opencog-services/src && \
    make

# working directory for the ai engine
WORKDIR /opencog-services
