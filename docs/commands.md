# Commands used (in order)

## Step 1 – Git repository
```bash
git init azure-iac-foundation
cd azure-iac-foundation
mkdir -p bicep/modules bicep/params terraform docs screenshots
git add . && git commit -m "Initial repo structure"
git branch -M main
git remote add origin https://github.com/<your-user>/azure-iac-foundation.git
git push -u origin main
```

## Step 0 – Sign in and check the subscription
```bash
az login
az account show -o table
az account set --subscription "<subscription name or id>"
az bicep upgrade
terraform version
```

## Steps 2–3 – Bicep
```bash
cd bicep
az bicep build --file main.bicep          # compile check (creates main.json, git-ignored)
az bicep lint --file main.bicep
az group create -n rg-iacfnd-bicep-dev -l canadacentral --tags environment=dev owner=SK project=Module4-IaC
az deployment group what-if -g rg-iacfnd-bicep-dev -p params/dev.bicepparam
az deployment group create  -g rg-iacfnd-bicep-dev -n vnet-dev-01 -p params/dev.bicepparam
az deployment group show    -g rg-iacfnd-bicep-dev -n vnet-dev-01 --query properties.outputs
az network vnet subnet list -g rg-iacfnd-bicep-dev --vnet-name vnet-iacfnd-dev -o table

# Repeatability test: run the same create again – nothing changes
az deployment group create  -g rg-iacfnd-bicep-dev -n vnet-dev-02 -p params/dev.bicepparam

# Optional: test environment
az group create -n rg-iacfnd-bicep-test -l canadacentral --tags environment=test owner=SK project=Module4-IaC
az deployment group create -g rg-iacfnd-bicep-test -n vnet-test-01 -p params/test.bicepparam
```

## Steps 4–5 – Terraform init and local state
```bash
cd ../terraform
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
terraform fmt
terraform init
terraform validate
ls -a                       # .terraform/ folder and .terraform.lock.hcl appear
```

## Step 6 – Remote state
```bash
az storage account show -n sksawebdemo --query "{rg:resourceGroup, location:primaryLocation}" -o table
az storage container create --account-name sksawebdemo -n tfstate --auth-mode login
az role assignment create --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Storage Blob Data Contributor" \
  --scope $(az storage account show -n sksawebdemo --query id -o tsv)
cp backend.tf.example backend.tf
cp backend.hcl.example backend.hcl        # edit resource_group_name
terraform init -migrate-state -backend-config=backend.hcl
```

## Step 7 – Plan, apply, verify
```bash
terraform plan  -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
terraform output
terraform state list
terraform state show azurerm_storage_account.foundation
az resource list -g rg-iacfnd-tf-dev -o table
az storage blob list --account-name sksawebdemo -c tfstate --auth-mode login -o table
terraform plan -var-file=dev.tfvars       # second plan: "No changes"
```

## Step 8 – Commit
```bash
git add .
git status                                # confirm no .tfstate / backend.hcl staged
git commit -m "Add Bicep VNet module, Terraform RG+storage, docs and cleanup steps"
git push
```

## Cleanup
See README.md → Cleanup.
