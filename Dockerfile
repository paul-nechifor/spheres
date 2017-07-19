FROM ubuntu:16.04
RUN apt-get update && \
    apt-get install povray nodejs npm -y && \
    ln -s /usr/bin/nodejs /usr/bin/node && \
    npm i yarn@0.27.5 -g
ADD . /spheres
WORKDIR /spheres
RUN yarn && mkdir output
