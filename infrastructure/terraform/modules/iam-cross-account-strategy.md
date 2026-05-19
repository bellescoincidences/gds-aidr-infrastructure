# GDS AIDR IAM Cross-Account Strategy

<!--date_added:tues19-may-2026-->
<!--date_updated:tues19-may-2026-->

## Overview

The `gds-aidr-infrastructure`  uses a centralised identity model where
all human users authenticate in the `gds-users` AWS organisation root account
and assume roles into the three target accounts (dev, staging, prod).

CI/CD pipelines (GitHub Actions) authenticate via OIDC — no long-lived
credentials are stored anywhere.

## Account Layout

```
gds-users (org root)
├── dev account
│   ├── gds-aidr-admin
│   ├── gds-aidr-readonly
│   ├── gds-aidr-security-audit
│   └── gds-aidr-terraform
├── staging account
│   ├── gds-aidr-readonly
│   ├── gds-aidr-security-audit
│   └── gds-aidr-terraform
└── prod account
    ├── gds-aidr-readonly
    ├── gds-aidr-security-audit
    └── gds-aidr-terraform
```

## Role Descriptions

**admin**: Full `AdministratorAccess`. Only in dev. For initial setup and
break-glass scenarios. Requires MFA.

**readonly**: AWS-managed `ReadOnlyAccess`. For viewing resources, debugging,
and dashboarding. Requires MFA.

**security-audit**: AWS-managed `SecurityAudit`. Used by the GDS Cyber Security
team and automated scanning tools. Follows the pattern from
`alphagov/cyber-security-shared-terraform-modules`.

**terraform**: Full `AdministratorAccess` but trusts both gds-users (human)
and GitHub Actions OIDC (CI/CD). This is the role that plans and applies
infrastructure changes.

## How to Assume a Role

### From the CLI

```bash
# Configure your gds-users profile in ~/.aws/config
[profile gds-aidr-dev]
role_arn = arn:aws:iam::<DEV_ACCOUNT_ID>:role/gds-aidr-admin
source_profile = gds-users
mfa_serial = arn:aws:iam::<GDS_USERS_ACCOUNT_ID>:mfa/<your-username>
region = eu-west-2

# Then use it
aws sts get-caller-identity --profile gds-aidr-dev
```

### From GitHub Actions

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<DEV_ACCOUNT_ID>:role/gds-aidr-terraform
    aws-region: eu-west-2
```

## Applying the Terraform

Each environment has its own directory under
`infrastructure/terraform/environments/`. Apply them one at a time using the
bootstrap role:

```bash
cd infrastructure/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with actual account IDs

terraform init
terraform plan
terraform apply
```

Repeat for staging and prod.

## Security Considerations

1. **MFA is mandatory** for all human role assumptions.
2. **No long-lived credentials** — CI/CD uses OIDC tokens only.
3. **Admin role only in dev** — staging and prod use readonly + terraform.
4. **Permissions boundaries** can be added via `permissions_boundary_arn`.
5. **IP restrictions** can be added via `allowed_source_ips` if needed.
6. **GitHub OIDC subjects** are locked to specific repos and branches.

## Terraform State

State should be stored in S3 with DynamoDB locking. Each environment gets its
own state bucket and lock table to prevent cross-environment interference. The
S3 backend configuration is commented out in each environment's `main.tf` —
uncomment and configure once the state buckets exist.

## References

- [GDS Way: AWS account management](https://gds-way.cloudapps.digital/)
- [alphagov/cyber-security-shared-terraform-modules](https://github.com/alphagov/cyber-security-shared-terraform-modules)
- [alphagov/govuk-infrastructure](https://github.com/alphagov/govuk-infrastructure)
- [alphagov/github-oidc-proxy](https://github.com/alphagov/github-oidc-proxy)

---

<!--END-->