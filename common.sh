#! /usr/bin/env bash

log () {
    echo $* >&2
}

get_deployments_by_date() {
    local RS_YAML_FILE=$1
    local STACK=$2
    local MICROSERVICE=$(get_deployment_name_from_rs $RS_YAML_FILE)
    kubectl get rs --sort-by=.metadata.creationTimestamp -oname \
          --selector=microservice=$MICROSERVICE,stack=$STACK \
        | tac | xargs -r basename -a
}

enable_deployment() {
    local DEPLOYMENT=$1
    local SERVICE=$2
    local VALUE=$3
    log enable-deployment $DEPLOYMENT $VALUE
    # set state of pods created by the rs in the future (e.g., by scaling)
    kubectl patch rs $1 -p "'spec': {template: {metadata: {labels: {service_$SERVICE: '$VALUE'}}}}" > /dev/null
    # enable/disable existing pods in the deployment
    kubectl label pod --overwrite -l deployment=$DEPLOYMENT service_$SERVICE=$VALUE > /dev/null
}

get_deployment_name_from_rs() {
    local YAML_FILE=$1
    python -c 'import yaml,sys; print yaml.load(sys.stdin)["metadata"]["name"]' < $YAML_FILE
}

deploy () {
    local RS_YAML_FILE=$1
    local SERVICE_NAME=$2
    local PROJECT_NAME=$3
    local STACK=$4

    local GUID=$(printf "%04x\n" $RANDOM)
    local MICROSERVICE=$(get_deployment_name_from_rs $RS_YAML_FILE)
    local DEPLOYMENT=${MICROSERVICE}-${GUID}

    log create-deployment $MICROSERVICE $STACK $GUID

    local ENV="SERVICE_NAME PROJECT_NAME MICROSERVICE GUID STACK"
    local RS=$(export $ENV;
        kubectl patch --local=true -oyaml \
            -f <(envsubst < $RS_YAML_FILE) \
            -p "$(envsubst < patch.yaml)" | \
        kubectl apply -f- -o name)

    # Wait for pods to be ready
    log wait-for-deployment
    while true ; do
        local expr=$(kubectl get $RS -o 'go-template=[ "{{.status.readyReplicas}}" = "{{.status.replicas}}" ]')
        eval $expr && break
        sleep 1
    done
    echo $RS
}


