#!/bin/bash

# Build Android APK using Docker
echo "Building Android APK with Docker..."

# Build Docker image
docker build -f Dockerfile.android -t tipme-android-builder .

# Run container and build APK
docker run --rm -v $(pwd):/workspace tipme-android-builder

# Copy APK from container
echo "APK built successfully!"
echo "Location: build/app/outputs/flutter-apk/app-release.apk"
