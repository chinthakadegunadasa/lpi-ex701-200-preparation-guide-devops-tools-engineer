# Appendix F: Building an Interactive Hands-On Lab Environment with Killercoda

To truly master the **LPI 701-200 DevOps Tools Engineer** syllabus, theoretical knowledge must be paired with immediate, reproducible hands-on execution. [Killercoda](https://killercoda.com) provides an ideal browser-based platform for running interactive, multi-node Linux and Kubernetes environments without requiring local resource provisioning.

This appendix provides a complete framework for creating, structuring, and deploying custom interactive scenarios that mirror every module in the LPI 701-200 objective matrix.

---

## F.1 Architecture & Core Components of a Killercoda Scenario

A standard Killercoda scenario is version-controlled via Git and consists of a directory structure defining the user environment, automated initial setups, step-by-step instructions, and verification scripts.

```
.
├── index.json          # Scenario configuration metadata
├── intro.md            # Scenario background and prerequisites
├── step1.md            # First learning objective and instructions
├── step1/
│   └── verify.sh       # Automated verification script for Step 1
├── step2.md            # Second learning objective
├── step2/
│   └── verify.sh       # Automated verification script for Step 2
├── finish.md           # Scenario wrap-up and key takeaways
└── background.sh       # Silent background initialization script
```

---

## F.2 Scenario Blueprint: LPI 701-200 Environment Configurations

Depending on the module being tested, choose the appropriate base environment in `index.json`:

| Module | Base Environment (`backend.imageid`) | Target Tooling Stack |
| :--- | :--- | :--- |
| **Module 1 & 4** | `ubuntu:2204` | NGINX, Git, Docker Compose, Jenkins/Runner |
| **Module 2** | `kubernetes-kubeadm-2nodes` | Kubernetes Cluster, `kubectl`, CNI, Helm |
| **Module 3** | `ubuntu:2204` | Terraform / OpenTofu, Ansible, Packer |
| **Module 5** | `ubuntu:2204` / `kubernetes-kubeadm-1node` | Prometheus, Grafana, Loki, OpenTelemetry |
| **Module 6** | `kubernetes-kubeadm-2nodes` | Chaos Mesh, Continuous Testing Suites |

---

## F.3 Sample Production Configuration Files

### 1. `index.json` Configuration Example
This manifest defines a multi-node Kubernetes scenario designed for **Topic 702 (Container Management & Orchestration)** and **Topic 706 (Chaos Engineering)**:

```json
{
  "title": "LPI 701-200 Lab: Chaos Mesh & Resiliency on Kubernetes",
  "description": "Learn to inject network latency and pod failures into K8s workloads using Chaos Mesh.",
  "difficulty": "intermediate",
  "time": "30 minutes",
  "details": {
    "steps": [
      {
        "title": "Inspect Cluster & Deploy Sample Workload",
        "text": "step1.md",
        "verify": "step1/verify.sh"
      },
      {
        "title": "Install Chaos Mesh via Helm",
        "text": "step2.md",
        "verify": "step2/verify.sh"
      },
      {
        "title": "Inject Network Latency Fault (NetworkChaos)",
        "text": "step3.md",
        "verify": "step3/verify.sh"
      }
    ],
    "intro": {
      "text": "intro.md",
      "background": "background.sh"
    },
    "finish": {
      "text": "finish.md"
    }
  },
  "backend": {
    "imageid": "kubernetes-kubeadm-2nodes"
  }
}
```

---

### 2. `background.sh` (Automated Environment Setup)
This script runs silently when the environment launches to pre-install dependencies without blocking the user.

```bash
#!/bin/bash
set -e

# Log setup output
exec > /var/log/killercoda-init.log 2>&1

echo "==> Updating environment packages..."
apt-get update -qq && apt-get install -y -qq jq curl git

echo "==> Pre-installing Helm package manager..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "==> Waiting for Kubernetes nodes to become ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "==> Environment ready for LPI 701-200 Lab!"
touch /tmp/finished-setup
```

---

### 3. Step 1 Instructions (`step1.md`)
Killercoda supports executable inline code blocks. Clicking a code block automatically executes it in the integrated terminal.

```markdown
# Step 1: Verify Kubernetes Cluster and Deploy Web Application

Before testing resiliency, establish a baseline workload running on the cluster.

### Task:

1. Check that all nodes are in a `Ready` state:
   ```bash
   kubectl get nodes
   ```

2. Deploy an NGINX web service with 3 replicas:
   ```bash
   kubectl create deployment target-app --image=nginx:alpine --replicas=3
   ```

3. Expose the deployment as a ClusterIP service:
   ```bash
   kubectl expose deployment target-app --port=80 --target-port=80
   ```

4. Verify all pods are running:
   ```bash
   kubectl get pods -l app=target-app
   ```

Click **Check** below to verify completion of this step.
```

---

### 4. Step 1 Verification Script (`step1/verify.sh`)
Killercoda evaluates this bash script when the user clicks **Check**. Returning exit code `0` passes the step, while any non-zero exit code prompts the user to review their work.

```bash
#!/bin/bash

# Check if target-app deployment exists
if ! kubectl get deployment target-app > /dev/null 2>&1; then
  echo "Deployment 'target-app' was not found."
  exit 1
fi

# Check if 3 pods are running and ready
READY_PODS=$(kubectl get deployment target-app -o jsonpath='{.status.readyReplicas}')

if [ "$READY_PODS" -eq 3 ]; then
  echo "Deployment successfully created with 3 ready replicas."
  exit 0
else
  echo "Waiting for all 3 replicas to be Ready. Current ready replicas: ${READY_PODS:-0}"
  exit 1
fi
```

---

## F.4 Matrix-to-Lab Mapping Strategy

To build out your complete lab suite, map each module from the **LPI 701-200 Matrix** to individual Killercoda scenarios:

```
LPI 701-200 Hands-on Curriculum
├── Module 1: Software Architecture & DevSecOps
│   └── Scenario: SAST Pipeline & NGINX Reverse Proxy Lab
├── Module 2: Container Management & Orchestration
│   ├── Scenario: Docker Storage, CNI, & Overlay Networks
│   └── Scenario: K8s Storage, RBAC, & Network Policies
├── Module 3: Infrastructure Configuration & Automation
│   └── Scenario: Terraform State Management & Ansible Playbooks
├── Module 4: Continuous Delivery & CI/CD Pipelines
│   └── Scenario: Git Hooks, Branching, & Blue-Green Deployments
├── Module 5: Monitoring, Logging, & SRE
│   └── Scenario: Prometheus Metrics & Grafana Alerting Setup
└── Module 6: Cloud Architecture & Testing
    └── Scenario: Resilience Testing with Chaos Mesh & Fault Injection
```

---

## F.5 Deployment & Maintenance Workflow

1. **Create Repository:** Store scenarios in a public or private GitHub repository.
2. **Connect to Killercoda:** Link your GitHub account to the [Killercoda Creator Portal](https://killercoda.com/creator).
3. **Automate Updates:** Any `git push` to your default branch automatically updates the live interactive scenario on Killercoda within seconds.
4. **Validation:** Run local linting on your JSON and Shell scripts before pushing to ensure zero environment build failures.
