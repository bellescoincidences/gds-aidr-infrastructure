# IAM Cross-Account Strategy (Centralised)

<!--date_added:thurs-28-may-2026-->
<!--date_updated:thurs-28-may-2026-->

**date_updated:*** thurs-28-may-2026

**Description:** Our account strategy is built in conjunction witg GDS Engineering Enablement Cloud Platform Team and Secure by Design processes.

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

## How the cross-account assumption works

### The trust chain

Every action on the AIDR platform traces back to your `gds-users` identity.
Here is how the chain works when you run Terraform locally:

```
User (gds-users account, 622626885786)
  │
  │  1. You run `aws sts assume-role` with your MFA code.
  │     AWS checks: does gds-aidr-admin in production trust gds-users? Yes.
  │     Result: you get temporary credentials for production.
  │
  ├─► production: gds-aidr-admin (052997916327)
  │     │
  │     │  2. Terraform starts. It reads provider aliases in main.tf.
  │     │     The development alias says: assume gds-aidr-terraform in dev.
  │     │     AWS checks: does gds-aidr-terraform in dev trust gds-users? Yes.
  │     │     (Your session still carries the gds-users origin.)
  │     │     Result: Terraform can create/modify resources in dev.
  │     │
  │     ├─► development: gds-aidr-terraform (444083008220)
  │     │
  │     │  3. Same for staging.
  │     │
  │     ├─► staging: gds-aidr-terraform (577449503821)
  │     │
  │     │  4. Production resources use the default provider (no alias).
  │     │     No second hop needed — Terraform is already in production.
  │     │
  │     └─► production resources (direct, no assume needed)
  │
  │  For manual debugging (not Terraform):
  │
  ├─► development: gds-aidr-readonly (444083008220)
  │     View resources, check CloudWatch, verify deployments.
  │
  └─► staging: gds-aidr-readonly (577449503821)
        Same as above.
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

### Security considerations

1. **MFA is mandatory** for all human role assumptions.
2. **No long-lived credentials** — CI/CD uses OIDC tokens only.
3. **No admin in staging** — changes go through Terraform only.
4. **Admin trust is name-scoped** — specific user ARNs, not account root.
5. **OIDC subjects are branch-locked** — only `main` can trigger applies.
6. **4-hour session max** — limits the window if credentials are compromised.

**Terraform state**
Each environment stores state in its own S3 bucket with S3-native locking:


| Environment | S3 Bucket |
|---|---|
| development | `gds-aidr-terraform-state-development` |
| staging | `gds-aidr-terraform-state-staging` |
| production | `gds-aidr-terraform-state-production` |

State locking uses the `use_lockfile = true` setting (S3-native locking),
which replaced the older DynamoDB-based approach.


## References

- [alphagov/cyber-security-shared-terraform-modules](https://github.com/alphagov/cyber-security-shared-terraform-modules)
- [alphagov/govuk-infrastructure](https://github.com/alphagov/govuk-infrastructure)
- [alphagov/github-oidc-proxy](https://github.com/alphagov/github-oidc-proxy)
- [GDS Way: AWS account management](https://gds-way.cloudapps.digital/)

## Annex

### Bootstrap (completed)

The bootstrap process has been completed and the bootstrap roles have been
deleted. This section is kept for historical reference.

Before running the centralised Terraform for the first time, temporary
`gds-aidr-terraform-bootstrap` roles were created in development and staging.
These had `IAMFullAccess` only and trusted the production account root, so
that the first `terraform apply` could create the proper IAM roles.

After the first successful apply, the provider aliases in `main.tf` were
updated to use `gds-aidr-terraform` instead of `gds-aidr-terraform-bootstrap`,
and the bootstrap roles were deleted.

## FAQs

* **Why gds-aidr-admin, not bootstrap?**

The `bootstrap` role was a temporary role created before any Terraform-managed
roles existed. It only had `IAMFullAccess` (not full admin) and its sole
purpose was to allow the first `terraform apply` to create the proper roles.

Once the proper roles exist, the bootstrap roles are deleted. The
`gds-aidr-admin` role is the permanent replacement — it has full
`AdministratorAccess` but is restricted to named IAM users only (you and
your LM), with MFA required.

* **Why the trust works across accounts**

The `gds-aidr-terraform` roles in development and staging have a trust policy
that says: "allow anyone from the gds-users account root to assume this role,
with MFA". When you assume `gds-aidr-admin` in production, your session token
still records that you originally authenticated from `gds-users`. So when
Terraform (running as your production session) tries to assume
`gds-aidr-terraform` in development, AWS sees the gds-users origin and
allows it.

If someone tried to assume `gds-aidr-terraform` in dev directly from a
production-only role (one that doesn't trace back to gds-users), it would
be denied. This is what happened with the old `bootstrap` role — it was
a production-local role with no gds-users lineage.