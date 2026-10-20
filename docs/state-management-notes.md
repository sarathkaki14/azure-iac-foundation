# State management notes

## Bicep / ARM – no state file
- Bicep keeps no state. Azure Resource Manager compares the template with the live resources
  on every deployment.
- Deployment history (inputs and outputs) is stored in the resource group:
  Portal → `rg-iacfnd-bicep-dev` → Deployments → `vnet-dev-01`.
- Default mode is **Incremental**: resources in the template are created or updated; resources
  that exist in Azure but not in the template are left alone (Bicep does not delete them).
- Repeat deployments are idempotent. The first repeat what-if reported a "modify" on
  `privateEndpointVNetPolicies` – a default Azure applies server-side, so it existed on the live
  VNet but not in the template. After declaring it explicitly, what-if returned **"1 no change"**.

## Terraform – state file
- `terraform.tfstate` is Terraform's record of which real Azure resource belongs to each
  block of code (resource IDs, attributes, outputs).
- `plan` compares three things: the code, the state, and the real resources in Azure.
- After the first `terraform init` the backend was **local**. `terraform state list` returned
  *"No state file was found!"* and `plan` proposed 3 resources to add – without state,
  Terraform assumes it manages nothing. Plan does not write state; only apply does.
- `.terraform.lock.hcl` is committed (pins azurerm 4.81.0 and random 3.9.1).
  `.terraform/`, `*.tfstate`, `tfplan`, `backend.tf` and `backend.hcl` are git-ignored.

## Remote state configuration
- The Module 3 storage account no longer existed, so a dedicated state account was created:
  `sttfstatesk#####` (StorageV2, Standard LRS, TLS 1.2, HTTPS only, no public blob access,
  **blob versioning enabled**) in its own resource group `rg-tfstate-sk`.
- Keeping state in a separate resource group means `terraform destroy` can never delete its own state.
- Backend: `azurerm`, container `tfstate`, key `module4/foundation-dev.tfstate`.
- Authentication: Entra ID (`use_azuread_auth = true`) – no storage keys in any file.
  Subscription Owner was not enough: blob access is data plane and required the
  **Storage Blob Data Contributor** role, scoped to the state storage account only.
- Partial configuration: fixed settings in `backend.tf`, personal values in `backend.hcl`
  (backend blocks cannot use variables). `.example` versions are committed.
- `terraform init -migrate-state "-backend-config=backend.hcl"` switched the backend to azurerm.

## Local vs remote state

| | Local state | Remote state (Azure Storage) |
|---|---|---|
| Location | `terraform.tfstate` on my laptop | Blob in private `tfstate` container |
| Sharing | One machine only | Anyone with access uses the same state |
| Locking | None across machines | Blob lease ("Acquiring/Releasing state lock") |
| Durability | Lost laptop = lost state | Durable, with blob versioning for rollback |
| Secrets | Plain-text file on disk | Private container, Entra ID access |

## Observations
- Plan and apply printed *Acquiring state lock* / *Releasing state lock*; after the run the
  blob's lease state was **Available**.
- The state blob appeared only after the first apply.
- The state file contains the storage account access keys in plain text – the reason it is
  never committed and is kept in a private container.
- A second plan reported **"No changes"**. The random storage-name suffix stayed the same
  because its value is stored in state.
- Drift test: a tag added manually in Azure was detected by `terraform plan` and removed by
  `terraform apply` – the code is the source of truth.
