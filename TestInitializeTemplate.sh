#!/usr/bin/env bash
# Test script for InitializeTemplate.sh

set -e

# Configuration for the test
TEST_DIR="test-workspace"
INPUT_AUTHOR="TestAuthor"
INPUT_NAME="TestProject"
INPUT_SCOPE="TestScope"
INPUT_ORG="TestOrg"
INPUT_REPO="https://github.com/TestAuthor/custom-repo-name.git"

# Clean up any previous test runs
if [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
fi

mkdir -p "$TEST_DIR"

echo "Setting up test environment in $TEST_DIR..."

# Copy project files to test environment
cp -r ProjectScope.ProjectName "$TEST_DIR/"
cp InitializeTemplate.sh "$TEST_DIR/"
cp knope.toml "$TEST_DIR/"

pushd "$TEST_DIR" > /dev/null

echo "Running InitializeTemplate.sh with test inputs..."

# Prepare the input for the interactive script
# Order: Author, Name, Scope, Organization, Repository
printf "${INPUT_AUTHOR}\n${INPUT_NAME}\n${INPUT_SCOPE}\n${INPUT_ORG}\n${INPUT_REPO}\n" | bash InitializeTemplate.sh

echo "Verifying results..."

# 1. Check if directories were renamed correctly
EXPECTED_ROOT="${INPUT_SCOPE}.${INPUT_NAME}"
EXPECTED_PACKAGE_NAME="com.$(echo "${INPUT_SCOPE}" | tr '[:upper:]' '[:lower:]').$(echo "${INPUT_NAME}" | tr '[:upper:]' '[:lower:]')"
EXPECTED_PACKAGE_PATH="${EXPECTED_ROOT}/Packages/${EXPECTED_PACKAGE_NAME}"

if [[ ! -d "$EXPECTED_ROOT" ]]; then
    echo "FAILED: Root directory $EXPECTED_ROOT not found"
    exit 1
fi

if [[ ! -d "$EXPECTED_PACKAGE_PATH" ]]; then
    echo "FAILED: Package directory $EXPECTED_PACKAGE_PATH not found"
    exit 1
fi

# 2. Check package.json content
PACKAGE_JSON="${EXPECTED_PACKAGE_PATH}/package.json"
if [[ ! -f "$PACKAGE_JSON" ]]; then
    echo "FAILED: package.json not found at $PACKAGE_JSON"
    exit 1
fi

grep -q "\"name\": \"${EXPECTED_PACKAGE_NAME}\"" "$PACKAGE_JSON" || { echo "FAILED: Incorrect name in package.json"; exit 1; }
grep -q "\"repository\": \"${INPUT_REPO}\"" "$PACKAGE_JSON" || { echo "FAILED: Incorrect repository in package.json; expected \"${INPUT_REPO}\""; exit 1; }
grep -q "\"name\": \"${INPUT_AUTHOR}\"" "$PACKAGE_JSON" || { echo "FAILED: Incorrect author name in package.json"; exit 1; }

# 3. Check README.md content
README="README.md"
if [[ ! -f "$README" ]]; then
    echo "FAILED: Root README.md not found"
    exit 1
fi

grep -q "${INPUT_REPO}?path=${EXPECTED_PACKAGE_PATH}" "$README" || { echo "FAILED: Git URL in README.md not updated correctly; expected \"${INPUT_REPO}?path=${EXPECTED_PACKAGE_PATH}\""; exit 1; }
grep -q "com.$(echo "${INPUT_SCOPE}" | tr '[:upper:]' '[:lower:]').$(echo "${INPUT_NAME}" | tr '[:upper:]' '[:lower:]')" "$README" || { echo "FAILED: Package name in README.md not updated correctly"; exit 1; }

# 4. Check asmdef files
ASMDEF="${EXPECTED_PACKAGE_PATH}/Runtime/${INPUT_SCOPE}.${INPUT_NAME}.asmdef"
if [[ ! -f "$ASMDEF" ]]; then
    echo "FAILED: asmdef file not renamed correctly: $ASMDEF"
    exit 1
fi

popd > /dev/null

echo "All tests passed successfully!"

# Wait for user to inspect the results
read -rp "Tests passed. Press [Enter] to clean up the test environment, or Ctrl+C to keep it: "

# Cleanup
rm -rf "$TEST_DIR"
echo "Test environment cleaned up."
