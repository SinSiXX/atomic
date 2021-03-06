#!/bin/bash
set -xeuo pipefail

# https://bugzilla.redhat.com/show_bug.cgi?id=1318547#c7
mount --make-rshared /


if [ -f /run/ostree-booted ]; then
    if [ ! -e /var/tmp/ostree-unlock-ovl.* ]; then
        ostree admin unlock
    fi
else
    dnf install -y atomic python3-coverage
fi

systemctl start docker

# somewhat mimic the spec conditional
source /etc/os-release
if [ "$ID" == fedora ]; then
  PYTHON=python3
else
  PYTHON=python
fi

DOCKER_RUN="docker run --rm \
              --privileged \
              -v $PWD:/code \
              -v /:/host \
              --workdir /code \
                projectatomic/atomic-tester"

# pylint, build, and install in the container...
$DOCKER_RUN make pylint-check
$DOCKER_RUN make test-python3-pylint
$DOCKER_RUN make PYTHON=$PYTHON PYLINT=true install DESTDIR=/host

# ... but run the testsuite on the host
PYTHON=$PYTHON ./test.sh
