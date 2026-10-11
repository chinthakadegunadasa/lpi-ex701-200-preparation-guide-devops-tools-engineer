# Appendix B: Comprehensive Tooling Command Matrix

This appendix serves as an authoritative, enterprise-grade command reference manual designed to cover the complete toolchain scope of the **LPI DevOps Tools Engineer (701-200)** certification. It provides practical, battle-tested syntax for day-two operations, troubleshooting, and infrastructure automation.

---

## B.1. Docker & Container Management CLI Quick Reference

Containerized environments require precise inspection, resource constraint tuning, and cache hygiene.

### 1. Advanced Container Inspection & Diagnostics
* **Inspect resource utilization across running containers:**
  ```bash
  docker stats --no-stream --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
  ```
* **Inspect low-level container metadata (JSON format with Go templates):**
  ```bash
  docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container_id>
  ```
* **Trace container filesystem changes (diff):**
  ```bash
  docker diff <container_id>
  ```

### 2. Storage and Network Management
* **Prune unused build cache and dangling volumes to reclaim storage:**
  ```bash
  docker system prune --all --volumes --force
  ```
* **Create an isolated user-defined bridge network with custom subnet:**
  ```bash
  docker network create --driver bridge --subnet 172.28.0.0/16 --gateway 172.28.0.1 devops_net
  ```

---

## B.2. Kubernetes (`kubectl`) Operations & Troubleshooting Matrix

Enterprise Kubernetes troubleshooting requires extracting precise telemetry and manipulating live cluster objects without destabilizing production workloads.

### 1. Diagnostics & Debugging
* **Execute an interactive diagnostic shell inside an ephemeral debug container attached to a pod:**
  ```bash
  kubectl debug -it <pod_name> --image=nicolaka/netshoot --target=<container_name>
  ```
* **Stream live logs from all containers within a deployment with timestamps:**
  ```bash
  kubectl logs deployment/<deployment_name> --all-containers=true --tail=100 -f --timestamps
  ```
* **Port-forward a backend service securely for local integration testing:**
  ```bash
  kubectl port-forward svc/<service_name> 8080:80 --namespace production
  ```

### 2. Advanced JSONPath & Go-Template Filtering
* **List all node internal IP addresses and kernel versions:**
  ```bash
  kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\t"}{.status.nodeInfo.kernelVersion}{"\n"}{end}'
  ```
* **Extract unready pods across all namespaces:**
  ```bash
  kubectl get pods --all-namespaces -o jsonpath='{range .items[?(@.status.phase!="Running")]}{.metadata.namespace}{"/"}{.metadata.name}{" - "}{.status.phase}{"\n"}{end}'
  ```

---

## B.3. Terraform / OpenTofu State Management Commands

State manipulation is critical when handling infrastructure drift, refactoring resource modules, or recovering from partial applies.

### 1. State Inspection & Migration
* **List all resources tracked in the remote state backend:**
  ```bash
  tofu state list
  ```
* **Inspect attribute values of a specific state resource:**
  ```bash
  tofu state show aws_instance.web_server[0]
  ```
* **Move a resource within state to refactor module hierarchies without destroying infrastructure:**
  ```bash
  tofu state mv aws_instance.legacy_node module.migrated_cluster.aws_instance.node
  ```

### 2. Emergency Recovery & Import
* **Remove a resource from state tracking without deleting actual cloud infrastructure:**
  ```bash
  tofu state rm aws_security_group.manual_override
  ```
* **Import an existing unmanaged cloud resource into Terraform/OpenTofu management:**
  ```bash
  tofu import aws_instance.web_server i-0123456789abcdef0
  ```

---

## B.4. Ansible Execution & Vault Command Reference

Executing playbooks in production requires strict verbosity control, dry runs, and secure handling of sensitive variables.

### 1. Enterprise Playbook Execution
* **Execute a playbook in dry-run (check) mode with high verbosity for debugging task impacts:**
  ```bash
  ansible-playbook -i inventories/production/hosts.ini site.yml --check --diff -vvv
  ```
* **Target a specific subset of hosts using patterns and limit flags:**
  ```bash
  ansible-playbook -i inventories/production/hosts.ini site.yml --limit "webservers:&dc-west" --tags "nginx,ssl"
  ```

### 2. Ansible Vault Lifecycle Management
* **Encrypt a sensitive secrets file in place:**
  ```bash
  ansible-vault encrypt inventories/production/group_vars/vault.yml --vault-password-file ~/.vault_pass.txt
  ```
* **View an encrypted vault file without saving plaintext to disk:**
  ```bash
  ansible-vault view inventories/production/group_vars/vault.yml --vault-password-file ~/.vault_pass.txt
  ```
* **Rekey an encrypted file with a new password key:**
  ```bash
  ansible-vault rekey inventories/production/group_vars/vault.yml
  ```

---

## B.5. Git Advanced Operations Reference

Managing messy history, isolating regressions, and surgical cherry-picking are vital competencies for CI/CD pipeline engineers.

### 1. History Exploration & Bisecting
* **Binary search through commit history to isolate a performance regression:**
  ```bash
  git bisect start
  git bisect bad HEAD
  git bisect good v1.2.0
  # Test code, then run: git bisect good (or bad)
  git bisect reset
  ```
* **Examine commit history with graph topologies and patch changes:**
  ```bash
  git log --all --graph --decorate --oneline --stat -n 20
  ```

### 2. Recovery, Reflog, and Patching
* **Recover a detached or accidentally deleted commit using the reference log:**
  ```bash
  git reflog
  git checkout -b recovered-branch HEAD@{2}
  ```
* **Apply a specific commit from another branch without merging the entire branch:**
  ```bash
  git cherry-pick -x <commit_sha>
  ```

---

## B.6. PromQL & LogQL Query Cheat Sheet

Observability relies on precise data extraction from Prometheus metrics and Grafana Loki log streams.

### 1. Prometheus PromQL Reference
* **Calculate the per-second HTTP request rate over a 5-minute sliding window:**
  ```promql
  sum(rate(http_requests_total{job="api-server"}[5m])) by (status, handler)
  ```
* **Compute high-percentile latency response times ($99^{\text{th}}$ percentile):**
  ```promql
  histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
  ```
* **Calculate instant CPU saturation ratio relative to total capacity:**
  ```promql
  1 - rate(node_cpu_seconds_total{mode="idle"}[5m])
  ```

### 2. Grafana Loki LogQL Reference
* **Stream and filter logs matching a specific container error keyword:**
  ```logql
  {job="kubernetes-pods", namespace="production"} |= "ERROR" != "healthcheck"
  ```
* **Extract structured JSON fields (e.g., status code) and filter numerically:**
  ```logql
  {app="payment-gateway"} | json | status_code >= 500
  ```
* **Calculate log event error frequency over a 1-minute interval:**
  ```logql
  sum(rate({namespace="kube-system"} |= "panic" [1m]))