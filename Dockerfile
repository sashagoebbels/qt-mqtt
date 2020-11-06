FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && apt-get install -y apt-utils build-essential git wget cmake \
    libgl-dev libz3-dev libjpeg-dev libpng-dev libfreetype-dev libpcre2-dev doxygen graphviz plantuml \
    libgtest-dev libharfbuzz-dev locales libmosquitto-dev python3 python3-pip libsystemd-dev \
    libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-xfixes0-dev \
    libxcb-sync-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-image0-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libxcb-util-dev vim \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LC_ALL en_US.UTF-8

RUN echo "dash dash/sh boolean false" | debconf-set-selections && dpkg-reconfigure -p critical dash \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen en_US.UTF-8 && dpkg-reconfigure locales && /usr/sbin/update-locale LANG=en_US.UTF-8 \
 && useradd -s /bin/bash --create-home hudson && addgroup hudson staff && addgroup hudson sudo

# adding python requirements
ADD requirements.txt /home/hudson/
WORKDIR /home/hudson
RUN pip3 install -r requirements.txt

# build qt5
RUN git clone git://code.qt.io/qt/qt5.git
WORKDIR /home/hudson/qt5
RUN git checkout 5.15.2 && ./init-repository && mkdir /home/hudson/qt5-build
WORKDIR /home/hudson/qt5-build
RUN ../qt5/configure -opensource -nomake examples -nomake tests -confirm-license -system-zlib -system-libjpeg -system-libpng -system-freetype -system-pcre -system-harfbuzz \
 && make -j4 && make install

# build qtmqtt plugin
# from patched sources. See https://stackoverflow.com/questions/61677080/error-qabstractsocket-while-installing-mqtt-in-qt-c
WORKDIR /home/hudson
RUN git clone https://code.qt.io/qt/qtmqtt.git
WORKDIR /home/hudson/qtmqtt
RUN git checkout 5.15.2 \
 && mkdir build
WORKDIR /home/hudson/qtmqtt/build
# dirty shitty hack to cope with stupid qmake ...
RUN ( /usr/local/Qt-5.15.2/bin/qmake -r .. || true ) && /usr/local/Qt-5.15.2/bin/qmake -r ..
RUN make -j4 \
 && make install

WORKDIR /home/hudson/qt5-build
RUN make clean
WORKDIR /home/hudson/qtmqtt/build
RUN make clean