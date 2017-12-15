FROM python:2.7.14-alpine3.6
RUN pip install Flask==0.12.2
RUN apk add --no-cache build-base && pip install google-cloud-datastore==1.4.0
COPY hello.py /var/www/hello.py	
CMD FLASK_APP=/var/www/hello.py flask run --host=0.0.0.0
