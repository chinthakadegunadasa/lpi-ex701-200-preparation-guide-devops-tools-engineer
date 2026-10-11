# Appendix F: Comprehensive Killercoda Hands-On Environments for LPI 701-200

To master the **LPI 701-200 DevOps Tools Engineer** syllabus, every theoretical objective must be practiced in a controlled, multi-node interactive environment. [Killercoda](https://killercoda.com) provides an ideal browser-based execution engine to deliver these interactive labs.

This appendix provides fully implemented Killercoda scenario configurations, provisioning scripts, instructions, and verification hooks for all **27 chapters across the 6 modules** of the LPI 701-200 certification curriculum.

---

## F.1 Global Directory Architecture & Structure

To maintain a scalable repository for all 27 labs, organize your GitHub repository with the following structure:

```text
.
├── module1-software-architecture/
│   ├── ch01-cloud-native-patterns/
│   ├── ch02-agile-devops-sre/
│   ├── ch03-devsecops-compliance/
│   └── ch04-middleware-app-services/
├── module2-container-orchestration/
│   ├── ch05-docker-architecture/
│   ├── ch06-container-storage-networking/
│   ├── ch07-service-discovery/
│   ├── ch08-kubernetes-architecture/
│   ├── ch09-kubernetes-workloads/
│   ├── ch10-kubernetes-storage-config/
│   └── ch11-kubernetes-rbac-hardening/
├── module3-infrastructure-automation/
│   ├── ch12-iac-state-management/
│   ├── ch13-declarative-provisioning/
│   ├── ch14-ansible-architecture/
│   ├── ch15-ansible-roles-vault/
│   └── ch16-immutable-image-pipelines/
├── module4-cicd-pipelines/
│   ├── ch17-git-workflows-internals/
│   ├── ch18-continuous-integration/
│   ├── ch19-pipeline-automation/
│   └── ch20-deployment-strategies/
├── module5-monitoring-logging-sre/
│   ├── ch21-prometheus-metrics/
│   ├── ch22-log-management-pipelines/
│   ├── ch23-dashboards-alerting/
│   └── ch24-observability-tracing/
└── module6-cloud-testing-resiliency/
    ├── ch25-multicloud-architectures/
    ├── ch26-continuous-testing/
    └── ch27-chaos-engineering/
```

Each chapter folder contains:
* `index.json`: Killercoda backend engine parameters and UI configuration.
* `background.sh`: Asynchronous background initialization script execution.
* `step1.md`: Clear, step-by-step instructional prompt with clickable code snippets.
* `step1/verify.sh`: Automated bash evaluation script for real-time validation.
* `finish.md`: Summary, cleanup verification, and key takeaways.

---

## F.2 Base Environment Selection Matrix

When defining `index.json`, map each scenario to the required Killercoda environment backend (`backend.imageid`):

| Module | Chapters | Recommended `backend.imageid` | Installed Tooling Base |
| :--- | :--- | :--- | :--- |
| **Module 1** | Ch 01 - 04 | `ubuntu:2204` | Docker Engine, NGINX, HAProxy, Redis, Go, Python |
| **Module 2** | Ch 05 - 07 | `ubuntu:2204` | Docker Engine, Containerd, cgroupv2, Consul, Traefik |
| **Module 2** | Ch 08 - 11 | `kubernetes-kubeadm-2nodes` | Kubernetes 1.28+, `kubectl`, Helm, Cilium/Flannel |
| **Module 3** | Ch 12 - 16 | `ubuntu:2204` | Terraform, OpenTofu, Ansible, Packer, QEMU |
| **Module 4** | Ch 17 - 20 | `ubuntu:2204` | Git, GitLab Runner CLI, Jenkins CLI, Docker Engine |
| **Module 5** | Ch 21 - 24 | `kubernetes-kubeadm-1node` | Prometheus Operator, Grafana, Loki, Jaeger |
| **Module 6** | Ch 25 - 27 | `kubernetes-kubeadm-2nodes` | AWS CLI, Chaos Mesh, k6, SonarQube CLI |

---

## F.3 Module 1: Software Engineering & Architecture Labs

### Chapter 1: Cloud-Native Architecture Patterns (gRPC & Microservices)

#### `index.json`
```json
{
  "title": "Ch 01: Deploying Cloud-Native Microservices with gRPC",
  "description": "Configure microservices communication using gRPC protocol buffers.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [
      {
        "title": "Build gRPC Protocol Buffer Definition",
        "text": "step1.md",
        "verify": "step1/verify.sh"
      }
    ],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
set -e
exec > /var/log/killercoda-init.log 2>&1
apt-get update -qq && apt-get install -y -qq protobuf-compiler golang-goprotobuf-dev
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Compile Proto Definition

Define a service interface in `service.proto` and compile it into Go stubs.

1. Create `service.proto`:
```bash
cat << 'EOF' > service.proto
syntax = "proto3";
package api;
option go_package = "./api";

message Request { string name = 1; }
message Response { string message = 1; }

service Greeter {
  rpc SayHello (Request) returns (Response);
}
EOF
```

2. Generate code:
```bash
mkdir -p api && protoc --go_out=api service.proto
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
if [ -f "/root/api/service.pb.go" ]; then
  echo "Protocol buffer compiled successfully!"
  exit 0
else
  echo "File /root/api/service.pb.go not found."
  exit 1
fi
```

---

### Chapter 2: Agile, DevOps, & SRE Methodology (SLO/SLI Calculation Engine)

#### `index.json`
```json
{
  "title": "Ch 02: Implementing Error Budgets & SLIs",
  "description": "Calculate availability SLIs and track error budget consumption using Prometheus metrics.",
  "difficulty": "beginner",
  "time": "15 minutes",
  "details": {
    "steps": [{ "title": "Calculate SLI & Error Budget", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq python3 python3-pip jq
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Calculate Error Budget Remaining

Write a script `sli_calculator.py` that parses HTTP request logs and outputs error budget availability based on a target SLO of 99.5%.

Create `sli_calculator.py`:
```bash
cat << 'EOF' > sli_calculator.py
import json

total_requests = 100000
failed_requests = 250
slo = 0.995

actual_sli = (total_requests - failed_requests) / total_requests
allowed_failures = total_requests * (1 - slo)
budget_consumed = (failed_requests / allowed_failures) * 100

print(f"SLI: {actual_sli * 100:.2f}%")
print(f"Error Budget Consumed: {budget_consumed:.2f}%")

with open("metrics.json", "w") as f:
    json.dump({"sli": actual_sli, "budget_consumed": budget_consumed}, f)
EOF
python3 sli_calculator.py
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
if [ -f "metrics.json" ] && grep -q "budget_consumed" metrics.json; then
  exit 0
fi
exit 1
```

---

### Chapter 3: Enterprise DevSecOps & Security Compliance (SAST Integration)

#### `index.json`
```json
{
  "title": "Ch 03: Automated SAST with Trivy and Bandit",
  "description": "Execute Static Application Security Testing against Python applications.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Run Security Scans", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
pip install bandit
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Scan Source Code for Vulnerabilities

Analyze the sample python codebase for hardcoded credentials and unsafe evaluations.

1. Scan codebase using Bandit and save results:
```bash
bandit -r /root/app -f json -o /root/sast-results.json || true
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -f /root/sast-results.json && exit 0 || exit 1
```

---

### Chapter 4: Enterprise Middleware & Application Services (HAProxy & Redis)

#### `index.json`
```json
{
  "title": "Ch 04: Reverse Proxying & Caching with HAProxy and Redis",
  "description": "Deploy HAProxy to load-balance traffic across backend application services.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Configure HAProxy Frontend and Backend", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq haproxy redis-server
systemctl stop haproxy
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Configure HAProxy Load Balancer

Edit `/etc/haproxy/haproxy.cfg` to load balance across ports 8081 and 8082.

```bash
cat << 'EOF' >> /etc/haproxy/haproxy.cfg

frontend http_in
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    server web1 127.0.0.1:8081 check
    server web2 127.0.0.1:8082 check
EOF
systemctl restart haproxy
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
systemctl is-active --quiet haproxy && exit 0 || exit 1
```

---

## F.4 Module 2: Container Management & Orchestration Labs

### Chapter 5: Docker Containerization Architecture & Core Operations

#### `index.json`
```json
{
  "title": "Ch 05: Multi-Stage Docker Builds and cgroups",
  "description": "Build lightweight containers and enforce cgroup memory limits.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Build Multi-Stage Image & Limit Memory", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq docker.io
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Run Container with Strict Memory Limit

Run an NGINX container named `restricted-app` limited to 128MB of memory.

```bash
docker run -d --name restricted-app --memory="128m" nginx:alpine
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
MEM=$(docker inspect restricted-app --format '{{.HostConfig.Memory}}')
if [ "$MEM" -eq 134217728 ]; then
  exit 0
fi
exit 1
```

---

### Chapter 6: Advanced Container Storage & Overlay Networking

#### `index.json`
```json
{
  "title": "Ch 06: Docker Overlay Networks & Custom Drivers",
  "description": "Create custom Docker bridge and overlay networks with custom subnetting.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Create Isolated Bridge Network", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq docker.io
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Create Isolated Network

Create a custom Docker network named `secure-net` using the subnet `172.28.0.0/16`.

```bash
docker network create --subnet=172.28.0.0/16 secure-net
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
docker network inspect secure-net | grep -q "172.28.0.0/16" && exit 0 || exit 1
```

---

### Chapter 7: Service Discovery & Dynamic Routing (Consul & Traefik)

#### `index.json`
```json
{
  "title": "Ch 07: Service Discovery with HashiCorp Consul",
  "description": "Register services in HashiCorp Consul and perform DNS query resolution.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Start Consul and Register Service", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
wget https://releases.hashicorp.com/consul/1.16.1/consul_1.16.1_linux_amd64.zip
unzip consul_1.16.1_linux_amd64.zip -d /usr/local/bin/
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Launch Consul Agent in Dev Mode

Start Consul in development mode as a background service:

```bash
consul agent -dev -client=0.0.0.0 > /var/log/consul.log 2>&1 &
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
curl -s http://127.0.0.1:8500/v1/status/leader | grep -q "8300" && exit 0 || exit 1
```

---

### Chapter 8: Enterprise Kubernetes Architecture & Operations

#### `index.json`
```json
{
  "title": "Ch 08: Inspecting Kubernetes Control Plane Components",
  "description": "Query etcd and evaluate control plane static pod health.",
  "difficulty": "advanced",
  "time": "25 minutes",
  "details": {
    "steps": [{ "title": "Inspect Control Plane", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "kubernetes-kubeadm-2nodes" }
}
```

#### `background.sh`
```bash
#!/bin/bash
kubectl wait --for=condition=Ready node --all --timeout=120s
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Save Control Plane Pod Manifest List

Extract all running control plane pod names into `/root/control-plane.txt`.

```bash
kubectl get pods -n kube-system -l tier=control-plane -o jsonpath='{.items[*].metadata.name}' > /root/control-plane.txt
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
grep -q "kube-apiserver" /root/control-plane.txt && exit 0 || exit 1
```

---

### Chapter 9: Kubernetes Workload Management (StatefulSets & Deployments)

#### `index.json`
```json
{
  "title": "Ch 09: Deploying StatefulSets and Rolling Updates",
  "description": "Create a 3-replica StatefulSet with ordered scaling.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Deploy StatefulSet", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "kubernetes-kubeadm-2nodes" }
}
```

#### `background.sh`
```bash
#!/bin/bash
kubectl wait --for=condition=Ready node --all --timeout=120s
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Create StatefulSet Manifest

Deploy an NGINX StatefulSet named `web-stateful` with 2 replicas.

```bash
cat << 'EOF' > statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: "nginx"
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
EOF
kubectl apply -f statefulset.yaml
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
kubectl get statefulset web-stateful -o jsonpath='{.status.readyReplicas}' | grep -q "2" && exit 0 || exit 1
```

---

### Chapter 10: Kubernetes Storage, ConfigMaps, & Secrets

#### `index.json`
```json
{
  "title": "Ch 10: Volume Binding with PV, PVC, and Secret Projection",
  "description": "Configure persistent volumes and project Secrets as volume mounts.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Create Secret and Mount to Pod", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "kubernetes-kubeadm-2nodes" }
}
```

#### `background.sh`
```bash
#!/bin/bash
kubectl wait --for=condition=Ready node --all --timeout=120s
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Create Generic Secret

Create a generic Kubernetes secret named `db-credentials` containing key `password=supersecret`.

```bash
kubectl create secret generic db-credentials --from-literal=password=supersecret
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
kubectl get secret db-credentials > /dev/null 2>&1 && exit 0 || exit 1
```

---

### Chapter 11: Kubernetes RBAC, Network Policies, & Hardening

#### `index.json`
```json
{
  "title": "Ch 11: Enforcing RBAC and NetworkPolicy Isolation",
  "description": "Build RoleBindings and restrict ingress traffic using NetworkPolicies.",
  "difficulty": "advanced",
  "time": "25 minutes",
  "details": {
    "steps": [{ "title": "Create Restrictive NetworkPolicy", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "kubernetes-kubeadm-2nodes" }
}
```

#### `background.sh`
```bash
#!/bin/bash
kubectl wait --for=condition=Ready node --all --timeout=120s
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Apply Default Deny Network Policy

Block all ingress traffic to pods in the `default` namespace.

```bash
cat << 'EOF' > deny-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
kubectl apply -f deny-ingress.yaml
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
kubectl get networkpolicy default-deny-ingress > /dev/null 2>&1 && exit 0 || exit 1
```

---

## F.5 Module 3: Infrastructure Configuration & Automation Labs

### Chapter 12: IaC Architecture & State Management (Terraform/OpenTofu)

#### `index.json`
```json
{
  "title": "Ch 12: Terraform/OpenTofu Local State Management",
  "description": "Initialize OpenTofu, manage state resources, and perform state inspection.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Provision Local Resource with OpenTofu", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
snap install --classic opentofu || apt-get install -y -qq terraform
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Provision Local File via OpenTofu

Create `main.tf` to generate a local file resource:

```bash
cat << 'EOF' > main.tf
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

resource "local_file" "sample" {
  content  = "LPI 701-200 OpenTofu State Management"
  filename = "/tmp/opentofu_test.txt"
}
EOF
tofu init && tofu apply -auto-approve
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -f /tmp/opentofu_test.txt && exit 0 || exit 1
```

---

### Chapter 13: Declarative Infrastructure Provisioning (HCL Modules)

#### `index.json`
```json
{
  "title": "Ch 13: Writing and Instantiating Terraform Modules",
  "description": "Build modular HCL infrastructure blueprints.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Construct Reusable Local Module", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq terraform
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Create Module Structure

Create a module in `./modules/file_creator` that writes an input string to disk.

```bash
mkdir -p modules/file_creator
cat << 'EOF' > modules/file_creator/main.tf
variable "text_content" { type = string }
resource "local_file" "output" {
  content  = var.text_content
  filename = "/tmp/module_output.txt"
}
EOF
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -f modules/file_creator/main.tf && exit 0 || exit 1
```

---

### Chapter 14: Ansible Architecture & Core Playbooks

#### `index.json`
```json
{
  "title": "Ch 14: Idempotent Server Configuration with Ansible Playbooks",
  "description": "Construct playbooks utilizing core inventory files and configuration modules.",
  "difficulty": "beginner",
  "time": "15 minutes",
  "details": {
    "steps": [{ "title": "Execute Playbook on Localhost", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq ansible
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Run Ansible Playbook

Create and execute `setup.yml` targeting `localhost`:

```bash
cat << 'EOF' > setup.yml
- hosts: localhost
  connection: local
  tasks:
    - name: Ensure Apache is installed
      apt:
        name: apache2
        state: present
EOF
ansible-playbook setup.yml
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
dpkg -l | grep -q apache2 && exit 0 || exit 1
```

---

### Chapter 15: Advanced Ansible Patterns, Roles, & Automation

#### `index.json`
```json
{
  "title": "Ch 15: Encrypting Variables using Ansible Vault",
  "description": "Store secret variables using Ansible Vault and execute roles safely.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Create Encrypted Vault File", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq ansible
echo "vaultpassword123" > /root/.vault_pass
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Encrypt Variable File

Create `/root/secrets.yml` and encrypt it using `ansible-vault` with the vault pass stored at `/root/.vault_pass`.

```bash
cat << 'EOF' > /root/secrets.yml
db_password: "SuperSecretPassword"
EOF
ansible-vault encrypt /root/secrets.yml --vault-password-file /root/.vault_pass
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
grep -q "\$ANSIBLE_VAULT" /root/secrets.yml && exit 0 || exit 1
```

---

### Chapter 16: Automated Immutable Image Pipelines (Packer)

#### `index.json`
```json
{
  "title": "Ch 16: Building Machine Images with HashiCorp Packer",
  "description": "Construct immutable Docker images using Packer HCL templates.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Build Image with Packer", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update -qq && apt-get install -y -qq packer docker.io
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Write Packer HCL Template

Create `image.pkr.hcl`:

```bash
cat << 'EOF' > image.pkr.hcl
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  name = "lpi-packer"
  sources = ["source.docker.ubuntu"]
}
EOF
packer init image.pkr.hcl
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -f image.pkr.hcl && exit 0 || exit 1
```

---

## F.6 Module 4: Continuous Delivery & CI/CD Pipelines Labs

### Chapter 17: Enterprise Git Workflows & Internal Internals

#### `index.json`
```json
{
  "title": "Ch 17: Git Hooks and Low-Level Object Inspection",
  "description": "Implement automated pre-commit hooks and inspect `.git/objects`.",
  "difficulty": "intermediate",
  "time": "15 minutes",
  "details": {
    "steps": [{ "title": "Configure Pre-Commit Hook", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq git
cd /root && git init repo
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Install Executable Pre-Commit Hook

In `/root/repo/.git/hooks/pre-commit`, write a bash hook that prevents commits to `main` branch directly.

```bash
cat << 'EOF' > /root/repo/.git/hooks/pre-commit
#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
  echo "Direct commits to main branch are prohibited!"
  exit 1
fi
EOF
chmod +x /root/repo/.git/hooks/pre-commit
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -x /root/repo/.git/hooks/pre-commit && exit 0 || exit 1
```

---

### Chapter 18: Continuous Integration Architecture

#### `index.json`
```json
{
  "title": "Ch 18: Configuring Local Runners and Artifact Caching",
  "description": "Configure build environments and artifact preservation pipelines.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Setup Artifact Build Script", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq tar gzip
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Package CI Build Artifact

Build an automated shell script `/root/package_artifact.sh` that bundles all `.log` files in `/var/log` into `/root/artifacts.tar.gz`.

```bash
cat << 'EOF' > /root/package_artifact.sh
#!/bin/bash
tar -czf /root/artifacts.tar.gz /var/log/*.log 2>/dev/null || true
EOF
chmod +x /root/package_artifact.sh
/root/package_artifact.sh
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -f /root/artifacts.tar.gz && exit 0 || exit 1
```

---

### Chapter 19: Enterprise CI/CD Pipeline Automation (GitHub Actions / GitLab CI)

#### `index.json`
```json
{
  "title": "Ch 19: Declarative Pipeline Automation Syntax",
  "description": "Write and validate declarative pipeline syntax files.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Create GitHub Actions Workflow", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
mkdir -p /root/project/.github/workflows
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Create GitHub Actions Workflow

Write `.github/workflows/ci.yml` with a single job named `build` executing `echo "CI Test"`.

```bash
cat << 'EOF' > /root/project/.github/workflows/ci.yml
name: CI Pipeline
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "CI Test"
EOF
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -f /root/project/.github/workflows/ci.yml && exit 0 || exit 1
```

---

### Chapter 20: Modern Deployment Strategies (Blue/Green & Canary)

#### `index.json`
```json
{
  "title": "Ch 20: Automated Canary Deployments with Traffic Weighting",
  "description": "Shift traffic dynamically between stable and canary application pods.",
  "difficulty": "advanced",
  "time": "25 minutes",
  "details": {
    "steps": [{ "title": "Configure Canary Weighting via Service", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "kubernetes-kubeadm-2nodes" }
}
```

#### `background.sh`
```bash
#!/bin/bash
kubectl wait --for=condition=Ready node --all --timeout=120s
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Deploy Primary and Canary Workloads

Deploy two workloads with identical app labels `app=my-service`, but different version tags (`v1` and `v2`).

```bash
kubectl create deployment app-v1 --image=nginx:1.20 --replicas=3
kubectl label deployment app-v1 app=my-service
kubectl create deployment app-v2 --image=nginx:1.21 --replicas=1
kubectl label deployment app-v2 app=my-service
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
V1=$(kubectl get deployment app-v1 -o jsonpath='{.status.readyReplicas}')
V2=$(kubectl get deployment app-v2 -o jsonpath='{.status.readyReplicas}')
if [ "$V1" -eq 3 ] && [ "$V2" -eq 1 ]; then
  exit 0
fi
exit 1
```

---

## F.7 Module 5: Monitoring, Logging, & SRE Labs

### Chapter 21: Prometheus Monitoring & Metrics Engineering

#### `index.json`
```json
{
  "title": "Ch 21: Writing PromQL Queries and Alerting Rules",
  "description": "Configure Prometheus metrics scrapers and PromQL alerting expressions.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Define PromQL Alert Rule", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "kubernetes-kubeadm-1node" }
}
```

#### `background.sh`
```bash
#!/bin/bash
kubectl wait --for=condition=Ready node --all --timeout=120s
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Write High CPU Prometheus Alerting Rule

Write a Prometheus rule manifest in `/root/alert.yaml` that fires when CPU usage exceeds 80%.

```bash
cat << 'EOF' > /root/alert.yaml
groups:
- name: node-alerts
  rules:
  - alert: HighNodeCPU
    expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 2m
    labels:
      severity: critical
EOF
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
grep -q "HighNodeCPU" /root/alert.yaml && exit 0 || exit 1
```

---

### Chapter 22: Enterprise Log Management Pipelines (Loki & Fluentd)

#### `index.json`
```json
{
  "title": "Ch 22: Aggregating Logs with Promtail and Loki",
  "description": "Configure Promtail scrapers to collect system logs into Grafana Loki.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Configure Promtail Targets", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
mkdir -p /etc/promtail
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Configure Promtail to Scrape `/var/log/syslog`

Create `/etc/promtail/config.yml`:

```bash
cat << 'EOF' > /etc/promtail/config.yml
server:
  http_listen_port: 9080
positions:
  filename: /tmp/positions.yaml
clients:
  - url: http://localhost:3100/loki/api/v1/push
scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/syslog
EOF
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
grep -q "/var/log/syslog" /etc/promtail/config.yml && exit 0 || exit 1
```

---

### Chapter 23: Enterprise Dashboards & Alert Management (Grafana & Alertmanager)

#### `index.json`
```json
{
  "title": "Ch 23: Managing Routing Trees in Alertmanager",
  "description": "Configure Alertmanager routing trees, receivers, and inhibition rules.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Build Alertmanager Routing Config", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
mkdir -p /etc/alertmanager
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Configure Alertmanager Receiver Routes

Configure `/etc/alertmanager/alertmanager.yml` to route `severity=critical` alerts to a webhook:

```bash
cat << 'EOF' > /etc/alertmanager/alertmanager.yml
route:
  group_by: ['alertname']
  receiver: 'default-receiver'
  routes:
  - match:
      severity: critical
    receiver: 'pager-duty'

receivers:
- name: 'default-receiver'
- name: 'pager-duty'
EOF
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
grep -q "pager-duty" /etc/alertmanager/alertmanager.yml && exit 0 || exit 1
```

---

### Chapter 24: Observability, Tracing, & Incident Management (OpenTelemetry & Jaeger)

#### `index.json`
```json
{
  "title": "Ch 24: Distributed Tracing with OpenTelemetry",
  "description": "Instrument applications with OpenTelemetry collector pipelines.",
  "difficulty": "advanced",
  "time": "25 minutes",
  "details": {
    "steps": [{ "title": "Configure OTel Collector Pipeline", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
mkdir -p /etc/otelcol
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Configure OpenTelemetry Collector

Create `/etc/otelcol/config.yaml` to receive OTLP telemetry and export to Jaeger:

```bash
cat << 'EOF' > /etc/otelcol/config.yaml
receivers:
  otlp:
    protocols:
      grpc:
exporters:
  jaeger:
    endpoint: "jaeger-all-in-one:14250"
    tls:
      insecure: true
service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [jaeger]
EOF
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
grep -q "jaeger-all-in-one:14250" /etc/otelcol/config.yaml && exit 0 || exit 1
```

---

## F.8 Module 6: Cloud Architecture & Testing Labs

### Chapter 25: Multi-Cloud Architectures & Service Models

#### `index.json`
```json
{
  "title": "Ch 25: Cloud Infrastructure Abstraction CLI Tools",
  "description": "Interact with multi-cloud APIs through standardized CLI abstractions.",
  "difficulty": "intermediate",
  "time": "15 minutes",
  "details": {
    "steps": [{ "title": "Configure AWS CLI Local Emulation", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
apt-get update -qq && apt-get install -y -qq awscli
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Configure AWS Dummy Credentials

Set local credentials for offline cloud emulation testing:

```bash
aws configure set aws_access_key_id "mock_key"
aws configure set aws_secret_access_key "mock_secret"
aws configure set default.region "us-east-1"
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
aws configure get default.region | grep -q "us-east-1" && exit 0 || exit 1
```

---

### Chapter 26: Continuous Testing Frameworks (k6 & Integration Tests)

#### `index.json`
```json
{
  "title": "Ch 26: Automated Load Testing with k6",
  "description": "Execute performance and load testing scripts against HTTP targets.",
  "difficulty": "intermediate",
  "time": "20 minutes",
  "details": {
    "steps": [{ "title": "Run Load Test Suite", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "ubuntu:2204" }
}
```

#### `background.sh`
```bash
#!/bin/bash
gpg -k
gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | tee /etc/apt/sources.list.d/k6.list
apt-get update -qq && apt-get install -y -qq k6
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Create k6 Performance Script

Create `load_test.js`:

```bash
cat << 'EOF' > load_test.js
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '5s',
};

export default function () {
  http.get('https://test.k6.io');
  sleep(1);
}
EOF
k6 run load_test.js
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
test -f load_test.js && exit 0 || exit 1
```

---

### Chapter 27: Enterprise Chaos Engineering & Fault Injection (Chaos Mesh)

#### `index.json`
```json
{
  "title": "Ch 27: Injecting Faults using Chaos Mesh",
  "description": "Inject pod failure and network delay faults in a Kubernetes environment.",
  "difficulty": "advanced",
  "time": "25 minutes",
  "details": {
    "steps": [{ "title": "Inject Network Delay via Chaos CRD", "text": "step1.md", "verify": "step1/verify.sh" }],
    "intro": { "text": "intro.md", "background": "background.sh" },
    "finish": { "text": "finish.md" }
  },
  "backend": { "imageid": "kubernetes-kubeadm-2nodes" }
}
```

#### `background.sh`
```bash
#!/bin/bash
kubectl wait --for=condition=Ready node --all --timeout=120s
touch /tmp/finished-setup
```

#### `step1.md`
````markdown
# Step 1: Create NetworkChaos Fault Injection Manifest

Write a `NetworkChaos` manifest named `/root/network-chaos.yaml` to inject a 120ms latency:

```bash
cat << 'EOF' > /root/network-chaos.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: delay-experiment
  namespace: default
spec:
  action: delay
  mode: one
  selector:
    namespaces:
      - default
  delay:
    latency: '120ms'
EOF
```
````

#### `step1/verify.sh`
```bash
#!/bin/bash
grep -q "delay-experiment" /root/network-chaos.yaml && exit 0 || exit 1
```

---

## F.9 Automated Scenario Testing & CI Validation Workflow

To ensure all 27 scenario verification scripts and configurations operate cleanly without errors, implement this GitHub Actions pipeline in your scenario repository:

```yaml
name: Killercoda Scenario Validation
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate-json:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate index.json files
        run: |
          find . -name "index.json" -exec jq . {} \; > /dev/null
          echo "All 27 index.json files are valid JSON."

  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ShellCheck on verification scripts
        run: |
          sudo apt-get install -y shellcheck
          find . -name "*.sh" -exec shellcheck {} \;
```
