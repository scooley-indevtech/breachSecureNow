# Import required modules
Import-Module ActiveDirectory
Add-Type -AssemblyName PresentationFramework

# Prompt the user
$choice = [System.Windows.MessageBox]::Show(
    "Do you want to create the schema AND copy users from the 'KnowBe4 Users' group to 'BSN-Employees'?",
    "BSN Setup Options",
    "YesNo",
    "Question"
)

# Determine action based on response
$copyUsers = $false
if ($choice -eq 'Yes') {
    $copyUsers = $true
    Write-Host "You chose to create schema AND copy users."
} else {
    Write-Host "You chose to create schema only (no user copying)."
}

# Get domain DN
$domainDN = (Get-ADDomain).DistinguishedName

# Locate "M365 Sync" OU if it exists
$m365SyncOU = Get-ADOrganizationalUnit -Filter 'Name -eq "M365 Sync"' -ErrorAction SilentlyContinue | Select-Object -First 1

# Determine Applications OU path
if ($m365SyncOU) {
    $applicationsPath = "OU=Applications," + $m365SyncOU.DistinguishedName
    Write-Host "Found 'M365 Sync'. Applications will be created inside it."
} else {
    $applicationsPath = "OU=Applications,$domainDN"
    Write-Host "'M365 Sync' not found. Applications will be created at the root."
}

# Create "Applications" OU if needed
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$applicationsPath)" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Applications" -Path ($m365SyncOU?.DistinguishedName ?? $domainDN)
    Write-Host "Created OU: Applications"
}

# Create "Breach Secure Now" OU inside Applications
$bsnPath = "OU=Breach Secure Now,$applicationsPath"
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$bsnPath)" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Breach Secure Now" -Path $applicationsPath
    Write-Host "Created OU: Breach Secure Now"
}

# Create required groups inside BSN OU
$groups = @("BSN-Employees", "BSN-Managers", "BSN-ManagerAdmins")
foreach ($group in $groups) {
    if (-not (Get-ADGroup -Filter { Name -eq $group } -SearchBase $bsnPath -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path $bsnPath
        Write-Host "Created group: $group"
    }
}

# Optional: Copy users if selected
if ($copyUsers) {
    $sourceGroup = "KnowBe4 Users"
    $targetGroup = "BSN-Employees"

    try {
        $members = Get-ADGroupMember -Identity $sourceGroup -Recursive
        foreach ($member in $members) {
            Add-ADGroupMember -Identity $targetGroup -Members $member -ErrorAction SilentlyContinue
        }
        Write-Host "Added members from '$sourceGroup' to '$targetGroup'"
    } catch {
        Write-Warning "Could not add members from '$sourceGroup': $_"
    }
}
