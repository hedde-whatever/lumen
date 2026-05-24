#!/usr/bin/env bash
set -e

awslocal s3 mb s3://"${S3_BUCKET_NAME}"
echo "Bucket ${S3_BUCKET_NAME} created."
