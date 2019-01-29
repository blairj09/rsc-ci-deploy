#!/bin/bash

# Script for automatically deploying content via Travis CI
# This script assumes that the manifest and bundle have been created and 
# commited to GH. It also assumes the following environment variables are set:
# - RSC_SERVER: URL to RSC server
# - RSC_API_KEY: Key to authorize deployment on RSC_SERVER
# - CONTENT_GUID: GUID for the content being deployed to RSC

# TODO: Should these be converted into bash functions?

set -ev

# Generate the manifest
Rscript -e "rsconnect::writeManifest(appFiles = 'simple-rmd.Rmd')"

# Create the bundle
tar czf bundle.tar.gz manifest.json simple-rmd.Rmd

# Upload the bundle
curl --silent --show-error -L --max-redirs 0 --fail -X POST \
    -H "Authorization: Key ${RSC_API_KEY}" \
    --data-binary @"bundle.tar.gz" \
    "${RSC_SERVER}__api__/v1/experimental/content/${CONTENT_GUID}/upload" > bundle-id
    
# Deploy the bundle
export BUNDLE_ID=$(cat bundle-id | jq '.bundle_id')
export DATA='{"bundle_id":'${BUNDLE_ID}'}'

curl --silent --show-error -L --max-redirs 0 --fail -X POST \
    -H "Authorization: Key ${RSC_API_KEY}" \
    --data "${DATA}" \
    "${RSC_SERVER}__api__/v1/experimental/content/${CONTENT_GUID}/deploy" > task-id


# Query task
# TODO: Add checks for successful deployment Fail Travis build if deployment
# fails