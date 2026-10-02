# Chapter 13: Declarative Infrastructure Provisioning

This chapter covers the operational mechanics, language constructs, and design patterns required to write enterprise-grade HashiCorp Configuration Language (HCL) code. It maps directly to the **LPI 701-200 DevOps Tools Engineer Exam Objectives** under Subject Area 701 (Infrastructure as Code and Automation).

---

## 13.1 HCL (HashiCorp Configuration Language) Syntax and Data Types

HashiCorp Configuration Language (HCL2) is a declarative, human-readable, and machine-friendly language optimized for defining infrastructure resources. Understanding its underlying syntax rules, block types, and type system is essential for developing predictable IaC configurations.

### HCL Core Syntax Architecture

An HCL configuration file consists of **blocks**, **arguments**, and **expressions**:

```hcl
# Block Type: "resource"
# Block Labels: "aws_instance" (Type), "app_node" (Local Name)
resource "aws_instance" "app_node" {
  # Argument Key = Expression Value
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "production-app-node"
  }
}

```

* **Blocks:** Containers for configuration objects. Blocks have a type (e.g., `resource`, `variable`, `data`, `output`, `module`) and zero or more block labels.
* **Arguments:** Assign values to names within a block using the `=` operator.
* **Expressions:** Represent values, either literally or by referencing other elements in the configuration graph.

### HCL Primitive and Complex Data Types

HCL enforces strong typing to validate infrastructure configurations prior to API execution.

#### Primitive Data Types

* `string`: A sequence of Unicode characters (e.g., `"t3.micro"`, `"us-east-1"`).
* `number`: Integer or floating-point numeric value (e.g., `80`, `3.14`).
* `bool`: Boolean flag (`true` or `false`).

#### Complex (Collection and Structural) Data Types

| Type Construct | Description | Example Syntax |
| --- | --- | --- |
| `list(...)` | Ordered collection of elements of a single type. Indexing is zero-based (`[0]`). | `list(string)` → `["subnet-a", "subnet-b"]` |
| `set(...)` | Unordered collection of unique values of a single type. Automatically removes duplicates. | `set(string)` → `["sg-123", "sg-456"]` |
| `map(...)` | Collection of key-value pairs where all values must share the same type. | `map(string)` → `{ env = "prod", owner = "ops" }` |
| `object(...)` | Structural type defining specific named attributes, each with its own designated type. | `object({ id = string, port = number, active = bool })` |
| `tuple(...)` | Sequence of elements where each element position has a distinct, predefined type. | `tuple([string, number, bool])` → `["vpc-1", 443, true]` |

#### Structural Type Example

```hcl
variable "database_config" {
  type = object({
    instance_class    = string
    allocated_storage = number
    multi_az          = bool
    engine_version    = string
  })
  default = {
    instance_class    = "db.r6g.xlarge"
    allocated_storage = 100
    multi_az          = true
    engine_version    = "15.3"
  }
}

```

---

## 13.2 Dynamic Infrastructure with Variables, Outputs, and Locals

Enterprise IaC configurations must be dynamic, parameterized, and modular. Hardcoding values into resource blocks is anti-pattern in production environments.

### Input Variables (`variables.tf`)

Input variables serve as parameters for a module or workspace.

```hcl
variable "environment" {
  type        = string
  description = "Target execution environment (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "ingress_ports" {
  type        = list(number)
  description = "List of allowed inbound ports"
  default     = [80, 443]
}

```

#### Variable Precedence Hierarchy (Lowest to Highest)

When the same variable is defined in multiple places, Terraform resolves the value according to the following strict order of precedence (1 is lowest, 6 is highest):

1. Default value in `variable` block.
2. Environment variables (`TF_VAR_variable_name`).
3. `terraform.tfvars` or `terraform.tfvars.json` file.
4. `*.auto.tfvars` or `*.auto.tfvars.json` files (loaded lexicographically).
5. Command-line flag `-var` or `-var-file` explicitly passed during run execution.

### Local Values (`locals.tf`)

Local values assign a name to an expression, preventing repetitive code and simplifying complex calculations.

```hcl
locals {
  name_prefix = "${var.organization}-${var.environment}"
  
  common_tags = {
    Organization = var.organization
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Project      = "Core-Infrastructure"
  }
}

resource "aws_vpc" "primary" {
  cidr_block = "10.0.0.0/16"
  tags       = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

```

### Output Values (`outputs.tf`)

Outputs expose specific infrastructure attributes for consumption by external pipelines, root configurations, or remote state lookups.

```hcl
output "vpc_id" {
  description = "The ID of the provisioned primary VPC"
  value       = aws_vpc.primary.id
}

output "db_password" {
  description = "Sensitive master database password"
  value       = aws_db_instance.main.password
  sensitive   = true # Prevents value from displaying in standard console outputs
}

```

---

## 13.3 Enterprise Module Architecture and Reusability

A Terraform/OpenTofu module is a container for multiple resources configured together. A **Root Module** executes from the main working directory, while **Child Modules** are instantiated inside configurations to standardize patterns.

### Standard Module Structure

An enterprise-ready child module maintains a clean interface boundary:

```text
modules/aws-compute-node/
├── README.md           # Documentation and usage examples
├── main.tf             # Core resource definitions
├── variables.tf        # Explicit input parameters
├── outputs.tf          # Explicit output exports
├── versions.tf         # Terraform and provider version pinning
└── tests/              # Native unit/integration tests

```

### Instantiating Child Modules

```hcl
module "app_server_cluster" {
  source  = "git::https://github.com/enterprise/terraform-aws-compute.git//modules/instance?ref=v2.1.0"

  environment   = var.environment
  instance_type = "t3.medium"
  subnet_ids    = data.terraform_remote_state.network.outputs.private_subnet_ids

  tags = local.common_tags
}

```

### Dynamic Resource Generation: `for_each` and `count`

To generate multiple instances of a resource or module dynamically, use `count` or `for_each`.

#### `count` Meta-Argument

Useful when creating identical copies based on an integer value:

```hcl
resource "aws_instance" "worker" {
  count         = var.worker_count
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "worker-node-${count.index + 1}"
  }
}

```

#### `for_each` Meta-Argument

Preferred for collection-driven provisioning. Prevents cascading updates when items are removed from the middle of a list:

```hcl
variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "public-a"  = { cidr = "10.0.1.0/24", az = "us-east-1a" }
    "public-b"  = { cidr = "10.0.2.0/24", az = "us-east-1b" }
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

---

## 13.4 Resource Lifecycle Management and Workspace Management

Managing infrastructure state safely requires control over resource update behaviors and environment isolates.

### Controlling Resource Lifecycles

The `lifecycle` meta-block customizes default creation/destruction behaviors for individual resources:

```hcl
resource "aws_instance" "critical_app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.large"

  lifecycle {
    # 1. Prevent accidental destruction via 'terraform destroy'
    prevent_destroy = true

    # 2. Create replacement before destroying old resource during immutable updates
    create_before_destroy = true

    # 3. Ignore external modifications to specific attributes (prevents drift conflict)
    ignore_changes = [
      tags["LastScanned"],
      user_data
    ]
  }
}

```

### Workspace Management

Workspaces allow multiple state files to be managed from the same root configuration directory.

```bash
# List existing workspaces
terraform workspace list

# Create and switch to a new workspace
terraform workspace new staging

# Select an existing workspace
terraform workspace select production

# Display current active workspace
terraform workspace show

```

#### Utilizing Workspace Name in Code

```hcl
locals {
  # Dynamically scale instance type depending on active workspace
  instance_type = lookup({
    dev        = "t3.micro"
    staging    = "t3.medium"
    production = "c6i.xlarge"
  }, terraform.workspace, "t3.micro")
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = local.instance_type

  tags = {
    Name        = "web-server-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

```

---

## 13.5 Hands-On Lab: Building Modular Terraform Code for Automated Cloud Node Provisioning

### Objective

Design and deploy a reusable enterprise module that provisions AWS compute instances attached to a customized VPC, using dynamic variable inputs, outputs, and local tags.

---

### Step 1: Directory Setup

Create a structured workspace containing both the child module definition and a root caller configuration:

```bash
mkdir -p terraform-lab13/modules/compute
cd terraform-lab13

```

---

### Step 2: Build the Child Compute Module

#### `modules/compute/variables.tf`

```hcl
variable "ami_id" {
  type        = string
  description = "AMI ID to launch instance"
}

variable "instance_type" {
  type        = string
  description = "Compute instance SKU"
  default     = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "Target subnet ID"
}

variable "node_name" {
  type        = string
  description = "Logical name tag for instance"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

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
output "instance_id" {
  description = "ID of created EC2 instance"
  value       = aws_instance.node.id
}

output "private_ip" {
  description = "Private IP address assigned to node"
  value       = aws_instance.node.private_ip
}

```

---

### Step 3: Configure Root Module and Invocation

Return to the root `terraform-lab13` folder and construct the root caller configuration.

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
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

```

#### `main.tf`

```hcl
# Look up latest Amazon Linux 2 AMI dynamically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Provision foundational Network infrastructure
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

  tags = {
    Name = "lab-subnet-a"
  }
}

# Call local child module
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
  description = "Details exported from child compute module"
  value = {
    instance_id = module.app_node.instance_id
    private_ip  = module.app_node.private_ip
  }
}

```

---

### Step 4: Validate, Plan, and Apply

Execute the standard validation and deployment workflow:

```bash
# 1. Initialize working directory and load providers/modules
terraform init

# 2. Validate configuration syntax and consistency
terraform validate

# 3. Perform dry-run plan step
terraform plan -out=tfplan.binary

# 4. Apply execution plan
terraform apply tfplan.binary

```

---

### Step 5: Verification and Cleanup

Confirm that outputs are correctly populated from the child module:

```bash
# Display output values
terraform output deployed_node_details

# Clean up resources to prevent cloud cost accumulation
terraform destroy -auto-approve

```
