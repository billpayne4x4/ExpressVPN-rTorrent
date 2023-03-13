#!/bin/bash

echo -e "\nPruning build cache..."
docker builder prune --all --force

echo "Stopping all containers..."
docker stop $(docker ps -aq)

echo -e "\nPruning all unused images..."
docker image prune --all --force

echo -e "\nPruning all stopped containers..."
docker container prune --all --force

echo -e "\nPruning all unused data (images, containers, networks, volumes)..."
docker system prune --all --force --volumes

echo -e "\nDeleting all containers..."
docker rm -f $(docker ps -aq)

echo -e "\nDeleting all images..."
docker rmi -f $(docker images -aq)

