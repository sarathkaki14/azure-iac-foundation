# State management notes

## Bicep / ARM – no state file
- Bicep has no state file. Azure Resource Manager compares the template to what is
  actually deployed every time you run it.
- Deployment history is kept in the resource group (Portal → Resource group → Deployments),
  including the inputs and outputs of each run.
- Default mode is **Incremental**: resources in the template are created or updated;
  resources that exist in Azure but are not in the template are left alone.
- Running the same deployment twice produced no changes (idempotent).

## Terraform – state file
- `terraform.tfstate` is Terraform's record of which real Azure resource belongs to each
  block in the code (resource IDs, attributes, outputs).
- `plan` compares three things: the code, the state file, and the real resources in Azure.
- After `init` with no backend, state is **local**: the file appears in the `terraform/`
  folder only after the first `apply`.
- State can contain sensitive values (for example storage account keys), so it is
  excluded from Git with `.gitignore`.
- `.terraform.lock.hcl` *is* committed – it pins provider versions so every run uses the same ones.

## Local vs remote state

| | Local state | Remote state (Azure Storage) |
|---|---|---|
| Where | `terraform.tfstate` on my laptop | Blob `module4/foundation-dev.tfstate` in container `tfstate` of `sksawebdemo` |
| Team sharing | No – only my machine knows the resources | Yes – anyone with access uses the same state |
| Locking | None across machines | Blob lease locks state during plan/apply |
| Risk | Lost laptop = Terraform loses track of resources | Durable, versionable storage |

## What I observed
- After `terraform init -migrate-state`, Terraform asked to copy the existing state to
  the new backend; the local file became empty and the blob appeared in the container.
- During `apply`, the blob showed **Lease state: Leased** (lock), released afterwards.
- A second `terraform plan` reported *No changes* – state, code and Azure all matched.

(Edit these observations to match exactly what you saw.)
