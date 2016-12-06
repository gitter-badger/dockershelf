FROM luisalejandro/debian:sid-min
MAINTAINER Luis Alejandro Martínez Faneyth <luis@huntingbears.com.ve>

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="python2.7" \
      org.label-schema.description="A Python 2.7 image based on Debian Sid." \
      org.label-schema.url="https://github.com/LuisAlejandro/dockerfiles" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://github.com/LuisAlejandro/dockerfiles" \
      org.label-schema.vendor="Luis Alejandro Martínez Faneyth" \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0"

ENV PY_VER_NUM="2.7" PY_DEBIAN_SUITE="stretch"

COPY build-image.sh /usr/share/docker/python/2.7/
RUN bash /usr/share/docker/python/2.7/build-image.sh