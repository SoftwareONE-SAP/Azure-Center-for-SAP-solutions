# Import Azure PowerShell Module
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}

# Set the Customer Name
$CustomerName = "YourCustomerName"  # Replace with actual customer name

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

            # Set default Storage Account Name and Managed Resource Group Name
            $defaultStorageAccountName = "${CustomerName}sa"
            $defaultManagedResourceGroupName = "${CustomerName}rg"

            # Prompt for Storage Account Name with a default value
            $storageAccountName = Read-Host -Prompt "Enter Storage Account Name for VM $($vm.Name) in Resource Group $($vm.ResourceGroupName) [$defaultStorageAccountName]"
            if ([string]::IsNullOrWhiteSpace($storageAccountName)) {
                $storageAccountName = $defaultStorageAccountName
            }

            # Prompt for Managed Resource Group Name with a default value
            $managedResourceGroupName = Read-Host -Prompt "Enter Managed Resource Group Name for VM $($vm.Name) [$defaultManagedResourceGroupName]"
            if ([string]::IsNullOrWhiteSpace($managedResourceGroupName)) {
                $managedResourceGroupName = $defaultManagedResourceGroupName
            }

            $vmDetails += [PSCustomObject]@{
                VMName                     = $vm.Name
                Location                   = $vm.Location
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
$csvFilePath = "output.csv"

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

# Output the details in a table format
$vmDetails | Format-Table -AutoSize

Write-Output "Script execution completed"
