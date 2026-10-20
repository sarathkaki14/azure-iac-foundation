# Module 4 – Versioned IaC Foundation Deployment

Deploys a small, repeatable Azure foundation from code instead of portal clicks.

| Tool | What it deploys | Folder | Resource group |
|------|-----------------|--------|----------------|
| **Bicep** | Virtual Network `vnet-iacfnd-dev` (10.10.0.0/16) with subnets `snet-web`, `snet-app` | `bicep/` | `rg-iacfnd-bicep-dev` |
| **Terraform** | Resource group + Storage account (Standard LRS, TLS 1.2, HTTPS only) | `terraform/` | `rg-iacfnd-tf-dev` |
| **Terraform state** | Remote state blob `module4/foundation-dev.tfstate` in a dedicated, versioned storage account | – | `rg-tfstate-sk` |

Author: Sarath Kaki (SK) · Region: Canada Central · Subscription: Pay-As-You-Go · Shell: Windows PowerShell

## Repository layout

```
azure-iac-foundation/
├── bicep/
│   ├── main.bicep                 # entry point: names, tags, calls the module
│   ├── modules/vnet.bicep         # reusable VNet + subnets module (loop over subnets)
│   └── params/
│       ├── dev.bicepparam         # dev values  (10.10.0.0/16, 2 subnets)
│       └── test.bicepparam        # test values (10.20.0.0/16, 3 subnets) – optional extension
├── terraform/
│   ├── providers.tf               # Terraform >= 1.6, azurerm ~> 4.0, random ~> 3.6
│   ├── variables.tf               # location, environment, workload, tags (with validation)
│   ├── main.tf                    # resource group + storage account
│   ├── outputs.tf                 # names / IDs printed after apply
│   ├── dev.tfvars                 # dev variable values
│   ├── .terraform.lock.hcl        # pinned provider versions (azurerm 4.81.0, random 3.9.1)
│   ├── backend.tf.example         # remote state backend  -> copy to backend.tf
│   └── backend.hcl.example        # your backend settings -> copy to backend.hcl
├── docs/
│   ├── commands.md                # every command used, in order (PowerShell)
│   ├── state-management-notes.md  # local vs remote state, observations
│   ├── bicep-vs-terraform.md      # differences observed
│   ├── bicep-deployment-output.json
│   └── terraform-outputs.txt
└── screenshots/
```

## Prerequisites

| Tool | Version used |
|------|--------------|
| Git | 2.56 |
| Azure CLI | 2.90 |
| Bicep CLI | 0.48.1 (`az bicep upgrade`) |
| Terraform | 1.16.5 |

```powershell
az login
az account set --subscription "<Pay-As-You-Go subscription name>"
az account show -o table
```

> **PowerShell note:** quote Terraform arguments whose value contains a dot, e.g.
> `"-var-file=dev.tfvars"` and `"-backend-config=backend.hcl"`. Unquoted, PowerShell splits
> them at the dot and Terraform fails with *"Too many command line arguments"*.

## Deploy – Bicep (VNet)

```powershell
cd bicep
az bicep build --file main.bicep
az bicep lint  --file main.bicep

az group create -n rg-iacfnd-bicep-dev -l canadacentral --tags environment=dev owner=SK project=Module4-IaC
az deployment group what-if -g rg-iacfnd-bicep-dev -p params\dev.bicepparam
az deployment group create  -g rg-iacfnd-bicep-dev -n vnet-dev-01 -p params\dev.bicepparam
az deployment group show    -g rg-iacfnd-bicep-dev -n vnet-dev-01 --query properties.outputs
```

Optional test environment:

```powershell
az group create -n rg-iacfnd-bicep-test -l canadacentral --tags environment=test owner=SK project=Module4-IaC
az deployment group create -g rg-iacfnd-bicep-test -n vnet-test-01 -p params\test.bicepparam
```

## Deploy – Terraform (RG + storage)

### One-time: remote state storage

```powershell
az group create -n rg-tfstate-sk -l canadacentral --tags purpose=terraform-state owner=SK project=Module4-IaC
$sa = "sttfstatesk" + (Get-Random -Minimum 10000 -Maximum 99999)   # note the name
az storage account create -n $sa -g rg-tfstate-sk -l canadacentral --sku Standard_LRS --kind StorageV2 `
  --min-tls-version TLS1_2 --https-only true --allow-blob-public-access false
az storage account blob-service-properties update --account-name $sa -g rg-tfstate-sk --enable-versioning true

$me   = az ad signed-in-user show --query id -o tsv
$saId = az storage account show -n $sa -g rg-tfstate-sk --query id -o tsv
az role assignment create --assignee-object-id $me --assignee-principal-type User `
  --role "Storage Blob Data Contributor" --scope $saId
# wait 2–5 minutes for the role to apply
az storage container create --account-name $sa -n tfstate --auth-mode login
```

### Init, plan, apply

```powershell
cd terraform
$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)   # required by azurerm 4.x; per terminal session

Copy-Item backend.tf.example backend.tf
Copy-Item backend.hcl.example backend.hcl    # set storage_account_name

terraform init -migrate-state "-backend-config=backend.hcl"
terraform validate
terraform plan "-var-file=dev.tfvars" -out=tfplan
terraform apply tfplan
terraform output
```

## Verify

```powershell
az network vnet subnet list -g rg-iacfnd-bicep-dev --vnet-name vnet-iacfnd-dev -o table
az deployment group what-if -g rg-iacfnd-bicep-dev -p params\dev.bicepparam    # expect: no change

terraform state list                                                            # 3 resources
az resource list -g rg-iacfnd-tf-dev -o table
az storage blob list --account-name $sa -c tfstate --auth-mode login -o table   # state blob
terraform plan "-var-file=dev.tfvars"                                           # expect: No changes
```

## Cleanup

Pay-As-You-Go bills until resources are deleted. Run in this order: Terraform first
(it needs its state), then Bicep, then the state storage **last**.

```powershell
# 1. Terraform resources (from terraform/)
$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
terraform destroy "-var-file=dev.tfvars"          # type yes

# 2. Bicep resource groups (deleting the RG removes the VNet and subnets)
az group delete -n rg-iacfnd-bicep-dev  --yes --no-wait
az group delete -n rg-iacfnd-bicep-test --yes --no-wait    # only if deployed

# 3. Remote state storage – only after destroy has finished
az group delete -n rg-tfstate-sk --yes --no-wait

# 4. Confirm nothing is left
az group list --query "[?starts_with(name,'rg-iacfnd') || name=='rg-tfstate-sk'].name" -o table
```

The role assignment is removed automatically when the storage account is deleted.

## Cost notes

Resource groups, VNets, subnets and ARM/Bicep deployments are free. Two near-empty
Standard LRS storage accounts and a few-KB state file cost fractions of a cent per day.

## Lessons learned

- **what-if noise:** a repeat what-if reported a "modify" on `privateEndpointVNetPolicies`, a
  default Azure sets server-side. Declaring it explicitly in `vnet.bicep` gave a clean "no change".
- **PowerShell quoting:** Terraform arguments containing a dot must be quoted.
- **Data-plane permissions:** subscription Owner can manage a storage account but needs
  *Storage Blob Data Contributor* to read and write state blobs with Entra ID auth.
- **State placement:** state lives in its own resource group so `terraform destroy` can never delete it.
