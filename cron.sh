#!/bin/sh -x

for script in mirage-dev; do
  for distro in ubuntu-trusty; do
    for ver in 4.01.0 4.02.1; do
      ./build.sh $distro-$ver $script > logs/$script-$distro-$ver
      if [ $? = 0 ]; then
        rm -f BROKEN-$script-$distro-$ver
        ln -nsf logs/$script-$distro-$ver WORKS-$script-distro-ver
      else
        rm -f WORKS-$script-$distro-$ver
        ln -nsf logs/$script-$distro-$ver BROKEN-$script-distro-ver
      fi
    done
  done
done
