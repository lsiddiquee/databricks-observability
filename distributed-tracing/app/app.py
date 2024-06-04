from dotenv import load_dotenv
load_dotenv()

import logging

import flask

from azure.monitor.opentelemetry import configure_azure_monitor
configure_azure_monitor()

from api import api_blueprint

def create_app():
    app = flask.Flask(__name__)
    app.register_blueprint(api_blueprint)

    return app

app = create_app()

logging.getLogger(__name__).setLevel(logging.DEBUG)
app.logger.setLevel(logging.DEBUG)

if __name__ == '__main__':
    app.run()
