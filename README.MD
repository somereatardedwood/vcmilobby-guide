# vcmilobby running guide (native and docker)

Lobby for the [VCMI](https://github.com/vcmi/vcmi) project could be built and run by everyone since its codebase is present in the main repo. Point of this guide/example is to show some key moments of doing that. Since I'm not a dev at all (and there are no docs in the repo on building lobby atm), IvanSavenko helped me a lot with figuring out how to build vcmilobby specifically.

## Native install

### Building

Install build dependencies:

```sh
sudo apt-get install cmake g++ libboost-dev libboost-filesystem-dev libboost-system-dev libboost-thread-dev libboost-program-options-dev libboost-locale-dev libboost-iostreams-dev libtbb-dev libsqlite3-dev libminizip-dev zlib1g-dev
```

Recursievly clone `vcmi` repo (I preferred cloning release tag):

```sh
git clone -b 1.7.1 --recursive https://github.com/vcmi/vcmi.git
```

Go to project root:

```sh
cd vcmi
```

Create `build` directory:

```sh
mkdir build
```

Change to `build`:

```sh
cd build
```

Configure Makefiles:

```sh
cmake -DENABLE_LOBBY=ON -DENABLE_VIDEO=OFF -DENABLE_TRANSLATIONS=OFF -DENABLE_NULLKILLER_AI=OFF -DENABLE_NULLKILLER2_AI=OFF -DENABLE_STUPID_AI=OFF -DENABLE_BATTLE_AI=OFF -DENABLE_MMAI=OFF -DENABLE_EDITOR=OFF -DENABLE_CLIENT=OFF -DENABLE_LAUNCHER=OFF -DENABLE_INNOEXTRACT=OFF -DENABLE_SERVER=OFF -DENABLE_TEMPLATE_EDITOR=OFF -DENABLE_LUA=OFF ..
```
Here we're enabling lobby and disabling everything else: video, translations, ai's, editor, client, launcher, innoextract, server, template editor and lua.

Compile:

```sh
cmake --build . -j8
```
`-j8` means we're compiling on 8 threads, you may adjust this value.

After compilation, binaries will be located under `bin` directory. Go there:

```sh
cd bin
```

And run `vcmilobby`:

```sh
./vcmilobby
```

You won't be able to run `vcmilobby` from other directories.

### Changing default listening port

Lobby runs on `3031` port by default. To change that, you should edit `lobby/EntryPoint.cpp` as follows:

```git
diff --git a/lobby/EntryPoint.cpp b/lobby/EntryPoint.cpp
index 250eee25a..7b2c5a332 100644
--- a/lobby/EntryPoint.cpp
+++ b/lobby/EntryPoint.cpp
@@ -17,7 +17,7 @@
 #include "../lib/filesystem/Filesystem.h"
 #include "../lib/VCMIDirs.h"

-static const int LISTENING_PORT = 3031;
+static const int LISTENING_PORT = 3032;

 int main(int argc, const char * argv[])
 {
```

and recompile. After that running `vcmilobby` should output:

```
Starting server on port 3032
```

### IPv6

IPv6 support is not here yet (as of 1.7.1), but it may added by making following changes:

```git
diff --git a/lib/network/NetworkServer.cpp b/lib/network/NetworkServer.cpp
index 87ab0b52c..4a5d8cfdf 100644
--- a/lib/network/NetworkServer.cpp
+++ b/lib/network/NetworkServer.cpp
@@ -21,7 +21,8 @@ NetworkServer::NetworkServer(INetworkServerListener & listener, NetworkContext &

 uint16_t NetworkServer::start(uint16_t port)
 {
-       acceptor = std::make_shared<NetworkAcceptor>(context, boost::asio::ip::tcp::endpoint(boost::asio::ip::tcp::v4(), port));
+       acceptor = std::make_shared<NetworkAcceptor>(context, boost::asio::ip::tcp::endpoint(boost::asio::ip::tcp::v6(), port));
        return startAsyncAccept();
 }
```

and, of course, recompiling. After that, lobby should be accessible via both IPv4 and IPv6; you don't need to make any changes and recompile clients.

## Docker

### Dockerfile

Warning: AI-generated, works:

```Dockerfile
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
```
### docker-compose.yml

Warning: AI-generated and edited, works:

```yml
services:
  vcmilobby:
    build: .
    container_name: vcmi-lobby
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
      - "3031:3031"
    volumes:
      - ./database:/root/.local/share/vcmi
```

Place `Dockerfile` and `docker-compose.yml` in the same directory and run

```sh
docker compose up -d
```

`database` subdirectory will be created, where `vcmiLobby.db` will be located. It persists between container restarts.

## Potential improvements

1. Figure out what cmake flags may be unnecessary (`-DENABLE_TEMPLATE_EDITOR=OFF` should be since afai understood `-DENABLE_EDITOR=OFF` sets `-DENABLE_TEMPLATE_EDITOR` `OFF` too; not sure about `-DENABLE_LUA=OFF`).

2. Figure out how to add `-DENABLE_MINIMAL_LIB=ON`. For now it fails configuring makefiles step with:
```
CMake Error at lib/CMakeLists.txt:831 (target_link_libraries):
  Target "vcmi" links to:

    TBB::tbb

  but the target was not found.
```
even though tbb is installed.

3. Minimize docker image by removing builddeps and unnecessary source files.

### Thanks to IvanSavenko for helping with figuring most of the things out