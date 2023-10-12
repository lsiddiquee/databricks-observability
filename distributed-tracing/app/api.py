from flask import request

from opentelemetry import trace
from opentelemetry.trace import SpanKind
from opentelemetry.semconv.trace import SpanAttributes
from opentelemetry.trace.status import StatusCode
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

from urllib.parse import urlparse

from random import randrange

import os
import requests
import logging
import time

logger = logging.getLogger(__name__)

def anonymize():
    logger.warning("logging warning message in anonymize")

    # The tracer needs to be explicitly retrieved from the context as the middleware already creates a tracer, and we want to join to that one.
    # tracer = trace.get_tracer()
    tracer = trace.get_tracer(__name__)
    print(trace.get_current_span().get_span_context())
    logger.warning("Orchestration invoked")
    # Creating a validation span
    with tracer.start_as_current_span(name='invoke-validation'):
        logger.warning("Invoking validation")
        response = requests.get("http://localhost:5000/api/validate")
        if response.status_code != 200:
            raise ValueError(response.content)
        logger.critical("Invoking validation complete")

    # Creating a jobs api invocation span
    with tracer.start_as_current_span(name='invoke-jobs-api'):
        logger.warning("Invoking jobs api")

        _api_endpoint = os.environ.get('DATABRICKS_HOST').removesuffix('/')
        _api_token = os.environ.get('DATABRICKS_TOKEN')

        headers={
            "Authorization": "Bearer {}".format(_api_token),
            "Content-Type": "application/json"
        }

        run_now_url = f"{_api_endpoint}/api/2.0/jobs/run-now"

        with tracer.start_as_current_span(name="test", kind=SpanKind.CLIENT) as span:
            params = {}
            TraceContextTextMapPropagator().inject(params) # This injects the tracecontext in the params.
            print(params)
            payload = {
                "job_id": 739361035815801,
                "notebook_params": params
            }

            print(span.get_span_context())
            response = handle_request_post_with_span(
                    span=span,
                    url=run_now_url,
                    headers=headers,
                    payload=payload
                ).json()
            response["operation_id"] = hex(span.get_span_context().trace_id)

            return response
        
def validate():
    logger.critical("logging critical message in validate")
    print("Request Headers:")
    print(str(request.headers))

    tracer = trace.get_tracer(__name__)
    print(trace.get_current_span().get_span_context())

    with tracer.start_as_current_span(name="simulate-purview"):
        logger.warning(f"Calling purview")
        time.sleep(randrange(start=1, stop=3))
        logger.critical(f"purview responded")
    with tracer.start_as_current_span(name="simulate-strategy-provider"):
        logger.warning(f"Calling strategy provider")
        time.sleep(randrange(start=1, stop=3))
        logger.critical(f"strategy provider responded")

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
