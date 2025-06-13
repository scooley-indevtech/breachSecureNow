# Ensure the Active Directory module is available
Import-Module ActiveDirectory

# Set OU paths
$domainDN = (Get-ADDomain).DistinguishedName
$applicationsOU = "OU=Applications,$domainDN"
$bsnOU = "OU=Breach Secure Now,$applicationsOU"

# Create 'Applications' OU if it doesn't exist
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$applicationsOU)" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Applications" -Path $domainDN
    Write-Host "Created OU: Applications"
}

# Create 'Breach Secure Now' OU if it doesn't exist
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$bsnOU)" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Breach Secure Now" -Path $applicationsOU
    Write-Host "Created OU: Breach Secure Now"
}

# Define group names
$groups = @("BSN-Employees", "BSN-Managers", "BSN-ManagerAdmins")

# Create groups if they don't exist
foreach ($group in $groups) {
    $groupPath = "$bsnOU"
    if (-not (Get-ADGroup -Filter { Name -eq $group } -SearchBase $groupPath -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path $groupPath
        Write-Host "Created group: $group"
    }
}

# Add members from 'KnowBe4 Users' to 'BSN-Employees'
$sourceGroup = "KnowBe4 Users"
$targetGroup = "BSN-Employees"

try {
    $members = Get-ADGroupMember -Identity $sourceGroup -Recursive
    foreach ($member in $members) {
        Add-ADGroupMember -Identity $targetGroup -Members $member -ErrorAction SilentlyContinue
    }
    Write-Host "Successfully added members from '$sourceGroup' to '$targetGroup'"
} catch {
    Write-Warning "Failed to retrieve or add group members: $_"
}
