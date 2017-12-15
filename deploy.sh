#! /usr/bin/env bash
set -e
RS_YAML=${1:-rs.yaml}
SERVICE=${SERVICE:=service}
PROJECT=${PROJECT:=$(gcloud config get-value project)}
STACK=${STACK:=staging}

source common.sh


DEPLOYMENT=$(basename $(deploy $RS_YAML $SERVICE $PROJECT $STACK))
