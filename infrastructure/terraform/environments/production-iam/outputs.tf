# environments/production-iam/outputs.tf

# --------------------------------------------------------------------------
# Development account
# --------------------------------------------------------------------------

output "development_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN in the development account."
  value       = module.iam_development.oidc_provider_arn
}

output "development_admin_role_arn" {
  description = "Admin role ARN in the development account."
  value       = module.iam_development.admin_role_arn
}

output "development_readonly_role_arn" {
  description = "Readonly role ARN in the development account."
  value       = module.iam_development.readonly_role_arn
}

output "development_terraform_role_arn" {
  description = "Terraform role ARN in the development account."
  value       = module.iam_development.terraform_role_arn
}

# --------------------------------------------------------------------------
# Staging account
# --------------------------------------------------------------------------

output "staging_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN in the staging account."
  value       = module.iam_staging.oidc_provider_arn
}

output "staging_readonly_role_arn" {
  description = "Readonly role ARN in the staging account."
  value       = module.iam_staging.readonly_role_arn
}

output "staging_terraform_role_arn" {
  description = "Terraform role ARN in the staging account."
  value       = module.iam_staging.terraform_role_arn
}

# --------------------------------------------------------------------------
# Production account
# --------------------------------------------------------------------------

output "production_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN in the production account."
  value       = module.iam_production.oidc_provider_arn
}

output "production_admin_role_arn" {
  description = "Admin role ARN in the production account."
  value       = module.iam_production.admin_role_arn
}

output "production_readonly_role_arn" {
  description = "Readonly role ARN in the production account."
  value       = module.iam_production.readonly_role_arn
}

output "production_terraform_role_arn" {
  description = "Terraform role ARN in the production account."
  value       = module.iam_production.terraform_role_arn
}
