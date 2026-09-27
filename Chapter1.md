# Chapter 1: Cloud-Native Architecture Patterns

This chapter covers foundational cloud-native architectural patterns for the **DevOps Tools Engineer (LPI 701-200)** certification. It provides enterprise-grade architectural analysis, hands-on configuration examples, protocol comparisons, reliability patterns, and DALL-E 3 prompts for generating clean, print-style visual documentation.

## 1.1 Monolithic vs. Microservices vs. Serverless Paradigms

Selecting an application architecture requires evaluating operational complexity, deployment velocity, fault isolation, and resource consumption. Enterprise environments often transition from monolithic codebases to microservices or serverless architectures to increase velocity and scalability.

![Architectural Evolution Paradigms](assets/images/chapter1/1-1-Architectural-Evolution-Paradigms.png)

### Paradigm Comparison Matrix

![Architectural Paradigms Matrix](assets/images/chapter1/1-1-Architectural-Paradigms-Matrix.png)

## 1.2 API-First Architectures: RESTful APIs, gRPC, and GraphQL

API-First architecture establishes contract-driven interfaces before implementation begins. This ensures seamless cross-team integration and contract testing.

### Protocol Analysis and Configuration

- **REST (OpenAPI/Swagger):** Standardized over HTTP/1.1 or HTTP/2 using JSON payloads and standard HTTP methods (`GET`, `POST`, `PUT`, `DELETE`).
- **gRPC (Protocol Buffers):** High-performance, low-latency framework using HTTP/2 transport and binary protocol buffers for schema definitions and multiplexing.
- **GraphQL:** Query language for APIs enabling clients to request exactly the payload fields required, eliminating over-fetching and under-fetching.

#### Protocol Buffers Interface Definition (`user_service.proto`)

```protobuf
syntax = "proto3";

package enterprise.users.v1;

option go_package = "github.com/enterprise/pkg/api/v1/userv1";

// UserManagement service provides user lifecycle operations.
service UserManagement {
  rpc GetUserByID (GetUserRequest) returns (UserResponse);
  rpc StreamUserAuditLogs (AuditLogRequest) returns (stream AuditLogResponse);
}

message GetUserRequest {
  string user_id = 1;
}

message UserResponse {
  string user_id = 1;
  string email = 2;
  string full_name = 3;
  bool is_active = 4;
  int64 created_at_unix = 5;
}

message AuditLogRequest {
  string user_id = 1;
  int64 start_time_unix = 2;
}

message AuditLogResponse {
  string log_id = 1;
  string action = 2;
  string timestamp = 3;
}
```

![API Protocol Interaction Patterns](assets/images/chapter1/1-2-API-Protocol-Interaction-Patterns.png)

## 1.3 Event-Driven Architecture & Message Queuing

Event-Driven Architecture (EDA) decouples producers and consumers using event brokers, providing asynchronous execution, buffering, and message replay capabilities.

### Event Processing Patterns

- **Pub/Sub (Publish/Subscribe):** Events are broadcast to all subscribed consumers (e.g., Kafka Topics, SNS).
- **Point-to-Point (Queue):** Messages are consumed by exactly one consumer worker from a shared pool (e.g., SQS, RabbitMQ Queues).
- **Event Sourcing:** State changes are logged as an immutable sequence of events, allowing point-in-time reconstruction.

![Event Routing and DLX Processing Workflow](assets/images/chapter1/1-3-Event-Routing-and-DLX-Processing-Workflow.png)

## 1.4 Enterprise Scalability, Fault Tolerance, and High Availability

Building resilient systems requires engineering for failure at every layer of the enterprise stack.

### Resiliency Patterns

1. **Circuit Breaker:** Prevents cascading failures by stopping requests to a struggling service once an error threshold is reached (States: *Closed*, *Open*, *Half-Open*).
2. **Bulkhead:** Isolates critical resource pools (e.g., separate thread pools per downstream dependency) so that an outage in one pool does not starve others.
3. **Rate Limiting & Throttling:** Protects services from overload by enforcing upper limits on incoming request rates using algorithms like token bucket or leaky bucket.

![Circuit Breaker State Machine Topology](assets/images/chapter1/1-4-Circuit-Breaker-State-Machine-Topology.png)

## 1.5 Hands-On Lab: Decoupling a Monolithic Application into Event-Driven Microservices

This lab demonstrates decoupling a synchronous monolithic processing path into an asynchronous event-driven workflow using Docker Compose, NGINX, RabbitMQ, Python application services, and Redis.

### Lab Topology Schematic

![Hands-On Decoupled Lab Infrastructur](assets/images/chapter1/1-5-Hands-On-Decoupled-Lab-Infrastructure.png)

### Deployment Orchestration (`docker-compose.yml`)

```yaml
version: '3.8'

networks:
  cloudnative_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/16

services:
  gateway:
    image: haproxy:2.8-alpine
    container_name: lab_gateway
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    networks:
      cloudnative_net:
        ipv4_address: 172.30.0.10

  order_service:
    build:
      context: ./order_service
    container_name: lab_order_service
    restart: unless-stopped
    environment:
      AMQP_URL: "amqp://admin:CloudNative2026!@message_broker:5672/"
    depends_on:
      message_broker:
        condition: service_healthy
    networks:
      cloudnative_net:
        ipv4_address: 172.30.0.20

  message_broker:
    image: rabbitmq:3.12-management-alpine
    container_name: lab_message_broker
    restart: unless-stopped
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: CloudNative2026!
    ports:
      - "5672:5672"
      - "15672:15672"
    networks:
      cloudnative_net:
        ipv4_address: 172.30.0.30
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "check_running"]
      interval: 10s
      timeout: 5s
      retries: 5

  payment_worker:
    build:
      context: ./payment_worker
    container_name: lab_payment_worker
    restart: unless-stopped
    environment:
      AMQP_URL: "amqp://admin:CloudNative2026!@message_broker:5672/"
      REDIS_URL: "redis://:CacheSecure2026!@state_cache:6379/0"
    depends_on:
      message_broker:
        condition: service_healthy
      state_cache:
        condition: service_healthy
    networks:
      cloudnative_net:
        ipv4_address: 172.30.0.40

  state_cache:
    image: redis:7.2-alpine
    container_name: lab_state_cache
    restart: unless-stopped
    command: redis-server --requirepass CacheSecure2026!
    networks:
      cloudnative_net:
        ipv4_address: 172.30.0.50
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "CacheSecure2026!", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
```

### Order Ingestion Publisher (`order_service/app.py`)

```python
import os
import json
import pika
from flask import Flask, request, jsonify

app = Flask(__name__)

AMQP_URL = os.getenv("AMQP_URL", "amqp://admin:CloudNative2026!@localhost:5672/")

def publish_event(routing_key, payload):
    params = pika.URLParameters(AMQP_URL)
    connection = pika.BlockingConnection(params)
    channel = connection.channel()
    
    # Declare resilient topic exchange
    channel.exchange_declare(exchange='orders_exchange', exchange_type='topic', durable=True)
    
    channel.basic_publish(
        exchange='orders_exchange',
        routing_key=routing_key,
        body=json.dumps(payload),
        properties=pika.BasicProperties(
            delivery_mode=2,  # Persistent message on disk
            content_type='application/json'
        )
    )
    connection.close()

@app.route('/api/v1/orders', methods=['POST'])
def create_order():
    data = request.get_json()
    if not data or 'order_id' not in data:
        return jsonify({"error": "Invalid order payload"}), 400
    
    # Publish event asynchronously
    publish_event('order.created', data)
    
    return jsonify({
        "status": "Accepted",
        "message": "Order queued for processing",
        "order_id": data['order_id']
    }), 202

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Lab Verification Steps

1. **Spin up the decoupled microservice stack:**
   ```bash
   docker compose up -d --build
   ```
2. **Verify container health and network connectivity:**
   ```bash
   docker compose ps
   ```
3. **Dispatch a test order via the HAProxy endpoint:**
   ```bash
   curl -X POST http://localhost/api/v1/orders \
     -H "Content-Type: application/json" \
     -d '{"order_id": "ORD-2026-8891", "user_id": "USR-402", "amount": 249.99}'
   ```
4. **Confirm worker event processing in Redis:**
   ```bash
   docker exec -it lab_state_cache redis-cli -a CacheSecure2026! GET "order:ORD-2026-8891:status"
   ```
