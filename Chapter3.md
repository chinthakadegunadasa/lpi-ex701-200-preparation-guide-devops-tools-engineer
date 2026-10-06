<img width="1024" height="559" alt="image" src="https://github.com/user-attachments/assets/3da1142e-83ce-44e4-a8e4-75b0c8ecad43" /># Chapter 3: Enterprise DevSecOps & Security Compliance

## 3.1 Shift-Left Security Principles in CI/CD Pipelines

Shift-left security incorporates security practices, checks, and compliance audits early into the Software Development Life Cycle (SDLC) rather than treating security as an afterthought prior to production release. In enterprise CI/CD workflows, shifting left shifts vulnerability detection from late-stage manual penetration testing to automated pipeline stages.

![Shift-Left Security Pipeline Integration](assets/images/chapter3/3-1-Shift-Left-Security-Pipeline-Integration.png)

### Enterprise Security Gates and Automated Controls

Automated quality gates fail pipeline builds if predefined security baselines are breached. Key components include:

1. **Pre-commit Hooks:** Prevent sensitive information (API tokens, private keys) from entering git version history.
2. **Static Analysis Gates:** Enforce static analysis execution; fail builds on `CRITICAL` or `HIGH` Severity Vulnerability Findings.
3. **Software Bill of Materials (SBOM) Attestation:** Generate signed SBOMs during build time to guarantee package integrity.
4. **Automated Compliance Verification:** Use Infrastructure as Code (IaC) scanners like Checkov or Trivy to evaluate Terraform/Kubernetes manifests against CIS Benchmarks before deployment.

## 3.2 Static Application Security Testing (SAST) and Dynamic Scanning (DAST)

Securing modern application pipelines requires combining **Static Application Security Testing (SAST)** and **Dynamic Application Security Testing (DAST)**.

![SAST and DAST Execution Paradigms](assets/images/chapter3/3-2-Shift-Left-Security-Pipeline-Integration.png)

### Implementing SAST with SonarQube & Semgrep

Semgrep enables custom security rule enforcement using pattern-matching on abstract syntax trees (ASTs).

```yaml
# semgrep-rules/sql-injection.yaml
rules:
  - id: custom-python-sqli-check
    patterns:
      - pattern: cursor.execute(...)
      - pattern-either:
          - pattern: cursor.execute(f"...{$VAR}...")
          - pattern: cursor.execute("..." + $VAR)
    message: "Potential SQL Injection detected. Use parameterized queries instead."
    languages: [python]
    severity: ERROR
```

### Dynamic Scanning with OWASP ZAP

OWASP ZAP (Zed Attack Proxy) performs dynamic vulnerability scanning against exposed enterprise endpoints. ZAP runs in automation mode via CLI or Docker container during staging verification.

```bash
# Execute ZAP Baseline Scan against staging target
docker run -v $(pwd):/zap/wrk/:rw -t zaproxy/zap-stable zap-baseline.py \
  -t https://staging-api.internal.net \
  -g gen.conf \
  -r zap_report.html \
  -x zap_report.xml
```

## 3.3 Software Supply Chain Security & Dependency Vulnerability Scanning

Modern application frameworks rely heavily on third-party dependencies, creating a large attack surface across the software supply chain. Software Supply Chain Security focuses on tracking, validating, and auditing every external library and base container image.

![Supply Chain Verification and Container Attestation](assets/images/chapter3/3-3-Supply-Chain-Verification-and-Container-Attestation.png)

### Software Composition Analysis (SCA) & SBOM Generation

Generating a Software Bill of Materials (SBOM) provides visibility into nested dependencies and open-source licenses. Syft is widely used to generate industry-standard SPDX and CycloneDX formats.

```bash
# Generate CycloneDX SBOM for an application repository
syft dir:. -o cyclonedx-json=sbom.json

# Scan container image for OS and application dependencies using Trivy
trivy image --severity HIGH,CRITICAL --format table app-service:v1.2.0
```

### Container Image Attestation with Cosign

Cosign (part of the Sigstore project) cryptographically signs container images to prevent unauthorized or tampered artifacts from running in production environments.

```bash
# Generate keypair for container signing
cosign generate-key-pair

# Sign container image digest in registry
cosign sign --key cosign.key registry.internal.net/apps/order-service@sha256:d82e1c98a31...

# Verify image signature prior to deployment
cosign verify --key cosign.pub registry.internal.net/apps/order-service@sha256:d82e1c98a31...
```

## 3.4 Enterprise Secrets Management Standards

Hardcoding API keys, passwords, database credentials, or certificates in source code repository commits introduces severe security vulnerabilities. Enterprise secrets management replaces static credentials with dynamic, short-lived secrets stored in dedicated secret management systems (e.g., HashiCorp Vault).

![HashiCorp Vault Dynamic Secret Injection Topology](assets/images/chapter3/3-4-HashiCorp-Vault-Dynamic-Secret-Injection-Topology.png)

### HashiCorp Vault Integration Workflow

#### 1. Configure K8s Auth Method in Vault

```bash
# Enable K8s authentication backend in HashiCorp Vault
vault auth enable kubernetes

# Configure Vault to communicate with local Kubernetes cluster API
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

#### 2. Define Policy and Role
```hcl
# policy-app.hcl
path "secret/data/production/database" {
  capabilities = ["read"]
}
```

```bash
# Register policy and bind to Kubernetes service account
vault policy write app-policy policy-app.hcl

vault write auth/kubernetes/role/app-role \
    bound_service_account_names=payment-api-sa \
    bound_service_account_namespaces=production \
    policies=app-policy \
    ttl=1h
```

## 3.5 Hands-On Lab: Building a Complete SAST/DAST Vulnerability Scanning Pipeline

### Lab Scenario
You are assigned to build an automated DevSecOps security pipeline for a critical microservice. The pipeline must enforce strict security controls: detect hardcoded secrets using Gitleaks, perform SAST analysis via Semgrep, verify container dependencies with Trivy, sign the built artifact using Cosign, and execute a DAST baseline security scan against the staging application endpoint.

![Hands-On DevSecOps Pipeline Security Architecture](assets/images/chapter3/3-5-Hands-On-DevSecOps-Pipeline-Security-Architecture.png)

### Step-by-Step Implementation

#### Step 1: Pre-commit Secret Scanning Configuration (`.gitleaks.toml`)

```toml
# .gitleaks.toml - Custom Secret Detection Rules
title = "Enterprise Secret Scanner Configuration"

[[rules]]
id = "generic-api-key"
description = "Generic API Key Detection"
regex = '''(?i)(api_key|apikey|secret|token)\s*[:=]\s*["']([A-Za-z0-9_\-]{16,64})["']'''
tags = ["key", "generic"]

[[rules]]
id = "private-key"
description = "Unencrypted Private Key Detection"
regex = '''-----BEGIN PRIVATE KEY-----'''
tags = ["key", "crypto"]
```

#### Step 2: Complete DevSecOps Pipeline Definition (`.gitlab-ci.yml` / GitHub Actions equivalent)

```yaml
# .gitlab-ci.yml
stages:
  - secret-scan
  - sast
  - build-and-sca
  - sign
  - dast

variables:
  IMAGE_NAME: "registry.internal.net/devsecops/payment-service"
  IMAGE_TAG: "$CI_COMMIT_SHA"

# STAGE 1: Secret Scanning
secret_detection:
  stage: secret-scan
  image: zricethezav/gitleaks:latest
  script:
    - gitleaks detect --source=. --verbose --config=.gitleaks.toml

# STAGE 2: Static Application Security Testing
sast_semgrep:
  stage: sast
  image: returntocorp/semgrep:latest
  script:
    - semgrep scan --config=auto --error --output=semgrep-results.json --json .
  artifacts:
    reports:
      sast: semgrep-results.json

# STAGE 3: Build & Container Vulnerability Scanning
container_sca:
  stage: build-and-sca
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind
  script:
    - docker build -t $IMAGE_NAME:$IMAGE_TAG .
    - wget https://github.com/aquasecurity/trivy/releases/download/v0.45.0/trivy_0.45.0_Linux-64bit.tar.gz
    - tar -zxvf trivy_0.45.0_Linux-64bit.tar.gz && mv trivy /usr/local/bin/
    - trivy image --exit-code 1 --severity CRITICAL $IMAGE_NAME:$IMAGE_TAG
    - docker push $IMAGE_NAME:$IMAGE_TAG

# STAGE 4: Image Attestation / Signing
cosign_signing:
  stage: sign
  image: bitnami/cosign:latest
  script:
    - echo "$COSIGN_PRIVATE_KEY" > cosign.key
    - cosign sign --key cosign.key -y $IMAGE_NAME:$IMAGE_TAG

# STAGE 5: Dynamic Application Security Testing
dast_zap_scan:
  stage: dast
  image: zaproxy/zap-stable:latest
  script:
    - mkdir -p /zap/wrk
    - zap-baseline.py -t http://staging-payment.internal.net -g gen.conf -r zap_report.html || true
  artifacts:
    paths:
      - zap_report.html
```

#### Step 3: Verification & Pipeline Execution Results

1. Trigger pipeline execution by submitting a commit containing a test payload or pull request.
2. Monitor stage logs to ensure Gitleaks blocks any committed plain-text credentials.
3. Validate that Semgrep parses ASTs to flag insecure code constructs before image compilation.
4. Verify that Trivy halts deployment if base OS layers contain unpatched `CRITICAL` Common Vulnerabilities and Exposures (CVEs).
5. Inspect the generated OWASP ZAP HTML report (`zap_report.html`) for dynamic HTTP security header gaps, missing anti-CSRF tokens, or permissive CORS configurations.

### Key Exam Takeaways (LPI 701-200)

* **Shift-Left Paradigm:** Security checks must be integrated into early stages of development (IDE, pre-commit, pull requests) to lower remediation overhead and limit risk exposure.
* **SAST vs. DAST:** SAST analyzes source code without executing it (White-Box, early CI), whereas DAST evaluates running application binaries/endpoints (Black-Box, staging runtime).
* **Supply Chain Security:** Requires tracking dependencies with software composition analysis (SCA), enforcing Software Bill of Materials (SBOM) generation, and signing artifacts with tools like Cosign.
* **Secrets Management:** Enterprise environments must avoid static file-based secrets, using dynamic injection and lease management via centralized secret engines like HashiCorp Vault.
