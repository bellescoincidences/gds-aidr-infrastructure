# iam-centralised/main.tf
#
# Creates the GitHub OIDC provider and IAM roles in a single target account.
# Called once per account (development, staging, production) from the
# production-iam environment using provider aliases.

# --------------------------------------------------------------------------
# GitHub OIDC Identity Provider
# --------------------------------------------------------------------------
# This lets GitHub Actions authenticate to AWS without long-lived credentials.
# GitHub sends a signed JWT token; AWS validates it against this provider.
# One provider per account is required.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

# --------------------------------------------------------------------------
# Admin Role
# --------------------------------------------------------------------------
# Full AdministratorAccess. Only created if create_admin_role = true.
# Trust is restricted to specific named IAM user ARNs (not the broad account
# root), so only you and your LM can assume it. MFA is always required.

resource "aws_iam_role" "admin" {
  count = var.create_admin_role ? 1 : 0

  name = "${var.role_prefix}-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.admin_trusted_arns
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "admin" {
  count = var.create_admin_role ? 1 : 0

  role       = aws_iam_role.admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --------------------------------------------------------------------------
# Readonly Role
# --------------------------------------------------------------------------
# AWS-managed ReadOnlyAccess. For viewing resources, debugging, verifying
# deployments in CloudWatch, etc. Your contractor developer would use this for
# staging and production. MFA required.

resource "aws_iam_role" "readonly" {
  count = var.create_readonly_role ? 1 : 0

  name = "${var.role_prefix}-readonly"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_account_arns
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count = var.create_readonly_role ? 1 : 0

  role       = aws_iam_role.readonly[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# --------------------------------------------------------------------------
# Security Audit Role
# --------------------------------------------------------------------------
# AWS-managed SecurityAudit policy. Used by GDS Cyber Security team and
# automated scanning. Follows alphagov/cyber-security-shared-terraform-modules
# pattern.

resource "aws_iam_role" "security_audit" {
  count = var.create_security_audit_role ? 1 : 0

  name = "${var.role_prefix}-security-audit"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_account_arns
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "security_audit" {
  count = var.create_security_audit_role ? 1 : 0

  role       = aws_iam_role.security_audit[0].name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# --------------------------------------------------------------------------
# Terraform Role
# --------------------------------------------------------------------------
# Full AdministratorAccess, but trusted by BOTH humans (gds-users via MFA)
# and GitHub Actions (via OIDC). This is the role that plans and applies
# infrastructure changes. The OIDC subject condition locks it to specific
# repos and branches.

resource "aws_iam_role" "terraform" {
  count = var.create_terraform_role ? 1 : 0

  name = "${var.role_prefix}-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Human access via gds-users with MFA
      {
        Sid    = "AllowHumanAssumeWithMFA"
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_account_arns
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
      # GitHub Actions access via OIDC
      {
        Sid    = "AllowGitHubActionsOIDC"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.github_oidc_allowed_subjects
          }
        }
      }
    ]
  })

  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform" {
  count = var.create_terraform_role ? 1 : 0

  role       = aws_iam_role.terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
