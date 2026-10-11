# Appendix D: Full-Length Practice Examination (LPI 701-200)

## D.1. Practice Exam Overview & Guidelines

This full-length practice examination simulates the structure, scope, and technical depth of the **LPI DevOps Tools Engineer (701-200)** certification exam.

* **Total Questions:** 60 scenario-based, multiple-choice questions
* **Time Allowed:** 90 minutes
* **Passing Score:** ~70% (42 out of 60 correct answers)
* **Objective Coverage:** Topics 701.1 through 706.3
* **Exam Strategy:** Each question presents a realistic enterprise operational scenario testing CLI commands, syntax, configuration schemas, architecture patterns, and troubleshooting techniques.

---

## D.2. Exam Simulation: 60 Scenario-Based Questions

### Domain 1: Modern Software Development & DevOps Principles (701.1–701.3)

#### Question 1 (Objective 701.1)
An enterprise software organization is adopting Continuous Delivery. Which operational metric best measures the engineering pipeline's agility and time-to-market efficiency?
A. Mean Time Between Failures (MTBF)  
B. Lead Time for Changes  
C. Service Level Objective (SLO) margin  
D. Total Cost of Ownership (TCO)  

#### Question 2 (Objective 701.2)
A platform team wants to implement a zero-downtime deployment strategy where production traffic is gradually shifted from version 1.0 to version 2.0 based on health metrics. Which deployment pattern should be used?
A. Blue/Green Deployment  
B. Canary Deployment  
C. Recreate Deployment  
D. In-Place Update  

#### Question 3 (Objective 701.3)
Which Twelve-Factor App principle dictates that application instances must be stateless and share nothing, relying on external stateful services for persistent data?
A. Factors III & IV (Config & Backing Services)  
B. Factor VI (Processes)  
C. Factor IX (Disposability)  
D. Factor XI (Logs)  

---

### Domain 2: Container Management & Orchestration (702.1–702.5)

#### Question 4 (Objective 702.1)
An engineer needs to build an OCI container image while ensuring build-time secrets are not leaked into intermediate layer history. Which Docker command flag and feature should be utilized?
A. `docker build --build-arg SECRET=value .`  
B. `docker build --secret id=mysecret,src=secret.txt .` with BuildKit enabled  
C. `docker run -v secret.txt:/tmp/secret.txt`  
D. `docker commit --change "ENV SECRET=value"`  

#### Question 5 (Objective 702.1)
What is the primary benefit of using multi-stage builds in Dockerfiles for enterprise applications?
A. It enables parallel execution of containers at runtime.  
B. It separates compile-time dependencies from runtime dependencies to minimize total image footprint and vulnerability surface area.  
C. It permits non-root user creation automatically across image layers.  
D. It forces Docker to ignore `.dockerignore` files during execution.  

#### Question 6 (Objective 702.2)
You need to inspect detailed resource consumption (CPU %, Memory usage, Network I/O) for all active Docker containers in real time without continuous output scrolling. Which command achieves this?
A. `docker inspect --format='{{.State.Health}}'`  
B. `docker stats --no-stream`  
C. `docker top <container_id>`  
D. `docker events --filter type=container`  

#### Question 7 (Objective 702.2)
Which Docker CLI command removes all stopped containers, unused networks, unreferenced images, and dangling build cache in a single non-interactive operation?
A. `docker container rm -f $(docker ps -aq)`  
B. `docker system prune --all --force`  
C. `docker image rm --all`  
D. `docker volume rm $(docker volume ls -q)`  

#### Question 8 (Objective 702.3)
In Kubernetes architecture, which core control plane component maintains the primary datastore for cluster state, configuration data, and object metadata?
A. `kube-apiserver`  
B. `etcd`  
C. `kube-scheduler`  
D. `kube-controller-manager`  

#### Question 9 (Objective 702.3)
Which `kubectl` command retrieves the internal IP addresses and container runtime versions of all nodes formatted as custom JSON outputs?
A. `kubectl describe nodes`  
B. `kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'`  
C. `kubectl get nodes --show-labels`  
D. `kubectl get pods -o wide`  

#### Question 10 (Objective 702.4)
A developer needs to execute an interactive shell inside a running container named `app-container` residing in pod `backend-pod` under namespace `staging`. Which command is correct?
A. `kubectl exec -it backend-pod -c app-container -n staging -- /bin/sh`  
B. `kubectl debug pod/backend-pod -n staging --shell`  
C. `kubectl attach backend-pod -c app-container -n staging`  
D. `kubectl run -it app-container --image=alpine -- /bin/sh`  

#### Question 11 (Objective 702.4)
What happens when a Pod’s readiness probe fails continuously in a production Kubernetes deployment?
A. The container is immediately terminated and restarted by the kubelet based on its `restartPolicy`.  
B. The Pod is deleted from the cluster and recreated by the Deployment controller.  
C. The Pod’s IP address is removed from the endpoints of associated Kubernetes Services, blocking incoming traffic.  
D. The node running the Pod is marked as `NotReady`.  

#### Question 12 (Objective 702.5)
You need to create a Kubernetes `NetworkPolicy` that denies all incoming traffic to pods with the label `app: secure-api` except from pods in the `ingress-nginx` namespace. Which policy specification attribute enforces this restriction?
A. `ingress.from.namespaceSelector`  
B. `egress.to.podSelector`  
C. `spec.podSelector.matchExpressions`  
D. `spec.ingress.ports.protocol`  

#### Question 13 (Objective 702.5)
Which Kubernetes object manages stateful applications by guaranteeing ordering, unique network identifiers, and persistent storage bindings across pod reschedules?
A. Deployment  
B. DaemonSet  
C. StatefulSet  
D. ReplicaSet  

---

### Domain 3: Infrastructure as Code & Configuration Management (703.1–703.4)

#### Question 14 (Objective 703.1)
What is the primary operational objective of Infrastructure as Code (IaC) tools like Terraform and OpenTofu?
A. Replacing CI/CD pipeline triggers with shell scripts.  
B. Declaring cloud infrastructure states declaratively, ensuring reproducible and audit-compliant provisioning.  
C. Encrypting system passwords before writing to server disk.  
D. Managing application log aggregation in real time.  

#### Question 15 (Objective 703.1)
An engineer refactors a Terraform root module into child modules. Running `terraform plan` shows that Terraform intends to destroy existing production cloud instances and recreate them under the new module paths. Which state command prevents infrastructure destruction during refactoring?
A. `terraform state rm`  
B. `terraform state mv`  
C. `terraform refresh`  
D. `terraform state push`  

#### Question 16 (Objective 703.2)
In OpenTofu / Terraform configuration, how do you mark sensitive variables so that their values are masked in plan and apply terminal outputs?
A. Set `encrypted = true` in `versions.tf`.  
B. Define `sensitive = true` within the `variable` configuration block.  
C. Wrap the variable in `vault_read()` functions.  
D. Rename the variable file to `.env.tf`.  

#### Question 17 (Objective 703.2)
Which command imports a pre-existing cloud resource (e.g., AWS EC2 instance `i-0abcdef1234567890`) into Terraform state under the resource identifier `aws_instance.legacy_web`?
A. `terraform import aws_instance.legacy_web i-0abcdef1234567890`  
B. `terraform state add aws_instance.legacy_web i-0abcdef1234567890`  
C. `terraform plan -import=i-0abcdef1234567890`  
D. `terraform apply -target=aws_instance.legacy_web`  

#### Question 18 (Objective 703.3)
How does Ansible execute tasks on remote Linux managed nodes?
A. By maintaining a continuous master-agent daemon connection over gRPC.  
B. By pushing Python code modules via standard SSH connections, executing them, and removing temporary files.  
C. By installing the `ansible-engine` package on every managed node prior to playbook runs.  
D. By mounting host local storage over NFS.  

#### Question 19 (Objective 703.3)
An Ansible playbook run must execute a task only if a previous package installation task triggered a state change. Which Ansible keyword mechanism controls this workflow?
A. `when: result.changed`  
B. `notify` linked to a `handlers` block  
C. `failed_when` override  
D. `block` / `rescue` structure  

#### Question 20 (Objective 703.4)
Which Ansible Vault command encrypts a single sensitive string variable for inline insertion into a `group_vars/all.yml` file?
A. `ansible-vault encrypt_string`  
B. `ansible-vault encrypt`  
C. `ansible-vault view`  
D. `ansible-vault rekey`  

#### Question 21 (Objective 703.4)
You run an Ansible playbook using `ansible-playbook -i production hosts.yml --check --diff`. What effect does this execution have?
A. It executes tasks and permanently commits changes to managed hosts while logging differences.  
B. It performs a dry run without applying changes to remote hosts, printing structural and configuration differences.  
C. It checks the syntax of the inventory file and exits immediately.  
D. It encrypts all plain-text files using Ansible Vault.  

---

### Domain 4: Version Control & CI/CD Pipelines (704.1–704.4)

#### Question 22 (Objective 704.1)
An engineer needs to isolate a bug introduced in a project repository containing over 500 commits. Which Git command automates binary search across commit history using test script execution?
A. `git reflog`  
B. `git bisect`  
C. `git log --graph`  
D. `git blame`  

#### Question 23 (Objective 704.1)
What action does `git cherry-pick <commit-hash>` perform?
A. It merges an entire remote branch into the current working branch.  
B. It applies the specific changes introduced by an individual commit onto the current branch as a new commit.  
C. It reverts the changes made in `<commit-hash>` and deletes the commit from history.  
D. It resets the working directory to match `<commit-hash>`.  

#### Question 24 (Objective 704.2)
A branch commit was lost after a force push (`git reset --hard HEAD~3`). How can an engineer recover the lost commit SHA on their local workstation?
A. By executing `git reflog` to locate the unreferenced commit hash, then creating a new branch from it.  
B. By running `git fsck --lost-found` to delete bad objects.  
C. By issuing `git pull --rebase origin main`.  
D. Recovery is impossible after `git reset --hard`.  

#### Question 25 (Objective 704.3)
In GitLab CI/CD architecture, what component executes the jobs defined in `.gitlab-ci.yml`?
A. GitLab Server Engine  
B. GitLab Runner  
C. GitLab Agent for Kubernetes  
D. Runner Daemon Controller  

#### Question 26 (Objective 704.3)
Which section of a `.gitlab-ci.yml` manifest ensures that job steps run only when a commit is pushed to the `main` branch?
A. `only: branches` or `rules: - if: '$CI_COMMIT_BRANCH == "main"'`  
B. `stage: deploy`  
C. `environment: production`  
D. `artifacts: paths`  

#### Question 27 (Objective 704.4)
In GitHub Actions workflows, how are sensitive secrets safely injected into job steps?
A. By checking plain-text variables into `.github/workflows/main.yml`.  
B. Reference them using `${{ secrets.SECRET_NAME }}` after defining them in the repository settings.  
C. Hardcoding secrets in repository environment files.  
D. Encrypting the entire `.github` folder using GPG.  

#### Question 28 (Objective 704.4)
Which Jenkinsfile pipeline block specifies environment-wide execution rules, agent nodes, and global stage definitions in Jenkins Declarative syntax?
A. `node { }`  
B. `pipeline { agent any; stages { } }`  
C. `script { }`  
D. `buildStep { }`  

---

### Domain 5: Observability, Logging & Monitoring (705.1–705.3)

#### Question 29 (Objective 705.1)
Which Prometheus metric type represents a monotonically increasing counter that can only increase or reset to zero on restart?
A. Gauge  
B. Counter  
C. Histogram  
D. Summary  

#### Question 30 (Objective 705.1)
Which PromQL query calculates the overall 5-minute per-second average rate of HTTP server errors (HTTP status codes matching `5xx`) across all instances?
A. `sum(rate(http_requests_total{status=~"5.."}[5m]))`  
B. `http_requests_total{status="500"} / 5m`  
C. `count_over_time(http_requests_total[5m])`  
D. `increase(http_requests_total{status="500"})`  

#### Question 31 (Objective 705.2)
In Prometheus architecture, how are active monitoring targets primarily discovered in dynamic cloud-native environments?
A. Static IP address lists defined in `alertmanager.yml`.  
B. Service Discovery mechanisms (`sd_configs` such as `kubernetes_sd_configs` or `aws_ec2_sd_configs`).  
C. Pushing metrics via Pushgateway on every node.  
D. Querying Grafana dashboards via REST API.  

#### Question 32 (Objective 705.2)
What is the function of Prometheus Alertmanager in an enterprise observability pipeline?
A. It executes PromQL queries against raw log files.  
B. It handles alert deduplication, grouping, inhibition, and routing to notification channels (PagerDuty, Slack, Email).  
C. It stores historical metric time-series data permanently on object storage.  
D. It generates synthetic HTTP traffic for availability monitoring.  

#### Question 33 (Objective 705.3)
In Grafana Loki log aggregation system, what query language is used to stream, filter, and parse log lines?
A. PromQL  
B. LogQL  
C. SQL  
D. Flux  

#### Question 34 (Objective 705.3)
Which LogQL expression streams logs from namespace `production`, selects app `auth-service`, and filters lines containing the word `"CRITICAL"`?
A. `{namespace="production", app="auth-service"} |= "CRITICAL"`  
B. `select * from logs where app='auth-service' and level='CRITICAL'`  
C. `rate({app="auth-service"}[5m]) > 0`  
D. `{namespace="production"} + "CRITICAL"`  

---

### Domain 6: Security, Compliance & System Hardening (706.1–706.3)

#### Question 35 (Objective 706.1)
Which security concept dictates that system accounts, services, and pipeline execution tokens must be granted only the minimum permissions required to perform their designated function?
A. Defense in Depth  
B. Least Privilege  
C. Zero Trust Architecture  
D. Continuous Integration  

#### Question 36 (Objective 706.1)
An enterprise security audit mandates blocking cloud metadata endpoint access (`169.254.169.254`) from application containers running in Kubernetes. How can this be enforced at the network level?
A. Define an egress `NetworkPolicy` excluding `169.254.169.254/32`.  
B. Set `readOnlyRootFilesystem: true` in the deployment pod spec.  
C. Remove `curl` from the container image.  
D. Disable container logging.  

#### Question 37 (Objective 706.2)
Which tool perform static security scanning of container images to identify known vulnerabilities (CVEs) prior to deployment?
A. Trivy  
B. Ansible Vault  
C. Prometheus  
D. Terraform  

#### Question 38 (Objective 706.2)
Which Linux kernel security module feature limits system call access for container processes in Kubernetes workloads?
A. AppArmor / Seccomp profiles  
B. Systemd service slices  
C. iptables chains  
D. PAM (Pluggable Authentication Modules)  

#### Question 39 (Objective 706.3)
In HashiCorp Vault architecture, what mechanism provides dynamic, short-lived database credentials for microservices?
A. Static Secret Engine  
B. Dynamic Database Secrets Engine  
C. Transit Secrets Engine  
D. PKI Secrets Engine  

#### Question 40 (Objective 706.3)
How can developers prevent accidental commits of API keys or private keys into Git version control repositories?
A. Configure pre-commit hooks using secret detection tools like `gitleaks` or `trufflehog`.  
B. Compress repository files using zip encryption.  
C. Never use branches other than `main`.  
D. Use `git commit --no-verify`.  

---

### Additional Comprehensive Scenario Questions (Questions 41–60)

#### Question 41 (Objective 702.1)
What is the effect of the Dockerfile instruction `STOPSIGNAL SIGINT`?
A. It causes the container to immediately crash on startup.  
B. It configures the system call signal that will be sent to the container process when issuing `docker stop`.  
C. It blocks container exit signals from host systems.  
D. It restarts the container automatically upon receiving network errors.  

#### Question 42 (Objective 702.2)
An engineer needs to link a local volume `/var/log/app` on the host to `/app/logs` inside a container with read-only permissions. Which `--mount` flag syntax is correct?
A. `--mount type=bind,source=/var/log/app,target=/app/logs,readonly`  
B. `-v /var/log/app:/app/logs:rw`  
C. `--volume-mount /var/log/app:/app/logs`  
D. `--storage-bind /app/logs`  

#### Question 43 (Objective 702.3)
In Kubernetes, what is the role of `kube-proxy` running on worker nodes?
A. Maintaining persistent disk attachments.  
B. Managing network routing, packet filtering, and load balancing for Kubernetes Services on each node.  
C. Compiling container images locally.  
D. Managing cluster DNS record registration.  

#### Question 44 (Objective 702.4)
You want to apply a rolling restart to a Kubernetes deployment named `web-api` in namespace `prod`. Which command executes this gracefully?
A. `kubectl delete deployment web-api -n prod`  
B. `kubectl rollout restart deployment/web-api -n prod`  
C. `kubectl scale deployment web-api --replicas=0 -n prod`  
D. `kubectl replace -f deployment.yaml --force`  

#### Question 45 (Objective 702.5)
Which field in a Kubernetes Pod spec prevents privilege escalation by stopping processes from gaining more privileges than their parent process?
A. `allowPrivilegeEscalation: false`  
B. `runAsNonRoot: true`  
C. `readOnlyRootFilesystem: true`  
D. `privileged: false`  

#### Question 46 (Objective 703.2)
In OpenTofu / Terraform, what happens when you run `tofu refresh`?
A. It updates state file metadata to align with actual infrastructure without updating resource configurations.  
B. It overwrites cloud resources with state file values.  
C. It deletes unused state files.  
D. It destroys all infrastructure in the workspace.  

#### Question 47 (Objective 703.3)
In an Ansible directory structure, where should common variables shared across all target hosts be defined?
A. `host_vars/localhost.yml`  
B. `group_vars/all.yml`  
C. `roles/common/handlers/main.yml`  
D. `ansible.cfg`  

#### Question 48 (Objective 703.4)
An engineer needs to run an Ansible playbook using a custom SSH private key located at `~/.ssh/prod_id_rsa`. Which command line flag overrides default SSH key selection?
A. `--private-key ~/.ssh/prod_id_rsa`  
B. `--key-file ~/.ssh/prod_id_rsa`  
C. `-u root`  
D. `--vault-password-file`  

#### Question 49 (Objective 704.1)
Which Git command combines all commits from a feature branch into a single clean commit on the destination branch during integration?
A. `git merge --squash`  
B. `git rebase --no-ff`  
C. `git checkout -b`  
D. `git cherry-pick --all`  

#### Question 50 (Objective 704.2)
You need to temporarily save uncommitted local changes on a working directory without committing them, switch branches, and apply those changes back later. Which Git command sequence achieves this?
A. `git stash` then `git stash pop`  
B. `git reset --soft` then `git pull`  
C. `git commit -m "temp"` then `git revert`  
D. `git clean -fd`  

#### Question 51 (Objective 704.3)
In GitLab CI/CD, what is the purpose of caching (`cache:`) versus artifacts (`artifacts:`)?
A. Cache stores build dependencies across pipeline runs to speed up build jobs; artifacts store final build outputs shared between stages in the same pipeline.  
B. Cache is permanent; artifacts are deleted immediately after job completion.  
C. Cache is used only for docker images; artifacts are used for text logs.  
D. There is no operational difference between cache and artifacts.  

#### Question 52 (Objective 704.4)
In GitHub Actions, how do you pass data between sequential steps inside the same job execution?
A. By writing outputs to `$GITHUB_OUTPUT` environment file.  
B. Using global operating system environment variables.  
C. Modifying `.git/config`.  
D. Uploading data to external S3 buckets.  

#### Question 53 (Objective 705.1)
What type of metric calculation does the PromQL function `histogram_quantile(0.95, ...)` perform?
A. It measures total packet drops over time.  
B. It computes the estimated $95^{\text{th}}$ percentile value from metric histogram buckets (e.g., latency measurements).  
C. It counts total HTTP request failures.  
D. It predicts memory usage 95 minutes in the future.  

#### Question 54 (Objective 705.2)
In Prometheus Alertmanager, what does the `inhibition` rule configuration achieve?
A. It suppresses specific alert notifications if another related higher-priority alert is already active.  
B. It automatically restarts failing containers.  
C. It deletes metrics from disk.  
D. It routes alerts exclusively via email.  

#### Question 55 (Objective 705.3)
In Grafana Loki, which component is responsible for parsing log lines, extracting labels, and forwarding log streams to the Loki storage backend?
A. Promtail (or Alloy)  
B. FluentBit Agent  
C. Prometheus Server  
D. Alertmanager  

#### Question 56 (Objective 706.1)
What security vulnerability occurs when container workloads are executed as default `root` user without namespace remapping?
A. A container break-out exploit could allow unprivileged processes to gain root access on the underlying host node.  
B. Containers cannot open network ports.  
C. Container images double in disk size.  
D. Kubernetes deployments fail to schedule.  

#### Question 57 (Objective 706.2)
What is the primary function of static application security testing (SAST) tools integrated into CI/CD pipelines?
A. Scanning compiled container binaries during production runtime.  
B. Analyzing source code for security vulnerabilities, bad coding practices, and hardcoded secrets before compilation.  
C. Simulating Distributed Denial of Service (DDoS) attacks.  
D. Generating TLS certificates automatically.  

#### Question 58 (Objective 706.3)
Which authentication method allows Kubernetes workloads to authenticate seamlessly with HashiCorp Vault using native ServiceAccount tokens?
A. Kubernetes Auth Method  
B. Userpass Auth Method  
C. GitHub OAuth  
D. AppRole Auth Method  

#### Question 59 (Objective 701.2)
In continuous deployment architectures, what is "Blue/Green" deployment?
A. Updating application instances one node at a time in place.  
B. Maintaining two identical production environments (Blue and Green), where one serves live production traffic while the other is updated and verified before switching router traffic instantly.  
C. Deploying software exclusively to staging servers.  
D. Merging code into main branch without automated testing.  

#### Question 60 (Objective 703.1)
Why is maintaining state locking essential when managing Terraform / OpenTofu state files in enterprise remote backends (e.g., AWS S3 with DynamoDB)?
A. To speed up execution times.  
B. To prevent concurrent execution runs from corrupting or causing race conditions in state data.  
C. To reduce cloud storage costs.  
D. To compress state files automatically.  

---

## D.3. Detailed Answer Explanations, Domain Mapping, & Topic Weighting Analysis

### Exam Domain Weighting Distribution

| Domain | Exam Weighting (%) | Target Question Count |
| :--- | :--- | :--- |
| **Domain 1: Modern Software Development & DevOps** | 15% | 9 Questions |
| **Domain 2: Container Management & Orchestration** | 25% | 15 Questions |
| **Domain 3: Infrastructure as Code & Automation** | 20% | 12 Questions |
| **Domain 4: Version Control & CI/CD Pipelines** | 20% | 12 Questions |
| **Domain 5: Observability, Logging & Monitoring** | 10% | 6 Questions |
| **Domain 6: Security, Compliance & System Hardening** | 10% | 6 Questions |
| **Total** | **100%** | **60 Questions** |

---

### Answer Key & Explanations

1. **B** (Obj 701.1): *Lead Time for Changes* (the time elapsed from code commit to production deployment) measures pipeline speed and organizational agility.
2. **B** (Obj 701.2): *Canary Deployment* routes a small percentage of traffic to the new version to validate metrics before full rollout.
3. **B** (Obj 701.3): *Factor VI (Processes)* dictates that apps must execute as stateless, share-nothing processes.
4. **B** (Obj 702.1): BuildKit (`--secret`) mounts secrets during build time without storing them in image layer history.
5. **B** (Obj 702.1): Multi-stage builds keep runtime images minimal by leaving build tools in build-stage layers.
6. **B** (Obj 702.2): `docker stats --no-stream` returns a single snapshot table of container resource usage.
7. **B** (Obj 702.2): `docker system prune --all --force` cleans all unused container state and dangling cache.
8. **B** (Obj 702.3): `etcd` is the consistent and highly available key-value store for all Kubernetes cluster data.
9. **B** (Obj 702.3): JSONPath queries allow filtering specific status array fields like `InternalIP`.
10. **A** (Obj 702.4): `kubectl exec -it` attaches an interactive tty to a specified pod container.
11. **C** (Obj 702.4): Readiness failures cause the endpoint controller to strip the pod IP from service routing.
12. **A** (Obj 702.5): `namespaceSelector` matches source namespaces for ingress traffic rules in NetworkPolicies.
13. **C** (Obj 702.5): `StatefulSet` provides sticky identities, ordered deployment, and dedicated PV volumes.
14. **B** (Obj 703.1): IaC allows declarative infrastructure provisioning that is reproducible and auditable.
15. **B** (Obj 703.1): `terraform state mv` refactors state resource addresses without altering real resources.
16. **B** (Obj 703.2): `sensitive = true` prevents variable output logging in CLI terminal output.
17. **A** (Obj 703.2): `terraform import <resource_address> <id>` binds remote resources to state.
18. **B** (Obj 703.3): Ansible is agentless; it executes temporary Python scripts over standard SSH.
19. **B** (Obj 703.3): Tasks issue `notify` calls that run `handlers` only when state changes occur.
20. **A** (Obj 703.4): `ansible-vault encrypt_string` creates encrypted inline vault strings.
21. **B** (Obj 703.4): `--check --diff` performs a dry run and outputs exact file changes without altering target systems.
22. **B** (Obj 704.1): `git bisect` uses binary search to pinpoint specific regression-introducing commits.
23. **B** (Obj 704.1): `git cherry-pick` extracts a specific commit patch and applies it to current `HEAD`.
24. **A** (Obj 704.2): `git reflog` tracks local HEAD pointer movements, enabling recovery of lost commits.
25. **B** (Obj 704.3): GitLab Runners are execution agents that process job scripts offloaded by GitLab.
26. **A** (Obj 704.3): `rules: - if: '$CI_COMMIT_BRANCH == "main"'` evaluates conditional branch execution.
27. **B** (Obj 704.4): `${{ secrets.SECRET_NAME }}` securely injects encrypted GitHub Actions secrets.
28. **B** (Obj 704.4): Declarative Jenkins syntax requires a root `pipeline` block containing `agent` and `stages`.
29. **B** (Obj 705.1): A `Counter` metric monotonically increments and resets only upon process restart.
30. **A** (Obj 705.1): Combining `sum()` with `rate()` calculates total global per-second request error rates over 5-minute windows.
31. **B** (Obj 705.2): Service discovery (`sd_configs`) allows Prometheus to dynamically watch cloud APIs for new targets.
32. **B** (Obj 705.2): Alertmanager manages notification routing, deduplication, silencing, and grouping.
33. **B** (Obj 705.3): Grafana Loki uses LogQL for log stream querying and label transformation.
34. **A** (Obj 705.3): LogQL uses stream selectors `{}` combined with filter operators (`|=`).
35. **B** (Obj 706.1): Least privilege restricts access strictly to the minimal bounds required for function.
36. **A** (Obj 706.1): NetworkPolicies with CIDR exceptions explicitly drop metadata target IPs (`169.254.169.254/32`).
37. **A** (Obj 706.2): Trivy scans container filesystem layers for CVE vulnerabilities.
38. **A** (Obj 706.2): Seccomp and AppArmor profiles filter restricted kernel system calls for processes.
39. **B** (Obj 706.3): Vault's Database secret engine dynamically provisions timed, unique DB credentials on demand.
40. **A** (Obj 706.3): Pre-commit hooks (`gitleaks`) block secret patterns prior to git commit creation.
41. **B** (Obj 702.1): `STOPSIGNAL` defines the system signal (e.g., `SIGINT`) sent when stopping containers.
42. **A** (Obj 702.2): `--mount type=bind` explicitly defines bind sources, targets, and read-only flags.
43. **B** (Obj 702.3): `kube-proxy` configures host iptables/IPVS rules to load balance cluster Service traffic.
44. **B** (Obj 702.4): `kubectl rollout restart` triggers a graceful rolling update without downscaling manually.
45. **A** (Obj 702.5): `allowPrivilegeEscalation: false` stops process child privilege elevation (SUID binaries).
46. **A** (Obj 703.2): `refresh` queries actual cloud APIs and updates state tracking to match reality.
47. **B** (Obj 703.3): `group_vars/all.yml` holds global inventory values across all groups.
48. **A** (Obj 703.4): `--private-key` specifies explicit identity files for Ansible SSH connections.
49. **A** (Obj 704.1): `git merge --squash` squashes feature branch histories into a single combined commit patch.
50. **A** (Obj 704.2): `git stash` saves uncommitted working copy state to a temporary stack.
51. **A** (Obj 704.3): Caches persist intermediate dependencies across runs; artifacts store output deliverables between stages.
52. **A** (Obj 504.4): Writing key-value pairs to `$GITHUB_OUTPUT` exposes step outputs to downstream steps.
53. **B** (Obj 705.1): `histogram_quantile` calculates quantile distributions from histogram metrics.
54. **A** (Obj 705.2): Alertmanager inhibition silences lower-severity alerts when matching higher-severity alerts trigger.
55. **A** (Obj 705.3): Promtail (or Grafana Alloy) tails local log files and ships them to Loki.
56. **A** (Obj 706.1): Root container breakout grants root access on the underlying node if namespaces aren't isolated.
57. **B** (Obj 706.2): SAST inspects source code for security flaws and hardcoded secrets statically prior to build.
58. **A** (Obj 706.3): Vault's Kubernetes auth engine validates service account JWT tokens natively against `kube-apiserver`.
59. **B** (Obj 701.2): Blue/Green maintains two separate full environment stacks, switching traffic instantly via load balancers.
60. **B** (Obj 703.1): State locking prevents race conditions and state file corruption during simultaneous execution runs.