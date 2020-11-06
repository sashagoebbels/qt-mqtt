FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && apt-get install -y apt-utils build-essential git wget cmake \
    libgl-dev libz3-dev libjpeg-dev libpng-dev libfreetype-dev libpcre2-dev doxygen graphviz plantuml \
    libgtest-dev libharfbuzz-dev locales libmosquitto-dev python3 python3-pip libsystemd-dev \
    libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-xfixes0-dev \
    libxcb-sync-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-image0-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libxcb-util-dev vim
# These go on a separate line to be more easy substituted by the commercial version
# RUN apt-get install -y qt5-default qttools5-dev-tools qtdeclarative5-dev qtbase5-private-dev

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "dash dash/sh boolean false" | debconf-set-selections && dpkg-reconfigure -p critical dash

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen en_US.UTF-8 && dpkg-reconfigure locales && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN useradd -s /bin/bash --create-home hudson && addgroup hudson staff && addgroup hudson sudo

# adding python requirements
ADD requirements.txt /home/hudson/
# ADD qtmqtt.tgz /home/hudson/
WORKDIR /home/hudson
RUN pip3 install -r requirements.txt

# build qt5
RUN git clone git://code.qt.io/qt/qt5.git
WORKDIR /home/hudson/qt5
RUN git checkout 5.15.2 && ./init-repository && mkdir /home/hudson/qt5-build
WORKDIR /home/hudson/qt5-build
RUN ../qt5/configure -opensource -nomake examples -nomake tests -confirm-license -system-zlib -system-libjpeg -system-libpng -system-freetype -system-pcre -system-harfbuzz
RUN make -j4 && make install

# build qtmqtt plugin
# from patched sources. See https://stackoverflow.com/questions/61677080/error-qabstractsocket-while-installing-mqtt-in-qt-c
WORKDIR /home/hudson
RUN git clone https://code.qt.io/qt/qtmqtt.git
WORKDIR /home/hudson/qtmqtt
RUN git checkout 5.15.2
RUN mkdir build
WORKDIR /home/hudson/qtmqtt/build
# dirty shitty hack to cope with stupid qmake ...
RUN ( /usr/local/Qt-5.15.2/bin/qmake -r .. || true ) && /usr/local/Qt-5.15.2/bin/qmake -r ..
RUN make -j4 && make install

#RUN cd /tmp \
#    && wget -q http://mgeartifactory.miltenyibiotec.de:8081/artifactory/mops/release/amneo/1.7.1%2B23.g5db510e/sdk/automacs-glibc-x86_64-amneo-image-1.7.1-core2-64-fischer-toolchain-1.7.1.sh \
#    && chmod +x automacs-glibc-x86_64-amneo-image-1.7.1-core2-64-fischer-toolchain-1.7.1.sh \
#    && ./automacs-glibc-x86_64-amneo-image-1.7.1-core2-64-fischer-toolchain-1.7.1.sh -y -d /sdk

# TAG: workflow-execution-engine_qtcontainer:latest