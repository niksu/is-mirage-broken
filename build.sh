#!/bin/sh -ex

tag=$1
script=$2

repo=avsm/docker-opam
docker=docker.io

${docker} run -v `pwd`/scripts:/scripts -t $repo:$tag sh -c "cd /scripts && ./run.sh $script"
