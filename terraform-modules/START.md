## ✅ Terraform Modules - Clean & Ready

### Directory Structure
```
terraform-modules/
├── modules/
│   ├── resource_group/       (RG + Managed Identities with foreach + nested map)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── acr/                  (Container Registries with dynamic blocks + optional attributes)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── aks/                  (Kubernetes with nested node pools + dynamic blocks + conditionals)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── examples/
    ├── 00-provider.tf        (Provider config)
    ├── 01-variables.tf       (Input variables)
    ├── 02-prerequisites.tf   (VNet, Log Analytics, Key Vault)
    ├── 03-modules.tf         (Module usage - all 3 modules)
    ├── 04-outputs.tf         (Aggregated outputs)
    └── terraform.tfvars.example
```

### Advanced Patterns Used

✅ **foreach + Nested Maps**
- Resource Groups with nested Managed Identities
- Registries with nested Webhooks & Network Rules  
- Clusters with nested Node Pools
- Flattening: `merge([for...])` pattern

✅ **Dynamic Blocks**
- ACR IP rules, virtual network rules
- AKS add-ons, node taints, maintenance windows
- Conditional dynamic block rendering

✅ **Optional Attributes**
- `optional()` function throughout
- Sensible defaults for all fields
- Type-safe configurations

✅ **Conditional Logic**
- Resource creation based on conditions
- Ternary operators for values
- Conditional `for_each` filters

✅ **Complex Expressions**
- Tag merging with locals
- Map transformations
- Input validation

### Quick Start

```bash
cd examples
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### Module Usage Example

```hcl
module "resource_groups" {
  source = "./modules/resource_group"
  
  resource_groups = {
    core = {
      location = "eastus"
      managed_identities = {
        aks_id = { name = "aks" }
        acr_id = { name = "acr" }
      }
    }
  }
}

module "acr" {
  source = "./modules/acr"
  
  registries = {
    prod = {
      sku = "Premium"
      webhooks = {
        webhook1 = { service_uri = "..." }
      }
    }
  }
}

module "aks" {
  source = "./modules/aks"
  
  clusters = {
    prod = {
      node_pools = {
        compute = { vm_size = "Standard_D4s_v3" }
        gpu = { vm_size = "Standard_NC6s_v3" }
      }
    }
  }
}
```

---

**All code ready to use. No bloat. Just Terraform best practices. ✅**
