from flask import Flask, request, jsonify
from prometheus_client import Counter, Histogram, Gauge, generate_latest, REGISTRY
import time
import random

app = Flask(__name__)

REQUEST_COUNT = Counter('quicknotes_http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('quicknotes_http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
NOTES_TOTAL = Gauge('quicknotes_notes_total', 'Total number of notes')

notes = []
note_id = 0

@app.route('/metrics')
def metrics():
    return generate_latest(REGISTRY)

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/notes', methods=['GET'])
def get_notes():
    start_time = time.time()
    REQUEST_COUNT.labels(method='GET', endpoint='/notes', status='200').inc()
    REQUEST_DURATION.labels(method='GET', endpoint='/notes').observe(time.time() - start_time)
    return jsonify(notes), 200

@app.route('/notes', methods=['POST'])
def create_note():
    global note_id
    start_time = time.time()
    
    data = request.get_json()
    
    if not data or 'title' not in data or 'content' not in data:
        REQUEST_COUNT.labels(method='POST', endpoint='/notes', status='400').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/notes').observe(time.time() - start_time)
        return jsonify({"error": "Missing title or content"}), 400
    
    if random.random() < 0.1:
        REQUEST_COUNT.labels(method='POST', endpoint='/notes', status='500').inc()
        REQUEST_DURATION.labels(method='POST', endpoint='/notes').observe(time.time() - start_time)
        return jsonify({"error": "Internal server error"}), 500
    
    note_id += 1
    note = {
        "id": note_id,
        "title": data['title'],
        "content": data['content'],
        "created_at": time.time()
    }
    notes.append(note)
    NOTES_TOTAL.set(len(notes))
    
    REQUEST_COUNT.labels(method='POST', endpoint='/notes', status='201').inc()
    REQUEST_DURATION.labels(method='POST', endpoint='/notes').observe(time.time() - start_time)
    return jsonify(note), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
