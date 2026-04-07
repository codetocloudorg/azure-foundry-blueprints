# Azure Foundry Blueprints — Instructions

## Overview

**azure-foundry-blueprints** provides a **developer-focused enterprise-style reference implementation** for deploying Microsoft Azure Foundry using Infrastructure-as-Code (IaC).  

It supports both:

- Terraform
- Bicep

The repository demonstrates **enterprise architecture patterns** while remaining simple and easy to deploy for developers.

**Key goals:**

- Use the **latest Azure Foundry APIs**, including Foundry Project APIs
- Maintain parity between Terraform and Bicep
- Provide a self-contained dev-focused spoke environment
- Teach enterprise practices without production complexity

> This repository is **for development and learning purposes only**. It is not intended as a production landing zone.

---

## Design Philosophy

- Enterprise architecture **patterns preserved**
- Self-contained spoke: no hub, no peering dependencies
- Private networking first, secure-by-default
- Observability enabled (Application Insights + Log Analytics)
- Reusable modular IaC
- Developer-focused deployment: quick and understandable

---

## Platform Layering Model (Developer Edition)

Even for dev, we preserve the concept of **layers**:

| Enterprise Concept | Dev Implementation |
|-------------------|------------------|
| Foundation Layer  | Included inside dev deployment |
| Platform Layer    | Included inside dev deployment |
| Workload Layer    | Azure Foundry deployment |
| Environment Layer | Dev only |

---

## Repository Structure
azure-foundry-blueprints
│
├── README.md
├── INSTRUCTIONS.md
├── CONTRIBUTING.md
│
├── docs/
│   ├── architecture.md
│   ├── networking.md
│   └── observability.md
│
├── bicep/
│   ├── modules/
│   └── dev/
│
├── terraform/
│   ├── modules/
│   └── dev/
│
├── shared/
│   ├── naming/
│   ├── tags/
│   └── network-design/
│
├── scripts/
│   ├── bootstrap/
│   └── validate/
│
└── .github/
└── workflows/
**Notes:**

- Terraform and Bicep mirrors each other.
- All infrastructure is modular, even for dev.
- Only a single dev environment is included to simplify usage.

---

## Module Best Practices

- Modular, reusable building blocks
- Parameterized inputs, meaningful outputs
- Single responsibility per module
- Avoid hard-coded environment values
- Prefer **Azure Verified Modules (AVM)** where available
- All modules documented with clear intent and guidance

---

## Terraform Standards

- Remote backend required (Azure Storage recommended)
- State locking enabled
- Separate state per layer/environment
- Providers centrally managed and version pinned
- Root modules orchestrate only; logic lives in `/modules`
- Follow enterprise folder naming conventions

---

## Bicep Standards

- Modular architecture
- Reusable modules under `/modules`
- Environment parameter files
- Avoid large monolithic deployments
- Prefer AVM Bicep modules
- Maintain parity with Terraform architecture

---

## Networking Standards

Even in a dev environment, enforce:

- Segmented subnets
- Private endpoints for all supported resources
- Public access disabled where possible
- Private DNS zones configured
- Minimal controlled internet breakout
- Enterprise-style address planning

---

## Observability

- Application Insights deployed for Foundry
- Log Analytics workspace deployed
- Diagnostic settings applied to all supported resources
- Centralized metrics and logging enabled
- Observability resources deployed **before workloads**

---

## Security Standards

- Least privilege RBAC
- Managed identities preferred
- Encryption enabled by default
- Secure defaults enforced
- Private networking enforced

---

## Developer Deployment Flow
Local Validation
↓
Deploy Dev Spoke
↓
Fix Errors
↓
Experiment Safely
- Local validation: `terraform fmt`, `terraform validate`, `terraform plan`, `bicep build`, lint checks
- Azure validation: deploy dev environment, catch errors, confirm networking and observability

---

## Quick Start

1. Bootstrap Azure environment
2. Choose deployment flavour:
   - Terraform
   - Bicep
3. Deploy dev environment

Goal: deploy in **<15 minutes**.

---

## Code Quality Expectations

- Comment all code clearly
- Explain architectural and networking intent
- Document security decisions
- Enable new developers to understand infrastructure without external documentation

---

## Contributor Guidance

- Maintain Terraform/Bicep parity
- Follow module boundaries
- Respect networking and security guardrails
- Validate locally and in Azure before PRs
- Keep infrastructure modular and reusable

---

## Repository Identity

**Azure Foundry Blueprints**

> Developer-focused Azure Foundry enterprise spoke using the latest Foundry APIs with Terraform and Bicep.  
> Teaches enterprise patterns safely, simplifies development, and provides an accurate dev learning environment.
