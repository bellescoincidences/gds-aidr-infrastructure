# IAM Cross-Account Strategy (Centralised)

<!--date_added:thurs-28-may-2026-->
<!--date_updated:thurs-28-may-2026-->

**date_updated:*** thurs-28-may-2026

---

## Overview

All IAM roles and GitHub OIDC providers across all three AWS accounts
(development, staging, production) are managed from a single Terraform
environment: `production-iam`.

This runs in the production account and uses provider aliases to assume into
development and staging to create resources there.

**Why centralised**

- **Single source of truth**: one state file contains every role across every
  account. No drift between environments.
- **Single PR**: a change to any role goes through one pull request with one
  review.
- **Auditability**: `terraform state list` shows every role in the organisation.

**Proposed layout**
```
gds-users (org root, 622626885786)
├── gds-aidr-development (444083008220)
│   ├── gds-aidr-admin          ← admins only
│   ├── gds-aidr-readonly
│   ├── gds-aidr-security-audit
│   ├── gds-aidr-terraform      ← human + GitHub OIDC
│   └── GitHub OIDC provider
├── gds-aidr-staging (577449503821)
│   ├── gds-aidr-readonly
│   ├── gds-aidr-security-audit
│   ├── gds-aidr-terraform      ← human + GitHub OIDC
│   └── GitHub OIDC provider
└── gds-aidr-production (052997916327)
    ├── gds-aidr-admin          ← admins only
    ├── gds-aidr-readonly
    ├── gds-aidr-security-audit
    ├── gds-aidr-terraform      ← human + GitHub OIDC
    └── GitHub OIDC provider
```

### How the cross-account assumption works

```
(gds-users account)
  │
  ├─ aws sts assume-role ──► production: gds-aidr-admin (MFA required)
  │                             │
  │                             └─ terraform runs here
  │                                  │
  │                                  ├─ provider "aws" { }                    → production resources
  │                                  ├─ provider "aws" { alias=development }  → development resources
  │                                  └─ provider "aws" { alias=staging }      → staging resources
  │
  ├─ aws sts assume-role ──► development: gds-aidr-readonly (MFA required)
  │   (for manual debugging)
  │
  └─ aws sts assume-role ──► staging: gds-aidr-readonly (MFA required)
      (for manual debugging)
```

### Role scopes (planned)

**admin**: Full `AdministratorAccess`. In development and production only.
Trust restricted to specific named IAM user ARNs (not the broad account root).
MFA always required.

**readonly**: AWS-managed `ReadOnlyAccess`. For viewing resources, debugging,
verifying CloudWatch logs. Developers uses this for staging and
production. MFA required.

**security-audit**: AWS-managed `SecurityAudit`. Used by the GDS Cyber
Security team and automated scanning tools. Follows
`alphagov/cyber-security-shared-terraform-modules` pattern.

**terraform**: Full `AdministratorAccess`. Trusts both gds-users (human, MFA)
and GitHub Actions (OIDC). The OIDC subject is locked to
`repo:alphagov/gds-aidr-infrastructure:ref:refs/heads/main` so only merged
PRs can trigger applies.

### How to assume a role (CLI)

```bash
# ~/.aws/config
[profile gds-aidr-bootstrap-production] # ADMINS ONLY
role_arn = arn:aws:iam::052997916327:role/gds-aidr-admin
source_profile = gds-users
mfa_serial = arn:aws:iam::622626885786:mfa/<your-username>
duration_seconds = 14400
region = eu-west-2

[profile gds-aidr-bootstrap-development]
role_arn = arn:aws:iam::444083008220:role/gds-aidr-readonly
source_profile = gds-users
mfa_serial = arn:aws:iam::622626885786:mfa/<your-username>
duration_seconds = 14400
region = eu-west-2
```

```bash
# Verify it works
aws sts get-caller-identity --profile gds-aidr-bootstrap-production
```

**How to apply**

```bash
cd infrastructure/terraform/environments/production-iam
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values

export AWS_PROFILE=gds-aidr-bootstrap-production
terraform init
terraform plan
terraform apply
```

<!--
COMMENTING OUT BECAUSE ONLY RELEVANT IN FIRST-TIME SETUP
## Bootstrap

Before running the centralised Terraform for the first time, ADMIN need to
create minimal trust roles in development and staging so that Terraform
(running in production) can assume into those accounts.

See `infrastructure/terraform/bootstrap/README.md` for the step-by-step
instructions.

After the first successful `terraform apply`, the proper `gds-aidr-terraform`
roles exist in development and staging. Update the provider aliases in
`main.tf` to use those roles instead of the bootstrap ones, then delete the
bootstrap roles.-->

### Security considerations

1. **MFA is mandatory** for all human role assumptions.
2. **No long-lived credentials** — CI/CD uses OIDC tokens only.
3. **No admin in staging** — changes go through Terraform only.
4. **Admin trust is name-scoped** — specific user ARNs, not account root.
5. **OIDC subjects are branch-locked** — only `main` can trigger applies.
6. **4-hour session max** — limits the window if credentials are compromised.

**Terraform state**

Each environment stores state in its own S3 bucket with DynamoDB locking:

| Environment | S3 Bucket | DynamoDB Table |
|---|---|---|
| development | `gds-aidr-terraform-state-development` | `gds-aidr-terraform-locks-development` |
| staging | `gds-aidr-terraform-state-staging` | `gds-aidr-terraform-locks-staging` |
| production | `gds-aidr-terraform-state-production` | `gds-aidr-terraform-locks-production` |

The S3 backend configuration is commented out in `production-iam/main.tf` —
uncomment and configure once the state buckets exist.

### References

- [alphagov/cyber-security-shared-terraform-modules](https://github.com/alphagov/cyber-security-shared-terraform-modules)
- [alphagov/govuk-infrastructure](https://github.com/alphagov/govuk-infrastructure)
- [alphagov/github-oidc-proxy](https://github.com/alphagov/github-oidc-proxy)
- [GDS Way: AWS account management](https://gds-way.cloudapps.digital/)
