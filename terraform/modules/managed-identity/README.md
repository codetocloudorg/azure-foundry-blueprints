# Managed Identity Module

Creates a user-assigned managed identity for secretless authentication across Azure resources. Use this identity with RBAC role assignments to follow the principle of least privilege.

## Usage

```hcl
module "identity" {
  source              = "../modules/managed-identity"
  name                = "id-foundry-dev-swedencentral"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                  | Description                                     | Type          | Default | Required |
|-----------------------|-------------------------------------------------|---------------|---------|----------|
| `name`                | The name of the managed identity                | `string`      | —       | yes      |
| `resource_group_name` | The resource group containing this identity     | `string`      | —       | yes      |
| `location`            | The Azure region                                | `string`      | —       | yes      |
| `tags`                | Tags to apply                                   | `map(string)` | `{}`    | no       |

## Outputs

| Name           | Description                                              |
|----------------|----------------------------------------------------------|
| `id`           | The resource ID of the managed identity                  |
| `principal_id` | The principal (object) ID, used for RBAC assignments     |
| `client_id`    | The client (application) ID                              |
