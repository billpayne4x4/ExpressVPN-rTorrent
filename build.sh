#!/bin/bash
IP="159.196.118.2"

IMAGE_NAME="expressvpn-rtorrent"

echo "Building docker image..."

docker buildx build --build-arg PLATFORM="amd64" \
    --build-arg NUM="3.46.0.7" \
    --platform linux/amd64 \
    --tag ${IMAGE_NAME} \
    -o type=docker \
    .

docker run -d \
    --env CODE=${EXPRESSVPN_CODE} \
    --env SERVER=smart \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    --privileged \
    --detach=true \
    --tty=true \
    --name ${IMAGE_NAME} \
    --publish 80:80 \
    -p 3000:3000 \
    -p 5000:5000 \
    --env=PROTOCOL=lightway_udp \
    --env=CIPHER=chacha20 \
    -v /home/bill/Downloads:/downloads \
    -e EXPRESSVPN_CODE=${EXPRESSVPN_CODE} \
    ${IMAGE_NAME}

docker exec -it ${IMAGE_NAME} /bin/bash
