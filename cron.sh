#!/bin/sh -x

for script in mirage-dev; do
  for distro in ubuntu-trusty; do
    for ver in 4.01.0 4.02.1; do
      ./build.sh $distro-$ver $script | tee logs/$script-$distro-$ver
    done
  done
done
