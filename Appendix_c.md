# Appendix C: Common Configuration Schemas

This appendix provides production-grade, battle-tested configuration schemas across the core domains of the **LPI DevOps Tools Engineer (701-200)** certification. These templates adhere to enterprise security baselines, OCI standards, least-privilege principles, and high-availability design patterns.

## C.1. Enterprise Dockerfile Templates (Multi-stage, Non-root)

In enterprise containerization pipelines, security and minimal image size are paramount. The following multi-stage Dockerfile builds a compiled backend application (using Go as an exemplary compiled runtime) while ensuring that the final execution artifact runs as an unprivileged user within a minimal distroless/scratch runtime environment, completely stripping out build-time dependencies, package managers, and shell utilities to minimize the CVE attack surface.

```dockerfile
# ==============================================================================
# Stage 1: Build Stage
# ==============================================================================
FROM golang:1.22-bookworm AS builder

# Set working directory
WORKDIR /src

# Copy dependency definition files first for optimal caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build statically linked binary with stripped debug symbols
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/bin/enterprise-service .

# ==============================================================================
# Stage 2: Production Runtime Stage
# ==============================================================================
FROM gcr.io/distroless/static-debian12:nonroot

# Set metadata labels compliant with OCI image specification
LABEL org.opencontainers.image.title="Enterprise Core Service" \
      org.opencontainers.image.vendor="DevOps Enterprise Engineering" \
      org.opencontainers.image.version="1.2.0" \
      org.opencontainers.image.source="https://github.com/enterprise/core-service"

# Copy binary from builder stage
COPY --from=builder /app/bin/enterprise-service /usr/local/bin/enterprise-service

# Expose enterprise application port
EXPOSE 8080

# Configure non-root execution (UID 65532 - nonroot in distroless)
USER 65532:65532

# Define entrypoint
ENTRYPOINT ["/usr/local/bin/enterprise-service"]
```

## C.2. Kubernetes Production Manifests (Deployment, StatefulSet, Ingress, NetworkPolicy)

Production Kubernetes clusters require strict resource quotas, security contexts, ingress routing rules, and strict pod-to-pod network isolation.

### 1. Production Deployment Manifest (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: core-api-service
  namespace: production
  labels:
    app.kubernetes.io/name: core-api-service
    app.kubernetes.io/part-of: enterprise-platform
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: core-api-service
  template:
    metadata:
      labels:
        app: core-api-service
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: api
        image: registry.enterprise.internal/platform/core-api:v1.2.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          name: http
        resources:
          limits:
            cpu: "1"
            memory: 1Gi
          requests:
            cpu: "500m"
            memory: 512Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 15
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /readyz
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 2. Production StatefulSet Manifest (`statefulset.yaml`)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: enterprise-db
  namespace: production
  labels:
    app.kubernetes.io/name: enterprise-db
spec:
  serviceName: "enterprise-db-headless"
  replicas: 3
  selector:
    matchLabels:
      app: enterprise-db
  template:
    metadata:
      labels:
        app: enterprise-db
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
        fsGroup: 999
      containers:
      - name: postgres
        image: postgres:16-bookworm
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_DB
          value: production_db
        - name: POSTGRES_PASSWORD_FILE
          value: /etc/secrets/db-password/password
        resources:
          limits:
            cpu: "2"
            memory: 4Gi
          requests:
            cpu: "1"
            memory: 2Gi
        volumeMounts:
        - name: pgdata
          mountPath: /var/lib/postgresql/data
        - name: secret-volume
          mountPath: /etc/secrets/db-password
          readOnly: true
      volumes:
      - name: secret-volume
        secret:
          secretName: db-credentials-secret
  volumeClaimTemplates:
  - metadata:
      name: pgdata
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "enterprise-fast-ssd"
      resources:
        requests:
          storage: 50Gi
```

### 3. Ingress Route Manifest (`ingress.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: enterprise-ingress-router
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-production"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/rate-limit-rps: "50"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.enterprise.internal
    secretName: enterprise-api-tls
  rules:
  - host: api.enterprise.internal
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: core-api-service
            port:
              number: 8080
```

### 4. NetworkPolicy Zero-Trust Isolation (`networkpolicy.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-and-allow-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: core-api-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: enterprise-db
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32 # Block access to cloud metadata services (IMDSv1/v2 protection)
    ports:
    - protocol: TCP
      port: 443
    - protocol: UDP
      port: 53
```

## C.3. Terraform Reusable Module Schema Template

Enterprise infrastructure-as-code follows strict modular design patterns with enforced version constraints, input validation, standardized tagging, and segregated output contracts.

### 1. Module Root Structure Layout

```
modules/
└── enterprise_vpc/
    ├── README.md
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
    └── versions.tf
```

### 2. `versions.tf`

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### 3. `variables.tf` (With Enterprise Validation)

```hcl
variable "environment" {
  type        = string
  description = "Target deployment environment (dev, staging, production)."
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the enterprise VPC."
  default     = "10.100.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for subnet distribution."
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

### 4. `main.tf`

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.environment}-core"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Compliance  = "SOC2"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "subnet-${var.environment}-public-${var.availability_zones[count.index]}"
    Environment = var.environment
    Tier        = "Public"
  }
}
```

### 5. `outputs.tf`

```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The unique identifier of the provisioned VPC."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs."
}
```

## C.4. Ansible Production Directory Layout and Playbook Schema

Enterprise configuration management requires robust role-based directory organization, encrypted credential storage via Ansible Vault, and defensive error handling.

### 1. Enterprise Directory Tree Structure

```
ansible/
├── ansible.cfg
├── inventories/
│   └── production/
│       ├── hosts.ini
│       └── group_vars/
│           ├── all.yml
│           └── vault.yml (encrypted)
├── roles/
│   └── hardening/
│       ├── tasks/main.yml
│       ├── handlers/main.yml
│       └── templates/sshd_config.j2
└── site.yml
```

### 2. Configuration (`ansible.cfg`)

```ini
[defaults]
inventory = inventories/production/hosts.ini
remote_user = devops-admin
private_key_file = ~/.ssh/id_ed25519
host_key_checking = True
retry_files_enabled = False
roles_path = roles/
vault_password_file = ~/.vault_pass.txt

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

### 3. Production Playbook with Error Handling (`site.yml`)

```yaml
---
- name: Enterprise Server Provisioning and Hardening
  hosts: all
  gather_facts: yes
  serial: "20%" # Rolling update constraint across hosts

  pre_tasks:
    - name: Verify operating system version compatibility
      assert:
        that:
          - ansible_os_family == "Debian"
          - ansible_distribution_version is version('13', '>=')
        fail_msg: "Unsupported OS. Enterprise hardening requires Debian 13 or higher."

  roles:
    - role: hardening

  tasks:
    - name: Ensure critical audit logging daemon is active
      block:
        - name: Install auditd package
          apt:
            name: auditd
            state: present
            update_cache: yes
        - name: Enable and start auditd service
          service:
            name: auditd
            state: started
            enabled: yes
      rescue:
        - name: Log critical provisioning failure
          debug:
            msg: "Failed to configure auditd on host {{ inventory_hostname }}. Initiating rollback flag."
      always:
        - name: Record compliance check execution timestamp
          file:
            path: /var/log/compliance_checked.lock
            state: touch
            mode: '0600'
```

## C.5. Prometheus & Alertmanager Enterprise YAML Configurations

Observability infrastructure must aggregate metrics reliably while routing high-severity alerts to operational responders through deduplication and grouping rules.

### 1. Prometheus Scrape Configuration (`prometheus.yml`)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'enterprise-production-monitor'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager.monitoring.svc:9093']

rule_files:
  - '/etc/prometheus/rules/*.rules.yml'

scrape_configs:
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### 2. Prometheus Alerting Rules (`app.rules.yml`)

```yaml
groups:
  - name: CoreAppAlerts
    rules:
      - alert: HighHttpErrorRate
        expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High HTTP 5xx Error Rate detected on {{ $labels.instance }}"
          description: "Error rate has exceeded 5% over the last 5 minutes (current value: {{ $value | humanizePercentage }})."

      - alert: NodeCpuSaturation
        expr: 1 - rate(node_cpu_seconds_total{mode="idle"}[5m]) > 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node CPU utilization critical on {{ $labels.instance }}"
```

### 3. Alertmanager Routing Configuration (`alertmanager.yml`)

```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'pagerduty-escalation'
  routes:
    - match:
        severity: warning
      receiver: 'slack-notifications'

receivers:
  - name: 'pagerduty-escalation'
    pagerduty_configs:
      - service_key: '<secret-pagerduty-integration-key>'
        severity: critical

  - name: 'slack-notifications'
    slack_configs:
      - channel: '#platform-alerts'
        send_resolved: true
        text: "Alert: {{ .CommonAnnotations.summary }}\nDescription: {{ .CommonAnnotations.description }}"
```

## C.6. Multi-Stage CI/CD Pipeline Manifests (GitLab CI, GitHub Actions, Jenkinsfile)

Enterprise CI/CD pipelines enforce automated linting, security scanning (SAST and container vulnerability checks), container building, and deployment orchestration.

### 1. GitLab CI/CD Pipeline (`.gitlab-ci.yml`)

```yaml
stages:
  - lint
  - test
  - security
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  CONTAINER_IMAGE: registry.enterprise.internal/platform/core-api:$CI_COMMIT_SHA

lint-code:
  stage: lint
  image: golangci/golangci-lint:v1.57-alpine
  script:
    - golangci-lint run --timeout 5m

unit-test:
  stage: test
  image: golang:1.22-bookworm
  script:
    - go test -v -race -coverprofile=coverage.out ./...
  coverage: '/total:\s+\(statements\)\s+(\d+.\d+\%)/'

container-scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $CONTAINER_IMAGE

build-and-push:
  stage: build
  image: docker:26.0.0
  services:
    - docker:26.0.0-dind
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
    - docker build -t $CONTAINER_IMAGE .
    - docker push $CONTAINER_IMAGE
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'

deploy-production:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/core-api-service api=$CONTAINER_IMAGE --namespace production
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

### 2. GitHub Actions Workflow (`.github/workflows/pipeline.yml`)

```yaml
name: Enterprise CI/CD Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  validate-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Run Unit Tests
        run: go test -v -race ./...

  build-and-push-container:
    needs: validate-and-test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Enterprise Registry
        uses: docker/login-action@v3
        with:
          registry: registry.enterprise.internal
          username: ${{ secrets.REGISTRY_USER }}
          password: ${{ secrets.REGISTRY_PASSWORD }}

      - name: Build and Push OCI Image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: registry.enterprise.internal/platform/core-api:${{ github.sha }}
```

### 3. Declarative Jenkinsfile (`Jenkinsfile`)

```groovy
pipeline {
    agent {
        label 'docker-agent'
    }
    options {
        timeout(time: 1, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    environment {
        REGISTRY = 'registry.enterprise.internal'
        IMAGE_NAME = 'platform/core-api'
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }
    stages {
        stage('Checkout & Lint') {
            steps {
                checkout scm
                sh 'golangci-lint run'
            }
        }
        stage('Unit Tests') {
            steps {
                sh 'go test -v ./...'
            }
        }
        stage('Build Container') {
            steps {
                script {
                    appImg = docker.build("${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}")
                }
            }
        }
        stage('Security Scan') {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
            }
        }
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'k8s-prod-creds', passwordVariable: 'K8S_PASS', usernameVariable: 'K8S_USER')]) {
                    sh "kubectl set image deployment/core-api-service api=${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG} --namespace production"
                }
            }
        }
    }
    post {
        failure {
            echo "Pipeline failed! Dispatching incident webhook to Slack..."
        }
    }
}
