FROM  openshift/origin-docker-builder:latest

MAINTAINER Andrew Block

ADD bin/build.sh /tmp/build.sh

ENTRYPOINT ["/tmp/build.sh"]