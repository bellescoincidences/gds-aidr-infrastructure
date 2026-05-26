# environments/production-iam/variables.tf

# --------------------------------------------------------------------------
# Account IDs
# --------------------------------------------------------------------------

variable "development_account_id" {
  description = "AWS account ID for the development account."
  type        = string
}

variable "staging_account_id" {
  description = "AWS account ID for the staging account."
  type        = string
}

variable "production_account_id" {
  description = "AWS account ID for the production account."
  type        = string
}

variable "gds_users_account_arn" {
  description = "ARN of the gds-users organisation root account. Format: arn:aws:iam::ACCOUNT_ID:root"
  type        = string
}

# --------------------------------------------------------------------------
# Role configuration
# --------------------------------------------------------------------------

variable "role_prefix" {
  description = "Prefix for all IAM role names."
  type        = string
  default     = "gds-aidr"
}

variable "admin_trusted_arns" {
  description = "List of specific IAM user ARNs that can assume the admin role. Should be only you and your LM."
  type        = list(string)
}

variable "github_oidc_allowed_subjects" {
  description = "GitHub OIDC subject claims allowed to assume the terraform role. Format: 'repo:org/repo-name:ref:refs/heads/branch'."
  type        = list(string)
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds. 14400 = 4 hours."
  type        = number
  default     = 14400
}
