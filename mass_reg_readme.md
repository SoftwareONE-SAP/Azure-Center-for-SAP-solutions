# Readme

## Script Purpose

This PowerShell script is designed to gather information from the Azure API for all running Virtual Machines (VMs) in your Azure subscription. The information collected is used to build a CSV file that serves as input for the Azure Centre for SAP Solutions (ACSS) registration of existing SAP systems.

## Prerequisites

1. **Azure PowerShell Module**: Ensure the Azure PowerShell module is installed. The script will install it if not already installed.
2. **Azure Account**: You must be connected to your Azure account with appropriate permissions to access the VMs and their details.

## Usage

1. **Install Azure PowerShell Module (if not already installed)**:
    ```powershell
    if (-not (Get-Module -ListAvailable -Name Az)) {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
    }
    ```

2. **Connect to Azure Account**:
    ```powershell
    Connect-AzAccount
    ```

3. **Run the Script**:
    ```powershell
    # Save the script content in a file, e.g., Gather-VMDetails.ps1
    .\Gather-VMDetails.ps1
    ```

## Script Workflow

1. **Install Azure PowerShell Module**: The script ensures the Az module is installed.
2. **Connect to Azure Account**: The user is prompted to log in to their Azure account.
3. **Prompt for Additional Criteria**: The script prompts the user to specify if any systems meet the following criteria:
    - HANA Large Instance (HLI)
    - Systems with HANA Scale-out, MCOS, and MCOD configurations
    - Java stack
    - Dual stack (ABAP and Java)
    - Systems using IPv6 addresses
    - Multiple SIDs running on the same set of Virtual Machines

   For each criterion, the user can choose "All", "Some", or "None". If any responses are "All" or "Some", the script will notify the user that these systems are not supported and terminate.

4. **Gather VM Details**: The script collects details about each running VM, including VM name, location, resource group, subscription ID, and subscription name. It prompts the user for the storage account name and managed resource group name for each VM.
5. **Generate CSV**: The collected information is exported to a CSV file at the specified path.

## Example Execution

```powershell
# Example script execution with prompts
# Save the script content in a file, e.g., Gather-VMDetails.ps1
.\Gather-VMDetails.ps1
