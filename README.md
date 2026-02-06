# Automated Strapi Deployment on AWS

A highly available, secure infrastructure using Terraform to deploy a containerized Strapi CMS application on AWS.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC (10.0.0.0/16)                    │
│  ┌──────────────────────────┐  ┌──────────────────────────────┐ │
│  │    Public Subnets        │  │     Private Subnets          │ │
│  │  ┌─────────────────────┐ │  │  ┌────────────────────────┐  │ │
│  │  │  Internet Gateway   │ │  │  │   EC2 (Strapi/Docker)  │  │ │
│  │  │  NAT Gateway        │ │  │  │   - Node.js 22         │  │ │
│  │  │  ALB               ─┼─┼──┼──▶   - Docker Container   │  │ │
│  │  └─────────────────────┘ │  │  └────────────────────────┘  │ │
│  └──────────────────────────┘  └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-AZ VPC** - Public/Private subnet architecture
- **NAT Gateway** - Enables private EC2 outbound internet access
- **Application Load Balancer** - Public-facing HTTP traffic routing
- **Docker Container** - Strapi runs in an isolated container
- **SSM Session Manager** - Secure EC2 access without bastion host
- **Least Privilege Security** - Strict security group rules

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS region: `us-east-1` (default)

## Quick Start

```bash
# 1. Clone and navigate
cd terraform

# 2. Initialize Terraform
terraform init

# 3. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 4. Deploy
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# 5. Access Strapi (after ~15-20 minutes)
# URL will be shown in terraform output
```

## Configuration

Edit `terraform.tfvars`:

```hcl
aws_region            = "us-east-1"
project_name          = "strapi-project"
instance_type         = "t3.medium"

# Strapi secrets (change these in production!)
strapi_app_keys       = "key1,key2"
strapi_api_token_salt = "your-salt"
strapi_admin_jwt_secret = "your-admin-secret"
strapi_jwt_secret     = "your-jwt-secret"
```

## Outputs

| Output | Description |
|--------|-------------|
| `strapi_url` | Strapi application URL via ALB |
| `ec2_instance_id` | Instance ID for SSM Session Manager |
| `ssm_connect_command` | CLI command to connect via SSM |

## Connecting to EC2

```bash
# Via AWS Console
EC2 → Select Instance → Connect → Session Manager

# Via CLI
aws ssm start-session --target <instance-id>

# Once connected, switch to ubuntu user
sudo su - ubuntu
```

---

## Common Errors & Mitigations

### 1. 502 Bad Gateway

**Cause:** EC2 user-data script ran before NAT Gateway was ready.

**Mitigation:** The script includes a connectivity wait loop (30 retries × 10s). If still occurring:
```bash
# SSH into EC2 and check logs
sudo cat /var/log/user-data.log

# Manually retry if needed
cd ~/strapi && docker compose up --build -d
```

### 2. Strapi Interactive Prompts Blocking Script

**Cause:** `create-strapi-app` requires user input for login/telemetry.

**Mitigation:** Script uses:
- `CI=true` environment variable
- `STRAPI_TELEMETRY_DISABLED=true`
- `echo "n" |` to skip prompts
- `--skip-cloud` flag

### 3. Docker Container Exits with Code 254

**Cause:** `package.json` not found - Strapi wasn't created properly.

**Mitigation:** Strapi is created on the host first (not inside Docker build), then copied into the container. Check:
```bash
ls ~/strapi/package.json
docker logs strapi
```

### 4. Node.js Version Mismatch

**Cause:** Strapi v5 requires Node.js >= 20.

**Mitigation:** Script installs Node.js 22 using NodeSource repository.

### 5. "Blocked Host" Error in Browser

**Cause:** Strapi's Vite dev server blocks unknown hostnames.

**Mitigation:** Container runs in production mode (`NODE_ENV=production`, `npm run start`) which bypasses Vite.

### 6. ALB Health Check Failures

**Cause:** Strapi takes 2-3 minutes to start after container launch.

**Mitigation:** ALB target group has:
- Health check interval: 30s
- Healthy threshold: 2
- Unhealthy threshold: 5

Wait 5+ minutes after `terraform apply` for health checks to pass.

---

## File Structure

```
terraform/
├── alb.tf           # Application Load Balancer
├── compute.tf       # EC2 instance with user-data script
├── iam.tf           # IAM role for SSM access
├── outputs.tf       # Terraform outputs
├── providers.tf     # AWS provider configuration
├── security.tf      # Security groups
├── variables.tf     # Variable definitions
├── vpc.tf           # VPC, subnets, NAT Gateway
├── terraform.tfvars # Your configuration (gitignored pattern)
└── .gitignore       # Git ignore rules
```

## Estimated Deployment Time

| Phase | Duration |
|-------|----------|
| NAT Gateway provisioning | 2-3 minutes |
| EC2 launch + connectivity wait | 1-2 minutes |
| System update + Docker install | 3-5 minutes |
| Strapi creation + Docker build | 8-12 minutes |
| ALB health check pass | 2-3 minutes |
| **Total** | **15-25 minutes** |

## Cleanup

```bash
terraform destroy -var-file=terraform.tfvars
```

## License

MIT
