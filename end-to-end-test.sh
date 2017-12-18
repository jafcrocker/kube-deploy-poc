#! /usr/bin/env bash
set -e
RS_YAML=$1
PROJECT=$(gcloud config get-value project)
STACK=staging

source common.sh

do_test () {
    local DEPLOYMENT=$1
    local PROJECT_NAME=$2

    log test-deployment $DEPLOYMENT
    local ENV="DEPLOYMENT PROJECT_NAME"
    local POD=$(kubectl create -f <(export $ENV; envsubst < test.yaml) -oname)

    log wait-for-test $POD
    while true ; do
        local status=$(kubectl get $POD -o 'go-template={{.status.phase}}')
        [ "$status" = "Succeeded" ] && return 0
        [ "$status" = "Failed" ] && return 1
        sleep 3
    done
}

MICROSERVICE=$(get_deployment_name_from_rs $RS_YAML)
SERVICE=$(get_service_name_from_rs $RS_YAML)
LAST_DEPLOYMENT=$(get_deployments_by_date $MICROSERVICE $STACK name | xargs -r basename -a | tail -1)

DEPLOYMENT=$(basename $(deploy $RS_YAML $SERVICE $PROJECT $STACK))

[ "$LAST_DEPLOYMENT" = "" ] || enable_deployment $LAST_DEPLOYMENT $SERVICE false
enable_deployment $DEPLOYMENT $SERVICE true

if do_test $DEPLOYMENT $PROJECT ; then
    [ "$LAST_DEPLOYMENT" = "" ] || kubectl delete rs $LAST_DEPLOYMENT
else
    [ "$LAST_DEPLOYMENT" = "" ] || enable_deployment $LAST_DEPLOYMENT $SERVICE true
    kubectl delete rs $DEPLOYMENT
fi

