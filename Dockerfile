FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-program-options-dev \
    libboost-locale-dev \
    libboost-iostreams-dev \
    libtbb-dev \
    libsqlite3-dev \
    libminizip-dev \
    zlib1g-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /vcmi

RUN git clone -b 1.7.1 --recursive https://github.com/vcmi/vcmi.git .

RUN mkdir build && cd build && \
    cmake -DENABLE_LOBBY=ON \
          -DENABLE_VIDEO=OFF \
          -DENABLE_TRANSLATIONS=OFF \
          -DENABLE_NULLKILLER_AI=OFF \
          -DENABLE_NULLKILLER2_AI=OFF \
          -DENABLE_STUPID_AI=OFF \
          -DENABLE_BATTLE_AI=OFF \
          -DENABLE_MMAI=OFF \
          -DENABLE_EDITOR=OFF \
          -DENABLE_CLIENT=OFF \
          -DENABLE_LAUNCHER=OFF \
          -DENABLE_INNOEXTRACT=OFF \
          -DENABLE_SERVER=OFF \
          -DENABLE_TEMPLATE_EDITOR=OFF \
          -DENABLE_LUA=OFF \
          .. && \
    cmake --build . -j$(nproc)

WORKDIR /vcmi/build/bin

CMD ["./vcmilobby"]