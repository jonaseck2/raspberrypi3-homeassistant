FROM homeassistant/raspberrypi3-homeassistant

ENV LIBCEC_VERSION=4.0.2 P8_PLATFORM_VERSION=2.1.0.1

WORKDIR /root

ADD https://github.com/Pulse-Eight/libcec/archive/libcec-${LIBCEC_VERSION}.tar.gz https://github.com/Pulse-Eight/platform/archive/p8-platform-${P8_PLATFORM_VERSION}.tar.gz ./

RUN ln -s /usr/bin/python3 /usr/bin/python \
&& PYTHON_LIBDIR=$(python -c 'from distutils import sysconfig; print(sysconfig.get_config_var("LIBDIR"))') \
&& PYTHON_LDLIBRARY=$(python -c 'from distutils import sysconfig; print(sysconfig.get_config_var("LDLIBRARY"))') \
&& PYTHON_LIBRARY="${PYTHON_LIBDIR}/${PYTHON_LDLIBRARY}" \
&& PYTHON_INCLUDE_DIR=$(python -c 'from distutils import sysconfig; print(sysconfig.get_python_inc())') \
# Build dependencies
&& apk update \
&& apk add libuv libxrandr \
&& apk add --virtual build-dependencies gcc eudev-dev cmake liblockfile-dev libuv-dev libxrandr-dev swig git build-base bzip2-dev raspberrypi-dev \
# Platform
&& tar xvzf p8-platform-${P8_PLATFORM_VERSION}.tar.gz && rm p8-platform-*.tar.gz && mv platform* platform \
&& mkdir platform/build \
&& cd platform/build \
&& cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr \
   .. \
&& make \
&& make install \
# Libcec
&& cd \
&& tar xvzf libcec-${LIBCEC_VERSION}.tar.gz && rm libcec-*.tar.gz && mv libcec* libcec \
&& mkdir libcec/build \
&& cd libcec/build \
&& cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr \
   -DRPI_INCLUDE_DIR=/opt/vc/include \
   -DRPI_LIB_DIR=/opt/vc/lib \
   -DPYTHON_LIBRARY="${PYTHON_LIBRARY}" \
   -DPYTHON_INCLUDE_DIR="${PYTHON_INCLUDE_DIR}" \
   .. \
&& make -j4 \
&& make install \
# Cleanup
&& rm -f /usr/bin/python \
&& apk del build-dependencies \
&& rm -rf /var/cache/apk/* \
&& cd \
&& rm -rf platform && rm -rf libcec

ENV LD_LIBRARY_PATH=/opt/vc/lib:${LD_LIBRARY_PATH}

WORKDIR /config/
