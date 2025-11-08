# GitHub OIDC and IAM Module

## Purpose

This module creates GitHub Actions OIDC provider and IAM role for secure, keyless authentication from GitHub Actions workflows. It provisions:

- **OIDC Provider**: GitHub Actions OIDC provider for federated authentication
- **IAM Role**: IAM role for GitHub Actions with least-privilege permissions
- **IAM Policies**: Tag-based resource management and Terraform state access

## Responsibilities

- Enable GitHub Actions to assume IAM role without long-lived credentials
- Provide access to Secrets Manager for backend credentials
- Provide access to S3 bucket for Terraform state
- Enable tag-based resource destruction (only resources with specific tags)
- Support environment-based filtering (optional)

## Usage

```hcl
module "github" {
  source = "./modules/cicd/github"

  role_name                    = "chatops-github-actions-role"
  github_owner                 = "my-org"
  github_repo                  = "my-repo"
  github_branch                = "main"
  secrets_manager_arn          = module.secrets.secret_arn
  terraform_backend_secret_arn = module.secrets.terraform_backend_secret_arn
  s3_bucket_arn                = "arn:aws:s3:::terraform-state-bucket"

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `role_name` | Name of the IAM role | `string` | - | yes |
| `github_owner` | GitHub repository owner/organization | `string` | - | yes |
| `github_repo` | GitHub repository name | `string` | - | yes |
| `github_branch` | GitHub branch for OIDC authentication | `string` | `"main"` | no |
| `secrets_manager_arn` | ARN of Secrets Manager secret | `string` | - | yes |
| `terraform_backend_secret_arn` | ARN of Terraform backend secret | `string` | - | yes |
| `s3_bucket_arn` | ARN of S3 bucket for Terraform state | `string` | - | yes |
| `resource_tag_key` | Tag key for ChatOps-managed resources | `string` | `"ChatOpsManaged"` | no |
| `resource_tag_value` | Tag value for ChatOps-managed resources | `string` | `"true"` | no |
| `environment_tag_key` | Tag key for environment filtering | `string` | `"Environment"` | no |
| `environment_tag_value` | Optional environment tag value | `string` | `null` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `oidc_provider_arn` | ARN of the GitHub OIDC provider |
| `oidc_provider_url` | URL of the GitHub OIDC provider |
| `github_role_arn` | ARN of the GitHub Actions IAM role |
| `github_role_name` | Name of the GitHub Actions IAM role |

## Dependencies

### Required
- **Secrets Manager Secret**: Must exist for backend credentials
- **S3 Bucket**: Must exist for Terraform state storage

## Important Considerations

1. **OIDC Authentication**: Uses GitHub Actions OIDC for keyless authentication (no long-lived credentials)
2. **Branch Restriction**: Only workflows from specified `github_branch` can assume the role
3. **Tag-Based Access**: Resources must be tagged with `ChatOpsManaged=true` (default) to be destroyed
4. **Supported Resource Types**: Tag-based destroy supports EC2, S3, RDS, DynamoDB, Lambda, API Gateway, ECS, Auto Scaling, CloudFormation, ELB, CloudWatch, SNS, SQS, IAM
5. **Environment Filtering**: Optional environment tag filtering for multi-environment setups
6. **Least Privilege**: IAM policies follow least-privilege principle
7. **Read-Only Access**: Provides read-only access to EC2, S3, Secrets Manager, and state bucket
8. **Terraform State Access**: Provides read/write access to S3 bucket and Secrets Manager for Terraform state management

## Example: With Custom Tags

```hcl
module "github" {
  source = "./modules/cicd/github"

  role_name                    = "chatops-github-actions-role"
  github_owner                 = "my-org"
  github_repo                  = "my-repo"
  github_branch                = "main"
  secrets_manager_arn          = module.secrets.secret_arn
  terraform_backend_secret_arn = module.secrets.terraform_backend_secret_arn
  s3_bucket_arn                = "arn:aws:s3:::terraform-state-bucket"

  # Custom tag-based resource management
  resource_tag_key   = "ManagedBy"
  resource_tag_value = "ChatOps"

  # Environment filtering
  environment_tag_key   = "Environment"
  environment_tag_value = "production"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Example: Multi-Environment Setup

```hcl
# Production environment
module "github_prod" {
  source = "./modules/cicd/github"

  role_name                    = "chatops-github-actions-role-prod"
  github_owner                  = "my-org"
  github_repo                   = "my-repo"
  github_branch                 = "main"
  secrets_manager_arn           = module.secrets.secret_arn
  terraform_backend_secret_arn  = module.secrets.terraform_backend_secret_arn
  s3_bucket_arn                 = "arn:aws:s3:::terraform-state-prod"

  environment_tag_key   = "Environment"
  environment_tag_value = "production"

  tags = {
    Environment = "production"
  }
}

# Development environment
module "github_dev" {
  source = "./modules/cicd/github"

  role_name                    = "chatops-github-actions-role-dev"
  github_owner                  = "my-org"
  github_repo                   = "my-repo"
  github_branch                 = "develop"
  secrets_manager_arn           = module.secrets.secret_arn
  terraform_backend_secret_arn  = module.secrets.terraform_backend_secret_arn
  s3_bucket_arn                 = "arn:aws:s3:::terraform-state-dev"

  environment_tag_key   = "Environment"
  environment_tag_value = "development"

  tags = {
    Environment = "development"
  }
}
```

## Tag-Based Resource Management

This module uses tag-based IAM policies to ensure GitHub Actions can only destroy resources managed by ChatOps:

### Default Behavior
- Resources must be tagged with `ChatOpsManaged = "true"` to be destroyed
- Tag key and value are configurable via `resource_tag_key` and `resource_tag_value`

### Supported Resource Types
The tag-based destroy policy supports:
- **EC2/VPC**: Instances, security groups, VPCs, subnets, volumes, snapshots
- **S3**: Buckets, objects
- **RDS**: Instances, clusters, snapshots, parameter groups
- **DynamoDB**: Tables, backups
- **Lambda**: Functions, layers, aliases
- **API Gateway**: APIs, stages, resources
- **ECS**: Services, clusters, tasks, task definitions
- **Auto Scaling**: Groups, launch configurations, launch templates
- **CloudFormation**: Stacks, stack sets
- **ELB/ALB**: Load balancers, target groups, listeners
- **CloudWatch**: Alarms, log groups, dashboards
- **SNS**: Topics
- **SQS**: Queues
- **IAM**: Roles, policies, instance profiles (with additional safety)

### Safety Features
- **IAM Resources**: Additional safety conditions on IAM resource deletion
- **Read-Only Access**: Provides read-only access to EC2, S3, Secrets Manager
- **Environment Filtering**: Optional environment tag filtering for multi-environment setups

## GitHub Actions Workflow Example

To use this role in GitHub Actions:

```yaml
name: Terraform Apply

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/chatops-github-actions-role
          aws-region: us-east-1
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

## Related Modules

- **[Secrets Module](../../core/secrets/)** - Provides secret ARN for backend credentials
- **[Webhook Handler Module](../../core/webhook-handler/)** - Can be managed by GitHub Actions (if tagged)

