ARG REGISTRY_HOST=ghcr.io
ARG IMAGE_USERNAME=haisamido
ARG IMAGE_NAME=nos3-64
ARG IMAGE_TAG=dev
ARG IMAGE_URI=${REGISTRY_HOST}/${IMAGE_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
ARG MAVEN_HTTPS_PROXY=
ARG HTTP_PROXY=
ARG HTTPS_PROXY=
ARG DEPLOYMENT_ENVIRO=
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
ARG GIT_URL=https://github.com/nasa/nos3
ARG GIT_BRANCH=dev

ARG NOS3_USER=nos3
ARG FLIGHT_SOFTWARE=cfs 
ARG GSW_SOFTWARE=yamcs

#------------------------------------------------------------------------------
FROM ${IMAGE_URI} AS nos3-base

ARG DEBIAN_FRONTEND=noninteractive

#------------------------------------------------------------------------------
# Proxy configs
#------------------------------------------------------------------------------
ARG MAVEN_HTTPS_PROXY
ARG HTTPS_PROXY
ARG HTTP_PROXY
ARG DEPLOYMENT_ENVIRO

ENV MAVEN_HTTPS_PROXY=${MAVEN_HTTPS_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV DEPLOYMENT_ENVIRO=${DEPLOYMENT_ENVIRO}

#------------------------------------------------------------------------------
# Git Configs
#------------------------------------------------------------------------------
ARG GIT_URL
ARG GIT_BRANCH

ENV GIT_URL=${GIT_URL}
ENV GIT_BRANCH=${GIT_BRANCH}

#------------------------------------------------------------------------------
# NOS3 Configs
#------------------------------------------------------------------------------
ARG FLIGHT_SOFTWARE
ARG GSW_SOFTWARE
ARG NOS3_USER

ENV NOS3_USER=${NOS3_USER}
ENV FLIGHT_SOFTWARE=${FLIGHT_SOFTWARE}
ENV GSW_SOFTWARE=${GSW_SOFTWARE}
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Tools
#------------------------------------------------------------------------------
RUN apt-get update && \
  apt-get install -y sudo git curl vim make cmake tmux tree python3 pip && \
  apt-get install -y iputils-ping dnsutils lsof net-tools tshark jq && \
  apt-get install -y libgcrypt20-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN git config --global http.sslVerify false

#------------------------------------------------------------------------------
# Create a new user named ${NOS3_USER} with a home directory
#------------------------------------------------------------------------------
RUN useradd -m ${NOS3_USER}

RUN adduser ${NOS3_USER} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the newly created user
USER ${NOS3_USER}

# Create builds directory
RUN mkdir -p /home/${NOS3_USER}/builds/

WORKDIR /home/${NOS3_USER}/builds/

#------------------------------------------------------------------------------
# Clone ${GIT_URL}
#------------------------------------------------------------------------------
RUN git clone --recurse-submodules -b ${GIT_BRANCH} -j4 ${GIT_URL}

WORKDIR /home/${NOS3_USER}/builds/nos3

RUN chown -R ${NOS3_USER}:${NOS3_USER} /home/${NOS3_USER}

# TODO: need to enhance this capability where they don't affect compilation
COPY ./assets/cfg/nos3-mission.xml        ./cfg/nos3-mission.xml
COPY ./assets/cfg/spacecraft              ./cfg/spacecraft
COPY ./assets/cfg/sims/nos3-simulator.xml ./cfg/sims/nos3-simulator.xml

RUN make -j7 clean
RUN make -j7 prep
RUN make -j7 config

RUN make -j7 build-cryptolib
RUN make -j7 build-fsw
RUN make -j7 build-sim
RUN make -j7 build-test

#------------------------------------------------------------------------------
# Install the GSW Software
#------------------------------------------------------------------------------
  RUN ./scripts/gsw/gsw_${GSW_SOFTWARE}_build.sh

RUN cd ${HOME}/.nos3/${GSW_SOFTWARE} && \
  mvn ${MAVEN_HTTPS_PROXY} package yamcs:bundle
#------------------------------------------------------------------------------

ENV GSW_DIR=/home/${NOS3_USER}/.nos3/${GSW_SOFTWARE}
ENV FORTYTWO_DIR=/home/${NOS3_USER}/.nos3/42

COPY entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]
