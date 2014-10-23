#!/bin/sh -x

sudo docker.io pull avsm/docker-opam

git pull --no-edit

for script in mirage-www mirage-skeleton; do
  for distro in ubuntu-trusty centos-7; do
    for ver in 4.01.0 4.02.1; do
      ./build.sh $distro-$ver $script 2>&1 | tee logs/$script-$distro-$ver
    done
  done
done

echo "Latest build logs" > logs/README
./analyse_logs >> logs/README

git add logs/
git commit -m "Sync logs"
git push
