# Module 4 – Versioned IaC Foundation Deployment

Deploys a small, repeatable Azure foundation from code instead of portal clicks:

| Tool | What it deploys | Folder |
|------|-----------------|--------|
| **Bicep** | Virtual Network with parameterized subnets (dev and test parameter files) | `bicep/` |
| **Terraform** | Resource group + storage account, with remote state in Azure Storage | `terraform/` |

Author: SK · Region: Canada Central · Subscription type: Pay-As-You-Go

## Repository layout

```
azure-iac-foundation/
├── bicep/
│   ├── main.bicep                 # entry point: names, tags, calls the module
│   ├── modules/vnet.bicep         # reusable VNet + subnets module
│   └── params/
│       ├── dev.bicepparam         # dev values  (10.10.0.0/16, 2 subnets)
│       └── test.bicepparam        # test values (10.20.0.0/16, 3 subnets)
├── terraform/
│   ├── providers.tf               # Terraform + azurerm/random provider versions
│   ├── variables.tf               # location, environment, workload, tags
│   ├── main.tf                    # resource group + storage account
│   ├── outputs.tf                 # names / IDs printed after apply
│   ├── dev.tfvars                 # dev variable values
│   ├── backend.tf.example         # remote state backend (copy to backend.tf)
│   └── backend.hcl.example        # your backend settings (copy to backend.hcl)
├── docs/
│   ├── commands.md                # every command used, in order
│   ├── state-management-notes.md  # local vs remote state observations
│   └── bicep-vs-terraform.md      # differences observed
└── screenshots/                   # evidence for submission
```

## Prerequisites

- Azure CLI (`az version`) and Bicep (`az bicep install` / `az bicep upgrade`)
- Terraform 1.6+ (`terraform version`)
- Git
- Logged in: `az login`, correct subscription selected: `az account set --subscription "<name or id>"`

## Deploy – Bicep (VNet)

```bash
cd bicep
az group create -n rg-iacfnd-bicep-dev -l canadacentral --tags environment=dev owner=SK project=Module4-IaC

# Preview first (what-if), then deploy
az deployment group what-if -g rg-iacfnd-bicep-dev -p params/dev.bicepparam
az deployment group create  -g rg-iacfnd-bicep-dev -n vnet-dev-01 -p params/dev.bicepparam

# Show the outputs again at any time
az deployment group show -g rg-iacfnd-bicep-dev -n vnet-dev-01 --query properties.outputs
```

Test environment (optional): repeat with `rg-iacfnd-bicep-test` and `params/test.bicepparam`.

## Deploy – Terraform (RG + storage)

```bash
cd terraform
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)   # PowerShell: $env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)

terraform fmt
terraform init
terraform validate
terraform plan  -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
terraform output
```

### Remote state (optional, uses the Module 3 storage account)

```bash
# one-time: container + data-plane permission
az storage container create --account-name sksawebdemo -n tfstate --auth-mode login
az role assignment create --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Storage Blob Data Contributor" \
  --scope $(az storage account show -n sksawebdemo --query id -o tsv)

cp backend.tf.example backend.tf
cp backend.hcl.example backend.hcl     # fill in resource_group_name
terraform init -migrate-state -backend-config=backend.hcl
```

## Verify

```bash
az resource list -g rg-iacfnd-bicep-dev -o table
az network vnet subnet list -g rg-iacfnd-bicep-dev --vnet-name vnet-iacfnd-dev -o table
az resource list -g rg-iacfnd-tf-dev -o table
terraform state list
```

## Cleanup (do this when done – Pay-As-You-Go bills until deleted)

```bash
# Terraform resources (run from terraform/)
terraform destroy -var-file=dev.tfvars

# Bicep resources (deleting the RG removes the VNet and subnets)
az group delete -n rg-iacfnd-bicep-dev --yes --no-wait
az group delete -n rg-iacfnd-bicep-test --yes --no-wait   # only if you deployed test

# Remote state blob (only after destroy; keeps the Module 3 account itself)
az storage blob delete --account-name sksawebdemo -c tfstate -n module4/foundation-dev.tfstate --auth-mode login

# Confirm nothing is left
az group list --query "[?starts_with(name,'rg-iacfnd')].name" -o table
```

## Cost notes

VNets, subnets, resource groups and ARM/Bicep deployments are free. The storage account
(Standard LRS, nearly empty) and the state file cost a few cents at most. Delete everything
with the cleanup section once screenshots are captured.
