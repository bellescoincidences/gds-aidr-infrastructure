
# GDS Data Innovation and AI Readiness Team Cloud Infrastructure Repository

<!--date_created: mon-18-may-2026-->
<!--date_updated: fri-29-may-2026-->


**Index**
 - [Repository Structure](#repository-structure)
 - [Get access to AIDR platform](#get-access-to-the-aidr-platform)
    *  [For developers and platform admins](#for-developers-and-platform-admins)

> **Note:** to avoid confusion we will not use short forms of any of the environment names. Development and Production will be referred to as that in any code, variables, policies and documents, not *Dev* or *Prod*

This is a **public repository**

---
## Repository Structure
*[(back)](#gds-data-innovation-and-ai-readiness-team-cloud-infrastructure-repository)*

```zsh
.gds-aidr-platform
├── .editorconfig
├── .eslintrc
├── .github
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── workflows
├── .gitignore
├── .prettierrc
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── infrastructure
│   └── terraform
│       ├── bootstrap
│       │   ├── trust-policy-development.json
│       │   └── trust-policy-staging.json
│       ├── environments
│       │   └── production-iam
│       │       ├── .terraform.lock.hcl
│       │       ├── main.tf
│       │       ├── outputs.tf
│       │       ├── terraform.tfvars
│       │       ├── terraform.tfvars.example
│       │       └── variables.tf
│       └── modules
│           └── iam-centralised
│               ├── main.tf
│               ├── outputs.tf
│               └── variables.tf
├── package.json
└── tree.txt
```
---

<!--There is no infrastructure in this repository. Code will be migrated once tested and necessary security parameters are in place-->

## Get access to the AIDR platform

**Some mandatory disclaimers**
* All users, with the exception of developer/engineer and admin users have access to the AIDR development environment.
* Developer/engineers and platform admins have access to all three environments. 
* Usage is tagged and tracked to ensure we can keep on top of resource use and spend per individual
* You will not have any rights to create iam roles on any account.
* Only `eu-west-2` region is permitted **by default**, without exception for anyone on the platform, including developer/engineer/platform admins. 

### Access the AIDR platform

0. If you are not currently a user on `gds-users` you will not be able to access the AIDR accounts

    **Request an AWS account from `gds-users`**
    
    **[https://engineering-enablement.gds-reliability.engineering/engineering/aws/users.html#requesting-a-new-aws-user](https://engineering-enablement.gds-reliability.engineering/engineering/aws/users.html#requesting-a-new-aws-user)**

> This is handled by another team in GDS/DSIT, you can contact engineering enablement on slack. The link above also has contact/escalation information. AIDR team cannot assist with this step. If you have issues with dsit email, contact EE team.


### Setup AWS CLI

> You must have MFA setup to use AWS. Once you have a `gds-users` user account on the organisation root:

1. [Login to AWS Console `eu-west-2`](https://eu-west-2.signin.aws.amazon.com/oauth?response_type=code&client_id=arn%3Aaws%3Asignin%3A%3A%3Aconsole%2Fcanvas&redirect_uri=https%3A%2F%2Feu-west-2.console.aws.amazon.com%2Fconsole%2Fhome%3Fca-oauth-flow-id%3D2e22%26hashArgs%3D%2523%26isauthcode%3Dtrue%26region%3Deu-west-2%26state%3DhashArgsFromTB_eu-west-2_6074d4ffbdeee16b&forceMobileLayout=0&forceMobileApp=0&code_challenge=sMKSP6mpJF8GyuCYUITXDoM1akiBy3asMJqP2U7AYpw&code_challenge_method=SHA-256)
2. Navigate to the top RHS: username -> Security Credentials
3. Setup MFA.
4. Make a note of these when you set up MFA and store in a safe place. You will need this to access AWS CLI: 
   
   - MFA_SERIAL/ARN
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY

5. Log in and out for changes to take effect. You should need to provide your MFA this time. 
    
> AWS accounts within AIDR team are assumed via the alphagov `gds-users` organisation/root account


### Assume role

0. You will be given a ROLE_ARN by the platform admin. Keep this in a safe place. 

> The following guidance assumes you have access to VSCODE

1. Install [`awscli`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

2. Configure your AWS profile(s)

> It is quite common to have more than one AWS profile for each role you are assuming

3. Your profile in `.config` will look like this; one corresponds to the ROOT `gds-users` account which you assume role into the AIDR platform, and the other corresponds to your role

```~.aws/~.config
# required by everyone
[profile gds-users]
region=eu-west-2
output=json
mfa_serial=<MFA_SERIAL>

# your specific profile
[profile gds-aidr-platform]
role_arn=<ROLE_ARN>
source_profile = gds-users
mfa_serial=<MFA_SERIAL>
region = eu-west-2
```

```~.aws/~.credentials
# required by everyone
[default]
aws_access_key_id=AWS_ACCESS_KEY_ID
aws_secret_access_key=AWS_SECRET_ACCESS_KEY_ID

# your specific profile
[profile gds-aidr-platform]
role_arn=<ROLE_ARN>
source_profile = gds-users
mfa_serial=<MFA_SERIAL>
region = eu-west-2
```

        
4. Assume your role via TerminalThe STS command looks like this. Copy-paste this block into a text file and update the values as required. `token-code` is your 6-digit MFA code. You can then copy the whole thing and paste into Terminal

```zsh
aws sts assume-role \
--role-arn "<ROLE_ARN" \
--role-session-name "TerraformLocalSession-AIDR" \
--serial-number "MFA_SERIAL" \
--token-code XXXXXX \ 
--profile gds-users \
```

5. Verify you are assumed into the role: `aws sts get-caller-identity`. The result should be something like this:

```zsh
    {
    "Credentials": {
        "AccessKeyId": "AWS_ACCESS_KEY_ID",
        "SecretAccessKey": "AWS_SECRET_ACCESS_KEY",
        "SessionToken": "",
        "Expiration": ""
    },
    "AssumedRoleUser": {
        "AssumedRoleId": "",
        "Arn": "ROLE_ARN+LOCAL_SESSION_NAME"
```

---

### For developers and platform admins

#### Files you must never commit

The `.gitignore` in this repository is configured to exclude sensitive and
generated files. However, as an additional safeguard, be aware of the
following:

**`terraform.tfvars`** — contains real AWS account IDs, IAM user ARNs, and
organisation account references. Each environment directory has a
`terraform.tfvars.example` file with placeholder values — copy this to
`terraform.tfvars` locally and fill in your values. The `.example` file is
safe to commit; the actual `.tfvars` file is not.

**`.terraform/`** — generated by `terraform init`. Contains downloaded
provider binaries and module caches. Never commit this directory. It is
regenerated automatically when anyone runs `terraform init`.

**`.terraform.lock.hcl`** — records the exact provider versions used.
This file **should** be committed (it ensures everyone uses the same
provider versions).

**`*.tfstate` / `*.tfstate.backup`** — Terraform state files. These are
stored remotely in S3, not locally. If you ever see one locally, do not
commit it — state files can contain sensitive resource attributes.

#### Terraform plugin cache (recommended)

By default, `terraform init` downloads the AWS provider binary (~300MB) into
each environment's `.terraform/` directory separately. If you are working
across multiple environments (development, staging, production), this
adds up.

To share a single copy of the provider across all environments, add this to
your shell configuration:

```zsh
# Add to ~/.zshrc (macOS) or ~/.zshrc (Linux)
echo 'export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"' >> ~/.zshrc
mkdir -p "$HOME/.terraform.d/plugin-cache"
source ~/.zshrc
```

This tells Terraform to cache provider binaries in one central location.
Every subsequent `terraform init` in any environment directory will symlink
to the cached provider instead of downloading it again. Saves disk space
and time.

#### Assuming roles for Terraform

Terraform cannot handle interactive MFA prompts. When running Terraform
locally, you need to assume into the target account first and export the
session credentials:

```zsh
eval $(aws sts assume-role \
  --role-arn "<ROLE_ARN>" \
  --role-session-name "TerraformSession" \
  --serial-number "<MFA_SERIAL>" \
  --token-code <YOUR_MFA_CODE> \
  --profile gds-users \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text | awk '{print "export AWS_ACCESS_KEY_ID="$1"\nexport AWS_SECRET_ACCESS_KEY="$2"\nexport AWS_SESSION_TOKEN="$3}')

unset AWS_PROFILE

# Verify you are in the correct account
aws sts get-caller-identity
```

Then run `terraform init`, `terraform plan`, or `terraform apply` as normal.
The session lasts 4 hours (configured via `max_session_duration` on the IAM
roles).

#### Repository structure (infrastructure)  

```
infrastructure/terraform/
├── bootstrap/                      # one-time setup for cross-account trust
│   ├── trust-policy-development.json
│   └── trust-policy-staging.json
├── environments/
│   └── production-iam/             # centralised IAM (runs in production)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
└── modules/
    └── iam-centralised/            # reusable module for OIDC + IAM roles
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

For detailed architecture documentation, see[`docs/infrastructure/iam-cross-account-strategy.md`.](docs/infrastructure/iam-cross-account-strategy.md)

---

---

<!--END-->
