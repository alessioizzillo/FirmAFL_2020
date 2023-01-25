#!/bin/bash

#This file provide some useful commands for create and eliminate docker containers
#USAGE: ./docker.sh NAME_CONTAINER
#It needs to be modified according to the Server we are in --> Ex. option -v in "docker run"

if [ -z "$1" ]
    then
        echo "No argument supplied. Type \"build\", \"run\", \"attach\" or \"rm\"."
        exit 1
fi

case $1 in
    build)
        docker build --tag firmafl .;
        ;;

    run)
    	docker run -dit --privileged --memory="15g" --network host --name $2 -v /dev:/dev -v $(pwd):/FirmAFL firmafl;
        ;;

    attach)
        docker attach $2 --detach-keys ctrl-a;
        ;;

    rm)
        docker rm --force {$2};
        ;;

    rmi)
        docker rmi --force iotafl;
        ;;
esac
