IMAGE_NAME=gcr.io/prod-185516/datastore:1.0
image:
	docker build -t ${IMAGE_NAME} .
push:
	gcloud docker -- push ${IMAGE_NAME}
run:
	docker run --rm -it --name datastore-run -v `pwd`/service-account.json:/run/secrets/service-account.json -e GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/service-account.json ${IMAGE_NAME}

test: 
	docker exec -t datastore-run wget -qO- localhost:5000/add?description=doowop
