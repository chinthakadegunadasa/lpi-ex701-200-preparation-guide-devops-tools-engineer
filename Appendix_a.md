# Appendix A: DevOps Toolchain Installation Protocols

This appendix provides production-ready, hands-on instructions for deploying, configuring, and maintaining an enterprise DevOps workstation on **Debian 13 (Trixie)**. Designed to meet and exceed the core operational standards of the **LPI DevOps Tools Engineer (701-200)** certification, this guide covers automated infrastructure bootstrapping, secure repository management, GPG key lifecycle handling, dependency locking, and container engine configuration.

---

## A.1. Automated Provisioning Script for Local Debian Workstations using Debian 13 Live image

In modern enterprise environments, manual workstation configuration introduces drift, security misconfigurations, and non-reproducible software stacks. Below is an enterprise-grade automated provisioning script (`provision-station.sh`) engineered to be executed from a clean Debian 13 Live image deployment. It bootstraps the complete 701-200 toolchain—including **Git**, **Docker CE**, **Podman**, **Kubectl**, **Helm**, and **Prometheus node exporters**—with strict error handling, idempotency checks, and structured logging.

### Enterprise Provisioning Script (`provision-station.sh`)

```bash
#!/usr/bin/env bash
# ==============================================================================
# Script Name: provision-station.sh
# Description: Automated DevOps Workstation Bootstrap for Debian 13 (Trixie)
# Target Scope: LPI 701-200 Exam & Enterprise Production Standards
# ==============================================================================

# Strict mode: Exit immediately on error, unset variables, and pipeline failures
set -euo pipefail
IFS=$'\n\t'

# Define logging functions
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $(date -u +'%Y-%m-%dT%H:%M:%SZ') - $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $(date -u +'%Y-%m-%dT%H:%M:%SZ') - $1" >&2
}

# Ensure script is run with root privileges
if [[ $EUID -ne 0 ]]; then
    log_error "This provisioning script must be executed with root privileges (sudo)."
    exit 1
fi

# Target non-root invoking user for group assignments
TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
log_info "Target non-root workstation user identified as: ${TARGET_USER}"

log_info "Step 1: Updating base system packages and installing foundational utilities..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    curl \
    git \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    ufw \
    jq \
    htop \
    tmux \
    make

log_info "Step 2: Configuring system security boundaries and firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

log_info "Step 3: Setting up upstream container and toolchain repositories..."
install -m 0755 -d /etc/apt/keyrings

# Docker GPG and Repository Setup
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Kubernetes Upstream (v1.30+) Repository Setup
KUBERNETES_VERSION="v1.30"
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

log_info "Step 4: Installing container runtimes, Podman, and orchestration CLIs..."
apt-get update -y
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    podman \
    buildah \
    skopeo \
    kubectl

log_info "Step 5: Installing Helm package manager..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

log_info "Step 6: Configuring group memberships and daemon runtimes..."
# Add target user to docker and podman groups
if id "${TARGET_USER}" &>/dev/null; then
    usermod -aG docker "${TARGET_USER}"
    usermod -aG sudo "${TARGET_USER}"
    log_info "User ${TARGET_USER} added to 'docker' and 'sudo' groups."
fi

# Configure Docker daemon with secure logging and OCI constraints
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl daemon-reload
systemctl enable --now docker
systemctl enable --now containerd

log_info "Step 7: Validating toolchain installations..."
docker --version
podman --version
kubectl version --client
helm version
git --version

log_info "Enterprise workstation provisioning completed successfully!"
```

---

## A.2. Package Repositories, Keys, and Dependency Management

In enterprise environments operating under strict compliance frameworks (such as SOC2, ISO 27001, or NIST), package installations cannot rely on blind execution or unverified public keys. Debian 13 introduces rigorous checks regarding repository structures and cryptographic verification.

### 1. Cryptographic Verification and Keyrings Lifecycle
Under Debian 13 and modern APT standards, legacy key placement in `/etc/apt/trusted.gpg` or `.gpg` ring files directly in `/etc/apt/trusted.gpg.d/` is deprecated due to global namespace pollution vulnerabilities. 

* **Best Practice:** Always place third-party repository GPG keys explicitly converted to binary format into `/etc/apt/keyrings/` and bind them explicitly using the `signed-by` attribute in source list files.

```bash
# Example explicit keyring association in /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.debian.com/linux/debian trixie stable
```

### 2. Package Pinning and Version Locking (`apt_pinning`)
To prevent unauthorized upstream breaking changes or unexpected minor-version upgrades during automated `apt-get upgrade` cycles in production pipelines, package pinning is enforced using `/etc/apt/preferences.d/`.

Create a preference pinning file `/etc/apt/preferences.d/devops-pins`:

```text
Package: docker-ce
Pin: version 26.0.*
Pin-Priority: 1001

Package: kubectl
Pin: version 1.30.*
Pin-Priority: 1001
```

* **Explanation of Pin-Priority Values:**
  * `P > 1000`: Causes a version to be installed even if this constitutes a version downgrade.
  * `990 <= P < 1000`: Causes a version to be installed even if it does not come from the target release, unless the target release version is already installed.
  * `500 <= P < 900`: Standard priority for packages from normal repositories.

### 3. Managing Dependencies and Cleaning Caches
In automated container build systems and Live image remastering pipelines, cache hygiene is critical to minimize disk footprints and vulnerability attack surfaces:

```bash
# Clean local package cache and remove obsolete packages
apt-get clean
apt-get autoclean
apt-get autoremove --purge -y

# Verify broken dependencies and verify system integrity
apt-get check
dpkg --audit
```

### Exam Key Takeaways for 701-200
1. **OCI Compliance:** Ensure your runtime engine (`docker` or `podman`) utilizes standards-compliant OCI image layers and secure overlay storage drivers (`overlay2`).
2. **Idempotency & Automation:** Write provisioning scripts that can run multiple times without failing or creating duplicate entries.
3. **Security Boundaries:** Never run container workloads or builds as root when unprivileged rootless modes (supported natively by Podman and Docker rootless) are available.
