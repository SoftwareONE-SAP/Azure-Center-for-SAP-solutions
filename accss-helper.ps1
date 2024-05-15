# Import Azure PowerShell Module
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}

# Connect to Azure Account
Connect-AzAccount

# Function to prompt for additional criteria and validate the responses
function Prompt-ForCriteria {
    param (
        [string]$CriteriaName
    )
    $response = $null
    while ($response -notin @("All", "Some", "None")) {
        $response = Read-Host -Prompt "Do any systems meet the criteria for $CriteriaName? (All/Some/None)"
    }
    return $response
}

# Prompt for each criteria
$hanaLargeInstance = Prompt-ForCriteria "HANA Large Instance (HLI)"
$hanaScaleOut = Prompt-ForCriteria "Systems with HANA Scale-out, MCOS and MCOD configurations"
$javaStack = Prompt-ForCriteria "Java stack"
$dualStack = Prompt-ForCriteria "Dual stack (ABAP and Java)"
$ipv6 = Prompt-ForCriteria "Systems using IPv6 addresses"
$multipleSIDs = Prompt-ForCriteria "Multiple SIDs running on same set of Virtual Machines"

# Check if any criteria is not supported
$unsupported = @($hanaLargeInstance, $hanaScaleOut, $javaStack, $dualStack, $ipv6, $multipleSIDs) -contains "All" -or @($hanaLargeInstance, $hanaScaleOut, $javaStack, $dualStack, $ipv6, $multipleSIDs) -contains "Some"

if ($unsupported) {
    Write-Host "Some or all of these systems are not supported."
    Write-Host "Please review the unsupported criteria and adjust accordingly."
    return
}

# Initialize an array to hold VM details
$vmDetails = @()

# Get all subscriptions
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    # Set the current context to the subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Get all VMs in the current subscription
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        # Get VM status
        $vmStatus = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses[1].DisplayStatus
        
        # Check if VM is running
        if ($vmStatus -eq "VM running") {
            # Get Managed Identity information
            $managedIdentity = $null
            if ($vm.Identity -ne $null -and $vm.Identity.Type -eq "UserAssigned") {
                $managedIdentity = $vm.Identity.UserAssignedIdentities.Keys -join ";"
            }

            # Prompt for Storage Account Name
            $storageAccountName = Read-Host -Prompt "Enter Storage Account Name for VM $($vm.Name) in Resource Group $($vm.ResourceGroupName)"

            # Prompt for Managed Resource Group Name
            $managedResourceGroupName = Read-Host -Prompt "Enter Managed Resource Group Name for VM $($vm.Name)"

            $vmDetails += [PSCustomObject]@{
                VMName                     = $vm.Name
                Location                   = $vm.Location
                ResourceGroup              = $vm.ResourceGroupName
                SubscriptionId             = $subscription.Id
                SubscriptionName           = $subscription.Name
                SID                        = ""  # Blank SID
                Environment                = ""  # Blank Environment
                Product                    = ""  # Blank Product
                CentralServerVmId          = $vm.Id  # Using VM ID as CentralServerVmId
                ManagedResourceGroupName   = $managedResourceGroupName
                ManagedRgStorageAccountName= $storageAccountName
                MsiId                      = $managedIdentity
                Tag                        = ""  # Blank Tag
            }
        }
    }
}

# Define the CSV file path
$csvFilePath = "C:\path\to\output\input.csv"

# Export the details to CSV
$vmDetails | Export-Csv -Path $csvFilePath -NoTypeInformation

# Check if the CSV file was created successfully
if (Test-Path $csvFilePath) {
    Write-Output "CSV file has been created at $csvFilePath"
} else {
    Write-Output "CSV file was not created successfully"
}

# Check if the CSV file contains the expected data
$csvData = Import-Csv -Path $csvFilePath
if ($csvData.Count -gt 0) {
    Write-Output "CSV file contains the expected data"
} else {
    Write-Output "CSV file does not contain the expected data"
}

Write-Output "Script execution completed"
