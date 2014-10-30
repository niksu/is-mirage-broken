#!/bin/sh -x

sudo docker.io pull avsm/docker-opam

git pull --no-edit

OUTPUT_FILE=README.md

for script in mirage-www mirage-skeleton tls-mvp-server; do
  for distro in ubuntu-trusty centos-7; do
    for ver in 4.01.0 4.02.1; do
      ./build.sh $distro-$ver $script 2>&1 | tee logs/$script-$distro-$ver
    done
  done
done

METADATA="(as of $(date))"
POLITE_NOTICE='<!--THIS FILE WAS GENERATED BY is-mirage-broken/cron.sh. DO NOT EDIT-->'

cat > logs/${OUTPUT_FILE} <<EOF
${POLITE_NOTICE}
<h2>${METADATA}</h2>
EOF
./analyse_logs >> logs/${OUTPUT_FILE}

git add logs/
git commit -m "Sync logs"
git push
