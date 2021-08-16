#!/bin/bash

RELEASE_TAG=$1
PRIMARY_BRANCH="main"

if [ "${RELEASE_TAG}nothing" == "nothing" ]; then
	echo "Please give a release tag, e.g., 0.12.1"
	exit
fi

# See https://stackoverflow.com/questions/1417957/show-just-the-current-branch-in-git
# for "git rev-parse --abbrev-ref HEAD"

CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

if [ "${PRIMARY_BRANCH}" != "${CURRENT_BRANCH}" ]; then
	echo "You are not on the ${PRIMARY_BRANCH} branch of the repo."
	exit
fi

echo "Adding release tag: $RELEASE_TAG"

git add -A
git commit -m "version $RELEASE_TAG"
git tag -a "$RELEASE_TAG" -m "version $RELEASE_TAG"
git push
git push --tags
