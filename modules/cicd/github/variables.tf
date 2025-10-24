variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to allow OIDC authentication from"
  type        = string
  default     = "main"
}

variable "secrets_manager_arn" {
  description = "ARN of the secrets manager secret"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


