###====================================================================================###
<#   
  FileName:  K8SAndGit.ps1
  Created By: Karl Vietmeier
    
  Description:
    Kubernetes and Git Functions/Aliases

#>
###====================================================================================###

###====================================================================================================###
###--- Kubernetes Related   
###====================================================================================================###

function SetKubePath { [Environment]::SetEnvironmentVariable("KUBE_CONFIG_PATH", "~/.kube/config") }
Set-Alias k8spath SetKubePath

# Bunch of Aliases
# https://manjit28.medium.com/powershell-define-shortcut-alias-for-common-kubernetes-commands-1c006d68cce2
Set-Alias -Name k -Value kubectl

function GetPods([string]$namespace='kube-system') { kubectl get pods -n $namespace }
Set-Alias -Name kgp -Value GetPods
 
function GetPods() { kubectl get pods -A }
Set-Alias -Name kgpa -Value GetPods

function GetPodsWide([string]$namespace='kube-system') { kubectl get pods -n $namespace -o wide }
Set-Alias -Name kgpw -Value GetPods

function GetPods() { kubectl get pods -A -o wide}
Set-Alias -Name kgpwa -Value GetPods

function GetAll([string]$namespace='kube-system') { kubectl get all -n $namespace }
Set-Alias -Name kgall -Value GetAll

function GetNodes() { kubectl get nodes -o wide }
Set-Alias -Name kgn -Value GetNodes

function DescribePod([string]$container, [string]$namespace='kube-system') { kubectl describe po $container -n $namespace }
Set-Alias -Name kdp -Value DescribePod

function GetLogs([string]$container, [string]$namespace='kube-system') { kubectl logs pod/$container -n $namespace }
Set-Alias -Name klp -Value GetLogs

function ApplyYaml([string]$filename, [string]$namespace='kube-system') { kubectl apply -f $filename -n $namespace }
Set-Alias -Name kaf -Value ApplyYaml

#function ExecContainerShell([string]$container, [string]$namespace='default') { kubectl exec -it $container -n $namespace — sh }
#Set-Alias -Name kexec -Value ExecContainerShell


###====================================================================================================###
###--- Git related
###====================================================================================================###

# For git commits
function Push-GitChanges {
  Param(
      [Parameter(Mandatory=$true)]
      [string]$Message
  )

  try {
      if (!(Get-Command git -ErrorAction Stop)) {
          throw "Git is not installed or not available in the system PATH."
      }

      $branch = git rev-parse --abbrev-ref HEAD
      if (!$branch) {
          throw "Failed to determine the current branch."
      }

      git add -A
      git commit -m $Message
      git push origin $branch
  }
  catch {
      Write-Error $_.Exception.Message
  }
}
Set-Alias -Name gpush -Value Push-GitChanges -Force -Option AllScope

function Get-GitTree { & git log --graph --oneline --decorate $args }
Set-Alias -Name glog -Value Get-GitTree -Force -Option AllScope

function Show-GitStatus { 
  try {
      if (Get-Command git -ErrorAction Stop) {
          & git status -sb @args
      }
  }
  catch {
      Write-Error "Git is not installed or not available in the system PATH."
  }
}
Set-Alias -Name gstatus -Value Show-GitStatus -Force -Option AllScope

function Invoke-GitPull {
    try {
        if (!(Get-Command git -ErrorAction Stop)) {
            throw "Git is not installed or not available in the system PATH."
        }

        $branch = git rev-parse --abbrev-ref HEAD
        if (!$branch) {
            throw "Failed to determine the current branch."
        }

        Write-Host "Pulling latest changes from branch: $branch"
        & git pull origin $branch @args
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

Set-Alias -Name gpl -Value Invoke-GitPull -Force -Option AllScope



<###  More GitHub aliases - uncomment to use. 

function Get-GitAdd { & git add --all $args }
Set-Alias -Name ga -Value Get-GitAdd -Force -Option AllScope

function Get-GitPush { & git push $args }
Set-Alias -Name gps -Value Get-GitPush -Force -Option AllScope

function Get-GitFetch { & git fetch $args }
Set-Alias -Name f -Value Get-GitFetch -Force -Option AllScope

function Get-GitCheckout { & git checkout $args }
Set-Alias -Name co -Value Get-GitCheckout -Force -Option AllScope

function Get-GitBranch { & git branch $args }
Set-Alias -Name b -Value Get-GitBranch -Force -Option AllScope

function Get-GitRemote { & git remote -v $args }
Set-Alias -Name r -Value Get-GitRemote -Force -Option AllScope

#>
