import logging

import connexion

from opentelemetry import (
    trace,
    _logs
)

from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# from azure.monitor.opentelemetry import configure_azure_monitor

from azure.monitor.opentelemetry._configure import (
    _setup_tracing,
    _setup_logging
)
from azure.monitor.opentelemetry.util.configurations import _get_configurations

# Explicitly not using this as this causes additional instrumentors to load and url exception does not work.
# configure_azure_monitor()

app = connexion.FlaskApp(__name__, specification_dir='openapi/')
app.add_api('api.yaml')

configurations = _get_configurations()
_setup_tracing(configurations)
_setup_logging(configurations)

# The following injects the middleware to instrument a flask api in general. It automatically creates a tracing session whenever a new request comes in to the application.
FlaskInstrumentor().instrument_app(app.app)

RequestsInstrumentor().instrument()

# Setting up the tracer settings that will be used by the middleware to trace. This needs to be instantiated at app level as we need to have a trace span started prior our route handler gets invoked.
print(trace.get_tracer_provider().resource.attributes)

# Setup logger
print(_logs.get_logger_provider().resource.attributes)

logging.getLogger(__name__).setLevel(logging.DEBUG)
app.app.logger.setLevel(logging.DEBUG)

if __name__ == '__main__':
    app.run()
