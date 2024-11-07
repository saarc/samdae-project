#!/bin/bash

COMPOSE_PROJECT_NAME=net docker-compose down 

rm -rf channel-artifacts/*
rm -rf system-genesis-block/*
sudo rm -rf organizations/*

docker volume rm -f $(docker volume ls -q)

docker ps -a
docker network ls