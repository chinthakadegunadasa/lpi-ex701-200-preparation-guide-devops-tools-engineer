# Enterprise Reverse Proxy and WAF Infrastructure

## System Architecture Overview

This document provides a detailed text-based transcription of the Enterprise Reverse Proxy and Web Application Firewall (WAF) Infrastructure diagram for instructional and reference purposes.

---

## 1. Encrypted Web Clients
- **Component**: Client Devices (Laptops/Workstations)
- **Connections & Protocols**:
  - `HTTPS (TLS)` -> **HAProxy Tier**
    - Endpoints:
      - `GET /api/v1/orders`
      - `GET /dashboard`

---

## 2. HAProxy Tier: High-Throughput TLS Offloading

### Configuration & Details
```haproxy
global
    tune.ssl.default-dh-param 2048

frontend https-in
    bind *:443 ssl crt /etc/ssl/cert.pem
    default_backend nginx-waf-pool
```

### Inter-Service Communication
- **To NGINX WAF Tier**:
  - Protocols: `HTTPS / gRPC`, `HTTP/1.1`
- **To/From AMQP Message Box**:
  - Label: `AMQP messages [events]`
  - Data Payload: `[telemetry.haproxy: {load: 65%}]`

---

## 3. AMQP Message Component
- **Component Name**: `AMQP message`
- **Status**: `status: OK`
- **Connected To**:
  - HAProxy Tier (Bi-directional telemetry and event streaming)
  - NGINX WAF Tier / SAST Integration (Incoming `AMQP messages [events]`)

---

## 4. NGINX WAF Tier: ModSecurity Inspection

### Configuration & Rules
```nginx
http {
    upstream backend-main {
        server ...
    }

    location /api/ {
        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec_rules.conf;
        proxy_pass http://backend_pool_api;
        http://backend_pool_api;
        rule 942100
        rule 942100
        ...
    }
}
```

### Sub-components & Reporting
- **Violation Reports Block**: `reports: ModSec_violation.json`
- **SAST & Telemetry Block**: 
  - `SAST Reports [telemetry, violations]`
  - Linked to Database: `polyglot database: redis` (`db_status=READ_WRITE`)
  - Sends `AMQP messages [events]` to the central AMQP component.

---

## 5. Backend Microservice Pools (Active Health Probing)

### A. Order Service Pool
- **Service Identifier**: `order_svc:v1.0`
- **Port**: `listen 8080`
- **Description**: Processes order requests
- **Inbound Connection**: `Inspected and HTTP Traffic`
- **Health Check**:
  - Probe: `HTTP/1.1 active health probe: /healthz`
  - Status: `status: OK`
- **Processing Logic**:
  ```text
  fn_process:
    if retry > 3 {
      ERROR: DLQ
    }
  ```
- **Database**: `order_db: pgsql`

---

### B. Dashboard Service Pool
- **Service Identifier**: `dash_svc:v1.0`
- **Port**: `listen 8080`
- **Description**: Serves real-time data
- **Health Check**:
  - Probe: `active health probe: /healthz`
  - Protocol: `HTTP/1.1`
  - Status: `status: OK`
- **Processing Logic**:
  ```text
  fn_process:
    if v > 80% {
      ERROR: REJECT
    }
  ```
- **Database**: `Dashboard Database`

---

### C. Authentication Service Pool
- **Service Identifier**: `auth_svc:v3.1`
- **Port**: `listen 8080`
- **Description**: Handles user tokens
- **Inbound Connection**: `Inspected and Cleaned HTTP Traffic` (`HTTP/1.1`)
- **Database**: `polyglot database: redis`
