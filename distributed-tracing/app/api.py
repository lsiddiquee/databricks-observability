from flask import Blueprint, request, url_for

from opentelemetry import trace
from opentelemetry.trace import SpanKind
from opentelemetry.semconv.trace import SpanAttributes
from opentelemetry.trace.status import StatusCode
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

import os
import requests
import logging
import time

from urllib.parse import urlparse
from random import randrange

logger = logging.getLogger(__name__)

api_blueprint = Blueprint('api_blueprint',__name__)

@api_blueprint.route('/notebook', methods=['GET'])
def notebook():
    logger.info("Logging warning message in notebook")

    # The tracer needs to be explicitly retrieved from the context as the middleware already creates a tracer, and we want to join to that one.
    tracer = trace.get_tracer(__name__)

    logger.info("Process to call notebook invoked")

    # Creating a validation span
    with tracer.start_as_current_span(name='invoke-validation'):
        logger.info("Invoking validation")
        scheme = request.headers.get('X-Forwarded-Proto', request.scheme)
        response = requests.get(url_for('api_blueprint.validate', _external=True, _scheme=scheme))
        if response.status_code != 200:
            raise ValueError(response.content)
        logger.info("Invoking validation complete")

    # Creating a jobs api invocation span
    with tracer.start_as_current_span(name='invoke-jobs-api'):
        logger.info("Invoking jobs api")

        _api_endpoint = os.environ.get('DATABRICKS_HOST').removesuffix('/')
        _api_token = os.environ.get('DATABRICKS_TOKEN')

        headers={
            "Authorization": "Bearer {}".format(_api_token),
            "Content-Type": "application/json"
        }

        run_now_url = f"{_api_endpoint}/api/2.0/jobs/run-now"

        with tracer.start_as_current_span(name="this_value_will_be_updated_later", kind=SpanKind.CLIENT) as span:
            params = {}
            TraceContextTextMapPropagator().inject(params) # This injects the tracecontext in the params.
            payload = {
                "job_id": os.environ.get('DATABRICKS_JOB_ID'),
                "job_parameters": params
            }

            response = handle_request_post_with_span(
                    span=span,
                    url=run_now_url,
                    headers=headers,
                    payload=payload
                ).json()
            response["operation_id"] = hex(span.get_span_context().trace_id)

            return response

@api_blueprint.route('/validate', methods=['GET'])
def validate():
    logger.info("Logging critical message in validate")

    tracer = trace.get_tracer(__name__)

    with tracer.start_as_current_span(name="simulate-service-a"):
        logger.warning(f"Calling service A")
        time.sleep(randrange(start=1, stop=3))
        logger.critical(f"Service A responded")
    with tracer.start_as_current_span(name="simulate-service-b"):
        logger.warning(f"Calling Service B")
        time.sleep(randrange(start=1, stop=3))
        logger.critical(f"Service B responded")

    return {}


def handle_request_post_with_span(span, url, headers, payload):

    parsed_url = urlparse(url)
    if parsed_url.port is None:
        host = parsed_url.hostname
    else:
        host = '{}:{}'.format(parsed_url.hostname, parsed_url.port)

    path = parsed_url.path if parsed_url.path else '/'

    span.update_name(path)
    # Add the component type to attributes
    span.set_attribute("component", "HTTP")
    span.set_attribute(SpanAttributes.HTTP_HOST, host)
    span.set_attribute(SpanAttributes.HTTP_METHOD, "POST")
    span.set_attribute("http.path", path)
    span.set_attribute(SpanAttributes.HTTP_URL, url)

    try:
        result = requests.post(
            url,
            headers=headers,
            json=payload)
    except Exception as e:
        span.set_status(StatusCode.ERROR, e)
        raise
    else:
        # Add the status code to attributes
        span.set_attribute(
            SpanAttributes.HTTP_STATUS_CODE, result.status_code)

        if result.ok:
            span.set_status(StatusCode.OK)
        else:
            span.set_status(StatusCode.ERROR, result.content)

    return result
