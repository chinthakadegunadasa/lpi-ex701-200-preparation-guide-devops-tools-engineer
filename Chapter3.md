# Chapter 3: Modern Software Development (Microservices, REST, & Session Handling)

## Table of Contents

* Introduction
* Microservices Architecture
* Common API Concepts and Standards: REST and JSON
* Data Storage, Service Status, and Session Handling in Cloud Applications
* Guided Exercises
* Explorational Exercises
* Summary
* Answers to Guided Exercises
* Answers to Explorational Exercises

---

## Introduction

As cloud platforms matured, enterprise systems transitioned from centralized monoliths to distributed **Microservices Architectures**. Modern cloud applications break complex domain logic into independent, fine-grained services that communicate via lightweight network protocols.

However, running software as a set of distributed web services introduces structural challenges:

1. Network boundaries replace fast, in-memory function calls.


2. Services must use standardized, platform-agnostic communication interfaces like **REST** and **JSON**.


3. Traditional monolithic techniques—such as storing session state in server memory—fail when scaling workloads across multiple instances.



This chapter examines the design of microservices, explores API standards using REST and JSON, and demonstrates patterns for managing state and sessions in cloud applications.

---

## Microservices Architecture

Microservices architecture decomposes a software application into small, independent services centered around specific business capabilities. Each microservice runs in its own process, owns its data, and can be developed, tested, deployed, and scaled independently.

```
+-----------------------------------------------------------------------+
|                      MICROSERVICES ARCHITECTURE                       |
+-----------------------------------------------------------------------+
|                                                                       |
|                         [ API Gateway / Router ]                      |
|                                   |                                   |
|          +------------------------+------------------------+          |
|          |                        |                        |          |
|          v                        v                        v          |
|  +---------------+        +---------------+        +---------------+  |
|  | User Service  |        | Order Service |        | Billing Svc   |  |
|  +---------------+        +---------------+        +---------------+  |
|          |                        |                        |          |
|          v                        v                        v          |
|  [( User DB )]            [( Order DB )]           [( Billing DB )]   |
+-----------------------------------------------------------------------+

```

### Core Characteristics of Microservices

* **Single Responsibility Principle (SRP):** Each service handles one bounded context (e.g., identity management, product catalog, payment processing).
* **Decentralized Data Management:** Services own their database schemas ("Database-per-Service" pattern). Direct database access across microservice boundaries is forbidden.
* **Failure Isolation:** An outage in one microservice (e.g., product reviews) does not crash critical operations (e.g., checkout).
* **Polyglot Engineering:** Teams can build individual services using different programming languages, runtime frameworks, and storage technologies based on requirement suitability.

### Microservices vs. Monolithic Architecture

| Architectural Trait | Monolithic Architecture | Microservices Architecture |
| --- | --- | --- |
| **Codebase Boundary** | Single, unified repository and build artifact

 | Multiple independent repositories and pipelines |
| **Deployment Model** | All-or-nothing release strategy | Independent releases per service |
| **Scalability** | Scale up overall instance resources | Scale out high-demand services horizontally |
| **Communication** | In-memory function/method calls | Remote procedure calls, HTTP REST, or message queues |
| **Data Consistency** | ACID transactions across schemas | Eventual consistency via Saga transactions |

---

## Common API Concepts and Standards: REST and JSON

To interact across network boundaries, microservices rely on standardized Application Programming Interfaces (APIs). The most widespread pattern in modern web platforms is **REST (Representational State Transfer)** using **JSON (JavaScript Object Notation)** for payload serialization.

### Key Principles of RESTful Interfaces

REST is an architectural style that exposes system resources via uniform resource identifiers (URIs) and standard HTTP methods:

* **Resource Identification:** Resources represent domain objects and are identified via nouns in standard URI patterns (e.g., `/api/v1/users`, `/api/v1/orders/108`).
* **Stateless Communication:** Every API request must contain all contextual information required to fulfill it. The server stores no client context between requests.
* **Standard HTTP Verbs:**
* `GET`: Retrieve resource data without modifying server state (Safe & Idempotent).
* `POST`: Create a new server resource (Unsafe & Non-idempotent).
* `PUT`: Replace an existing resource entirely or create it if missing (Idempotent).
* `PATCH`: Apply partial modifications to a resource (Unsafe).
* `DELETE`: Remove a designated resource (Idempotent).


* **Standard HTTP Status Codes:**
* `200 OK` / `201 Created`: Request succeeded.
* `400 Bad Request`: Validation failure or malformed JSON payload.
* `401 Unauthorized`: Authentication credentials missing or invalid.
* `403 Forbidden`: Authenticated caller lacks execution permissions.
* `404 Not Found`: Requested URI or resource entity does not exist.
* `500 Internal Server Error`: Unhandled application exception.



### JSON Payload Standard

JSON is a text-based, human-readable data format used to serialize structured data across endpoints:

```json
{
  "orderId": "ord-88392",
  "customerId": "usr-40192",
  "status": "PROCESSING",
  "items": [
    {
      "sku": "HW-SVR-01",
      "quantity": 2,
      "price": 1250.00
    }
  ],
  "totalAmount": 2500.00
}

```

---

## Data Storage, Service Status, and Session Handling in Cloud Applications

Scaling stateless microservices horizontally requires specific patterns for managing state, tracking health status, and handling user sessions.

```
+-----------------------------------------------------------------------+
|                 STATELESS SESSION MANAGEMENT VIA REDIS                |
+-----------------------------------------------------------------------+
|                                                                       |
|   Client Request (Bearer JWT / Session ID)                            |
|          |                                                            |
|          v                                                            |
|   +-------------------+                                               |
|   |   Load Balancer   |                                               |
|   +-------------------+                                               |
|          |                                                            |
|          +--------------------+--------------------+                  |
|          |                    |                    |                  |
|          v                    v                    v                  |
|   +--------------+     +--------------+     +--------------+          |
|   | App Node #1  |     | App Node #2  |     | App Node #3  |          |
|   +--------------+     +--------------+     +--------------+          |
|          |                    |                    |                  |
|          +--------------------+--------------------+                  |
|                               |                                       |
|                               v                                       |
|                     +--------------------+                            |
|                     | Redis Session Store| (Shared Backing Service)   |
|                     +--------------------+                            |
+-----------------------------------------------------------------------+

```

### Stateless vs. Stateful Applications

* **Stateful Services:** Store client interaction state directly in local memory or on local disk (e.g., web server RAM sessions). This binds users to a specific server instance (sticky sessions) and prevents automated scaling or rolling restarts.
* **Stateless Services:** Store no client state locally. Any instance can process any incoming request by looking up state in shared backing services (e.g., Redis, PostgreSQL) or reading cryptographically signed client tokens.

### Externalizing Session State

To achieve high availability, user sessions must be managed outside application containers:

1. **Centralized Caching (Redis/Memcached):** Server-side sessions are saved to an external, high-speed, key-value datastore accessible by all application nodes.
2. **Stateless JSON Web Tokens (JWT):** The client stores a signed, encrypted token containing authentication context and claims. The client passes this token in the HTTP `Authorization: Bearer <token>` header with every request, eliminating the need for server-side lookup calls.

### Health Probes and Status Checks

Orchestrators require visibility into service readiness and internal health to route network traffic effectively:

* **Status Probes:** HTTP API endpoints (e.g., `/healthz`, `/metrics`) exposed by microservices to output telemetry, operational state, and subsystem connectivity status.

---

## Guided Exercises

### Exercise 3.1: Building a Stateless Microservice with REST and Session Tokens

**Scenario:** Build a lightweight, stateless Python microservice using Flask that validates user requests via JWT bearer tokens and exposes standard health status probes.

**Step-by-Step Execution:**

1. Create a workspace directory and set up a virtual environment:

```bash
mkdir microservice-rest && cd microservice-rest
python3 -m venv venv
source venv/bin/activate
pip install flask pyjwt

```

2. Create an application file `server.py`:

```python
import os
import time
import jwt
from flask import Flask, request, jsonify

app = Flask(__name__)

# Secret key used for signing JWT tokens (Read from environment config)
SECRET_KEY = os.getenv("JWT_SECRET", "super-secret-enterprise-key")

@app.route("/api/v1/login", methods=["POST"])
def login():
    """Generates a stateless JWT token for valid credentials."""
    data = request.get_json() or {}
    username = data.get("username")
    password = data.get("password")

    if username == "admin" and password == "secret":
        payload = {
            "sub": username,
            "role": "administrator",
            "iat": int(time.time()),
            "exp": int(time.time()) + 3600  # Token valid for 1 hour
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
        return jsonify({"access_token": token, "token_type": "Bearer"}), 200
    
    return jsonify({"error": "Invalid credentials"}), 401

@app.route("/api/v1/orders", methods=["GET"])
def get_orders():
    """Protected endpoint validating stateless JWT session bearer token."""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": "Missing or invalid authorization header"}), 401
    
    token = auth_header.split(" ")[1]
    try:
        decoded = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return jsonify({
            "status": "success",
            "requested_by": decoded["sub"],
            "data": [
                {"order_id": 101, "item": "Cloud Server Node", "price": 450.00},
                {"order_id": 102, "item": "Container Storage Volume", "price": 80.00}
            ]
        }), 200
    except jwt.ExpiredSignatureError:
        return jsonify({"error": "Token has expired"}), 401
    except jwt.InvalidTokenError:
        return jsonify({"error": "Invalid token"}), 401

@app.route("/healthz", methods=["GET"])
def health_check():
    """Liveness probe reporting microservice status."""
    return jsonify({
        "status": "UP",
        "timestamp": int(time.time()),
        "service": "order-management-v1"
    }), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

```

3. Launch the REST microservice:

```bash
python3 server.py &

```

4. Verify health status probe output:

```bash
curl -i http://127.0.0.1:5000/healthz

```

5. Authenticate and retrieve a signed JWT access token:

```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:5000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"secret"}' | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')

echo "Generated JWT Token: $TOKEN"

```

6. Access the protected API resource using the stateless bearer token:

```bash
curl -i -H "Authorization: Bearer $TOKEN" http://127.0.0.1:5000/api/v1/orders

```

---

### Exercise 3.2: Inspecting Redis Externalized Session State

**Scenario:** Use Docker to launch a Redis session store and query externalized session state using `redis-cli`.

**Step-by-Step Execution:**

1. Launch a temporary Redis backing container:

```bash
docker run -d --name session-store -p 6379:6379 redis:alpine

```

2. Store a session object simulating externalized session management:

```bash
docker exec -it session-store redis-cli SET "session:usr-8812" "{\"user_id\":\"usr-8812\",\"role\":\"editor\",\"logged_in\":true}" EX 1800

```

3. Fetch session data and verify time-to-live (TTL) expiration settings:

```bash
docker exec -it session-store redis-cli GET "session:usr-8812"
docker exec -it session-store redis-cli TTL "session:usr-8812"

```

4. Stop and remove the testing container:

```bash
docker stop session-store && docker rm session-store

```

---

## Explorational Exercises

### Exercise 1: Designing an API Route for Partial Data Updates

Analyze the operational differences between HTTP `PUT` and `PATCH` requests when updating a complex JSON resource (such as a User Profile).

1. Draft a JSON schema representing a user profile with multiple sub-fields (Name, Contact Info, Address).
2. Write an example HTTP `PUT` body and an HTTP `PATCH` body targeting `/api/v1/users/402`.
3. Compare how the backend database handles each update pattern in terms of data integrity, validation, and idempotency.

### Exercise 2: Comparing JWT vs. Distributed Session Stores

Evaluate the trade-offs between using signed **JSON Web Tokens (JWT)** and a **Redis-backed session store** for microservices authentication. Build a comparative analysis focusing on:

* **Revocation Speed:** How quickly can a compromised session be invalidated?
* **Network Overhead:** Payload size variations in request headers.
* **Database IO Load:** Scalability impact on shared backing storage during high traffic spikes.

---

## Summary

* **Microservices Architecture** divides applications into fine-grained, loosely coupled services, each owning its independent business context and data storage.


* **REST** and **JSON** serve as standard protocols for service-to-service and client-to-service API communication over HTTP.


* **Stateless Design** is necessary for scaling cloud applications horizontally. Storing session data directly on web server instances causes scaling bottlenecks.


* Sessions can be managed statelessly across horizontal application instances using **externalized datastores (such as Redis)** or **cryptographically signed tokens (JWT)**.



---

## Answers to Guided Exercises

### Answer to Exercise 3.1

The Python Flask service demonstrates stateless REST principles:

* **Stateless Authentication:** The microservice validates incoming requests by parsing the cryptographically signed `Bearer` token in the `Authorization` header, requiring no database lookup or local session storage.


* **Observability:** Exposing a `/healthz` probe allows orchestrators to evaluate service health before routing incoming traffic.

### Answer to Exercise 3.2

The Redis commands demonstrate externalized session management:

* Using `SET key value EX seconds` sets session attributes alongside an explicit expiration TTL.
* Decoupling session storage from the application container allows instances to be terminated, scaled, or replaced without dropping user sessions.

---

## Answers to Explorational Exercises

### Sample Answer to Exercise 1: PUT vs. PATCH Update Behaviors

1. **HTTP PUT (Full Replacement):** Requires sending the complete updated resource payload. Missing fields are typically overwritten as `null` or reset to default values in the backend storage.
2. **HTTP PATCH (Partial Update):** Accepts only the modified attributes (e.g., updating `phone_number` while leaving `address` untouched), reducing network payload size and avoiding accidental data loss on unsubmitted fields.

### Sample Answer to Exercise 2: JWT vs. Redis Session Store Comparison

* **Session Revocation:** Redis allows immediate session invalidation by deleting keys directly from the cache. Standard JWTs cannot be revoked instantly without maintaining a secondary revocation blacklist, as validation relies entirely on cryptographic signature checks until the token expires.
* **Network Overhead:** Redis sessions pass a small key string (e.g., 32-character session ID), minimizing request header sizes. JWT payloads contain claims and signatures, generating larger header strings.
* **Database/Cache IO:** JWT validation requires no database IO calls, reducing server-side lookup latency. Redis session lookups perform a fast network read on every API call, requiring a scalable cache cluster to handle high traffic volumes.
