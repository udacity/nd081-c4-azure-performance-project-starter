import logging
import os
import socket

import redis
from flask import Flask, render_template, request
from opencensus.ext.azure import metrics_exporter
# required libraries for App Insights
from opencensus.ext.azure.log_exporter import (AzureEventHandler,
                                               AzureLogHandler)
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.ext.flask.flask_middleware import FlaskMiddleware
from opencensus.stats import stats as stats_module
from opencensus.trace import config_integration
from opencensus.trace.samplers import ProbabilitySampler
from opencensus.trace.tracer import Tracer

# For metrics
stats = stats_module.stats
view_manager = stats.view_manager

app = Flask(__name__)

# Load configurations from environment or config file
app.config.from_pyfile("config_file.cfg")

# Application Insight Instrumentation Key
instr_key = app.config["APP_INSIGHTS_INSTRUMENTATION_KEY"]

# instrumentation key validation
if not instr_key:
    raise Exception("Missing instrumentation key")

# Logging
config_integration.trace_integrations(["logging"])
config_integration.trace_integrations(["requests"])

# Standard Logging
logger = logging.getLogger(__name__)
handler = AzureLogHandler(connection_string=instr_key)
# handler.setFormatter(logging.Formatter('%(traceId)s %(spanId)s %(message)s'))
logger.addHandler(handler)

# Logging custom Events
logger.addHandler(AzureEventHandler(connection_string=instr_key))

# Set the logging level
logger.setLevel(logging.INFO)

# Metrics
exporter = metrics_exporter.new_metrics_exporter(
    enable_standard_metrics=True, connection_string=instr_key
)

view_manager.register_exporter(exporter)

# Tracing
tracer = Tracer(
    exporter=AzureExporter(connection_string=instr_key),
    sampler=ProbabilitySampler(1.0),
)

# Requests
middleware = FlaskMiddleware(
    app,
    exporter=AzureExporter(connection_string=instr_key),
    sampler=ProbabilitySampler(rate=1.0),
)

if "VOTE1VALUE" in os.environ and os.environ["VOTE1VALUE"]:
    button1 = os.environ["VOTE1VALUE"]
else:
    button1 = app.config["VOTE1VALUE"]

if "VOTE2VALUE" in os.environ and os.environ["VOTE2VALUE"]:
    button2 = os.environ["VOTE2VALUE"]
else:
    button2 = app.config["VOTE2VALUE"]

if "TITLE" in os.environ and os.environ["TITLE"]:
    title = os.environ["TITLE"]
else:
    title = app.config["TITLE"]

# Redis configurations
redis_server = os.environ['REDIS']

# Redis Connection to another container
try:
    if "REDIS_PWD" in os.environ:
        r = redis.StrictRedis(host=redis_server,
                              port=6379,
                              password=os.environ['REDIS_PWD'])
    else:
        r = redis.Redis(redis_server)
    r.ping()
except redis.ConnectionError:
    exit('Failed to connect to Redis, terminating.')

# Change title to host name to demo NLB
if app.config["SHOWHOST"] == "true":
    title = socket.gethostname()

# Init Redis
if not r.get(button1):
    r.set(button1, 0)
if not r.get(button2):
    r.set(button2, 0)


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "GET":

        # Get current values
        vote1 = r.get(button1).decode("utf-8")
        # use tracer object to trace cat vote
        tracer.span(name="CATS")
        vote2 = r.get(button2).decode("utf-8")
        # use tracer object to trace dog vote
        tracer.span(name="DOGS")
        # Return index with values
        return render_template(
            "index.html",
            value1=int(vote1),
            value2=int(vote2),
            button1=button1,
            button2=button2,
            title=title,
        )

    elif request.method == "POST":

        if request.form["vote"] == "reset":

            # Empty table and return results
            r.set(button1, 0)
            r.set(button2, 0)
            vote1 = r.get(button1).decode("utf-8")
            properties = {"custom_dimensions": {"Cats Vote": vote1}}
            # use logger object to log cat vote
            logger.info("CATS", extra=properties)

            vote2 = r.get(button2).decode("utf-8")
            properties = {"custom_dimensions": {"Dogs Vote": vote2}}
            # use logger object to log dog vote
            logger.info("DOGS", extra=properties)

            return render_template(
                "index.html",
                value1=int(vote1),
                value2=int(vote2),
                button1=button1,
                button2=button2,
                title=title,
            )

        else:

            # Insert vote result into DB
            vote = request.form["vote"]
            r.incr(vote, 1)

            # Get current values
            vote1 = r.get(button1).decode("utf-8")
            vote2 = r.get(button2).decode("utf-8")

            # Return results
            return render_template(
                "index.html",
                value1=int(vote1),
                value2=int(vote2),
                button1=button1,
                button2=button2,
                title=title,
            )


if __name__ == "__main__":
    # Use the statement below when running locally
    # app.run(port=2000)
    # Use the statement below before deployment to VMSS
    app.run(host="0.0.0.0", threaded=True, debug=True)  # remote
