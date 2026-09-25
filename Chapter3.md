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
