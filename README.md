# Minecraft containers

[![Quay build status](https://quay.io/repository/mikroskeem/minecraft-containers/status)](https://quay.io/repository/mikroskeem/minecraft-containers)

[Discord](https://discord.gg/KqqdgE7)

Minecraft Docker images for use in [Pterodactyl](https://pterodactyl.io/) panel

Note that this image is not recommended for public consumption/hosting services, because it is insecure (see features below)

## Features
- Drop-in replacement to Pterodactyl's own Java images.
- Based on [AdoptOpenJDK](https://adoptopenjdk.net/) JVM Debian Docker images
    - Debian is used because of better out of box support with JNI libraries
- Supplies [jemalloc](https://github.com/jemalloc/jemalloc)
- Supplies [mimalloc](https://github.com/microsoft/mimalloc)
- Ability to source a custom script before server boot
    - This feature is used mainly to set LD_PRELOAD to either mimalloc or jemalloc, and/or update server jar.
    - **NOTE**: this feature cannot be disabled without editing the entrypoint script. Allowing this for
    untrusted users might create unwanted situations.
- Ability to execute shell, instead of server (to manage files using a shell, for example)
    - **NOTE:** see above

## Flavours:
- Java 8 OpenJDK - `quay.io/mikroskeem/minecraft-containers:adoptopenjdk-8`
- Java 8 OpenJ9 - `quay.io/mikroskeem/minecraft-containers:adoptopenjdk-8-openj9`
- Java 11 OpenJDK - `quay.io/mikroskeem/minecraft-containers:adoptopenjdk-11`
- Java 11 OpenJ9 - `quay.io/mikroskeem/minecraft-containers:adoptopenjdk-11-openj9`

## Usage

### Using this image instead of Pterodactyl's

Under server's administrative config, pick Startup tab, scroll down to Docker Container Configuration and
fill in the Docker image name (see Flavours sub-topic)

### jemalloc and mimalloc
[jemalloc](https://github.com/jemalloc/jemalloc) is installed to `/opt/jemalloc/libjemalloc.so`  
[mimalloc](https://github.com/microsoft/mimalloc) is installed to `/opt/mimalloc/libmimalloc.so`

I provide both because either of them are better in Minecraft-related workloads than `glibc`'s default
`malloc(3)` implementation. While I don't have exact results around nor I don't know how to measure
their effectiveness scientifically, then I'll leave deciding which is better to the end user :smile:

To utilize jemalloc or mimalloc, create a custom script (see next sub-topic) with following line:  
`export LD_PRELOAD=/path/to/lib.so`

### Custom script
Create a file named `.env` in server root, it will be sourced.

Note that entrypoint script is ran by `/bin/sh`, which is [Dash shell](https://wiki.archlinux.org/index.php/Dash). It is not compatible with so-called bashisms, thus
you must make your `.env` script compatible with Dash.

### Debug shell
Create a file named `.debugshell` in server root. A shell will be executed instead of server, if it is present, remove it to
prevent starting up the shell next time.
