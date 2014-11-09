#!/bin/sh -x
#
# Update the sources of the openmirage.org site with the latest build info from
# is-mirage-broken. Generates a PR to mirage/mirage-www (from which the
# openmirage.org site is produced) if the most recent build info (generated by
# is-mirage-broken) differs (modulo the date in the title) from what's currently
# shown on openmirage.org.
#
# Nik Sultana, Cambridge University Computer Lab, November 2014
#
# NOTE
# - The "hub" tool is used here to interact with GitHub.
# - We rely on "hub" to have access to user credentials via the GITHUB_USER and
#   GITHUB_PASSWORD environment variables.
# - We rely on IS_MIRAGE_BROKEN_DIR to contain the path within which we'll keep
#   a clone of GITHUB_USER's fork of mirage/mirage-www.

EXPECTED_GITHUB_USER=bactrian

if [ ! ${GITHUB_USER} == ${EXPECTED_GITHUB_USER} ]
then
  echo "Expecting GITHUB_USER to be set to ${EXPECTED_GITHUB_USER}." >&2
  exit 1
fi

if [ -z ${GITHUB_PASSWORD} ]
then
  echo "Expecting GITHUB_PASSWORD to be set to the password of ${GITHUB_USER}'s
  GitHub account." >&2
  exit 1
fi

# Our location matters: make sure that IS_MIRAGE_BROKEN_DIR is defined, and
# changed directory to it.
if [ -z "${IS_MIRAGE_BROKEN_DIR}" ]
then
  echo "Missing configuration: environment variable IS_MIRAGE_BROKEN_DIR must
  contain the path in which we expect to find ${GITHUB_USER}'s fork of
  the mirage/is-mirage-broken repo.'" >&2
  exit 1
fi

cd ${IS_MIRAGE_BROKEN_DIR}

# FIXME how to regenerate the running site?

if [ -z "$(where hub)" ]
then
  echo "Missing dependency: hub" >&2
  echo "Can be downloaded from http://hub.github.com/" >&2
  exit 1
fi

if [ ! -d mirage-www ]
then
  echo "Did not find a copy of ${GITHUB_USER}'s fork of mirage-www.
  Forking and cloning it."

  # To use hub we first clone mirage-www, then we fork it using hub, and we
  # obtain a "remote" to GITHUB_USER's fork of mirage-www.
  git clone git://github.com/mirage/mirage-www
  # FIXME need to "cd" to mirage-www to run "hub fork"?
  # FIXME check that clone was successful -- if not then die
  hub fork
  # FIXME check that fork was successful -- if not then die
fi

cd mirage-www

echo "We seem to have a copy of ${GITHUB_USER}'s fork of mirage-www.
Making sure it's up to date."
git pull
# FIXME check that pull was successful -- if not then die, otherwise we'll be
# working with stale data. -- could use parameter to "sh" for this, I think --
# but would this fail at *any* non-zero exit status? That would be buggered up
# by "diff" below, for example.
# FIXME check if we've already set remote upstream
git checkout ${GITHUB_USER} master
# Bring bactrian's fork up to date.
# This should always be a fast-forward merge -- should never fail.
git merge origin/master

# Compare mirage-www/tmpl/wiki/is_mirage_broken.md with logs/README.md
# (modulo timestamp). Only proceed if something's changed.
# FIXME check if "diff" failure interferes with sh -x.
diff -q <(sed -e '1d' ../logs/README.md) <(sed -e '1d' tmpl/wiki/is_mirage_broken.md)
if [ $? -eq 1 ]
then
  # Make sure that TMPFILE is a not-yet-existing file
  TMPFILE=
  while [ -z "${TMPFILE}" ]
  do
    PROPOSAL=/tmp/cronsh-${RANDOM}
    if [ ! -f "${PROPOSAL}" ]
    then
      TMPFILE="${PROPOSAL}"
    fi
  done

  cp ../logs/README.md tmpl/wiki/is_mirage_broken.md
  perl -ne '
    if ($_ =~ /^(.*)date.+(\(\*NOTE is-mirage-broken:marker\*\))/)
    {
      my ($minute, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
      printf ("%sdate (%04d, %02d, %02d, %02d, %02d) %s\n", $1,
        $year + 1900, $month + 1, $day, $hour, $minute, $2);
    } else {
      print "$_";
    }' src/data.ml > "${TMPFILE}"
  mv "${TMPFILE}" src/data.ml

  MSG="updated build status at $(date);"

  # FIXME hardcoded paths -- also elsewhere in code.
  git commit tmpl/wiki/is_mirage_broken.md src/data.ml \
    -m "${MSG}"
  git push
  # make PR from bactrian/master to mirage-www/master
  hub pull-request -m "${MSG}" \
    -b mirage/mirage-www:master \
    -h ${GITHUB_USER}:mater
  # FIXME check outcome of pull request?
fi

cd ..
