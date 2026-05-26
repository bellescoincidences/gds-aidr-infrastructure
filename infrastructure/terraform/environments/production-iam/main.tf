# environments/production-iam/main.tf
#
# Centralised IAM management. This Terraform runs in the production account and
# creates OIDC providers + IAM roles in all three accounts (development, staging, production).
#
# Why centralised: one state file, one place to see all roles, no drift
# between environments. Changes to IAM go through a single PR.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # STATE BUCKET
  backend "s3" {
    bucket         = "gds-aidr-terraform-state-production"
    key            = "production-iam/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "gds-aidr-terraform-locks-production"
  }
}

# --------------------------------------------------------------------------
# Provider: production (default — no alias needed)
# --------------------------------------------------------------------------
# This is the account you are already assumed into when you run terraform.

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Team        = "gds-aidr"
      Environment = "production"
      Repository  = "alphagov/gds-aidr-infrastructure"
    }
  }
}

# --------------------------------------------------------------------------
# Provider: development (assumes into the development account)
# --------------------------------------------------------------------------
# Uses the bootstrap role initially. Once the proper gds-aidr-terraform role
# exists in development, update role_arn to point to that instead and delete the
# bootstrap role.

provider "aws" {
  alias  = "development"
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${var.development_account_id}:role/gds-aidr-terraform-bootstrap"
    session_name = "production-iam-terraform"
  }

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Team        = "gds-aidr"
      Environment = "development"
      Repository  = "alphagov/gds-aidr-infrastructure"
    }
  }
}

# --------------------------------------------------------------------------
# Provider: staging (assumes into the staging account)
# --------------------------------------------------------------------------

provider "aws" {
  alias  = "staging"
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${var.staging_account_id}:role/gds-aidr-terraform-bootstrap"
    session_name = "production-iam-terraform"
  }

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Team        = "gds-aidr"
      Environment = "staging"
      Repository  = "alphagov/gds-aidr-infrastructure"
    }
  }
}

# --------------------------------------------------------------------------
# Module: IAM for development account
# --------------------------------------------------------------------------
# Admin role enabled — this is the sandbox account. Your contractor developer
# gets readonly access via the readonly role.

module "iam_development" {
  source = "../../modules/iam-centralised"

  providers = {
    aws = aws.development
  }

  role_prefix          = var.role_prefix
  trusted_account_arns = [var.gds_users_account_arn]

  admin_trusted_arns = var.admin_trusted_arns

  create_admin_role          = true
  create_readonly_role       = true
  create_security_audit_role = true
  create_terraform_role      = true

  github_oidc_allowed_subjects = var.github_oidc_allowed_subjects

  max_session_duration = var.max_session_duration

  tags = {
    Environment = "development"
    AccountId   = var.development_account_id
  }
}

# --------------------------------------------------------------------------
# Module: IAM for staging account
# --------------------------------------------------------------------------
# No admin role — staging is a pre-production mirror. Changes go through
# Terraform only. Readonly for humans to verify deployments.

module "iam_staging" {
  source = "../../modules/iam-centralised"

  providers = {
    aws = aws.staging
  }

  role_prefix          = var.role_prefix
  trusted_account_arns = [var.gds_users_account_arn]

  admin_trusted_arns = var.admin_trusted_arns

  create_admin_role          = false
  create_readonly_role       = true
  create_security_audit_role = true
  create_terraform_role      = true

  github_oidc_allowed_subjects = var.github_oidc_allowed_subjects

  max_session_duration = var.max_session_duration

  tags = {
    Environment = "staging"
    AccountId   = var.staging_account_id
  }
}

# --------------------------------------------------------------------------
# Module: IAM for production account
# --------------------------------------------------------------------------
# Admin role enabled but restricted to named users only (you + your LM).
# This is the most sensitive account.

module "iam_production" {
  source = "../../modules/iam-centralised"

  # No provider alias — uses the default (production) provider.

  role_prefix          = var.role_prefix
  trusted_account_arns = [var.gds_users_account_arn]

  admin_trusted_arns = var.admin_trusted_arns

  create_admin_role          = true
  create_readonly_role       = true
  create_security_audit_role = true
  create_terraform_role      = true

  github_oidc_allowed_subjects = var.github_oidc_allowed_subjects

  max_session_duration = var.max_session_duration

  tags = {
    Environment = "production"
    AccountId   = var.production_account_id
  }
}
