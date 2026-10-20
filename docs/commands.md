# Commands used (in order) – Windows PowerShell

## Step 0 – Tools and sign-in
```powershell
git --version              # 2.56.0
az version                 # 2.90.0
az bicep upgrade           # Bicep 0.48.1
terraform version          # 1.16.5
az login
az account set --subscription "<Pay-As-You-Go subscription name>"
az account show -o table
```

## Step 1 – Git repository
```powershell
cd "C:\Users\kakis\Downloads\Azure\Module Projects\Module 4"
Expand-Archive -Path ".\azure-iac-foundation.zip" -DestinationPath "."
cd ".\azure-iac-foundation"
git init
git branch -M main
git add .
git commit -m "Initial repo structure with bicep and terraform folders"
git remote add origin https://github.com/sarathkaki14/azure-iac-foundation.git
git push -u origin main
```

## Step 2 – Bicep validation
```powershell
cd bicep
az bicep build --file main.bicep
az bicep lint --file main.bicep
az bicep build-params --file params\dev.bicepparam
```

## Step 3 – Bicep deployment
```powershell
az provider show -n Microsoft.Network --query registrationState -o tsv
az group create -n rg-iacfnd-bicep-dev -l canadacentral --tags environment=dev owner=SK project=Module4-IaC
az deployment group what-if -g rg-iacfnd-bicep-dev -p params\dev.bicepparam
az deployment group create -g rg-iacfnd-bicep-dev -n vnet-dev-01 -p params\dev.bicepparam | Tee-Object -FilePath ..\docs\bicep-deployment-output.json
az deployment group show -g rg-iacfnd-bicep-dev -n vnet-dev-01 --query properties.outputs
az network vnet subnet list -g rg-iacfnd-bicep-dev --vnet-name vnet-iacfnd-dev -o table

# Repeatability: first re-run showed what-if noise on privateEndpointVNetPolicies;
# after declaring it in vnet.bicep the result was "1 no change"
az deployment group what-if -g rg-iacfnd-bicep-dev -p params\dev.bicepparam
```

## Steps 4–5 – Terraform init and local state behaviour
```powershell
cd ..\terraform
terraform fmt -check
$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
terraform init
terraform validate
Get-ChildItem -Force
terraform providers
terraform state list                       # "No state file was found!"
terraform plan "-var-file=dev.tfvars"      # Plan: 3 to add (quoted for PowerShell)
git add .terraform.lock.hcl
git commit -m "Add Terraform provider lock file"
```

## Step 6 – Remote state (dedicated storage account; Module 3 account no longer existed)
```powershell
az group create -n rg-tfstate-sk -l canadacentral --tags purpose=terraform-state owner=SK project=Module4-IaC
$sa = "sttfstatesk" + (Get-Random -Minimum 10000 -Maximum 99999)
az storage account create -n $sa -g rg-tfstate-sk -l canadacentral --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --https-only true --allow-blob-public-access false --tags purpose=terraform-state owner=SK
az storage account blob-service-properties update --account-name $sa -g rg-tfstate-sk --enable-versioning true
$me   = az ad signed-in-user show --query id -o tsv
$saId = az storage account show -n $sa -g rg-tfstate-sk --query id -o tsv
az role assignment create --assignee-object-id $me --assignee-principal-type User --role "Storage Blob Data Contributor" --scope $saId
az storage container create --account-name $sa -n tfstate --auth-mode login
Copy-Item backend.tf.example backend.tf
Copy-Item backend.hcl.example backend.hcl          # set resource_group_name and storage_account_name
terraform init -migrate-state "-backend-config=backend.hcl"
```

## Step 7 – Plan, apply, verify
```powershell
terraform plan "-var-file=dev.tfvars" -out=tfplan
terraform apply tfplan
terraform output | Tee-Object -FilePath ..\docs\terraform-outputs.txt
terraform state list
terraform state show azurerm_storage_account.foundation
az resource list -g rg-iacfnd-tf-dev -o table
az storage blob list --account-name $sa -c tfstate --auth-mode login -o table
terraform plan "-var-file=dev.tfvars"              # No changes

# Drift test (optional)
az tag update --resource-id (az group show -n rg-iacfnd-tf-dev --query id -o tsv) --operation Merge --tags manualChange=yes
terraform plan "-var-file=dev.tfvars"              # shows tag removal
terraform apply "-var-file=dev.tfvars"             # restores code-defined state
```

## Step 8 – Commit
```powershell
cd ..
git status
git add .
git commit -m "Update README, commands and state notes; final Module 4 submission"
git push
git tag -a v1.0 -m "Module 4 submission"
git push origin v1.0
```

## Cleanup
See README.md → Cleanup.
