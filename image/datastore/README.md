Generate a service account:
```
export PROJECT_ID=$(gcloud config get-value core/project)
export SERVICE_ACCOUNT_NAME=datastore-app
gcloud beta iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
  --display-name "datastore app"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role='roles/datastore.user'
gcloud beta iam service-accounts keys create \
  --iam-account "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  service-account.json
```
Run in Docker:
```
docker run --rm -it -v `pwd`/service-account.json:/run/secrets/service-account.json -e GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/service-account.json image
```
