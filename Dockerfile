ARG REGISTRY_HOST=ghcr.io
ARG IMAGE_USERNAME=haisamido
ARG IMAGE_NAME=nos3-64
ARG IMAGE_TAG=dev
ARG IMAGE_URI=${REGISTRY_HOST}/${IMAGE_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
#------------------------------------------------------------------------------

ARG GIT_URL=https://github.com/nasa/nos3
ARG GIT_BRANCH=dev

#------------------------------------------------------------------------------
FROM ${IMAGE_URI} AS nos3-64
#------------------------------------------------------------------------------
ARG DEBIAN_FRONTEND=noninteractive

#---
ARG GIT_URL
ARG GIT_BRANCH

ENV GIT_URL=${GIT_URL}
ENV GIT_BRANCH=${GIT_BRANCH}
#---

RUN apt-get update && \
  apt-get install -y sudo git curl vim make cmake tmux tree python3 pip && \
  apt-get install -y iputils-ping dnsutils lsof net-tools tshark jq && \
  apt-get install -y libgcrypt20-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN mkdir -p /builds/

WORKDIR /builds/

# TODO: in gitlab cannot auto-mirror all the recursed submodules :-( https://github.com/nasa/nos3.git
RUN git clone --recurse-submodules -b ${GIT_BRANCH} -j2 ${GIT_URL}

WORKDIR /builds/nos3

RUN make -j7 clean
RUN make -j7 config

RUN make -j7 build-cryptolib
RUN make -j7 build-fsw
RUN make -j7 build-sim
RUN make -j7 build-test

COPY entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]
