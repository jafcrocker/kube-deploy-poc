#! /usr/bin/env bash
set -e
RS_YAML=${1:-rs.yaml}
PROJECT=${PROJECT:=$(gcloud config get-value project)}
STACK=${STACK:=staging}

source common.sh

SERVICE=$(get_service_name_from_rs $RS_YAML)

DEPLOYMENT=$(basename $(deploy $RS_YAML $SERVICE $PROJECT $STACK))
