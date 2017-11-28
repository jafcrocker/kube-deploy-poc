This repo is a proof-of-concept for deploying services to Kubernetes
in such a way as to enable canary and red-black testing.  The approach consists of a
labeling scheme based on that used by Spinnaker in which the pods indicate (via labels)
for which services they are enabled.  I.e., pods _a_ and _b_ indicate that they are 
enabled for service _alpha_ with the label "service_alpha: true".

This repo demonstrates a technique for conditionally deploying a new version of a 
microservice (as implemented by a ReplicaSet) to Kubernetes.  The strategy is:

1) Deploy a new version of the microservice,
2) Disable the existing version of the microservice, 
3) Enable the new version of the microservice,
4) Perform a test which exercises the new version of the microservice,
5) Depending on whther the test succeeded or failed, either
  a) delete the previous version, or
  b) enable the previous version and delete the new version

Instructions:
```
# Set an environment variable with the name of your Google Cloud project
GCLOUD_PROJECT=$(gcloud config get-value project)
```

1) Build the images:
```
docker build -t gcr.io/${GCLOUD_PROJECT}/service:1.0 image/service
docker build -t gcr.io/${GCLOUD_PROJECT}/test:1.0 image/test
```

2) Push the images:
```
gcloud docker -- push gcr.io/${GCLOUD_PROJECT}/service:1.0
gcloud docker -- push gcr.io/${GCLOUD_PROJECT}/test:1.0
```

3) Create a kubernetes service.  This service will route requests to a deployment
depending on whether the deployment is enabled.
```
kubectl apply -f service.yaml
```

4) Create a new deployment:
```
./deploy.sh
```

5) Modify the service such that the test fails
```
# Create a new service image
sed -i 's/Version ..0/Version 2.0/' image/service/version.html 
docker build -t gcr.io/${GCLOUD_PROJECT}/service:2.0 image/service
gcloud docker -- push gcr.io/${GCLOUD_PROJECT}/service:2.0

# Modify the replicaset to use the new image
sed -i 's/service:..0/service:2.0/' rs.yaml

./deploy.sh
```




