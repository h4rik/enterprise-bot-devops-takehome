import os
import socket

from flask import Flask, jsonify


def create_app():
    app = Flask(__name__)

    @app.get("/healthz")
    def health_check():
        return jsonify(status="healthy"), 200

    @app.get("/")
    def root():
        return jsonify(
            app=os.getenv("APP_NAME", "enterprise_bot"),
            version=os.getenv("VERSION", "dev"),
            pod=socket.gethostname(),
        ), 200

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
