# Chapter 3: Enterprise DevSecOps & Security Compliance

## 3.1 Shift-Left Security Principles in CI/CD Pipelines

Shift-Left Security integrates security practices, automated validation, and compliance policies early in the Software Development Life Cycle (SDLC). Rather than performing audit checks and penetration testing immediately prior to production deployment, security controls are embedded into developer IDEs, pre-commit hooks, pull request (PR) gating workflows, and continuous integration pipelines.

```
+--------------------------------------------------------------------------------------------------+
|                                  SHIFT-LEFT SECURITY ARCHITECTURE                                |
|                                                                                                  |
| [ IDE / Dev ] ----> [ Pre-Commit Hook ] ----> [ Pull Request Gate ] ----> [ Deployment Pipeline ]|
|       |                     |                         |                          |               |
|  IDE Linter           Secret Scanner             SAST & SCA Scanners       DAST & Runtime Policy |
|  & Formatting         (detect-secrets)           (SonarQube, Trivy)        (OWASP ZAP, OPA Gate) |
+--------------------------------------------------------------------------------------------------+
```

### DALL-E 3 Prompt: Shift-Left Security Architecture
> **DALL-E 3 Prompt:** A professional, technical architecture diagram titled "Shift-Left Security Architecture". Style & Aesthetics: Clean light-mode print style, minimal layout, crisp black vector line art on a stark white background with subtle slate-gray header highlights. Text labels use clear sans-serif typography, and inline commands use fixed-width code typography. Structure & Layout: A horizontal linear workflow showing four distinct stages connected by bold arrows: 1. "IDE / Dev" (containing sub-box "IDE Linter & Formatting"), 2. "Pre-Commit Hook" (containing sub-box "Secret Scanner"), 3. "Pull Request Gate" (containing sub-box "SAST & SCA Scanners"), and 4. "Deployment Pipeline" (containing sub-box "DAST & Runtime Policy"). High contrast, technical textbook schematic style.

---

### Security Control Matrix Across SDLC Stages

| SDLC Phase | Security Control | Primary Tooling | Enforcement Mechanism | Feedback Loop Target |
| :--- | :--- | :--- | :--- | :--- |
| **IDE / Local Dev** | Real-time SAST & Secret Linting | SonarLint, GitGuardian IDE Plugin | Local IDE Warning / Non-blocking | `< 5 Seconds` |
| **Pre-Commit** | Local Secret Detection & Formatter | `pre-commit`, `detect-secrets` | Git Hook Abort (Exit Code 1) | `< 2 Seconds` |
| **Pull Request (PR)**| Automated SAST, SCA, & License Check| SonarQube, Snyk, Trivy | Automated PR Status Check Block | `< 5 Minutes` |
| **Build & Package** | Container Image & Artifact Signing | Cosign, Syft, Grype | CI Pipeline Termination | `< 10 Minutes` |
| **Pre-Prod / Staging**| Dynamic App Security Testing (DAST)| OWASP ZAP, Nuclei | Automated Environment Rollback | `< 30 Minutes` |
| **Production** | Runtime Protection & Policy Control | Kyverno, Falco, OPA Gatekeeper | Pod Admission Deny / Alert | Real-Time (`< 1 Sec`) |

---

### DevSecOps Policy-as-Code Gating Model

In enterprise pipelines, security gates evaluate metrics returned by scanners against strict compliance policies using Policy-as-Code engines like Open Policy Agent (OPA).

```
                 +-----------------------------------+
                 |     Security Telemetry Input      |
                 | (SAST, SCA, Container Scans Json) |
                 +-----------------------------------+
                                   |
                                   v
+---------------------------------------------------------------------+
|                  Open Policy Agent Engine (Rego)                    |
|                                                                     |
|  * Block if Critical/High Vulnerabilities > 0                       |
|  * Block if Unapproved Software License (GPLv3) Detected            |
|  * Block if Plaintext Secrets/Keys Found                            |
+---------------------------------------------------------------------+
                                   |
                 +-----------------+-----------------+
                 |                                   |
                 v                                   v
      [ Policy Passed: 0 ]               [ Policy Violation: 1 ]
                 |                                   |
                 v                                   v
    Proceed to Deployment Stage          Pipeline Aborted & Jira
                                         Ticket Auto-Created
```

### DALL-E 3 Prompt: DevSecOps Policy-as-Code Gating Model
> **DALL-E 3 Prompt:** A professional technical diagram titled "DevSecOps Policy-as-Code Gating Model". Style & Aesthetics: Clean light-mode print style, stark white background with slate-gray fill accents, crisp black line art. Heading text uses clean sans-serif typography, and policy rules use monospace code typography. Structure & Layout: A vertical flowchart. Top box: "Security Telemetry Input (SAST, SCA, Container Scans Json)". Arrow down to a central processing block labeled "Open Policy Agent Engine (Rego)" listing three policy rules inside. Downward branching paths: Left path green arrow to "Policy Passed: 0" leading to "Proceed to Deployment Stage". Right path red arrow to "Policy Violation: 1" leading to "Pipeline Aborted & Jira Ticket Auto-Created". High-contrast schematic manual entry.

---

## 3.2 Static Application Security Testing (SAST) and Dynamic Scanning (DAST)

Enterprise vulnerability management requires combining Static Application Security Testing (SAST)—analyzing source code, bytecode, or binaries without execution—and Dynamic Application Security Testing (DAST)—testing running application endpoints for exploitable flaws.

```
+--------------------------------------------------------------------------------------------------+
|                                    SAST vs DAST COMPARISON                                       |
|                                                                                                  |
|             SAST (Static Analysis)               |              DAST (Dynamic Analysis)          |
|  +--------------------------------------------+  |  +--------------------------------------------+|
|  | * White-Box (Source Code / Bytecode)       |  |  | * Black-Box (Running HTTP/gRPC Endpoint)  ||
|  | * Execution Point: Build / PR Phase        |  |  | * Execution Point: Staging / Test Deploy   ||
|  | * Finds: SQLi, XSS, Hardcoded Credentials  |  |  | * Finds: Auth Flaws, CORS, Misconfigs     ||
|  | * High Speed, High False-Positive Potential|  |  | * Slower Execution, High Real-World Accuracy| |
|  +--------------------------------------------+  |  +--------------------------------------------+|
+--------------------------------------------------------------------------------------------------+
```

### DALL-E 3 Prompt: SAST vs DAST Comparison Diagram
> **DALL-E 3 Prompt:** A professional technical comparison diagram titled "SAST vs DAST Comparison". Style & Aesthetics: Clean light-mode print visual design, stark white background, vector black outlines, slate-gray heading bands. Labels use clean sans-serif typography, technical parameters use monospace code typography. Structure & Layout: Side-by-side 2-column layout. Left column titled "SAST (Static Analysis)" containing bulleted architectural features (White-Box, Build/PR Phase, SQLi/XSS detection). Right column titled "DAST (Dynamic Analysis)" containing bulleted runtime features (Black-Box, Staging/Test Deploy, Auth Flaws/CORS/Misconfigs). Crisp textbook graphic.

---

### Enterprise SAST Tooling Integration (SonarQube API & CLI)

In production pipelines, SAST tools process source code and transmit metrics to a central dashboard. Below is an enterprise SonarQube Scanner configuration (`sonar-project.properties`):

```properties
# Enterprise SonarQube Scanner Configuration
sonar.projectKey=enterprise-payment-service
sonar.projectName=Enterprise Payment Gateway Service
sonar.projectVersion=2.4.0

# Source & Binary Directories
sonar.sources=src/main/java
sonar.tests=src/test/java
sonar.java.binaries=target/classes

# Exclusions
sonar.exclusions=**/vendor/**,**/*_test.go,**/autogen/**
sonar.coverage.exclusions=**/config/**,**/dto/**

# Quality Gate Threshold Limits
sonar.qualitygate.wait=true
sonar.ws.timeout=60
```

#### Executing SonarScanner in Dockerized CI Runner
```bash
docker run --rm \
  -e SONAR_HOST_URL="https://sonarqube.internal.net" \
  -e SONAR_TOKEN="sqp_a8b9c7d6e5f43210123456789abcdef012345678" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey="enterprise-payment-service" \
  -Dsonar.qualitygate.wait=true
```

---

### Enterprise DAST Tooling Integration (OWASP ZAP Automation)

DAST scanners attack dynamic environments to identify runtime vulnerabilities. The following Python baseline script controls OWASP ZAP via its REST API:

```python
#!/usr/bin/env python3
"""
Enterprise DAST Automation Script utilizing OWASP ZAP API.
Executes Contextual Spidering and Active Scanning against target staging environment.
"""

import time
import sys
import json
from zapv2 import ZAPv2

ZAP_PROXY_URL = "http://zap.security.svc.cluster.local:8080"
ZAP_API_KEY = "env_zap_api_key_secret_89213"
TARGET_URL = "https://staging-payment.internal.net"

# Initialize ZAP Client
zap = ZAPv2(proxies={'http': ZAP_PROXY_URL, 'https': ZAP_PROXY_URL}, apikey=ZAP_API_KEY)

def run_dast_scan(target: str):
    print(f"[+] Starting DAST Spider Scan for: {target}")
    scan_id = zap.spider.scan(target)
    
    while int(zap.spider.status(scan_id)) < 100:
        print(f"[*] Spider progress: {zap.spider.status(scan_id)}%")
        time.sleep(5)
    print("[+] Spider scan complete.")

    print(f"[+] Starting Active Scanner for: {target}")
    active_scan_id = zap.ascan.scan(target)
    
    while int(zap.ascan.status(active_scan_id)) < 100:
        print(f"[*] Active Scan progress: {zap.ascan.status(active_scan_id)}%")
        time.sleep(10)
    print("[+] Active Scan complete.")

    # Evaluate High and Critical Vulnerabilities
    alerts = zap.core.alerts(baseurl=target)
    critical_high_alerts = [
        a for a in alerts if a['risk'] in ['High', 'Critical']
    ]

    if critical_high_alerts:
        print(f"[!] SECURITY GATE FAILURE: Found {len(critical_high_alerts)} High/Critical alerts!")
        for alert in critical_high_alerts:
            print(f"    - [{alert['risk']}] {alert['alert']} at URL: {alert['url']}")
        sys.exit(1)
    
    print("[+] DAST Security Gate Passed Successfully.")
    sys.exit(0)

if __name__ == "__main__":
    run_dast_scan(TARGET_URL)
```

---

## 3.3 Software Supply Chain Security & Dependency Vulnerability Scanning

Modern applications consist of up to 80% open-source third-party dependencies. Software Supply Chain Security focuses on securing dependencies, generating Software Bill of Materials (SBOM), and cryptographically signing artifacts.

```
+--------------------------------------------------------------------------------------------------+
|                             SOFTWARE SUPPLY CHAIN SECURITY PIPELINE                              |
|                                                                                                  |
| [ Source Code ] ---> [ Dependency Scan ] ---> [ Container Build ] ---> [ SBOM Generation ]       |
|                            (Trivy/Snyk)            (Docker)                 (Syft)               |
|                                                                               |                  |
|                                                                               v                  |
| [ Deployment Gate ] <--- [ OPA Verification ] <--- [ OCI Registry ] <--- [ Artifact Signing ]    |
|   (Kyverno/OPA)             (Cosign)              (Harbor/ECR)             (Cosign)              |
+--------------------------------------------------------------------------------------------------+
```

### DALL-E 3 Prompt: Software Supply Chain Pipeline Diagram
> **DALL-E 3 Prompt:** A professional, technical architecture diagram titled "Software Supply Chain Security Pipeline". Style & Aesthetics: Clean light-mode print style, minimal vector artwork on a white background with gray accents. Labels use clear sans-serif typography, and tooling/commands use monospace code typography. Structure & Layout: A cyclical horizontal workflow connecting 7 blocks with directional arrows: 1. "Source Code", 2. "Dependency Scan (Trivy/Snyk)", 3. "Container Build (Docker)", 4. "SBOM Generation (Syft)", 5. "Artifact Signing (Cosign)", 6. "OCI Registry (Harbor/ECR)", 7. "OPA Verification (Cosign)", returning to "Deployment Gate (Kyverno/OPA)". Technical schematic manual entry.

---

### Generating and Attesting SBOM (Software Bill of Materials) using Syft

An SBOM provides an inventory of all open-source components, modules, and libraries embedded within a build artifact.

#### Command: Generating SPDX SBOM JSON
```bash
# Generate SBOM in SPDX-JSON format for a container image
syft packages enterprise-payment-service:v2.4.0 \
  -o spdx-json \
  --file ./artifacts/sbom.spdx.json
```

#### Syft Output Snippet (`sbom.spdx.json`)
```json
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "enterprise-payment-service-v2.4.0",
  "packages": [
    {
      "name": "org.springframework.boot:spring-boot-starter-web",
      "SPDXID": "SPDXRef-Package-java-maven-org.springframework.boot-spring-boot-starter-web-3.1.2",
      "versionInfo": "3.1.2",
      "downloadLocation": "NOASSERTION",
      "filesAnalyzed": false,
      "licenseConcluded": "Apache-2.0",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:maven/org.springframework.boot/spring-boot-starter-web@3.1.2"
        }
      ]
    }
  ]
}
```

---

### Signing and Verifying Container Artifacts using Sigstore Cosign

Cryptographic artifact signing guarantees image integrity and non-repudiation between the build environment and deployment cluster.

```
       +--------------------+
       |  Container Image   |
       | (v2.4.0 Digest)    |
       +--------------------+
                 |
                 v
+----------------------------------+      +--------------------+
|   Cosign Keyless Signing Engine  | <--- |   OIDC Token /     |
|   (Fulcio CA & Rekor Ledger)     |      | GitHub Workflows   |
+----------------------------------+      +--------------------+
                 |
                 v
+----------------------------------+
| Signed OCI Container Signature   |
| Stored in Container Registry     |
+----------------------------------+
```

### DALL-E 3 Prompt: Artifact Signing and Verification Architecture
> **DALL-E 3 Prompt:** A professional technical diagram titled "Artifact Signing and Verification Architecture". Style & Aesthetics: Clean light-mode visual design, stark white background, crisp vector lines, slate-gray header styling. Labels use clean sans-serif typography, and cryptographic references use monospace code typography. Structure & Layout: Central top block "Container Image (v2.4.0 Digest)" pointing down to "Cosign Keyless Signing Engine (Fulcio CA & Rekor Ledger)", which accepts an input arrow from "OIDC Token / GitHub Workflows". Output points to "Signed OCI Container Signature Stored in Container Registry". Precise textbook blueprint style.

#### 1. Signing an OCI Image with Cosign
```bash
# Sign container image digest keylessly using OIDC identity
cosign sign --key k8s://kms-system/cosign-key \
  registry.internal.net/finance/payment-service@sha256:d8e9f1a2b3c4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0
```

#### 2. Verifying Image Signature in CI/CD Gate
```bash
# Verify image against trusted KMS public key
cosign verify --key k8s://kms-system/cosign-key \
  registry.internal.net/finance/payment-service@sha256:d8e9f1a2b3c4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0
```

---

## 3.4 Enterprise Secrets Management Standards

Hardcoding credentials, API keys, certificates, or database tokens in source code or CI/CD variable stores creates significant security exposure. Enterprise environments enforce central secrets engines (such as HashiCorp Vault) coupled with dynamic identity injection mechanisms.

```
+--------------------------------------------------------------------------------------------------+
|                               ENTERPRISE SECRETS INJECTION MODEL                                 |
|                                                                                                  |
| [ Kubernetes Pod ] ---> [ ServiceAccount JWT ] ---> [ Vault Agent Sidecar ]                      |
|                                                               |                                  |
|                                                               v                                  |
| [ App Runtime Memory ] <--- [ Temp Token Inject ] <--- [ Vault Kubernetes Auth ]                 |
+--------------------------------------------------------------------------------------------------+
```

### DALL-E 3 Prompt: Enterprise Secrets Injection Model
> **DALL-E 3 Prompt:** A professional technical architecture diagram titled "Enterprise Secrets Injection Model". Style & Aesthetics: Clean light-mode print style, minimal layout, crisp black vector line art on a stark white background with slate-gray highlight fills. Heading text uses clean sans-serif typography, and technical configurations use monospace code typography. Structure & Layout: A horizontal workflow with four sequential nodes: 1. "Kubernetes Pod", 2. "ServiceAccount JWT", 3. "Vault Agent Sidecar", 4. "Vault Kubernetes Auth", leading down to "Temp Token Inject", which feeds directly into "App Runtime Memory". High-contrast technical schematic style.

---

### HashiCorp Vault Policy Definition (`payment-service-policy.hcl`)

```hcl
# Read-only policy for payment service database credentials
path "secret/data/finance/payment-service/config" {
  capabilities = ["read"]
}

# Dynamic generation of short-lived PostgreSQL database credentials
path "database/creds/payment-db-role" {
  capabilities = ["read"]
}
```

---

### Production HashiCorp Vault Agent Kubernetes Deployment

Below is an enterprise Kubernetes Deployment configuring the Vault Agent Sidecar Injector to fetch dynamic secrets without exposing raw credentials to application developers.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: production
  labels:
    app.kubernetes.io/name: payment-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
      annotations:
        # Vault Sidecar Injection Configuration
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "payment-service-role"
        vault.hashicorp.com/agent-inject-secret-db-creds.txt: "database/creds/payment-db-role"
        # Secret Template Formatting
        vault.hashicorp.com/agent-inject-template-db-creds.txt: |
          {{- with secret "database/creds/payment-db-role" -}}
          export DB_USER="{{ .Data.username }}"
          export DB_PASSWORD="{{ .Data.password }}"
          {{- end -}}
    spec:
      serviceAccountName: payment-service-sa
      containers:
        - name: application
          image: registry.internal.net/finance/payment-service:v2.4.0
          command: ["/bin/sh", "-c", "source /vault/secrets/db-creds.txt && ./app-binary"]
          ports:
            - containerPort: 8080
          resources:
            limits:
              cpu: "500m"
              memory: "512Mi"
            requests:
              cpu: "250m"
              memory: "256Mi"
```

---

## 3.5 Hands-On Lab: Building a Complete SAST/DAST Vulnerability Scanning Pipeline

### Lab Scenario
You are an Enterprise DevSecOps Lead tasked with building a production-grade automated security pipeline in GitHub Actions for a microservice (`payment-service`).

The pipeline must enforce:
1. Local pre-commit hooks for secret detection.
2. SAST code scanning using Trivy Vulnerability Scanner.
3. Software Bill of Materials (SBOM) generation using Syft.
4. Container image security scanning using Trivy Container Engine.
5. Dynamic Application Security Testing (DAST) using OWASP ZAP against a target endpoint.
6. Automated Quality Gate enforcement blocking builds containing **HIGH** or **CRITICAL** vulnerabilities.

```
+----------------------------------------------------------------------------------------------------+
|                                    HANDS-ON LAB PIPELINE FLOW                                      |
|                                                                                                    |
| [ Developer Push ] ---> [ Job 1: SAST & Secret Scan ] ---> [ Job 2: Build & SBOM ]                 |
|                                                                        |                           |
|                                                                        v                           |
| [ Deployment Gate ] <--- [ Job 4: DAST Dynamic Scan ] <--- [ Job 3: Container Vulnerability Scan ] |
+----------------------------------------------------------------------------------------------------+
```

### DALL-E 3 Prompt: Hands-On Lab Pipeline Architecture
> **DALL-E 3 Prompt:** A professional technical flowchart diagram titled "Hands-On Lab Pipeline Architecture". Style & Aesthetics: Clean light-mode print aesthetic, crisp vector line art on a stark white background with subtle slate-gray header highlights. Text labels use clear sans-serif typography, and job names use monospace code typography. Structure & Layout: A horizontal multi-stage CI/CD flow: "Developer Push" arrow to "Job 1: SAST & Secret Scan", arrow to "Job 2: Build & SBOM", arrow down to "Job 3: Container Vulnerability Scan", arrow to "Job 4: DAST Dynamic Scan", arrow to "Deployment Gate". Precise blueprint style.

---

### Step 1: Pre-Commit Configuration (`.pre-commit-config.yaml`)

Create the following pre-commit configuration in your source repository root:

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: package-lock.json
```

---

### Step 2: Full DevSecOps CI/CD Workflow (`.github/workflows/devsecops-pipeline.yml`)

```yaml
name: Production DevSecOps Security Pipeline

on:
  push:
    branches: [ "main", "release/*" ]
  pull_request:
    branches: [ "main" ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  sast-and-secret-scan:
    name: 1. SAST & Secret Scanning
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v3

      - name: Run Secret Scanner (Trivy FS)
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          security-checks: 'secret,config'
          hide-progress: true
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'

      - name: Run SAST Static Analysis
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          security-checks: 'vuln'
          hide-progress: true
          format: 'sarif'
          output: 'trivy-sast-results.sarif'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'

      - name: Upload SAST SARIF Report
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-sast-results.sarif'

  build-and-sbom:
    name: 2. Container Build & SBOM Generation
    needs: sast-and-secret-scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build Container Image
        run: |
          docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .

      - name: Generate Software Bill of Materials (SBOM)
        uses: anchore/sbom-action@v0
        with:
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: spdx-json
          output-file: ./artifacts/sbom.spdx.json

      - name: Upload SBOM Artifact
        uses: actions/upload-artifact@v3
        with:
          name: sbom-spdx
          path: ./artifacts/sbom.spdx.json

  container-vulnerability-scan:
    name: 3. Container Vulnerability Scan
    needs: build-and-sbom
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v3

      - name: Run Container Image Vulnerability Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'

  dast-scan:
    name: 4. DAST Dynamic Scan
    needs: container-vulnerability-scan
    runs-on: ubuntu-latest
    services:
      staging-app:
        image: bkimminich/juice-shop:latest
        ports:
          - 3000:3000
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v3

      - name: Execute OWASP ZAP DAST Baseline Scan
        uses: zaproxy/action-baseline@v0.9.0
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          target: 'http://localhost:3000'
          issue_title: 'DAST Vulnerability Detected by ZAP'
          fail_action: true
```

---

### Step 3: Verification & Quality Gate Validation Commands

To verify pipeline functionality and test the failure modes locally:

```bash
# 1. Test local pre-commit hooks manually
pre-commit run --all-files

# 2. Execute local container image vulnerability scan with failure code
trivy image --exit-code 1 --severity HIGH,CRITICAL registry.internal.net/finance/payment-service:v2.4.0

# 3. Verify generated SBOM validity against SPDX spec
syft convert ./artifacts/sbom.spdx.json -o spdx-json
```

---

## 3.6 Chapter Review & Exam-Style Practice Questions

### Question 1
An enterprise organization requires that no container image containing unpatched `CRITICAL` vulnerability CVEs be deployed into Kubernetes clusters. Which DevSecOps practice ensures non-compliant images are blocked at deployment time even if built by external contractors?

A. Running static code analysis (SAST) during developer pull requests.  
B. Enforcing pre-commit secret detection hooks on local developer machines.  
C. Implementing Admission Controllers (OPA Gatekeeper/Kyverno) verifying cryptographic image signatures and vulnerability scan attestations before pod creation.  
D. Setting up weekly OWASP ZAP active DAST scans against internal staging environments.

* **Correct Answer:** C  
* **Explanation:** Admission Controllers (OPA Gatekeeper/Kyverno) act as runtime gates at the cluster API level. They verify that image digests are cryptographically signed by Cosign and pass vulnerability threshold attestations, preventing unverified contractor images from running regardless of build origin. Options A and B apply to build/dev stages, and D happens post-deployment.

---

### Question 2
During a CI/CD build execution, an automated Software Supply Chain security step detects that a developer added a third-party dependency distributed under a GPLv3 open-source license. The enterprise legal policy strictly forbids GPLv3 code in commercial SaaS binaries. Which tool category and output artifact best identify this policy violation before binary packaging?

A. Dynamic Application Security Testing (DAST) using OWASP ZAP HTML reports.  
B. Software Composition Analysis (SCA) generating SPDX/CycloneDX SBOM artifacts parsed by Policy-as-Code engines.  
C. Static Application Security Testing (SAST) generating SARIF files.  
D. Centralized Secrets Engine scanning for exposed private keys.

* **Correct Answer:** B  
* **Explanation:** Software Composition Analysis (SCA) tools scan application dependencies, produce Software Bill of Materials (SBOM) in SPDX/CycloneDX formats, and catalog software licenses. Policy-as-Code rules evaluate these license flags to fail builds violating corporate legal terms. SAST (C) checks source code bugs/vulnerabilities, while DAST (A) tests dynamic endpoints.
