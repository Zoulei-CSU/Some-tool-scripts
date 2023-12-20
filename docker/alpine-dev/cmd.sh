#!/bin/bash
# 这是一个创建alpine中C++开发环境的Docker

# 这个entrypoint.sh文件很魔性，必须是UTF-8编码加Linux换行符，否则会各种报错
chmod +x -v entrypoint.sh

# 可以临时启动一次alpine镜像，进入控制台看看系统文件
docker run --name temp --rm -it alpine:3.18

# 根据Dockerfile创建镜像，名称是alpine-ssh
docker build -t alpine-ssh .

# 简单的启动一次镜像看看是否有错误
docker run -itd --hostname x-dev --name x-dev alpine-ssh:latest

# 更复杂的启动方式，映射端口、存储目录
docker run -itd --hostname Alpine318 --name alpine318-dev \
-p 8023:22 -v /home/zoulei/projects/:/home/southgis/projects/ \
-u root -w /home/southgis/projects \
--privileged=true --restart=on-failure alpine-ssh:latest

# 也可以不根据Dockerfile创建镜像，直接通过docker-compose.yml来运行
# 但是这种方式再Deepin系统中，容器会一直不停重启，没找到原因
docker-compose up -d



