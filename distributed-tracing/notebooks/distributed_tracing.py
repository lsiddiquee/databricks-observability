# Databricks notebook source
# dbutils.widgets.removeAll()
# dbutils.widgets.text("traceparent", "00-80e1afed08e019fc1110464cfa66635c-7a085853722dc6d2-01")

# COMMAND ----------

trace_context = dbutils.widgets.get("traceparent")

# COMMAND ----------

from azure.monitor.opentelemetry.exporter import (
    AzureMonitorLogExporter,
    AzureMonitorTraceExporter
)

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.trace import get_tracer_provider, set_tracer_provider, SpanKind
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry._logs import get_logger_provider, set_logger_provider

from random import randrange

import logging
import time

def setup_tracing(connection_string, resource):
    tracer_provider = TracerProvider(resource=resource)
    set_tracer_provider(tracer_provider)
    trace_exporter = AzureMonitorTraceExporter(connection_string=connection_string)
    span_processor = BatchSpanProcessor(
        trace_exporter,
    )
    get_tracer_provider().add_span_processor(span_processor)

def setup_logging(connection_string, resource):
    logger_provider = LoggerProvider(resource=resource)
    set_logger_provider(logger_provider)
    log_exporter = AzureMonitorLogExporter(connection_string=connection_string)
    log_record_processor = BatchLogRecordProcessor(
        log_exporter
    )
    get_logger_provider().add_log_record_processor(log_record_processor)
    handler = LoggingHandler(logger_provider=get_logger_provider())
    logging.getLogger().addHandler(handler)

connection_string = "<connection_string_to_app_insights>"
resource = Resource.create({"service.name": "Anonymization Notebook"})

setup_tracing(connection_string, resource)
setup_logging(connection_string, resource)

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

logger.info("Inside notebook")
logger.info(f"Attempt to join an existing trace session with context: {trace_context}")

headers = {
    "traceparent": trace_context
}

print(headers)

# Explicitly the tracer is being created in here to ensure that we create it with the correct context from the headers.
context = TraceContextTextMapPropagator().extract(headers)
tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span(name="Notebook Invoked", context=context, kind=SpanKind.SERVER) as span:
    print(span.get_span_context())
    with tracer.start_as_current_span(name='extract'):
        logger.info("Extract")
        time.sleep(randrange(start=3, stop=10))
    with tracer.start_as_current_span(name='transform'):
        logger.info("Transform")
        time.sleep(randrange(start=3, stop=10))
    with tracer.start_as_current_span(name='load'):
        logger.info("Load")
        time.sleep(randrange(start=3, stop=10))
