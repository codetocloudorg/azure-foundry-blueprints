# Contributing to Azure Foundry Blueprints

Thank you for your interest in contributing to **azure-foundry-blueprints**. This repository provides enterprise-style reference implementations for deploying Azure AI Foundry using Terraform and Bicep. Contributions should preserve the architecture patterns, security posture, and code quality that make these blueprints useful for developers learning enterprise Azure practices.

---

## Guiding Principles

1. **Maintain Terraform/Bicep parity** — every module, parameter, and behavior available in Terraform must have a corresponding Bicep implementation, and vice versa. If you add or change a Terraform module, update the Bicep equivalent in the same PR.
2. **Follow module boundaries** — each module has a single responsibility. Do not combine unrelated resources into one module. If a new capability requires a new resource type, create a new module.
3. **Respect networking and security guardrails** — all resources must use private endpoints, public access must remain disabled, NSGs must default to deny-all inbound from the internet, and private DNS zones must be maintained. Do not introduce public IPs, service endpoints, or open inbound rules.
4. **Validate locally and in Azure before PRs** — run `terraform fmt`, `terraform validate`, and `terraform plan` (or `bicep build` and lint checks) locally, then deploy to a dev environment in Azure to confirm your changes work end-to-end.
5. **Keep infrastructure modular and reusable** — avoid hard-coded values. Use parameterized inputs with sensible defaults and expose meaningful outputs. Modules should work independently and compose cleanly.
6. **Comment all code and document intent** — explain architectural decisions, networking rationale, and security choices in code comments. A new developer should understand the infrastructure without external documentation.

---

## Repository Structure

```
azure-foundry-blueprints/
├── bicep/
│   ├── modules/        # Reusable Bicep modules (mirrors Terraform)
│   └── dev/            # Dev environment orchestration
├── terraform/
│   ├── modules/        # Reusable Terraform modules
│   └── dev/            # Dev environment orchestration
├── shared/             # Shared standards (naming, networking, tags)
├── scripts/            # Bootstrap and validation scripts
├── docs/               # Architecture and design documentation
└── .github/workflows/  # CI/CD pipelines
```

When adding or modifying code, place it in the correct location:

- **New resource type** → new module under `terraform/modules/` and `bicep/modules/`
- **New shared standard** → new directory under `shared/` with a `README.md`
- **Environment wiring** → `terraform/dev/` or `bicep/dev/`
- **Documentation** → `docs/` or inline module `README.md`

---

## Module Standards

Every module (Terraform and Bicep) must include:

| File | Purpose |
|------|---------|
| `main.tf` / `main.bicep` | Resource definitions with comments explaining intent |
| `variables.tf` / `params` | Parameterized inputs with descriptions and defaults |
| `outputs.tf` / `outputs` | Meaningful outputs for downstream module consumption |
| `README.md` | Purpose, usage example, input/output tables |

### Terraform Conventions

- Pin provider versions (currently `azurerm ~> 4.x`)
- Use `locals` for computed values and tag maps
- Mark sensitive outputs with `sensitive = true`
- Use `for_each` over `count` for named resources
- Remote backend with state locking (Azure Storage)

### Bicep Conventions

- Use parameter files for environment-specific values
- Prefer Azure Verified Modules (AVM) where available
- Use `@description()` decorators on all parameters and outputs
- Scope deployments to resource group level

---

## Networking Guardrails

These rules are non-negotiable for all contributions:

- **No public IPs** — resources are accessed via private endpoints only
- **No service endpoints** — use private endpoints exclusively
- **Private DNS zones required** — every PaaS resource with a private endpoint must have a corresponding private DNS zone linked to the VNet
- **NSG defaults enforced** — default deny inbound from internet (priority 4096), allow VNet-to-VNet (priority 100)
- **Subnets are purpose-specific** — place private endpoints in `snet-pe`, AI workloads in `snet-ai`, management in `snet-management`

If your change introduces a new PaaS resource, you must also:

1. Add a private endpoint configuration
2. Add or reference the appropriate private DNS zone
3. Disable public network access on the resource

---

## Security Requirements

- **RBAC-only authorization** — no access policies (e.g., Key Vault uses `enable_rbac_authorization = true`)
- **Managed identities** — prefer user-assigned managed identities over service principals or keys
- **Encryption enabled by default** — purge protection on Key Vault, encryption at rest on all resources
- **Least privilege** — parameterize role assignments; do not grant broad permissions
- **No secrets in code** — use Key Vault references and managed identity; never commit credentials

---

## Validation Checklist

Before submitting a pull request, confirm:

- [ ] **Local validation passes** — `terraform fmt -check`, `terraform validate`, `terraform plan` succeed (or `bicep build`, lint)
- [ ] **Azure deployment succeeds** — resources deploy cleanly in a dev environment
- [ ] **Terraform/Bicep parity maintained** — changes exist in both IaC flavours
- [ ] **Module README updated** — input/output tables and usage examples reflect your changes
- [ ] **Networking guardrails respected** — no public access, private endpoints configured, DNS zones linked
- [ ] **Code is commented** — architectural intent, security decisions, and networking rationale are explained
- [ ] **Naming conventions followed** — resources use the format `{prefix}-{workload}-{env}-{region}-{instance}` per `shared/naming/README.md`
- [ ] **Tags applied** — all resources include the five required tags (environment, workload, owner, cost-center, managed-by)

---

## Pull Request Process

1. **Fork and branch** — create a feature branch from `main` with a descriptive name (e.g., `add-storage-module`, `fix-nsg-rules`)
2. **Make changes** — follow the standards above, keeping commits focused and well-described
3. **Validate** — complete the validation checklist
4. **Open PR** — provide a clear description of what changed and why, reference any related issues
5. **Review** — maintainers will review for architecture alignment, security posture, and code quality
6. **Merge** — once approved and CI passes, your PR will be merged

---

## Questions?

If you are unsure about module boundaries, networking patterns, or security requirements, open an issue describing your proposed change before starting work. The maintainers are happy to help align your contribution with the project's architecture.
