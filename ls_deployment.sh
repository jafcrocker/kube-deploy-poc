#! /usr/bin/env bash

MICROSERVICE=${1}
STACK=${2}
FORMAT=${3}

source common.sh
get_deployments_by_date $MICROSERVICE $STACK
