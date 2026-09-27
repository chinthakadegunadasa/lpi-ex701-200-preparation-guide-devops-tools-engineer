# Chapter 2: Enterprise Cloud-Native Architecture & Microservices Implementation

## 2.1 Architectural Paradigms & System Deconstruction

### Monolithic vs. Microservices vs. Serverless Architectural Paradigms

![Architectural Evolution Paradigms](assets/images/chapter2/2-1-Architectural-Evolution-Paradigms.png)

#### Enterprise Trade-Off Matrix

![Architectural Paradigms Matrix](assets/images/chapter2/2-1-Architectural-Paradigms-Matrix.png)

## 2.2 Enterprise Inter-Service Communication

### API Design: REST, GraphQL, and gRPC Protocols

![API Protocol Interaction Patterns](assets/images/chapter2/2-2-API-Protocol-Interaction-Patterns.png)

## 2.3 Event-Driven Messaging Infrastructure

### Message Queuing Systems & Dead-Letter Processing

![Event Routing and DLX Processing Workflow](assets/images/chapter2/2-3-Event-Routing-and-DLX-Processing-Workflow.png)

## 2.4 Resiliency Architecture Patterns

### Circuit Breaker Pattern State Transitions

![Circuit Breaker State Machine Topology](assets/images/chapter2/2-4-Circuit-Breaker-State-Machine-Topology.png)

## 2.5 Enterprise Implementation Lab: Decoupled Order System

![Hands-On Decoupled Lab Infrastructure](assets/images/chapter2/2-5-Hands-On-Decoupled-Lab-Infrastructure.png)

### Hands-On Lab Instructions

#### 1. Deployment Specification (`docker-compose.yml`)

```yaml
version: '3.8'

services:
  edge-gateway:
    image: nginx:1.25-alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - ingestion-service

  rabbitmq:
    image: rabbitmq:3.12-management-alpine
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: enterprise_user
      RABBITMQ_DEFAULT_PASS: SecurePass123!

  redis-cache:
    image: redis:7.2-alpine
    ports:
      - "6379:6379"
    command: redis-server --requirepass RedisSecurePass123! --appendonly yes

  ingestion-service:
    build:
      context: ./ingestion
    environment:
      PORT: 8080
      AMQP_URL: amqp://enterprise_user:SecurePass123!@rabbitmq:5672/
    depends_on:
      - rabbitmq

  worker-service:
    build:
      context: ./worker
    environment:
      AMQP_URL: amqp://enterprise_user:SecurePass123!@rabbitmq:5672/
      REDIS_URL: redis://:RedisSecurePass123!@redis-cache:6379
    depends_on:
      - rabbitmq
      - redis-cache
```

#### 2. NGINX Gateway Configuration (`nginx.conf`)

```nginx
events { worker_connections 1024; }

http {
    upstream ingestion_cluster {
        server ingestion-service:8080 max_fails=3 fail_timeout=10s;
    }

    server {
        listen 80;

        location /api/v1/orders {
            proxy_pass http://ingestion_cluster;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 5s;
            proxy_read_timeout 10s;
        }
    }
}
```

#### 3. Execution Verification & Testing Commands

```bash
# 1. Provision environment
docker-compose up -d --build

# 2. Check cluster readiness
docker-compose ps

# 3. Simulate high-volume order ingestion
curl -X POST http://localhost/api/v1/orders \

# 4. Verify message queue delivery and consumption
docker exec -it $(docker-compose ps -q rabbitmq) rabbitmqctl list_queues

# 5. Query Redis persistent state store
docker exec -it $(docker-compose ps -q redis-cache) redis-cli -a RedisSecurePass123! GET "order:ORD-9921"
```
