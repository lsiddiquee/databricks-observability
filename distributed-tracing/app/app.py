from dotenv import load_dotenv
load_dotenv()

import logging

import flask

from opentelemetry import (
    trace,
    _logs
)

from azure.monitor.opentelemetry import configure_azure_monitor
configure_azure_monitor()

from api import api_blueprint

def create_app():
    app = flask.Flask(__name__)
    app.register_blueprint(api_blueprint)

    return app

app = create_app()

# Setting up the tracer settings that will be used by the middleware to trace. This needs to be instantiated at app level as we need to have a trace span started prior our route handler gets invoked.
print(trace.get_tracer_provider().resource.attributes)

# Setup logger
# print(_logs.get_logger_provider().resource.attributes)

logging.getLogger(__name__).setLevel(logging.DEBUG)
app.logger.setLevel(logging.DEBUG)

if __name__ == '__main__':
    app.run()
