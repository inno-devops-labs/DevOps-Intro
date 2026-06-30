FROM python:3.11-slim

WORKDIR /app

RUN pip install flask prometheus-client

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
