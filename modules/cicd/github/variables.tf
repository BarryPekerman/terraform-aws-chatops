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

variable "project_registry_secret_arn" {
  description = "ARN of the project registry secret"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "resource_tag_key" {
  description = "Tag key for ChatOps-managed resources"
  type        = string
  default     = "ChatOpsManaged"
}

variable "resource_tag_value" {
  description = "Tag value for ChatOps-managed resources"
  type        = string
  default     = "true"
}
