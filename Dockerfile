ARG PYTHON_BASE_IMAGE=3.10-slim-bullseye

FROM ubuntu AS s6build
ARG S6_RELEASE
ENV S6_VERSION ${S6_RELEASE:-v2.1.0.0}
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y curl ca-certificates && \
  apt-get autoclean && apt-get autoremove && apt-get purge \
  # && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/* \
  && echo "$(dpkg --print-architecture)"
WORKDIR /tmp
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
  amd64) ARCH='amd64';; \
  arm64) ARCH='aarch64';; \
  armhf) ARCH='armhf';; \
  *) echo "unsupported architecture: $(dpkg --print-architecture)"; exit 1 ;; \
  esac \
  && set -ex \
  && echo $S6_VERSION \
  && curl -fsSLO "https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-$ARCH.tar.gz"


FROM python:${PYTHON_BASE_IMAGE} AS build
ARG octoprint_ref
ENV octoprint_ref ${octoprint_ref:-master}

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
  avrdude \
  build-essential \
  cmake \
  curl \
  imagemagick \
  ffmpeg \
  fontconfig \
  g++ \
  git \
  haproxy \
  libffi-dev \
  libjpeg-dev \
  libjpeg62-turbo \
  libprotobuf-dev \
  libudev-dev \
  libusb-1.0-0-dev \
  libv4l-dev \
  openssh-client \
  v4l-utils \
  xz-utils \
  zlib1g-dev \
  x265 \
  && apt-get autoclean && apt-get autoremove && apt-get purge \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/*

# unpack s6
COPY --from=s6build /tmp /tmp
RUN s6tar=$(find /tmp -name "s6-overlay-*.tar.gz") \
  && tar xzf $s6tar -C / && rm -f $s6tar

# Install octoprint
RUN	curl -fsSLO --compressed --retry 3 --retry-delay 10 \
  https://github.com/OctoPrint/OctoPrint/archive/${octoprint_ref}.tar.gz \
	&& mkdir -p /opt/octoprint \
  && tar xzf ${octoprint_ref}.tar.gz --strip-components 1 -C /opt/octoprint --no-same-owner \
  && rm -f ${octoprint_ref}.tar.gz && cd /opt/octoprint \
  && printf '[install]\ncompile = no' > /etc/pip.conf \
  && pip install --no-cache-dir . && mkdir -p /octoprint/octoprint /octoprint/plugins

# Install mjpg-streamer
RUN curl -fsSLO --compressed --retry 3 --retry-delay 10 \
  https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz \
  && mkdir /mjpg \
  && tar xzf master.tar.gz -C /mjpg && rm -f /master.tar.gz \
  && cd /mjpg/mjpg-streamer-master/mjpg-streamer-experimental \
  && make && make install && make clean

# Copy services into s6 servicedir and set default ENV vars
COPY root /
ENV CAMERA_DEV=/dev/video0 \
    MJPG_STREAMER_INPUT="-n -r 640x480" \
    PIP_USER=true \
    PYTHONUSERBASE=/octoprint/plugins \
    PATH="${PYTHONUSERBASE}/bin:${PATH}"
# set WORKDIR 
WORKDIR /octoprint

# port to access haproxy frontend
EXPOSE 80

VOLUME /octoprint

ENTRYPOINT ["/init"]
