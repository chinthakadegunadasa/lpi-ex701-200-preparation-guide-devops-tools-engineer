```markdown
# Chapter 3: Enterprise DevSecOps & Security Compliance

Welcome to Chapter 3! This chapter transitions from the fundamental definitions of the LPI 701-200 Exam Objective 701.3 into a fully comprehensive, enterprise-oriented, and *hands-on* implementation guide for DevSecOps.

We will focus on moving past "security as an afterthought" and embedding it into the core of your CI/CD delivery lifecycle. This is where we learn how to implement security as code.

---

## 3.1 Shift-Left Security Principles in CI/CD Pipelines

### 3.1.1 The Definition of "Shift-Left"
In traditional, "waterfall" development, security was the *final* step before release—the gatekeeper. A "vulnerability report" would be generated, often forcing teams to scramble to rework weeks of code.

**Shift-Left** means integrating security considerations and automated testing at the earliest possible stage of the software development life cycle (SDLC)—specifically, when developers are checking in their code.

### 3.1.2 Enterprise Principles for DevSecOps Success
A true shift-left strategy is not just about tools; it is a cultural and process change.

| Principle | Enterprise Implementation |
| :--- | :--- |
| **Automation First** | If it can be automated, it must be automated. Do not rely on manual security reviews for common flaws. |
| **Integration, Not Interruption** | Security tools must live within the developer’s existing tooling (IDE plugins, pull-request hooks). |
| **Fail Fast, Fail Informatively** | Security testing should happen on every commit. If the pipeline fails, the developer must receive actionable remediation advice immediately, not just "Build Failed." |
| **Security as Code** | Define scanning rules, policy exceptions, and compliance standards within the version control system (Git) alongside the application code. |

### 3.1.3 The DevSecOps Pipeline Flow
An enterprise DevSecOps pipeline integrates specialized security checks at each gate.

```mermaid
graph LR
    A[Code (IDE)] -->|Commit| B(Pull Request/Merge);
    B -->|Check 1: SAST/Secrets| C{Automated Review};
    C -->|Pass| D(Merge & Build);
    D -->|Check 2: Supply Chain| E(Artifact Repository);
    E -->|Check 3: Container Scan| F(Staging Deploy);
    F -->|Check 4: DAST| G(Production Deploy);
    C -->|Fail| A;

```

---

## 3.2 Static Application Security Testing (SAST) and Dynamic Scanning (DAST)

Objective 701.3 specifically calls out "Static/Dynamic Scanning." These are the two primary pillars of application-level vulnerability testing.

### 3.2.1 Static Application Security Testing (SAST)

**SAST (White-Box Testing)** analyzes the application source code, bytecode, or binary without executing the application.

* **When it runs:** During the "Build" phase, immediately after the code is committed.
* **What it finds:** Common coding errors, SQL injection vulnerabilities, cross-site scripting (XSS) flows, hardcoded secrets, and cryptographic weaknesses.
* **Enterprise Tooling:** SonarQube, Semgrep, Snyk Code, Checkmarx.

### 3.2.2 Dynamic Application Security Testing (DAST)

**DAST (Black-Box Testing)** analyzes the application while it is running. It interacts with the web application’s endpoints and inputs to find vulnerabilities that only manifest at runtime.

* **When it runs:** In a dedicated Staging/UAT environment, after the application has been built and deployed.
* **What it finds:** Issues with authentication, configuration flaws, server-side request forgery (SSRF), and runtime XSS that SAST cannot detect.
* **Enterprise Tooling:** OWASP ZAP, Burp Suite Enterprise, StackHawk.

### 3.2.3 SAST vs. DAST Comparison for Enterprise

| Feature | SAST | DAST |
| --- | --- | --- |
| **Perspective** | Internal (Developer/White-Box) | External (Hacker/Black-Box) |
| **Requires Source Code** | Yes | No |
| **Application State** | Passive (Idle) | Active (Running) |
| **Accuracy** | Prone to False Positives | Prone to False Negatives |
| **Time to Run** | Fast (seconds/minutes) | Slow (minutes/hours) |
| **Remediation** | Identifies specific file/line number | Identifies specific URI/Endpoint |

---

## 3.3 Software Supply Chain Security & Dependency Vulnerability Scanning

The most critical threat vector today is not the code *you* write; it’s the code *you import*. Modern applications are often composed of 80%+ open-source libraries. If a single dependent library is compromised, your entire application is vulnerable (e.g., Log4Shell).

### 3.3.1 The Software Bill of Materials (SBOM)

An enterprise *must* generate a comprehensive, machine-readable inventory of all software components used in their product.

* **Format Standards:** CycloneDX or SPDX.
* **Purpose:** Allows organizations to quickly determine if they are impacted by a newly discovered CVE without scanning all their applications from scratch.

### 3.3.2 Dependency Scanning (Software Composition Analysis - SCA)

SCA tools automatically analyze the `package.json`, `pom.xml`, or `requirements.txt` files to inventory the direct and transitive dependencies and match them against known vulnerability databases (NVD).

* **Enterprise Tooling:** GitHub Dependency Graph/Dependabot, GitLab Dependency Scanning, Snyk Open Source, OWASP Dependency-Check.

---

## 3.4 Enterprise Secrets Management Standards

Secrets—API keys, database credentials, certificates, and SSH keys—are the crown jewels. Accidental exposure in Git (e.g., Leaked Keys on GitHub) is a primary cause of enterprise breaches.

### 3.4.1 Secrets Prevention (SAST-based)

Before secrets are managed, they must be prevented from leaking.

* **Principle:** Install "pre-commit hooks" that run `gitleaks` or `trufflehog` on the developer’s local machine before a commit can be finalized.

### 3.4.2 Secrets Lifecycle Management

Enterprise secrets must *never* be stored as plain text or base64 environment variables (like a default Kubernetes Secret).

* **Enterprise Tooling:** HashiCorp Vault, AWS Secrets Manager, Google Cloud Secret Manager.
* **Lifecycle Phases:**
1. **Generation:** Secrets are generated by the vault, not the user.
2. **Storage:** Stored in an encrypted vault.
3. **Access:** Applications authenticate using their identity (e.g., IAM role) to retrieve only the secrets they need.
4. **Rotation:** Secrets (like database passwords) are rotated automatically every 30 days without human intervention.
5. **Revocation:** Secrets can be immediately revoked if a breach is suspected.



---

## 3.5 Hands-On Lab: Building a Complete SAST/DAST Vulnerability Scanning Pipeline

This lab is purely practical. We will simulate an enterprise workflow using GitHub Actions to build a comprehensive security pipeline for a vulnerable application.

### Prerequisites

* A GitHub Account.
* A basic understanding of Git (`git commit`, `git push`).

### Step 1: Clone the Vulnerable Application

We will use an deliberately vulnerable application designed for testing security tools.

1. Navigate to your GitHub account and create a new repository.
2. Clone the standard "OWASP Juice Shop" application, or a simple Node.js "vulnerable web app." For simplicity, we will use a tailored vulnerable node app:

```bash
# Example bash commands for cloning (if local Git is used, otherwise, do this via GitHub import)
# git clone [https://github.com/OWASP/juice-shop.git](https://github.com/OWASP/juice-shop.git)
# cd juice-shop

```

### Step 2: Implement SAST (Semgrep)

Semgrep is a modern, fast, and open-source SAST tool perfect for CI/CD.

1. In your GitHub repository, navigate to **Actions** > **Set up a workflow yourself**.
2. Create a new file named `.github/workflows/devsecops.yml`.
3. Add the following workflow definition. This step configures the pipeline to run on every code push.

```yaml
# .github/workflows/devsecops.yml
name: "DevSecOps Pipeline"

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  # PHASE 1: Build and Basic Analysis
  sast-scan:
    name: Semgrep SAST Scan
    runs-on: ubuntu-latest
    container:
      image: returntocorp/semgrep
    steps:
      - name: Checkout Code
    with:
      fetch-depth: 0 # Required for deep scanning

      - name: Run Semgrep scan
    run: |
      semgrep scan \
        --config auto \
        --sarif --output=semgrep.sarif
    continue-on-error: true # Enterprise policy: We want the pipeline to proceed even if findings exist, so we can run other tools.

      # Upload findings to GitHub Security Tab
      - name: Upload SARIF output
    uses: github/codeql-action/upload-sarif@v3
    with:
      sarif_file: semgrep.sarif

```

### Step 3: Implement Software Composition Analysis (Snyk SCA)

We will now add dependency scanning. While Dependabot is native to GitHub, we will use Snyk as an example of a common enterprise third-party integration.

* *Note: For this to work in a real environment, you would need to create a Snyk account and add your `SNYK_TOKEN` as a GitHub Secret. We will simulate the step below.*

1. Update the `jobs` section of your `.github/workflows/devsecops.yml` to include Snyk.

```yaml
# ... (Continuing from sast-scan job)

  sca-scan:
    name: Snyk Dependency Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
    with:
      fetch-depth: 0

      - name: Snyk Open Source Scan
    uses: snyk/actions/node@master
    env:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }} # Simulation: Requires setting up Snyk token
    with:
      args: --severity-threshold=high --json-file-output=snyk-sca.json
    continue-on-error: true # Standard policy: We check for HIGH vulnerabilities

      - name: Upload findings to GitHub Security
    uses: github/codeql-action/upload-sarif@v3
    with:
      sarif_file: snyk-sca.json

```

### Step 4: Implement Secrets Scanning (TruffleHog)

We will now implement TruffleHog to ensure no secrets have been accidentally committed to the application history.

1. Update the workflow. This job runs *in parallel* with the SAST and SCA jobs.

```yaml
# ... (Continuing jobs section)

  secrets-scan:
    name: TruffleHog Secrets Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
    with:
      fetch-depth: 0 # Scan entire history, not just the last commit

      - name: Run TruffleHog
    uses: trufflesecurity/trufflehog@main
    with:
      base: "" # Scan from the start of time
      head: "HEAD"
      extra_args: --only-verified --debug
    continue-on-error: true

```

### Step 5: Implement Container Scanning (Trivy) and DAST (OWASP ZAP)

This is the final stage. We must build the application first (e.g., as a Docker container) before DAST can be run against it.

* *This requires deploying the application. For this lab, we will use the dynamic scanning action directly, assuming the application is running in the runner’s context.*

1. Add the final deployment and DAST jobs. Note how the `dast-scan` job `needs` the build stage to succeed.

```yaml
# ... (Continuing jobs section)

  # PHASE 2: Build and Containerization
  build-and-push-image:
    name: Build Docker Image
    runs-on: ubuntu-latest
    # This job only runs if previous scanning jobs finished (even if they had findings)
    needs: [ sast-scan, sca-scan, secrets-scan ]
    steps:
      - name: Checkout Code
    uses: actions/checkout@v3

      - name: Build local image
    run: docker build -t vulnerable-app:latest .

      - name: Run Trivy Container Scan
    uses: aquasecurity/trivy-action@master
    with:
      image-ref: 'vulnerable-app:latest'
      format: 'table'
      exit-code: '1' # Enterprise policy: Fail the build if critical flaws exist in the OS layer.
      severity: 'CRITICAL'

  # PHASE 3: Dynamic Analysis
  dast-scan:
    name: OWASP ZAP DAST Scan
    runs-on: ubuntu-latest
    # DAST requires the application to be deployed, so we wait for the image build
    needs: build-and-push-image
    steps:
      - name: Checkout Code
    with:
      fetch-depth: 0

      # Simulating Deployment: For this lab, ZAP will run against itself
      # as we don't have a public endpoint.

      - name: Run OWASP ZAP Baseline Scan
    uses: zaproxy/action-baseline@v0.12.0
    with:
      # In a real environment, this would be your staging URL (e.g., [https://staging.myapp.com](https://staging.myapp.com))
      target: '[http://example.com](http://example.com)'
      fail_action: false # Policy: Produce report, but do not block the pipeline.
      token: ${{ github.token }}

```

### Step 6: Verification and Remediation

Now you will generate a vulnerability and remediate it.

1. **Commit the Workflow:** Save and commit the new `.github/workflows/devsecops.yml` file and push it to GitHub.
2. **Verify the First Fail:** Navigate to your GitHub repository’s **Actions** tab. You should see the pipeline running. It will almost certainly fail or show warnings, as we have configured `continue-on-error` for most stages (allowing ZAP to produce reports), but Trivy might fail on critical vulnerabilities.
3. **Inspect Findings:** Go to your repository's **Security** > **Code scanning** tab. You will see the integrated findings from Semgrep (SAST) and Snyk (SCA), showing the exact lines of code with vulnerabilities.
4. **Hands-On Remediation:**
* Find a file (e.g., a `.js` or `.php` file) with an intentional vulnerability (like a hardcoded dummy API key).
* Edit the file to remove the hardcoded key.
* Commit and Push the fix.
* Verify the Action again. The SAST and secrets-scanning jobs should now report "Clean," and the findings will automatically close in the GitHub Security tab.



This hands-on lab demonstrates exactly how an enterprise combines multiple security paradigms—SAST, SCA, Secrets Detection, and DAST—into a single, automated source of truth.

```

```
