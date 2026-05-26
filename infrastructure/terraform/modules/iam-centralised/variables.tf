# iam-centralised/variables.tf

variable "role_prefix" {
  description = "Prefix for all IAM role names, e.g. 'gds-aidr'."
  type        = string
  default     = "gds-aidr"
}

variable "trusted_account_arns" {
  description = "List of AWS account root ARNs that can assume roles (typically the gds-users org root)."
  type        = list(string)
}

variable "admin_trusted_arns" {
  description = "List of specific IAM user ARNs that can assume the admin role. More restrictive than trusted_account_arns — only named individuals, not the whole account."
  type        = list(string)
  default     = []
}

variable "github_oidc_allowed_subjects" {
  description = "List of GitHub OIDC subject claims allowed to assume the terraform role. Format: 'repo:org/repo-name:ref:refs/heads/branch' or 'repo:org/repo-name:*' for any branch."
  type        = list(string)
  default     = []
}

variable "create_admin_role" {
  description = "Whether to create the admin role in this account."
  type        = bool
  default     = false
}

variable "create_readonly_role" {
  description = "Whether to create the readonly role in this account."
  type        = bool
  default     = true
}

variable "create_security_audit_role" {
  description = "Whether to create the security-audit role in this account."
  type        = bool
  default     = true
}

variable "create_terraform_role" {
  description = "Whether to create the terraform role (human + OIDC) in this account."
  type        = bool
  default     = true
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds when assuming roles. 14400 = 4 hours."
  type        = number
  default     = 14400
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
