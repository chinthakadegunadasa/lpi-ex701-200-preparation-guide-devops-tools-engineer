# Chapter 13: Declarative Infrastructure Provisioning

Welcome to **Chapter 13** of *The Ultimate Handbook of DevOps Practitioner*. In this chapter, we transition from theoretical infrastructure automation to rigorous, production-grade **HashiCorp Configuration Language (HCL)** engineering. 

Writing infrastructure code that runs cleanly in a local test environment is easy; designing enterprise-grade modules that withstand multi-region deployments, automated CI/CD pipelines, dynamic secrets management, GitOps controllers, and strict compliance audits requires a disciplined approach. This chapter maps directly to the **LPI 701-200 DevOps Tools Engineer Exam Objectives** under Subject Area 701 (Infrastructure as Code and Automation).

## 13.1 Mastering HCL2 Syntax and Strict Typing

HashiCorp Configuration Language (HCL2) bridges human readability and machine execution. In an enterprise environment, treating HCL as software code—complete with style guides, linters, and strict static validation—is non-negotiable.

### The Anatomy of an HCL Block

An HCL configuration is structured around three primary elements: **blocks**, **arguments**, and **expressions**.

```hcl
# Block Type: "resource"
# Block Labels: "aws_instance" (Resource Type), "app_node" (Local Identifier)
resource "aws_instance" "app_node" {
  # Argument Key = Expression Value
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "production-app-node"
  }
}
```

*   **Blocks:** The structural containers. They define infrastructure objects, variables, data sources, and outputs, characterized by a block type and optional string labels.

*   **Arguments:** Key-value assignments inside blocks that configure specific attributes using the `=` operator.

*   **Expressions:** Literals, function calls, or references to other objects within the configuration dependency graph.

### Enterprise Data Type Enforcement

Relying on implicit typing in production leads to runtime failures during `terraform apply`. HCL enforces strong typing to catch configuration errors at plan-time.

#### Primitive Data Types

*   `string`: Unicode character sequences (e.g., `"us-east-1"`).

*   `number`: Integer or floating-point values (e.g., `443`, `3.14`).

*   `bool`: Boolean flags (`true` or `false`).

#### Complex Collection & Structural Types

| Type Construct | Enterprise Use Case | Example Syntax |
| :--- | :--- | :--- |
| `list(...)` | Ordered sequences of identical types (e.g., subnet routing). | `list(string)` $\rightarrow$ `["subnet-a", "subnet-b"]` |
| `set(...)` | Unordered collections with automatic duplicate purging (e.g., security group rules). | `set(string)` $\rightarrow$ `["sg-123", "sg-456"]` |
| `map(...)` | Key-value dictionaries sharing a common value type (e.g., tags, lookup tables). | `map(string)` $\rightarrow$ `{ env = "prod", owner = "ops" }` |
| `object(...)` | Strongly typed structural schemas with named attributes. | `object({ id = string, port = number, active = bool })` |
| `tuple(...)` | Fixed-length sequences where each position has a distinct type. | `tuple([string, number, bool])` $\rightarrow$ `["vpc-1", 443, true]` |

#### Production Structural Validation Example

Using `object` types alongside `validation` blocks guarantees that incoming configuration parameters conform strictly to enterprise compliance standards:

```hcl
variable "database_config" {
  type = object({
    instance_class    = string
    allocated_storage = number
    multi_az          = bool
    engine_version    = string
  })
  
  description = "Standardized database configuration profile"
  
  validation {
    condition     = can(regex("^db\\.", var.database_config.instance_class))
    error_message = "Database instance class must be a valid RDS SKU starting with 'db'."
  }
}
```

## 13.2 Dynamic Infrastructure with Variables, Outputs, and Locals

Hardcoded values create brittle codebases. Enterprise infrastructure modules must be parameterized to handle multiple environments (dev, staging, production) cleanly.

### Input Variables & Precedence Hierarchy

Input variables define the public API of your module. 

```hcl
variable "environment" {
  type        = string
  description = "Target execution environment"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}
```

When managing variables across complex pipelines, understand the strict **Variable Precedence Hierarchy** (ordered from lowest to highest priority):

1. Default values defined in the `variable` block.

2. Environment variables prefixed with `TF_VAR_` (e.g., `TF_VAR_environment=prod`).

3. The `terraform.tfvars` or `terraform.tfvars.json` files.

4. Files matching `*.auto.tfvars` or `*.auto.tfvars.json` (evaluated lexicographically).

5. Explicit command-line flags (`-var` or `-var-file`).

### Local Values (`locals.tf`)

Local values prevent repetitive expressions and encapsulate internal naming conventions or tag schemas:


```hcl
locals {
  name_prefix = "enterprise-${var.environment}"
  
  common_tags = {
    Organization = "Cybergate Service"
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Audited      = "true"
  }
}

resource "aws_vpc" "primary" {
  cidr_block = "10.0.0.0/16"
  tags       = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}
```

### Secure Output Handling

Outputs expose resource attributes to parent modules or external CI/CD pipelines. Always mark sensitive credentials or keys:

```hcl
output "db_master_password" {
  description = "Master database password securely stored in state"
  value       = aws_db_instance.main.password
  sensitive   = true # Suppresses value output in standard console logs
}
```

## 13.3 Enterprise Module Architecture & Dynamic Iteration

Scaling IaC across dozens of microservices requires modularization. A clean child module follows a strict structural contract:

```text
modules/aws-compute-node/
├── README.md           # Architectural overview and usage examples
├── main.tf             # Core resource definitions
├── variables.tf        # Explicit input contracts
├── outputs.tf          # Explicit output interfaces
└── versions.tf         # Strict provider and language version pinning
```

### Dynamic Resource Generation: `for_each` vs. `count`

In enterprise environments, prefer `for_each` over `count` when managing collections. `count` relies on integer indexing; if an item is removed from the middle of a list, every subsequent resource is destroyed and recreated. `for_each` uses stable map keys, preventing accidental cascade updates.

```hcl
variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "public-a"  = { cidr = "10.0.1.0/24", az = "us-east-1a" }
    "private-a" = { cidr = "10.0.10.0/24", az = "us-east-1a" }
  }
}

resource "aws_subnet" "subnet" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.primary.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "subnet-${each.key}"
  }
}
```

## 13.4 Resource Lifecycle Control and State Workspaces

Production stability relies on fine-tuning how Terraform manages resource state changes.

### Lifecycle Meta-Blocks

```hcl
resource "aws_instance" "critical_app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.large"

  lifecycle {
    # 1. Prevent accidental deletion during teardown scripts
    prevent_destroy = true

    # 2. Ensure zero downtime during updates (Blue/Green pattern)
    create_before_destroy = true

    # 3. Protect auto-scaled or externally modified tags from state drift conflict
    ignore_changes = [
      tags["LastScanned"],
      user_data
    ]
  }
}
```

## 13.5 Hands-On Lab: Building a Production-Ready Compute Module

Let’s put these concepts into practice by constructing a modular, enterprise-grade directory layout that provisions an AWS VPC and an EC2 compute instance.

### Step 1: Initialize Directory Layout

```bash
mkdir -p terraform-lab13/modules/compute
cd terraform-lab13
```

### Step 2: Write the Compute Module Files

#### `modules/compute/variables.tf`

```hcl
variable "ami_id" { type = string }
variable "instance_type" { type = string; default = "t3.micro" }
variable "subnet_id" { type = string }
variable "node_name" { type = string }
variable "environment" { type = string }
```

#### `modules/compute/main.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  module_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
    NodeName    = var.node_name
  }
}

resource "aws_instance" "node" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  tags = merge(local.module_tags, {
    Name = "node-${var.node_name}-${var.environment}"
  })

  lifecycle {
    create_before_destroy = true
  }
}
```

#### `modules/compute/outputs.tf`

```hcl
output "instance_id" { value = aws_instance.node.id }
output "private_ip" { value = aws_instance.node.private_ip }
```

### Step 3: Implement the Root Caller Configuration

Navigate back to the root `terraform-lab13` folder.

#### `versions.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

#### `variables.tf`

```hcl
variable "aws_region" { type = string; default = "us-east-1" }
variable "environment" { type = string; default = "dev" }
```

#### `main.tf`

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name        = "lab-vpc-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "lab_subnet" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "lab-subnet-a" }
}

module "app_node" {
  source = "./modules/compute"

  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.lab_subnet.id
  node_name     = "primary-api"
  environment   = var.environment
}
```

#### `outputs.tf`

```hcl
output "deployed_node_details" {
  value = {
    instance_id = module.app_node.instance_id
    private_ip  = module.app_node.private_ip
  }
}
```

### Step 4: Execute Workflow & Clean Up

```bash
# 1. Initialize working directory
terraform init

# 2. Validate configuration syntax
terraform validate

# 3. Plan and execute
terraform apply -auto-approve

# 4. Clean up resources
terraform destroy -auto-approve
```

## 13.6 Enterprise State Management and State Locking

In local development, Terraform stores resource metadata in a local file named `terraform.tfstate`. In an enterprise setting with multiple engineers and automated CI/CD pipelines, local state files are a liability. They risk state corruption, expose plain-text secrets, and prevent concurrent deployments.

To solve this, enterprise IaC architectures rely on **remote backends** with distributed storage and **state locking**.

### S3 Backend with DynamoDB State Locking Architecture

By storing state in an encrypted Amazon S3 bucket and utilizing a DynamoDB table for locking, you prevent two engineers or CI/CD pipelines from applying conflicting state modifications simultaneously.

#### Creating the Backend Infrastructure (`backend-setup/main.tf`)
Before configuring your main project backend, provision the supporting state storage infrastructure:

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "cybergate-terraform-state-prod"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "cybergate-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

#### Configuring the Remote Backend in Root Modules (`backend.tf`)
Once your S3 bucket and DynamoDB table are provisioned, configure your root module to use the remote backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "cybergate-terraform-state-prod"
    key            = "compute-node/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cybergate-terraform-locks"
    encrypt        = true
  }
}
```

## 13.7 Automated Infrastructure Testing with Terratest

Writing enterprise IaC without automated testing is like writing production microservices without unit tests. **Terratest** is a Go-based library developed by Gruntwork that allows you to write automated tests for your Terraform code. It provisions real infrastructure, validates behavior using assertions, and cleans up after itself.

### Setting Up the Test Directory Structure

```text
terraform-lab13/
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
└── test/
    ├── go.mod
    ├── go.sum
    └── compute_test.go
```

### Step 1: Initialize Go Module & Install Terratest

```bash
cd test
go mod init github.com/enterprise/terraform-lab13/test
go get github.com/gruntwork-io/terratest/modules/terraform
```

### Step 2: Write the Integration Test (`test/compute_test.go`)

```go
package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformComputeModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"aws_region":  "us-east-1",
			"environment": "test",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	instanceID := terraform.Output(t, terraformOptions, "deployed_node_details")
	privateIP := terraform.Output(t, terraformOptions, "deployed_node_details")

	assert.NotEmpty(t, instanceID)
	assert.NotEmpty(t, privateIP)
}
```

### Step 3: Execute Automated Tests

```bash
go test -v -timeout 30m compute_test.go
```

## 13.8 GitHub Actions CI/CD Pipeline for Enterprise IaC

Manually executing `terraform apply` from a local workstation is an enterprise anti-pattern. Production infrastructure changes must be driven through automated, auditable, and secure CI/CD pipelines.

### Enterprise Workflow Configuration (`.github/workflows/terraform-ci.yml`)

```yaml
name: Enterprise Terraform CI/CD

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

permissions:
  id-token: write
  contents: read

jobs:
  validate-and-test:
    name: Validate, Lint & Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.6.0"

      - name: Verify Formatting
        run: terraform fmt -check -recursive

      - name: Initialize Terraform
        run: terraform init -backend=false

      - name: Validate Syntax
        run: terraform validate

      - name: Run TFLint
        uses: tflint-actions/setup-tflint@v3
        with:
          tflint_version: v0.50.0
      - run: tflint --init && tflint

      - name: Run Tfsec Security Scanner
        uses: tfsec/tfsec-action@v1

  deploy-infrastructure:
    name: Production Apply
    needs: validate-and-test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.6.0"

      - name: Authenticate to AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsTerraformDeploymentRole
          aws-region: us-east-1

      - name: Terraform Init & Apply
        run: |
          terraform init
          terraform apply -auto-approve
```

## 13.9 Secure Cloud Authentication via OpenID Connect (OIDC)

Hardcoding static AWS credentials inside GitHub repository secrets is a severe security vulnerability. Enterprise pipelines eliminate static credentials by utilizing **OpenID Connect (OIDC)**. GitHub acts as the OIDC Identity Provider (IdP), issuing short-lived JSON Web Tokens (JWT) directly to runners. AWS STS validates the token and exchanges it for temporary IAM credentials.

### IAM Role Trust Policy (`github-oidc-trust-policy.json`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:chinthakadegunadasa/lpi-ex701-200-preparation-guide-devops-tools-engineer:*"
        }
      }
    }
  ]
}
```

---

## 13.10 Domain-Driven Terraform State Partitioning and Remote Lookups

Managing a massive, monolithic Terraform configuration is an enterprise anti-pattern. A single state corruption halts all infrastructure deployments across the entire organization.

To scale infrastructure safely, enterprise architectures adopt **Domain-Driven State Partitioning**. State files are split into distinct functional boundaries (e.g., `network`, `database`, `compute`), managed in separate directories, and connected via `terraform_remote_state` data sources:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket         = "cybergate-terraform-state-prod"
    key            = "network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cybergate-terraform-locks"
  }
}

resource "aws_instance" "app_node" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[0]

  tags = {
    Name = "partitioned-app-node"
  }
}
```

## 13.11 Automated Policy-as-Code with OPA (Open Policy Agent) and Conftest

Enterprise governance requires **Policy-as-Code** using **Open Policy Agent (OPA)** and **Conftest**. OPA evaluates JSON execution plans generated by Terraform against declarative Rego policies *before* any cloud resources are touched.

### Rego Security Policy (`policy/security.rego`)

```rego
package terraform.security

import future.keywords.in

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    
    ingress := resource.change.after.ingress[_]
    cidr := ingress.cidr_blocks[_]
    cidr == "0.0.0.0/0"
    
    port := ingress.from_port
    port == 22
    
    msg := sprintf("CRITICAL SECURITY VIOLATION: Security group '%v' allows unrestricted public SSH access.", [resource.address])
}
```

### Executing Conftest in CI/CD Workflow

```bash
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
conftest test tfplan.json --policy policy/
```

## 13.12 Hardened Golden AMIs with HashiCorp Packer and Ansible

Relying on runtime bootstrapping scripts creates boot latency and repository dependency risks. Enterprise infrastructure standards mandate the **Immutable Infrastructure Pattern** via pre-baked **Golden AMIs** built with **HashiCorp Packer** and provisioned using **Ansible**.

### Packer Spec (`ami.pkr.hcl`)

```hcl
packer {
  required_plugins {
    amazon = { version = "~> 1.3"; source = "github.com/hashicorp/amazon" }
    ansible = { version = "~> 1.1"; source = "github.com/hashicorp/ansible" }
  }
}

source "amazon-ebs" "secure_node" {
  region        = "us-east-1"
  instance_type = "t3.micro"
  ami_name      = "cybergate-hardened-base-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.secure_node"]
  provisioner "ansible" {
    playbook_file = "./ansible/hardening.yml"
    user          = "ec2-user"
  }
}
```

### Ansible Hardening Playbook (`ansible/hardening.yml`)

```yaml
---
- name: Apply Enterprise Security Hardening
  hosts: all
  become: true
  tasks:
    - name: Update all system packages to latest security versions
      yum:
        name: '*'
        state: latest

    - name: Ensure SSH root login is disabled
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: Restart SSH

    - name: Ensure strict SSH protocol version
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^Protocol'
        line: 'Protocol 2'
      notify: Restart SSH

    - name: Install and start auditd service
      yum:
        name: audit
        state: present

  handlers:
    - name: Restart SSH
      systemd:
        name: sshd
        state: restarted
```

## 13.13 Advanced Terraform Drift Detection and Automated Remediation

Enterprise governance requires continuous, automated drift detection with real-time alerting.

### Scheduled Drift Detection Workflow (`.github/workflows/terraform-drift.yml`)

```yaml
name: Enterprise Infrastructure Drift Detection

on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  detect-drift:
    name: Run Drift Audit
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.6.0"

      - name: Authenticate to AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsTerraformDeploymentRole
          aws-region: us-east-1

      - name: Check for Infrastructure Drift
        run: |
          terraform init
          terraform plan -detailed-exitcode -no-color || exit_code=$?
          if [ "${exit_code:-0}" -eq 2 ]; then
            echo "DRIFT_DETECTED=true" >> $GITHUB_ENV
            echo "::warning::Infrastructure drift detected!"
            exit 2
          fi
```

## 13.14 Zero-Downtime Blue/Green Deployments with Terraform and Route53

Blue/Green Deployments eliminate update downtime by maintaining two identical production environments (**Blue** and **Green**) and shifting traffic using **Amazon Route 53 Weighted Routing Policies**.

```hcl
variable "traffic_shift_to_green" {
  type    = bool
  default = false
}

locals {
  blue_weight  = var.traffic_shift_to_green ? 0 : 100
  green_weight = var.traffic_shift_to_green ? 100 : 0
}

resource "aws_route53_record" "app_blue" {
  zone_id = var.route53_zone_id
  name    = "api.cybergate.one"
  type    = "A"
  ttl     = 30

  set_identifier = "blue-stack"
  weighted_routing_policy { weight = local.blue_weight }
  records = [aws_instance.blue_node.public_ip]
}

resource "aws_route53_record" "app_green" {
  zone_id = var.route53_zone_id
  name    = "api.cybergate.one"
  type    = "A"
  ttl     = 30

  set_identifier = "green-stack"
  weighted_routing_policy { weight = local.green_weight }
  records = [aws_instance.green_node.public_ip]
}
```

---

## 13.15 Multi-Region Disaster Recovery State Replication & Provider Aliasing

Designing a Multi-Region Disaster Recovery (DR) architecture with Terraform involves multi-region provider aliasing combined with S3 Cross-Region Replication (CRR) and DynamoDB Global Tables.

```hcl
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

resource "aws_instance" "primary_app" {
  provider      = aws.primary
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  tags          = { Name = "production-primary-node" }
}

resource "aws_instance" "dr_app" {
  provider      = aws.dr
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  tags          = { Name = "production-dr-node" }
}
```

## 13.16 Dynamic Secrets Management with HashiCorp Vault

Enterprise architectures eliminate static secrets by integrating **HashiCorp Vault**, dynamically generating short-lived, ephemeral database credentials and API tokens at runtime.

```hcl
provider "vault" {
  address = "https://vault.cybergate.one:8200"
}

data "vault_kv_secret_v2" "database_creds" {
  mount = "secret"
  name  = "production/rds-master"
}

resource "aws_db_instance" "secure_postgres" {
  identifier        = "cybergate-prod-db"
  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = "db.r6g.xlarge"
  allocated_storage = 100

  username = data.vault_kv_secret_v2.database_creds.data["username"]
  password = data.vault_kv_secret_v2.database_creds.data["password"]

  skip_final_snapshot = true
}
```

## 13.17 Advanced GitOps Continuous Delivery with Argo CD and Terraform Controllers

Enterprise GitOps flips traditional push-based deployment models to a **pull-based architecture** using **Argo CD** and Kubernetes-native Terraform Controllers.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: CronWorkflow
metadata:
  name: terraform-drift-reconciliation-cron
  namespace: argocd
spec:
  schedule: "*/30 * * * *"
  concurrencyPolicy: "Forbid"
  workflowSpec:
    spec:
      entrypoint: reconcile-infrastructure
      templates:
      - name: reconcile-infrastructure
        container:
          image: hashicorp/terraform:1.6.0
          command: ["sh", "-c"]
          args:
            - |
              git clone https://github.com/chinthakadegunadasa/lpi-ex701-200-preparation-guide-devops-tools-engineer.git /workspace/repo
              cd /workspace/repo
              terraform init
              terraform apply -auto-approve
```

## LPI 701-200 Exam Objective 701: Practice Questions

### Question 1: HCL Syntax and Variable Precedence
**Scenario:** A DevOps engineer runs `terraform apply -var="environment=staging"` while an environment variable `TF_VAR_environment=production` is exported in their active shell session, and a `terraform.tfvars` file specifies `environment = "development"`. 

Which value will Terraform assign to `var.environment` during execution?

A. `development` (from `terraform.tfvars`)

B. `production` (from environment variable `TF_VAR_environment`)

C. `staging` (from command-line `-var` flag)

D. Terraform will throw a validation conflict error and halt execution.

> **Correct Answer:** **C**  

> *Explanation:* According to Terraform's strict variable precedence hierarchy, explicit command-line flags (`-var` or `-var-file`) override environment variables, tfvars files, and default block values.

### Question 2: Resource Iteration (`for_each` vs. `count`)

**Scenario:** A team manages a list of three IAM users using an index-based iteration construct. When the middle user (`bob`) is removed from the list, Terraform destroys and recreates the user account for `charlie` (who was at index 2 and shifted to index 1). 

Which meta-argument should the engineer adopt to prevent cascading updates when items are modified in collections?

A. `count`

B. `for_each`

C. `lifecycle { create_before_destroy = true }`

D. `depends_on`

> **Correct Answer:** **B**  

> *Explanation:* `for_each` maps resources to unique map keys or set elements rather than positional integer indices (`count.index`), ensuring that removing an item from the middle of a collection does not alter the identifiers of remaining items.

### Question 3: State Locking and Remote Backends
**Scenario:** Two developers on an enterprise DevOps team attempt to run `terraform apply` concurrently against the same AWS infrastructure stack. 

What native mechanism prevents state corruption and simultaneous modifications in a production S3 backend?

A. S3 Bucket Versioning
B. DynamoDB State Locking via `LockID`
C. Git Branch Protection Rules
D. Terraform Workspace Isolation

> **Correct Answer:** **B**  

> *Explanation:* When configured with an S3 backend, Terraform utilizes an Amazon DynamoDB table to acquire an exclusive lock (`LockID`) during state read/write operations, preventing concurrent conflicting writes.

### Question 4: Policy-as-Code and Compliance

**Scenario:** Your security team mandates that no Terraform configuration may provision an AWS Security Group permitting unrestricted inbound access (`0.0.0.0/0`) on port 22. 

Which tool and policy language combination is standard for evaluating these rules against generated Terraform JSON execution plans prior to deployment?

A. TFLint using YAML configuration rules

B. Open Policy Agent (OPA) using Rego policy scripts

C. Ansible security playbooks with YAML linting

D. Terratest using Go assertion libraries

> **Correct Answer:** **B**  

> *Explanation:* Open Policy Agent (OPA) paired with Conftest evaluates structured JSON execution plans against declarative rules written in the Rego language to enforce automated Policy-as-Code compliance.

### Question 5: Immutable Infrastructure and Golden AMIs

**Scenario:** An enterprise team wants to eliminate boot-time configuration drift and reduce launch latency for auto-scaling EC2 fleets by pre-installing security patches and auditing tools into a snapshot image before deployment. 

Which tool combination is specifically engineered for building immutable golden AMIs?

A. Terraform and Docker

B. Packer and Ansible

C. Kubernetes and Helm

D. Vault and Consul

> **Correct Answer:** **B**  

> *Explanation:* HashiCorp Packer automates the creation of machine images (AMIs) across cloud platforms, while Ansible acts as the provisioner to apply hardening scripts and configurations inside the temporary build instance.
