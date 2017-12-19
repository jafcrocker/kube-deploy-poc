#! /usr/bin/env bash

log () {
    echo $* >&2
}

get_deployments_by_date() {
    local MICROSERVICE=$1
    local STACK=$2
	local FORMAT=$3
	SELECTOR=microservice=$MICROSERVICE
	if [ "$STACK" != "" ] ; then 
		SELECTOR=$SELECTOR,stack=$STACK
	fi
	if [ "$FORMAT" != "" ] ; then 
		OUTPUT=--output=$FORMAT
	fi
    kubectl get rs --sort-by=.metadata.creationTimestamp \
		    $OUTPUT \
		    --selector=$SELECTOR 
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

get_service_name_from_rs() {
    local YAML_FILE=$1
    python -c 'import yaml,sys; print yaml.load(sys.stdin)["metadata"]["annotations"]["zenoss.org/service"]' < $YAML_FILE
}




deploy () {
    local RS_YAML_FILE=$1
    local SERVICE_NAME=$2
    local PROJECT_NAME=$3
    local STACK=$4

    local GUID=$(head -c 3 /dev/urandom | base32 | tr '[A-Z=]' '[a-z\0]')
    local MICROSERVICE=$(get_deployment_name_from_rs $RS_YAML_FILE)
    local DEPLOYMENT=${MICROSERVICE}-${GUID}

    log create-deployment $MICROSERVICE $STACK $GUID

    # Define the patch which will add various labels to the replicaset
    #  allowing it to be treated as a deploymwnt by the other scripts.
    local PATCH=$(echo "
        metadata:
          name: &DEPLOYMENT ${MICROSERVICE}-${STACK}-${GUID}
          labels:
            # "microservice" label used to find existing deployments
            microservice: ${MICROSERVICE}
            stack: ${STACK}
        spec:
          selector:
            matchLabels:
              # Select pods managed by this RS
              deployment: *DEPLOYMENT
          template:
            metadata:
              labels:
                # label used to associate pod(s) with RS
                deployment: *DEPLOYMENT
                # label used by service to enable routing
                service_${SERVICE_NAME}: 'false'
        " | awk '{print substr($0, 9)}')
    local ENV="SERVICE_NAME PROJECT_NAME MICROSERVICE GUID STACK"
    local RS=$(export $ENV;
        kubectl patch --local=true -oyaml \
            -f <(envsubst < $RS_YAML_FILE) \
            -p "$(echo "$PATCH" | envsubst)" | \
        kubectl create -f- -o name)

    # Wait for pods to be ready
    log wait-for-deployment
    while true ; do
        local expr=$(kubectl get $RS -o 'go-template=[ "{{.status.readyReplicas}}" = "{{.status.replicas}}" ]')
        eval $expr && break
        sleep 1
    done
    echo $RS
}


