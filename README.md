# BSN_AD_Schema_Setup.ps1 – Script Walkthrough

This document explains in plain language what each part of the `BSN_AD_Schema_Setup.ps1` PowerShell script does. It is intended for readers who are not familiar with PowerShell but want to understand the purpose of each section.

---

## 1. Preparation: Load Tools Needed

```powershell
Import-Module ActiveDirectory
Add-Type -AssemblyName PresentationFramework
```

These two commands load the components Windows needs to:

- Talk to **Active Directory** – the service that stores information about users and groups on the network.
- Display a simple pop‑up window (the dialog box that will ask the administrator what to do).

---

## 2. Ask the Administrator What They Want to Do

```powershell
$choice = [System.Windows.MessageBox]::Show(
    "Do you want to create the schema AND copy users from the 'KnowBe4 Users' group to 'BSN-Employees'?",
    "BSN Setup Options",
    "YesNo",
    "Question"
)
```

This line shows a Yes/No dialog asking the person running the script whether they want to:

- Create the folder structure (the “schema”) *and* copy users from an old group, or
- Just create the folder structure.

---

## 3. Store the Administrator’s Answer

```powershell
$copyUsers = $false
if ($choice -eq 'Yes') {
    $copyUsers = $true
    Write-Host "You chose to create schema AND copy users."
} else {
    Write-Host "You chose to create schema only (no user copying)."
}
```

The script remembers the admin’s choice: if they clicked “Yes,” it will do everything (create folders and copy users); otherwise, it will only create the folders.

---

## 4. Figure Out Where to Put the New Structure

```powershell
$domainDN = (Get-ADDomain).DistinguishedName
...
if ($m365SyncOU) {
    ...
} else {
    ...
}
```

The script checks the existing layout of Active Directory:

- If a folder called `M365 Sync` already exists, the new folders will be created inside it.
- If not, they’ll be created near the top level of the directory structure.

---

## 5. Create the Necessary Organizational Units (Folders)

```powershell
New-ADOrganizationalUnit -Name "Applications" ...
New-ADOrganizationalUnit -Name "Breach Secure Now" ...
```

If the required folders are missing, the script creates them:

- **Applications** – a generic folder for company software.
- **Breach Secure Now** – a sub‑folder for everything related to the BSN security‑awareness platform.

---

## 6. Set Up the Required Security Groups

```powershell
$groups = @("BSN-Employees", "BSN-Managers", "BSN-ManagerAdmins")
foreach ($group in $groups) {
    ...
}
```

Inside the “Breach Secure Now” folder, three security groups are created (if they do not already exist):

- **BSN‑Employees** – regular users.
- **BSN‑Managers** – supervisors and managers.
- **BSN‑ManagerAdmins** – administrators who manage the BSN platform.

---

## 7. (Optional) Copy Users from the Old to the New Group

```powershell
if ($copyUsers) {
    ...
}
```

If the administrator chose to copy users, the script will:

1. Fetch everyone in the old `KnowBe4 Users` group.
2. Add each of those people to the new `BSN-Employees` group.
3. Skip over anyone already present and warn if any errors occur.

---

## 8. Result

After the script runs, you will have:

- A clean, standardized folder structure in Active Directory for Breach Secure Now.
- The necessary security groups ready to use.
- Optionally, all users from the legacy KnowBe4 group copied into the new BSN group.
