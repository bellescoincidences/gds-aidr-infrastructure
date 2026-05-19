
# `GDS` Data Innovation and AI Readiness Team Cloud Infrastructure Repository

<!--date_created: mon-18-may-2026-->
<!--date_updated: mon-18-may-2026-->

**Index**

* [Repository Structure]()
* 

---

## Tree 
*[back](#gds-data-innovation-and-ai-readiness-team-cloud-infrastructure-repository)*

The `gds-aidr-infrastructure` repository is a monorepo that combines cloud services (currently for AWS) in s single repository. The repository has been built where existing boilerplate code from the [@alphagov](@alphagov) GitHub org account exists

```
.gds-aidr-infrastructure
├── .editorconfig
├── .eslintrc
├── .github/
├── .gitignore
├── .prettierrc
├── docs/
├── frontend/
├── infrastructure/
├── package.json
├── repository_structure.md
├── services/
├── tests
├── CONTRIBUTING.md
├── LICENSE
├── README.md
└── tree.txt

22 directories, 13 files
```




---
## IAM Cross-Account Strategy

The `gds-aidr-infrastructure` project uses a centralised identity model where
all human users authenticate in the `gds-users` AWS organisation root account
and assume roles into the three target accounts (dev, staging, prod).

CI/CD pipelines (GitHub Actions) authenticate via OIDC — no long-lived
credentials are stored anywhere.


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





For new and existing user retention policies, see [docs/users/user_management.md](docs/users/user_management.md)

---

<!--END-->