# centos7-XE-java-tomcat

Cria a Imagem Docker parana/centos7-XE-java-tomcat

This **Dockerfile** is a [trusted build](https://hub.docker.com/r/parana/centos7-XE-java-tomcat/) of [Docker Registry](https://hub.docker.com/).

## Building on boot2docker & Docker Machine

You need to configure swap space in boot2docker / Docker Machine prior the build:

1. Log into boot2docker / Docker Machine: `boot2docker ssh` or `docker-machine ssh default` (replace `default` if needed).
2. Create a file named `bootlocal.sh` in `/var/lib/boot2docker/` with the following content:

        #!/bin/sh

        SWAPFILE=/mnt/sda1/swapfile

        dd if=/dev/zero of=$SWAPFILE bs=1024 count=2097152
        mkswap $SWAPFILE && chmod 600 $SWAPFILE && swapon $SWAPFILE

3. Make this file executable: `chmod u+x /var/lib/boot2docker/bootlocal.sh`

After restarting boot2docker / Docker Machine, it will have increased swap size.

## How to use

The command `docker run -p 8087:8087 -p 1521:1521 -d parana/centos7-XE-java-tomcat` will start new container and bind it's local ports `1521` and `8087` to host's `1521` and `8087` respectively.

Oracle Web Management Console (apex) will be available at [http://localhost:8087/apex](http://localhost:8087/apex).
Use the following credentials to login:

    workspace: INTERNAL
    user: ADMIN
    password: oracle

Connect to the database using the following details:

    hostname: localhost
    port: 1521
    sid: XE
    username: system
    password: oracle

