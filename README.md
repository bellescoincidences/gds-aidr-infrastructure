

```
govsynth-infra-core-tf/
├── modules/              # Reusable Gov-standard components
├── environments/
│   ├── dev/              # Dev account overrides
│   │   ├── main.tf       # Source modules/compute
│   │   └── variables.tf
│   └── prod/             # Prod account (mirrored config)
│       ├── main.tf       
│       └── variables.tf

```