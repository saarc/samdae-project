#!/bin/bash

COMPOSE_PROJECT_NAME=net docker-compose down 

rm -rf channel-artifacts/*
rm -rf system-genesis-block/*
sudo rm -rf organizations/*

docker volume rm -f $(docker volume ls -q)
docker rmi -f $(docker images dev-* -q)

rm -rf connection-org2.json

docker ps -a
docker network ls