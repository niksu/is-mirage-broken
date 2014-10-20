#!/bin/sh -ex

tag=$1
script=$2

repo=avsm/docker-opam
docker=docker.io

sudo ${docker} run --rm=true -v `pwd`/scripts:/scripts -t $repo:$tag sh -c "/scripts/$script"
