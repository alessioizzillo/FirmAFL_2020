# syntax=docker/dockerfile:1

FROM ubuntu:20.04

WORKDIR /FirmAFL

RUN apt-get update    
# RUN apt-get install -y apt-utils debconf-utils dialog
# RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
# RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections
# RUN apt-get update
# RUN apt-get install -y resolvconf
RUN apt install sudo
RUN export USER=root
