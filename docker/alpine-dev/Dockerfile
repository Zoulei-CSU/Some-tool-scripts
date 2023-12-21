# Alpine C++ 编译环境

FROM alpine:3.18
LABEL org.opencontainers.image.authors="zoulei<zoulei.csu@gmail.com>"

# 更换国内腾讯源
RUN echo -e "https://mirrors.cloud.tencent.com/alpine/v3.18/main\nhttps://mirrors.cloud.tencent.com/alpine/v3.18/community" \
    > /etc/apk/repositories

RUN apk add --no-cache openssh sudo 
RUN apk add --no-cache htop xz build-base cmake \
	qt5-qtbase-dev qt5-qtbase-sqlite qt5-qtbase-postgresql \
	libpq-dev curl-dev proj-dev geos-dev gdal-dev openscenegraph-dev
RUN apk add --no-cache go

RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
RUN adduser -u 502 -G wheel -h /home/southgis -s /bin/sh -D southgis
RUN echo -n 'southgis:123456' | chpasswd
RUN echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

ENV LANG=C.UTF8 

RUN mkdir -p /home/southgis/projects/

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
#CMD ["/usr/sbin/sshd", "-D"]
#ENTRYPOINT ["/bin/sh"]
EXPOSE 22


# #临时启动一次，进入控制台
#docker run --name temp --rm -it alpine:3.18

# #控制台方式启动，就不需要docker-compose方式启动了
#docker build -t alpine-ssh .
#docker run -itd --hostname x-dev --name x-dev -p 122:22 alpine-ssh:latest


# 更复杂的启动方式
#docker build -t alpine-ssh .    #创建镜像
#docker run -itd --hostname Alpine318 --name alpine318-dev \
#    -p 8023:22 -v /home/zoulei/projects/:/home/southgis/projects/ \
#    -u root -w /home/southgis/projects \
#    --privileged=true --restart=on-failure alpine-ssh:latest


