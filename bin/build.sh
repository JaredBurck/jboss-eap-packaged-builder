#!/bin/bash

set -e


# Configure Defaults
default_app_name="ROOT.war"
default_image="registry.access.redhat.com/jboss-eap-6/eap64-openshift:1.2"
FROM_IMAGE_NAME=${IMAGE_NAME:-$default_image}
TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
SRC_APP_NAME=${SRC_APP_NAME:-$default_app_name}
DOCKER_SOCKET=/var/run/docker.sock


echo ">> Running JBoss EAP Builder"

# Validate Parameters
if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Error: Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi


if [ -z "${SRC_APP_URL}" ]; then
  echo "Error: Application Source URL Not Provided!"
  exit 1
fi


mkdir -p /tmp/build && cd /tmp/build

# Create Docker File
cat > Dockerfile << EOF
FROM ${FROM_IMAGE_NAME}

# Download artifact
RUN curl -L -fs -o "/opt/eap/standalone/deployments/${SRC_APP_NAME}" "${SRC_APP_URL}"

# Start EAP
ENTRYPOINT ["/opt/eap/bin/openshift-launch.sh"]
EOF

echo ">> Building JBoss EAP Docker image ${TAG}"

# Run Docker build
docker build --no-cache --rm -t "${TAG}" .

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then
	echo ">> Pushing JBoss EAP Docker image"
	# Push to Docker
	docker push "${TAG}"
fi
