Here is the complete, enterprise-grade, hands-on **Chapter 7** for the LPIC-3 701-200 certification guide, fully formatted in Markdown and tailored for print-ready compilation.

---

# Chapter 7: Service Discovery & Dynamic Routing

In traditional static IT infrastructure, networking was straightforward: IP addresses were fixed, server names were permanent, and load balancers were reconfigured manually or through basic configuration management scripts whenever a node was replaced.

In a modern, highly dynamic cloud-native ecosystem, this static model falls apart. Container orchestrators, autoscaling groups, and microservice architectures cause workloads to spin up, migrate, and terminate continuously across heterogeneous clusters. Hardcoding IP addresses or relying on static DNS records leads to operational friction, service outages, and heavy maintenance overhead.

To manage this fluidity, enterprise architectures depend on two core capabilities: **Service Discovery** and **Dynamic Routing**. This chapter explores the mechanics of distributed service catalogs, multi-datacenter Consensus protocols, auto-configuring reverse proxies, dynamic health checking, and end-to-end traffic rerouting.

---

## 7.1 Principles of Service Discovery in Distributed Systems

At its core, **Service Discovery** acts as an automated, central directory of all active network services and their network locations (IP address and port). Rather than hardcoding connections between microservices, applications query a Service Discovery engine to locate upstream dependencies at runtime.

```
+-----------------------------------------------------------------------------------+
|                        SERVICE DISCOVERY ARCHITECTURE                             |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  +--------------------+        1. Register (Health: OK)     +------------------+  |
|  | Microservice A     |------------------------------------>| Service Catalog  |  |
|  | IP: 10.0.1.5:8080  |                                     | (Consul/Etcd/    |  |
|  +--------------------+                                     |  ZooKeeper)      |  |
|                                                             +------------------+  |
|  +--------------------+        2. Discover / Watch                   ^        |  |
|  | Dynamic Proxy      |<---------------------------------------------+        |  |
|  | (Traefik/Envoy)    |                                                       |  |
|  +--------------------+                                                       |  |
|            |                                                                      |  |
|            +----------------- 3. Route Traffic ------------------+            |  |
|                                                                  v            |  |
|                                                       +--------------------+  |
|                                                       | Microservice A     |  |
|                                                       | IP: 10.0.1.5:8080  |  |
|                                                       +--------------------+  |
+-----------------------------------------------------------------------------------+

```

> **DALL-E 3 Image Generation Prompt:**
> *A clean, high-resolution, light-mode architectural diagram illustrating Service Discovery principles on a crisp off-white background (#FAFAFA). The visual features three primary components: a Service Catalog database at the top, a Dynamic Proxy on the left, and a Microservice instance on the right. Dark slate (#2B2D42) structural boxes contain clear labels. Clean teal (#008080) directional arrows trace three distinct workflows: (1) Registration from Microservice to Catalog, (2) Watch/Discovery stream from Catalog to Dynamic Proxy, and (3) Dynamic Traffic Routing from Proxy to Microservice. All text labels use clean sans-serif typography (Google Sans Flex 12Pt style), and code snippets inside boxes use clear monospaced typography (Google Sans Code 12Pt style). Do not display font names in images. Minimalist, professional technical blueprint design.*

### Client-Side vs. Server-Side Discovery

Service discovery architectures generally fall into two primary patterns: **Client-Side Discovery** and **Server-Side Discovery**.

| Dimension | Client-Side Discovery | Server-Side Discovery |
| --- | --- | --- |
| **Discovery Mechanism** | The client queries the service registry directly to get an instance endpoint, then picks a node using an internal load-balancing algorithm. | The client sends a request to a proxy/router (e.g., AWS ALB, Traefik). The router queries the registry and forwards the request. |
| **Network Hops** | **1 Hop:** Client connects directly to the target instance. | **2 Hops:** Client connects to Proxy, Proxy connects to target instance. |
| **Client Overhead** | **High:** Every client language/framework must implement discovery logic, health checking awareness, and load-balancing algorithms. | **Low:** Clients remain simple and lightweight; they only need standard HTTP/gRPC libraries to hit the central proxy. |
| **Coupling** | High coupling between client implementation and service registry platform. | Decoupled; infrastructure handles routing transparently. |
| **Typical Tools** | Netflix Eureka, Finagle, custom SDKs. | Traefik, NGINX Plus, Envoy, Kubernetes Services, Consul Fabric. |

### Architecture Comparison: Consul vs. etcd vs. ZooKeeper

Distributed systems require a strongly consistent state store to avoid routing traffic to non-existent or unhealthy nodes. The primary tools in this space trade off simplicity, consistency, and feature breadth:

| Feature / Metric | HashiCorp Consul | CoreOS etcd | Apache ZooKeeper |
| --- | --- | --- | --- |
| **Primary Design Goal** | Native Service Mesh & Service Discovery | Distributed Key-Value Store for Configuration & State | Distributed Coordination for Large Systems |
| **Consensus Algorithm** | Raft | Raft | Zab (ZooKeeper Atomic Broadcast) |
| **Built-in Health Checking** | **Native:** Supports HTTP, TCP, gRPC, and custom script checks natively out of the box. | **None:** Requires external operators/sidecars to update keys upon health failure. | **None:** Relies on ephemeral nodes and active client heartbeats (leases). |
| **Multi-Datacenter Support** | **Native:** Built-in WAN gossip pools and cross-datacenter federation. | **Manual:** Requires separate clusters or complex overlay setups. | **Complex:** High latency overhead across WAN links; typically single-DC. |
| **KV Store Capability** | Rich hierarchical KV store with ACLs and long-polling support. | High-performance gRPC/v3 API KV store with lease capabilities. | Hierarchical znodes with watcher interfaces. |
| **Interface Protocols** | HTTP REST, DNS, gRPC, CLI. | gRPC, HTTP REST (via proxy). | Native Java/C Client Libraries, CLI. |

---

## 7.2 HashiCorp Consul Cluster Deployment and Service Registration

HashiCorp Consul uses a **Raft consensus protocol** for state replication among server nodes, alongside the **SWIM (Structured Weakness-Oriented with Infection-Style Process Group Membership Protocol) Gossip protocol** for node discovery, cluster health status, and event broadcast.

```
+-----------------------------------------------------------------------------------+
|                        CONSUL MULTI-DATACENTER ARCHITECTURE                       |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|    DATACENTER 1 (dc1) - LAN Gossip Pool                                           |
|    +-------------------------------------------------------------------------+    |
|    |                                                                         |    |
|    |   +------------------+    Raft Replication    +------------------+      |    |
|    |   | Consul Server 1  |<======================>| Consul Server 2  |      |    |
|    |   | (Leader)         |                        | (Follower)       |      |    |
|    |   +------------------+                        +------------------+      |    |
|    |            ^                                            ^               |    |
|    |            | LAN Gossip                                 | LAN Gossip    |    |
|    |            v                                            v               |    |
|    |   +------------------+                        +------------------+      |    |
|    |   | Consul Agent 1   |                        | Consul Agent 2   |      |    |
|    |   | (Client Node)    |                        | (Client Node)    |      |    |
|    |   +------------------+                        +------------------+      |    |
|    +-------------------------------------------------------------------------+    |
|                                     ||                                            |
|                                     || WAN Gossip Pool                            |
|                                     || (Cross-DC Federation)                      |
|                                     vv                                            |
|    DATACENTER 2 (dc2) - LAN Gossip Pool                                           |
|    +-------------------------------------------------------------------------+    |
|    |   +-----------------------------------------------------------------+   |    |
|    |   | Consul Server Cluster (dc2)                                     |   |    |
|    |   +-----------------------------------------------------------------+   |    |
|    +-------------------------------------------------------------------------+    |
+-----------------------------------------------------------------------------------+

```

> **DALL-E 3 Image Generation Prompt:**
> *An enterprise architectural diagram illustrating a Multi-Datacenter HashiCorp Consul Topology on a light grey background (#F8F9FA). The top section shows "Datacenter 1 (dc1)" containing two Consul Servers interlinked via a double line labeled "Raft Replication", and two Consul Client Agents connected via subtle mesh lines labeled "LAN Gossip Pool". The bottom section shows "Datacenter 2 (dc2)". A prominent bidirectional thick arrow labeled "WAN Gossip Pool (Cross-DC Federation)" links the two datacenters. All boxes have thin navy outlines (#1E293B) and clean white fill. All standard text is styled in Google Sans Flex 12Pt and all embedded code/command elements are styled in Google Sans Code 12Pt. Do not display font names in images. Clear, high-contrast, publication-quality technical illustration.*

### Production Multi-Node Consul Server Configuration

Deploying a resilient Consul cluster requires an odd number of server nodes (typically 3 or 5) to maintain a Raft quorum during network partitions or node failures.

Below is an enterprise-grade HCL configuration for a Consul Server node (`/etc/consul.d/consul.hcl`):

```hcl
# /etc/consul.d/consul.hcl
datacenter = "dc1"
data_dir   = "/var/lib/consul"
log_level  = "INFO"
node_name  = "consul-server-01"

# Network Binding Configuration
bind_addr   = "10.0.10.11"
client_addr = "0.0.0.0"

# Server Role and Clustering
server           = true
bootstrap_expect = 3
retry_join       = ["10.0.10.11", "10.0.10.12", "10.0.10.13"]

# UI Configuration
ui_config {
  enabled = true
}

# Performance Tuning for Production
performance {
  raft_multiplier = 1
}

# Connect Service Mesh Enforcement
connect {
  enabled = true
}

# Security and ACL Configuration
acl = {
  enabled                  = true
  default_policy           = "deny"
  enable_token_persistence = true
  down_policy              = "extend-cache"
}

# Encrypted Communications
encrypt = "s3cr3tG0ss1pK3yRequir3d="

tls {
  defaults {
    ca_file   = "/etc/consul.d/certs/consul-ca.pem"
    cert_file = "/etc/consul.d/certs/dc1-server-consul-0.pem"
    key_file  = "/etc/consul.d/certs/dc1-server-consul-0-key.pem"

    verify_incoming = true
    verify_outgoing = true
  }
}

```

To initialize and launch the Consul systemd unit across nodes:

```bash
# Verify permissions on configuration files
sudo chown -R consul:consul /etc/consul.d /var/lib/consul
sudo chmod 640 /etc/consul.d/consul.hcl

# Enable and start Consul service
sudo systemctl daemon-reload
sudo systemctl enable --now consul

# Bootstrap the ACL system (run once on the primary server)
consul acl bootstrap

```

### Static Service Registration via JSON Configuration

Services can be registered statically using JSON or HCL definition files placed inside Consul's configuration directory (`/etc/consul.d/`).

File: `/etc/consul.d/payment-service.json`

```json
{
  "service": {
    "id": "payment-service-prod-01",
    "name": "payment-service",
    "tags": [
      "primary",
      "v2.1.0",
      "traefik.enable=true",
      "traefik.http.routers.payment.rule=Host(`payment.internal.net`)"
    ],
    "address": "10.0.20.45",
    "port": 8080,
    "meta": {
      "environment": "production",
      "owner": "finance-engineering"
    },
    "checks": [
      {
        "id": "payment-api-health",
        "name": "Payment API HTTP Health Check",
        "http": "http://10.0.20.45:8080/health",
        "tls_skip_verify": false,
        "method": "GET",
        "interval": "10s",
        "timeout": "2s",
        "deregister_critical_service_after": "1m"
      }
    ]
  }
}

```

Reload the Consul agent to apply the configuration without downtime:

```bash
consul reload

```

### Dynamic Service Registration via Consul HTTP REST API

Applications can programmatically register themselves into Consul at startup using its REST API.

```bash
curl --request PUT \
  --url http://127.0.0.1:8500/v1/agent/service/register \
  --header 'Content-Type: application/json' \
  --header 'X-Consul-Token: <YOUR_ACL_AGENT_TOKEN>' \
  --data '{
    "Name": "order-fulfillment",
    "ID": "order-fulfillment-node-03",
    "Tags": ["shipping", "v1.4.2"],
    "Address": "10.0.20.88",
    "Port": 9090,
    "Check": {
      "HTTP": "http://10.0.20.88:9090/healthz",
      "Interval": "5s",
      "Timeout": "1s"
    }
  }'

```

### Querying the Service Catalog via API and DNS Interfaces

Consul exposes both REST and DNS interfaces to query service addresses.

#### Querying via HTTP API

```bash
# Query all healthy instances of payment-service
curl -s http://127.0.0.1:8500/v1/health/service/payment-service?passing=true | jq .

```

#### Querying via DNS Interface

Consul runs an embedded DNS server on port `8600` (by default).

```bash
# Standard A record query
dig @127.0.0.1 -p 8600 payment-service.service.consul A +short

# Service Record (SRV) query to resolve both IP and Port
dig @127.0.0.1 -p 8600 payment-service.service.consul SRV

```

Sample output:

```
; <<>> DiG 9.18.28-1~deb12u2-Debian <<>> @127.0.0.1 -p 8600 payment-service.service.consul SRV
;; ANSWER SECTION:
payment-service.service.consul. 0 IN SRV 1 1 8080 0a00142d.addr.dc1.consul.

;; ADDITIONAL SECTION:
0a00142d.addr.dc1.consul. 0 IN	A	10.0.20.45

```

---

## 7.3 Dynamic Reverse Proxying with Traefik and NGINX

While Consul acts as the system of record for service locations, external traffic and service-to-service requests require a reverse proxy to dynamically discover backend targets and balance traffic across them.

### Traefik Dynamic Ingress Architecture

Traefik is a modern edge router designed specifically to bind directly to service registries like Consul, Kubernetes, or Docker. It dynamically generates and updates its routing table in memory without requiring service restarts or configuration reloads.

```
+-----------------------------------------------------------------------------------+
|                        TRAEFIK DYNAMIC ROUTING MECHANISM                          |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  [ Incoming Client Request ]                                                      |
|               |                                                                   |
|               v                                                                   |
|    +---------------------+                                                        |
|    | EntryPoint (:80/:443)|                                                       |
|    +---------------------+                                                        |
|               |                                                                   |
|               v                                                                   |
|    +---------------------+    Consul Catalog Provider                             |
|    | Router              |<==============================+                        |
|    | (Evaluates Rules)   |  (Watches KV/Catalog Updates) |                        |
|    +---------------------+                               |                        |
|               |                                          |                        |
|               v                                  +---------------+                |
|    +---------------------+                       | HashiCorp     |                |
|    | Middlewares         |                       | Consul        |                |
|    | (Auth, Rate Limit)  |                       +---------------+                |
|    +---------------------+                                                        |
|               |                                                                   |
|               v                                                                   |
|    +---------------------+                                                        |
|    | Service             |                                                        |
|    | (Load Balancer)     |                                                        |
|    +---------------------+                                                        |
|               |                                                                   |
|        +------+------+                                                            |
|        |             |                                                            |
|        v             v                                                            |
|    Backend 1     Backend 2                                                        |
|    (Instance A)  (Instance B)                                                     |
+-----------------------------------------------------------------------------------+

```

> **DALL-E 3 Image Generation Prompt:**
> *A light-mode software pipeline diagram showing Traefik's internal routing flow on a clean light grey background (#F3F4F6). A top box titled "EntryPoint (:80/:443)" passes requests downward through "Router", "Middlewares", and "Service (Load Balancer)" to two bottom endpoints labeled "Backend 1" and "Backend 2". A separate block on the right labeled "HashiCorp Consul" streams updates into the "Router" via a dashed arrow marked "Consul Catalog Provider". Use cool blue hues (#0284C7) for routers and emerald green (#059669) for backends. Text formatting mimics Google Sans Flex 12Pt for labels and Google Sans Code 12Pt for code snippets/ports. Do not display font names in images. Crisp technical detail without clutter.*

### Production Traefik v3 Static Configuration

File: `/etc/traefik/traefik.yml`

```yaml
global:
  checkNewVersion: false
  sendAnonymousUsage: false

log:
  level: INFO
  format: json

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  consulCatalog:
    refreshInterval: 15s
    prefix: "traefik"
    endpoint:
      address: "127.0.0.1:8500"
      scheme: "http"
      token: "YOUR_CONSUL_READ_TOKEN"
    exposedByDefault: false
    defaultRule: "Host(`{{ .Name }}.internal.domain`)"

api:
  dashboard: true
  insecure: false

accessLog:
  format: json

```

When Consul Catalog integration is enabled, Traefik watches Consul for services tagged with `traefik.enable=true`. Traefik automatically builds the dynamic routing rule directly from the service tags without requiring a proxy reload.

### Enterprise NGINX Dynamic Reconfiguration using `consul-template`

Traditional NGINX Open Source does not dynamically poll Consul APIs directly into memory. Instead, the enterprise standard pattern uses **`consul-template`**. This daemon queries Consul for changes and dynamically renders an NGINX configuration file (`/etc/nginx/conf.d/upstream.conf`), then executes a graceful reload (`nginx -s reload`).

```
+-----------------------------------------------------------------------------------+
|                     NGINX DYNAMIC UPDATES VIA CONSUL-TEMPLATE                     |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  +--------------------+       1. Watch Events       +--------------------+        |
|  | HashiCorp Consul   |---------------------------->| consul-template    |        |
|  | Catalog / KV       |                             | Daemon             |        |
|  +--------------------+                             +--------------------+        |
|                                                                |                  |
|                                                                | 2. Render Template|
|                                                                v                  |
|  +--------------------+       3. Exec Reload        +--------------------+        |
|  | NGINX Master       |<----------------------------| /etc/nginx/conf.d/ |        |
|  | Process            |  (systemctl reload nginx)   | dynamic.conf       |        |
|  +--------------------+                             +--------------------+        |
+-----------------------------------------------------------------------------------+

```

> **DALL-E 3 Image Generation Prompt:**
> *A structural workflow diagram depicting dynamic configuration rendering on a light background. "HashiCorp Consul" streams watch events to "consul-template Daemon". "consul-template" writes an updated configuration file to "/etc/nginx/conf.d/dynamic.conf" and issues a reload signal to the "NGINX Master Process". Dark indigo lines (#312E81) depict the flow. Clear typography using Google Sans Flex 12Pt for text and Google Sans Code 12Pt for file paths. Do not display font names in images. Minimalist, professional software engineering layout.*

#### 1. Define the Consul-Template File (`/etc/consul-template/templates/app.conf.ctmpl`)

```nginx
upstream backend_app {
  zone backend_app_mem 64k;
  {{ range service "payment-service@dc1" }}
  server {{ .Address }}:{{ .Port }} max_fails=3 fail_timeout=10s weight=1;
  {{ else }}
  # Fallback target if no instances are healthy
  server 127.0.0.1:8080 down;
  {{ end }}
  keepalive 32;
}

server {
    listen 80;
    server_name payment.company.internal;

    location / {
        proxy_pass http://backend_app;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

```

#### 2. Configure Consul-Template Daemon (`/etc/consul-template/config/consul-template.hcl`)

```hcl
consul {
  address = "127.0.0.1:8500"
  retry {
    enabled  = true
    attempts = 12
    backoff  = "250ms"
  }
}

template {
  source      = "/etc/consul-template/templates/app.conf.ctmpl"
  destination = "/etc/nginx/conf.d/payment_service.conf"
  perms       = 0644
  command     = "systemctl reload nginx"
  command_timeout = "30s"
}

```

#### 3. Run `consul-template` as a Managed Systemd Service

```ini
# /etc/systemd/system/consul-template.service
[Unit]
Description="Consul Template daemon for NGINX"
After=network.target consul.service nginx.service
Requires=consul.service nginx.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/consul-template -config=/etc/consul-template/config/consul-template.hcl
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target

```

---

## 7.4 Health Checking and Automated Traffic Rerouting

Service discovery is only as accurate as its health-checking mechanism. Routing traffic to an unverified instance causes request drop-offs and cascaded failures.

### Active vs. Passive Health Checks

```
+-----------------------------------------------------------------------------------+
|                        ACTIVE VS PASSIVE HEALTH CHECKING                          |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  ACTIVE CHECKING (Proactive Polling)                                              |
|  +--------------+          GET /healthz Check (Every 5s)      +---------------+   |
|  | Consul Agent |-------------------------------------------->| Microservice  |   |
|  | / Proxy      |<--------------------------------------------| Endpoint      |   |
|  +--------------+          HTTP 200 OK (Status: Healthy)      +---------------+   |
|                                                                                   |
|  PASSIVE CHECKING (In-Flight Monitoring)                                          |
|  +--------------+          1. Forward Client Request          +---------------+   |
|  | Dynamic      |-------------------------------------------->| Microservice  |   |
|  | Proxy        |<--------------------------------------------| Endpoint      |   |
|  +--------------+          2. Detect TCP Reset / HTTP 503     +---------------+   |
|         |                                                                         |   |
|         +--- 3. Mark Instance Unhealthy & Retry Upstream Instance ---------------|   |
+-----------------------------------------------------------------------------------+

```

> **DALL-E 3 Image Generation Prompt:**
> *A clean dual-panel light-mode graphic illustrating Active vs Passive health check patterns. The top section depicts "Active Checking" with a proxy polling a microservice with scheduled HTTP check probes. The bottom section depicts "Passive Checking" with a proxy intercepting real user requests, catching a 503 response, marking the instance degraded, and rerouting to a healthy alternative. Color accent in deep orange (#EA580C) for failure states and soft green (#16A34A) for success states. Fonts styled as Google Sans Flex 12Pt for labels and Google Sans Code 12Pt for endpoints/HTTP status codes. Do not display font names in images. Publication ready.*

#### Active Health Checks

* **Mechanism**: The registry or edge proxy proactively polls the backend target on a fixed interval (e.g., every 5 seconds) via HTTP, TCP, gRPC, or an Exec script.
* **Advantage**: Faults are detected before real users hit the failing node.
* **Disadvantage**: Introduces extra network traffic and resource overhead as cluster sizes scale up.

#### Passive Health Checks (Outlier Detection)

* **Mechanism**: The proxy observes live production traffic. If an instance returns sequential errors (e.g., three consecutive 5xx errors or TCP timeouts), the proxy temporarily ejects the instance from the load balancing pool.
* **Advantage**: Zero extra probe overhead; detects failures under real application loads.
* **Disadvantage**: At least one or more real user requests must fail before the unhealthy node is detected and isolated.

### Health Check Circuit State Machine

In Consul, every health check progresses through three primary states:

```
                  +--------------------------------+
                  |                                |
                  |            PASSING             |
                  |     (Healthy Node Traffic)     |
                  |                                |
                  +--------------------------------+
                     /                          ^
      Failure Threshold                         Success Threshold
        Exceeded                                   Satisfied
                   /                            \
                  v                              \
  +--------------------------------+   Interval   +--------------------------------+
  |                                |------------->|                                |
  |            CRITICAL            |              |            WARNING             |
  |   (Removed from Routing Pool)  |<-------------| (Monitored / Degraded State)   |
  +--------------------------------+   Failure    +--------------------------------+
                  |                                
                  | Deregister Critical
                  | Timeout Elapsed
                  v
  +--------------------------------+
  |    DEREGISTERED / EJECTED      |
  |     (Purged from Catalog)      |
  +--------------------------------+

```

> **DALL-E 3 Image Generation Prompt:**
> *A state machine diagram on a light neutral background detailing health states: PASSING (Green fill), WARNING (Amber fill), CRITICAL (Red fill), and DEREGISTERED (Gray fill). Directed arrows indicate transitions between states based on health probe thresholds. Text formatted cleanly using Google Sans Flex 12Pt for state titles and Google Sans Code 12Pt for parameters. Do not display font names in images. Elegant technical presentation.*

### Configuring Advanced Health Checks in Consul

Consul supports multiple probe types within a single service registration.

```json
{
  "service": {
    "name": "data-processor",
    "id": "data-processor-01",
    "address": "10.0.30.12",
    "port": 9000,
    "checks": [
      {
        "id": "tcp-connectivity",
        "name": "TCP Socket Check",
        "tcp": "10.0.30.12:9000",
        "interval": "5s",
        "timeout": "1s"
      },
      {
        "id": "http-app-health",
        "name": "Application Liveness Endpoint",
        "http": "http://10.0.30.12:9000/healthz",
        "method": "GET",
        "header": {"X-Health-Check": ["Consul"]},
        "interval": "10s",
        "timeout": "2s"
      },
      {
        "id": "disk-space-script",
        "name": "Local Storage Capacity Check",
        "args": ["/usr/local/bin/check_disk.sh", "-w", "80%", "-c", "90%"],
        "interval": "30s",
        "timeout": "5s"
      }
    ]
  }
}

```

---

## 7.5 Hands-On Lab: Integrating HashiCorp Consul with Traefik for Automatic Dynamic Routing

This hands-on lab walks through building an enterprise-grade automated service discovery pipeline. We will set up a Consul server and a Traefik edge reverse proxy, then launch multiple instances of an upstream microservice.

Finally, we will simulate a service failure and observe how Consul and Traefik detect the failure and reroute live traffic with zero dropped requests.

```
+-----------------------------------------------------------------------------------+
|                              HANDS-ON LAB TOPOLOGY                                |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                                [ Client Request ]                                 |
|                                        |                                          |
|                                        v                                          |
|                       +---------------------------------+                         |
|                       |  Traefik Dynamic Edge Router    |                         |
|                       |  Port: 8080 (http://api.local)  |                         |
|                       +---------------------------------+                         |
|                                 |               |                                 |
|          +----------------------+               +---------------------+           |
|          | Dynamic Route                                Dynamic Route |           |
|          v                                                            v           |
|  +-----------------------+                            +-----------------------+   |
|  | App Instance 1        |                            | App Instance 2        |   |
|  | Port: 5001            |                            | Port: 5002            |   |
|  | Status: HEALTHY       |                            | Status: HEALTHY       |   |
|  +-----------------------+                            +-----------------------+   |
|          ^                                                            ^           |
|          |                    Active Health Checks                    |           |
|          +-----------------------+    +-------------------------------+           |
|                                  |    |                                           |
|                       +---------------------------------+                         |
|                       |  HashiCorp Consul Server        |                         |
|                       |  Port: 8500 (Catalog & State)   |                         |
|                       +---------------------------------+                         |
+-----------------------------------------------------------------------------------+

```

> **DALL-E 3 Image Generation Prompt:**
> *A detailed technical topology diagram on a clean white background (#FFFFFF) displaying a client request pointing to a Traefik Edge Router at the top. The router distributes load across two microservice backend instances ("App Instance 1" on port 5001 and "App Instance 2" on port 5002). A Consul Server at the bottom monitors both instances with HTTP checks and provides real-time service discovery updates to Traefik. Minimalist dark slate components with blue and teal accents. All main text uses Google Sans Flex 12Pt, and ports/code use Google Sans Code 12Pt. Do not display font names in images. No metadata included.*

### Prerequisites

* A Linux system (Ubuntu 22.04 / 24.04 LTS or Debian 12) with root or `sudo` access.
* Python 3 and `pip` installed.
* `curl`, `jq`, and `dig` utilities installed.

```bash
sudo apt-get update && sudo apt-get install -y curl jq dnsutils python3 python3-pip

```

---

### Task 1: Install and Launch HashiCorp Consul in Dev Mode

1. Install the official HashiCorp GPG key and repository:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y consul

```

2. Start the Consul agent in standalone development mode in the background:

```bash
consul agent -dev -client=0.0.0.0 -ui > /tmp/consul.log 2>&1 &

```

3. Verify that the Consul agent is running and healthy:

```bash
consul members

```

Expected output:

```
Node           Address        Status  Type    Build   Protocol  DC   Partition  Segment
ubuntu-node    127.0.0.1:8301  alive   server  1.19.0  2         dc1  default    <all>

```

---

### Task 2: Install and Configure Traefik with Consul Catalog Provider

1. Download and extract the latest Traefik binary:

```bash
TRAEFIK_VERSION="v3.1.2"
wget https://github.com/traefik/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_linux_amd64.tar.gz
tar -xzf traefik_${TRAEFIK_VERSION}_linux_amd64.tar.gz
sudo mv traefik /usr/local/bin/
sudo chmod +x /usr/local/bin/traefik

```

2. Create the Traefik configuration file `traefik.yml`:

```yaml
cat << 'EOF' > traefik.yml
global:
  checkNewVersion: false
  sendAnonymousUsage: false

log:
  level: INFO

entryPoints:
  web:
    address: ":8080"

providers:
  consulCatalog:
    refreshInterval: 3s
    prefix: "traefik"
    endpoint:
      address: "127.0.0.1:8500"
      scheme: "http"
    exposedByDefault: false

api:
  dashboard: true
  insecure: true
EOF

```

3. Start Traefik in the background using the configuration file:

```bash
traefik --configFile=traefik.yml > /tmp/traefik.log 2>&1 &

```

4. Confirm that Traefik is running on ports `8080` (Entrypoint) and `8080/dashboard` (API Dashboard on `:8080` or `:8080/dashboard`):

```bash
curl -s http://127.0.0.1:8080/api/rawdata | jq .

```

---

### Task 3: Deploy Two Backend Microservice Instances

We will write a minimal Python HTTP server that returns its instance ID, hostname, and health state.

1. Create the application code file `app.py`:

```python
# app.py
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

PORT = int(sys.argv[1])
INSTANCE_ID = sys.argv[2]
IS_HEALTHY = True

class SimpleHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return  # Suppress default access logging for clean output

    def do_GET(self):
        global IS_HEALTHY
        if self.path == '/health':
            if IS_HEALTHY:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "UP", "instance": INSTANCE_ID}).encode())
            else:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "DOWN", "instance": INSTANCE_ID}).encode())
        elif self.path == '/fail':
            IS_HEALTHY = False
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Instance marked UNHEALTHY")
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                "message": "Hello from Service Discovery!",
                "instance": INSTANCE_ID,
                "port": PORT
            }
            self.wfile.write(json.dumps(response).encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), SimpleHandler)
    print(f"Starting {INSTANCE_ID} on port {PORT}")
    server.serve_forever()
EOF

```

2. Start two backend instances on ports `5001` and `5002`:

```bash
python3 app.py 5001 app-node-01 > /dev/null 2>&1 &
python3 app.py 5002 app-node-02 > /dev/null 2>&1 &

```

3. Verify both nodes respond locally:

```bash
curl -s http://127.0.0.1:5001/
curl -s http://127.0.0.1:5002/

```

---

### Task 4: Register Both Instances with Consul

Register both instances with tags that instruct Traefik to expose them under the host rule `Host('api.local')`.

1. Register `app-node-01`:

```bash
curl --request PUT \
  --url http://127.0.0.1:8500/v1/agent/service/register \
  --header 'Content-Type: application/json' \
  --data '{
    "Name": "web-api",
    "ID": "web-api-1",
    "Address": "127.0.0.1",
    "Port": 5001,
    "Tags": [
      "traefik.enable=true",
      "traefik.http.routers.webapi.rule=Host(`api.local`)"
    ],
    "Check": {
      "HTTP": "http://127.0.0.1:5001/health",
      "Interval": "3s",
      "Timeout": "1s"
    }
  }'

```

2. Register `app-node-02`:

```bash
curl --request PUT \
  --url http://127.0.0.1:8500/v1/agent/service/register \
  --header 'Content-Type: application/json' \
  --data '{
    "Name": "web-api",
    "ID": "web-api-2",
    "Address": "127.0.0.1",
    "Port": 5002,
    "Tags": [
      "traefik.enable=true",
      "traefik.http.routers.webapi.rule=Host(`api.local`)"
    ],
    "Check": {
      "HTTP": "http://127.0.0.1:5002/health",
      "Interval": "3s",
      "Timeout": "1s"
    }
  }'

```

3. Verify both instances are registered and passing health checks in Consul:

```bash
curl -s http://127.0.0.1:8500/v1/health/service/web-api | jq '.[].flags'

```

---

### Task 5: Verify Traefik Dynamic Discovery & Load Balancing

Send multiple HTTP requests to Traefik using the host header `Host: api.local` to verify round-robin traffic distribution:

```bash
for i in {1..6}; do
  curl -s --header "Host: api.local" http://127.0.0.1:8080/
  echo ""
done

```

Expected output showing balanced traffic execution across both backends:

```json
{"message": "Hello from Service Discovery!", "instance": "app-node-01", "port": 5001}
{"message": "Hello from Service Discovery!", "instance": "app-node-02", "port": 5002}
{"message": "Hello from Service Discovery!", "instance": "app-node-01", "port": 5001}
{"message": "Hello from Service Discovery!", "instance": "app-node-02", "port": 5002}
{"message": "Hello from Service Discovery!", "instance": "app-node-01", "port": 5001}
{"message": "Hello from Service Discovery!", "instance": "app-node-02", "port": 5002}

```

---

### Task 6: Simulate Instance Failure and Observe Failover

1. Trigger a failure on `app-node-01` via its `/fail` endpoint:

```bash
curl -s http://127.0.0.1:5001/fail

```

2. Wait 3 to 5 seconds for Consul's health checker probe to run.
3. Inspect the Consul health status for `web-api`:

```bash
curl -s http://127.0.0.1:8500/v1/health/service/web-api | jq '.[].Checks[] | {Status: .Status, Output: .Output}'

```

Output confirming node failure detection:

```json
{
  "Status": "critical",
  "Output": "HTTP status code 500"
}
{
  "Status": "passing",
  "Output": "HTTP status code 200"
}

```

4. Repeat the request loop through Traefik:

```bash
for i in {1..4}; do
  curl -s --header "Host: api.local" http://127.0.0.1:8080/
  echo ""
done

```

Expected output confirming **100% automated rerouting** away from the failed instance to the remaining healthy instance (`app-node-02`):

```json
{"message": "Hello from Service Discovery!", "instance": "app-node-02", "port": 5002}
{"message": "Hello from Service Discovery!", "instance": "app-node-02", "port": 5002}
{"message": "Hello from Service Discovery!", "instance": "app-node-02", "port": 5002}
{"message": "Hello from Service Discovery!", "instance": "app-node-02", "port": 5002}

```

---

### Verification and Cleanup Commands

To clean up all processes and temporary files created during this lab:

```bash
# Terminate background tasks
pkill -f "consul agent"
pkill -f "traefik"
pkill -f "python3 app.py"

# Remove temporary files
rm -f traefik.yml app.py traefik_${TRAEFIK_VERSION}_linux_amd64.tar.gz
rm -rf /tmp/consul.log /tmp/traefik.log

```

---

## Chapter Summary

In this chapter, you learned how to transition from static network configurations to fully dynamic routing pipelines:

1. **Service Discovery Fundamentals**: How central catalogs maintain accurate service state, contrasting client-side and server-side discovery patterns.
2. **HashiCorp Consul Architecture**: Deploying consensus-driven Consul server clusters using Raft and Gossip protocols, with support for multi-datacenter setups.
3. **Dynamic Reverse Proxies**: Integrating Traefik and NGINX (via `consul-template`) to update active routing tables automatically without downtime.
4. **Health Checking & Circuit Breaking**: Implementing proactive and reactive probes to isolate faulty application instances before they cause service outages.
5. **Practical Hands-On Skills**: Building a complete service discovery pipeline that automatically registers services, balances load, and reroutes around failures.
