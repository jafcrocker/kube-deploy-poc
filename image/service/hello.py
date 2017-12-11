from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello World!\n"

@app.route("/version.html")
def version():
    return "Version 1.0\n"
