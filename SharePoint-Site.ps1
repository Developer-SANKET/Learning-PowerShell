$SiteURL="https://genzeon.sharepoint.com/sites/testsharepoint"
$LibraryName ="demo"

# Connect to SharePoint
Connect-PnPOnline -Url $SiteURL -UseWebLogin

Function Cleanup-DuplicateVersions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryName
    )

    try {
        # Get all items from the library
        $Items = Get-PnPListItem -List $LibraryName -PageSize 1000

        foreach ($Item in $Items) {
            # Get the file associated with the item
            $File = Get-PnPFile -Url $Item["FileRef"] -AsListItem  

            # Load the Versions collection explicitly to avoid initialization error
            Get-PnPProperty -ClientObject $File -Property Versions

            # Check if the file has versions
            if ($File.Versions.Count -gt 0) {    #Change zero to how many version need kept 
                $VersionGroups = $File.Versions | Group-Object { $_.Size, $_.CheckInComment }

                foreach ($Group in $VersionGroups) {
                    if ($Group.Count -gt 1) {
                        # Sort versions and delete duplicates
                        $VersionsToDelete = $Group.Group | Sort-Object -Property Created -Descending | Select-Object -Skip 1  # Change one to how mant version need to kept so it will skip that much update file version
                        foreach ($Version in $VersionsToDelete) {
                            Write-Host "Deleting duplicate version $($Version.VersionLabel) of file $($File.Name)"
                            $Version.DeleteObject()
                        }
                    }
                }
            }
        }
    } catch {
        Write-Host "An error occurred: $_"
    }
}

# Runs the cleanup function and pass the library name as a string
Cleanup-DuplicateVersions -LibraryName "demo"

# Disconnect from SharePoint
Disconnect-PnPOnline
