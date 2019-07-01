#!/bin/bash

# Build the website for production
JEKYLL_ENV=production bundle exec jekyll build
# Add checksum file
# Note: on linux, replace md5 with md5sum
tar c . | md5sum > CHECKSUM
# Sync all the built files to a bucket on S3.
pushd _site
aws s3 sync --exact-timestamps --delete . s3://happyislet/
popd
aws s3 sync --exact-timestamps --delete s3://happyislet/ /home/ec2-user/happyislet

