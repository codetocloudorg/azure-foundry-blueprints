# Resource Group Module

Creates an Azure Resource Group — the logical container for all resources in a deployment.

## Usage

```hcl
module "resource_group" {
  source   = "../modules/resource-group"
  name     = "rg-foundry-dev-swedencentral"
  location = "swedencentral"

  tags = {
    environment = "dev"
    project     = "azure-foundry"
  }
}
```

## Inputs

| Name       | Description                          | Type          | Default | Required |
|------------|--------------------------------------|---------------|---------|----------|
| `name`     | The name of the resource group       | `string`      | —       | yes      |
| `location` | The Azure region for the resource group | `string`   | —       | yes      |
| `tags`     | Tags to apply to the resource group  | `map(string)` | `{}`    | no       |

## Outputs

| Name       | Description                        |
|------------|------------------------------------|
| `id`       | The ID of the resource group       |
| `name`     | The name of the resource group     |
| `location` | The location of the resource group |
