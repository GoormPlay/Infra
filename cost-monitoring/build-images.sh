#!/bin/bash

# Build Cost Collector Image for MicroK8s
echo "Building Cost Collector image..."

# Build the image
docker build -t cost-collector:latest ./cost-collector/

# Import to MicroK8s
echo "Importing image to MicroK8s..."
docker save cost-collector:latest | microk8s ctr image import -

echo "Image build and import completed!"
echo "Available images in MicroK8s:"
microk8s ctr images list | grep cost-collector
