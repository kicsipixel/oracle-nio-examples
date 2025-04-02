#!/usr/bin/env bash
FOLDER=${1:-}
TEMPLATE_VERSION=0.9.2

if [[ -z "$FOLDER" ]]; then
  echo "Missing folder name"
  echo "Usage: download.sh <folder>"
  exit 1
fi

curl -sSL https://github.com/kicsipixel/openapi_template/archive/refs/tags/"$TEMPLATE_VERSION".tar.gz | tar xvz -s /openapi_template-"$TEMPLATE_VERSION"/"$FOLDER"/