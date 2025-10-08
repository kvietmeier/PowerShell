###====================================================================================###
<#   
  FileName:  TerraformFunctions.ps1
  Created By: Karl Vietmeier
    
  Description:
   Terraform related functions/aliases

#>
###====================================================================================###


###====================================================================================================###
###--- Terraform Related   
###====================================================================================================###

function tfapply {
  # Get all the .tfvars files in the current directory (no recursion)
  $VarFiles = Get-ChildItem -Path . -Filter "*.tfvars" | Select-Object -ExpandProperty FullName

  # Check if any .tfvars files were found
  if ($VarFiles.Count -eq 0) {
    Write-Host "No .tfvars files found in the current directory."
    return
  }

  # Build the Terraform apply command with each -var-file argument
  $TerraformArgs = $VarFiles | ForEach-Object { "-var-file=$($_)" }

  # Run terraform apply with the .tfvars files
  terraform apply --auto-approve $TerraformArgs
}

function tfdestroy {
  # Get all the .tfvars files in the current directory (no recursion)
  $VarFiles = Get-ChildItem -Path . -Filter "*.tfvars" | Select-Object -ExpandProperty FullName

  # Check if any .tfvars files were found
  if ($VarFiles.Count -eq 0) {
    Write-Host "No .tfvars files found in the current directory."
    return
  }

  # Build the Terraform destroy command with each -var-file argument
  $TerraformArgs = $VarFiles | ForEach-Object { "-var-file=$($_)" }

  # Run terraform destroy with the .tfvars files
  terraform destroy --auto-approve $TerraformArgs
}

function tfplan {
  # Get all the .tfvars files in the current directory (no recursion)
  $VarFiles = Get-ChildItem -Path . -Filter "*.tfvars" | Select-Object -ExpandProperty FullName

  # Check if any .tfvars files were found
  if ($VarFiles.Count -eq 0) {
    Write-Host "No .tfvars files found in the current directory."
    return
  }

  # Build the Terraform plan command with each -var-file argument
  $TerraformArgs = $VarFiles | ForEach-Object { "-var-file=$($_)" }

  # Run terraform plan with the .tfvars files
  terraform plan $TerraformArgs
}

function tfshow {
  # 
  terraform show
}

function tfinit {
  # 
  terraform init
}


#function tfaks2([string]$action='apply', [string]$approve='-auto-approve', [string]$var_file='.\aks2-terraform.tfvars') {
#  terraform $action $approve -var-file=$var_file
#}
