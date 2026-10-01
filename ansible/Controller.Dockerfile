FROM python:3.12-slim

RUN pip install --no-cache-dir --timeout 300 --retries 10 \
    ansible==10.7.0 paramiko==5.0.0

WORKDIR /workspace
