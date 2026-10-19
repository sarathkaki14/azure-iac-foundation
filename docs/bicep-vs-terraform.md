# Bicep vs Terraform – differences observed

| Area | Bicep | Terraform |
|------|-------|-----------|
| Clouds | Azure only | Multi-cloud (Azure, AWS, GCP, many SaaS) |
| State | None – Azure is the source of truth | State file required (local or remote) |
| New Azure features | Available on day one (uses ARM API versions directly) | Waits for the azurerm provider to add support |
| Install | Comes with Azure CLI (`az bicep`) | Separate binary + provider downloads on `init` |
| Preview changes | `az deployment group what-if` | `terraform plan` |
| Parameters | `param` + `.bicepparam` files | `variable` + `.tfvars` files |
| Reuse | Modules (`module` keyword) | Modules (`module` block) |
| Deleting resources | Not automatic in Incremental mode – delete the RG or use deployment stacks | `terraform destroy` removes exactly what it created |
| Deployment history | Stored in Azure (portal Deployments blade) | Your own logs / CI pipeline; state shows current only |
| Language | Azure-flavoured DSL, compiles to ARM JSON | HCL, provider-specific resource types |

## My takeaways
- Bicep felt simpler for Azure-only work: no state to manage and what-if worked straight away.
- Terraform needed more setup (providers, state, backend) but `destroy` and `plan` give
  tighter control over the full lifecycle, and the same skills transfer to other clouds.
