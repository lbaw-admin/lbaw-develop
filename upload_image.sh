#!/bin/bash

# Stop execution if a step fails
set -e

DOCKER_USERNAME=YOUR_DOCKER_ACCOUNT   # Replace by your docker hub username
IMAGE_NAME=lbaw18GG                   # Replace GG by your group's number

# Modified to work from docker container
docker exec lbaw_php composer install # Ensure that dependencies are available
docker exec lbaw_php php artisan clear-compiled
docker exec lbaw_php php artisan optimize

docker build -t $DOCKER_USERNAME/$IMAGE_NAME .
docker push $DOCKER_USERNAME/$IMAGE_NAME
