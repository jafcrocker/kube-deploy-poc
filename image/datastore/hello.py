
import datetime
from google.cloud import datastore

from flask import Flask
from flask import request
app = Flask(__name__)


@app.route("/")
def hello():
    return "Hello World!\n"

@app.route("/version.html")
def version():
    return "Version 1.0\n"

client = datastore.Client()

@app.route("/add")
def add():
    description=request.args.get('description', 'default')
    print 'add', description
    key = client.key('Task')
    task = datastore.Entity(key, exclude_from_indexes=['description'])
    task.update({
        'created': datetime.datetime.utcnow(),
        'description': description
    })
    client.put(task)
    return str(task.key.id_or_name)
