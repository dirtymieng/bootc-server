#!/bin/bash
# Build and optionally push the bootc image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DIR="${SCRIPT_DIR}/../image"
IMAGE_NAME="${IMAGE_NAME:-bootc-server:latest}"
REGISTRY="${REGISTRY:-forgejo.meatworks.org/dirtymieng}"

cd "${IMAGE_DIR}"

echo "Building image: ${IMAGE_NAME}"
podman build -t "${IMAGE_NAME}" .

if [ -n "${REGISTRY}" ]; then
    FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}"
    echo "Tagging image: ${FULL_IMAGE}"
    podman tag "${IMAGE_NAME}" "${FULL_IMAGE}"
    
    echo "Pushing image: ${FULL_IMAGE}"
    podman push "${FULL_IMAGE}"
    
    echo ""
    echo "Image pushed successfully!"
    echo "To install on a server, boot from Fedora live media and run:"
    echo "  bootc install to-disk --image ${FULL_IMAGE} /dev/sda"
else
    echo ""
    echo "Image built successfully!"
    echo "To push to a registry, set REGISTRY environment variable:"
    echo "  REGISTRY=registry.example.com ./scripts/build.sh"
fi
