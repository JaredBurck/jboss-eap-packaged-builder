#!/bin/bash

# Validate Environment Variables
echo ">> Running JBoss EAP Builder"

if [ -z "${ARTIFACT_HOST}" ]; then
  echo "Host for Artifact destination not provided"
  exit 1
fi

if [ -z "${ARTIFACT_GROUP_ID}" ]; then
  echo "Maven Group ID for remote artifact not provided"
  exit 1
fi

if [ -z "${ARTIFACT_ID}" ]; then
  echo "Maven Artifact ID not provided"
  exit 1
fi

if [ -z "${ARTIFACT_VERSION}" ]; then
  echo "Maven Artifact version not provided"
  exit 1
fi

default_image="registry.access.redhat.com/jboss-eap-6/eap-openshift:6.4"
default_packaging="war"
default_repository="public"


FROM_IMAGE_NAME=${IMAGE_NAME:-$default_image}
PACKAGING=${ARTIFACT_PACKAGING:-$default_packaging}
REPOSITORY=${REPOSITORY:-$default_repository}

TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"

# Create Docker File
cat > Dockerfile << EOF
FROM ${FROM_IMAGE_NAME}

# Download artifact
RUN curl -L -sf -o /opt/eap/standalone/deployments/${ARTIFACT_ID}-${ARTIFACT_VERSION}.${PACKAGING} "http://${ARTIFACT_HOST}/nexus/service/local/artifact/maven/redirect?r=${REPOSITORY}&g=${ARTIFACT_GROUP_ID}&a=${ARTIFACT_ID}&v=${ARTIFACT_VERSION}&p=${PACKAGING}"

# Start EAP
ENTRYPOINT ["/opt/eap/bin/openshift-launch.sh"]
EOF

echo ">> Building JBoss EAP Docker image"
# Run Docker build
docker build --rm -t ${TAG}

echo ">> Pushing JBoss EAP Docker image"
# Push to Docker
docker push ${TAG}