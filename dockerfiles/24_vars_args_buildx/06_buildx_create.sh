#!/bin/bash
docker buildx create --name mybuilder --driver docker-container --use
docker buildx inspect --bootstrap