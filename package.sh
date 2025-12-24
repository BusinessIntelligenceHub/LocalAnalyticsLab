#!/bin/bash
# Package Local Analytics Lab for distribution

set -e

VERSION="1.0.0"
PACKAGE_NAME="local-analytics-lab-v${VERSION}"
DIST_DIR="dist"

echo "=================================================="
echo "  Packaging Local Analytics Lab v${VERSION}"
echo "=================================================="
echo ""

# Create dist directory
mkdir -p "${DIST_DIR}"

# Create temporary packaging directory
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="${TEMP_DIR}/${PACKAGE_NAME}"
mkdir -p "${PACKAGE_DIR}"

echo "Copying files..."

# Core files
cp README.md "${PACKAGE_DIR}/"
cp LICENSE "${PACKAGE_DIR}/"
cp CONTRIBUTING.md "${PACKAGE_DIR}/"
cp SETUP_JOURNEY.md "${PACKAGE_DIR}/"
cp RELEASE_NOTES.md "${PACKAGE_DIR}/"
cp docker-compose.yml "${PACKAGE_DIR}/"
cp justfile "${PACKAGE_DIR}/"
cp .gitignore "${PACKAGE_DIR}/"
cp .env "${PACKAGE_DIR}/"
cp install.sh "${PACKAGE_DIR}/"
cp superset-init.sh "${PACKAGE_DIR}/"

# Create empty directories
mkdir -p "${PACKAGE_DIR}/dags"
mkdir -p "${PACKAGE_DIR}/logs"
mkdir -p "${PACKAGE_DIR}/plugins"
mkdir -p "${PACKAGE_DIR}/config"

# Add .gitkeep to empty directories
touch "${PACKAGE_DIR}/dags/.gitkeep"
touch "${PACKAGE_DIR}/logs/.gitkeep"
touch "${PACKAGE_DIR}/plugins/.gitkeep"
touch "${PACKAGE_DIR}/config/.gitkeep"

# Copy configuration directories
cp -r spark-conf "${PACKAGE_DIR}/"
cp -r spark-jars "${PACKAGE_DIR}/"
cp -r spark-apps "${PACKAGE_DIR}/"
cp -r hive-metastore "${PACKAGE_DIR}/"
cp -r trino "${PACKAGE_DIR}/"
cp -r superset-custom "${PACKAGE_DIR}/"

echo "Creating archive..."

# Create tar.gz
cd "${TEMP_DIR}"
tar -czf "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}"
mv "${PACKAGE_NAME}.tar.gz" "${OLDPWD}/${DIST_DIR}/"

# Create zip for Windows users
zip -r -q "${PACKAGE_NAME}.zip" "${PACKAGE_NAME}"
mv "${PACKAGE_NAME}.zip" "${OLDPWD}/${DIST_DIR}/"

cd "${OLDPWD}"

# Cleanup
rm -rf "${TEMP_DIR}"

# Calculate checksums
cd "${DIST_DIR}"
shasum -a 256 "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256"
shasum -a 256 "${PACKAGE_NAME}.zip" > "${PACKAGE_NAME}.zip.sha256"
cd ..

echo ""
echo "✓ Package created successfully!"
echo ""
echo "Distribution files:"
echo "  ${DIST_DIR}/${PACKAGE_NAME}.tar.gz"
echo "  ${DIST_DIR}/${PACKAGE_NAME}.zip"
echo ""
echo "Checksums:"
echo "  ${DIST_DIR}/${PACKAGE_NAME}.tar.gz.sha256"
echo "  ${DIST_DIR}/${PACKAGE_NAME}.zip.sha256"
echo ""
echo "File sizes:"
du -h "${DIST_DIR}/${PACKAGE_NAME}".*
echo ""
echo "To distribute:"
echo "1. Upload files to GitHub Releases"
echo "2. Include release notes from RELEASE_NOTES.md"
echo "3. Tag version: git tag -a v${VERSION} -m 'Release v${VERSION}'"
echo ""
