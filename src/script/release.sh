#/bin/bash -e

# Small helper to tag an image with a version and SHA1 and copy to the release dir.

IMAGE=$1
VERSION=$2
RELEASE_DIR=$3

SHA=`sha1sum "$IMAGE" | cut -d ' ' -f 1`
echo "SHA1: $SHA"
BASE_NAME=`basename $IMAGE`
IMAGE_EXT="${BASE_NAME##*.}"
IMAGE_NAME="${BASE_NAME%.*}"
RELEASE_NAME=$RELEASE_DIR/$IMAGE_NAME-$VERSION-SHA1-$SHA.$IMAGE_EXT
echo "Creating release: $RELEASE_NAME"
cp $IMAGE $RELEASE_NAME
