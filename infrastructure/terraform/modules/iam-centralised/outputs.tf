# iam-centralised/outputs.tf

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider created in this account."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "admin_role_arn" {
  description = "ARN of the admin role, if created."
  value       = var.create_admin_role ? aws_iam_role.admin[0].arn : null
}

output "readonly_role_arn" {
  description = "ARN of the readonly role, if created."
  value       = var.create_readonly_role ? aws_iam_role.readonly[0].arn : null
}

output "security_audit_role_arn" {
  description = "ARN of the security-audit role, if created."
  value       = var.create_security_audit_role ? aws_iam_role.security_audit[0].arn : null
}

output "terraform_role_arn" {
  description = "ARN of the terraform role, if created."
  value       = var.create_terraform_role ? aws_iam_role.terraform[0].arn : null
}
