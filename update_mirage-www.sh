#!/bin/bash -xe
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
# - An ocaml-github tool is used here to interact with GitHub.
#   CREATE_PULL_REQUEST must point to the create_pull_request tool.
# - GITHUB_USER is the GitHub account under which we'd like to create the PR --
#   for instance, this could be the account of the build bot.
# - We rely on IS_MIRAGE_BROKEN_DIR to contain the path within which we'll keep
#   a clone of our fork of mirage/mirage-www. We assume that this repo will
#   have a particular remote set: the GITHUB_USER remote should point to
#   GITHUB_USER's fork.
# - For git operations, such as "git push", we rely on contextually-available
#   credentials that git can use. These could be supplied via GIT_ASKPASS, etc.
# - In that clone, we assume that "origin" tracks mirage/mirage-www, while the
#   remote called GITHUB_USER tracks GITHUB_USER/mirage-www.

GITHUB_USER=bactrian

# Our location matters: make sure that IS_MIRAGE_BROKEN_DIR is defined, and
# changed directory to it.
if [ -z "${IS_MIRAGE_BROKEN_DIR}" ]
then
  echo "Missing configuration: environment variable IS_MIRAGE_BROKEN_DIR must
  contain the path in which we expect to find ${GITHUB_USER}'s fork of
  the mirage/is-mirage-broken repo.'" >&2
  exit 1
fi

cd "${IS_MIRAGE_BROKEN_DIR}"

if [ ! -d mirage-www ]
then
  echo "Did not find a copy of ${GITHUB_USER}'s fork of mirage-www.
  Please fork and clone it into ${IS_MIRAGE_BROKEN_DIR}."
  exit 1
fi

cd mirage-www

echo "We seem to have a copy of ${GITHUB_USER}'s fork of mirage-www.
Making sure it's up to date."
git fetch origin master
git checkout master
# Bring GITHUB_USER's fork up to date.
# This should always be a fast-forward merge -- should never fail.
git merge origin/master
git push "${GITHUB_USER}"

# Compare mirage-www/tmpl/wiki/is_mirage_broken.md with logs/README.md
# (modulo timestamp). Only proceed if something's changed.
# NOTE diff uses exit status 1 to indicate that the two files differ, but
#  a non-zero exit status will cause the whole script to fall (because of -e).
#  We avoid this by using the "&& true" suffix below.
CHECK_DIFF=$(diff -q <(sed -e '2d' ../logs/README.md) \
  <(sed -e '2d' tmpl/wiki/is_mirage_broken.md)) && true
if [[ ! ${CHECK_DIFF} =~ "differ" ]]
then
  echo "Build statuses haven't changed since last time we ran."
else
  echo "Current build statuses differ from last time we ran."
  # Make sure that TMPFILE is a not-yet-existing file
  TMPFILE=
  while [ -z "${TMPFILE}" ]
  do
    PROPOSAL="/tmp/cronsh-${RANDOM}"
    if [ ! -f "${PROPOSAL}" ]
    then
      TMPFILE="${PROPOSAL}"
    fi
  done

  cp ../logs/README.md tmpl/wiki/is_mirage_broken.md
  perl -ne '
    if ($_ =~ /^(.*)date.+$/)
    {
      my ($minute, $hour, $day, $month, $year) = (localtime)[1,2,3,4,5];
      printf ("%sdate (%04d, %02d, %02d, %02d, %02d) %s\n", $1,
        $year + 1900, $month + 1, $day, $hour, $minute);
    } else {
      print "$_";
    }' src/bactrian.ml > "${TMPFILE}"
  cp "${TMPFILE}" src/bactrian.ml

  MSG="updated build status at $(date);"

  # FIXME hardcoded paths -- also elsewhere in code.
  git commit tmpl/wiki/is_mirage_broken.md src/bactrian.ml \
    -m "${MSG}"
  git push "${GITHUB_USER}"
  # make PR from GITHUB_USER/master to mirage-www/master
  # NOTE instead of making a PR from GITHUB_USER/master, we could fork off the
  # current HEAD of mirage-www/master and create a new branch under
  # GITHUB_USER/mirage-www, and PR off that; but then we'd need to prune stale
  # branches.
  ${CREATE_PULL_REQUEST} -m "${MSG}" \
    -t "The current answer to the question: is-mirage-broken?" \
    -x ${GITHUB_USER} -r mirage-www -b master \
    -x mirage -r mirage-www -b master \
    -u ${GITHUB_USER} -h master -k infra
fi

cd ..