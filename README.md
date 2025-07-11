# AWS LLM Infrastructure

This repository contains Terraform configurations for deploying a secure, scalable AWS environment for running LLMs.

## Architecture Overview

- VPC with public and private subnets across 2 AZs
- Bastion host for secure SSH access
- Auto Scaling Group running local LLM instances
- RDS PostgreSQL database with pgvector support
- NAT Gateway for private subnet internet access

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- SSH key pair for bastion host access

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── networking/    # VPC, subnets, NAT Gateway
│   │   ├── bastion/      # Bastion host configuration
│   │   ├── asg/          # Auto Scaling Group for LLM instances
│   │   └── database/     # RDS PostgreSQL configuration
│   ├── environments/
│   │   └── prod/         # Production environment configuration
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   └── main.tf          # Main configuration
└── scripts/             # Helper scripts and instance configuration
```

## Usage

1. Initialize Terraform:
```bash
cd terraform/environments/prod
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

## Security Considerations

- Bastion host is the only public-facing instance
- Private subnets for compute and database resources
- Security groups with minimal required access
- All sensitive data should be stored in AWS Secrets Manager

## Maintenance

- Regular updates of AMIs and software packages
- Monitoring and logging via CloudWatch
- Backup strategy for RDS instances

## Contributing

1. Create a new branch for your changes
2. Make your changes and test thoroughly
3. Submit a pull request with a clear description of changes

## License

MIT 