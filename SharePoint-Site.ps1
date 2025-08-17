# To run the script need site owner level access
# require to install PnP moudules

$SiteURL = "https://genzeon.sharepoint.com/sites/testsharepoint"  #Just put the Site URL of the sharepoint to deleted the duplicate versioniung history
$LibraryName = "demopractice"  # Mention libraryName

# Connect to SharePoint

Connect-PnPOnline -Url $SiteURL -UseWebLogin
Function Cleanup-DuplicateVersions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryName,
        [string]$FolderPath = ""
    )

    try {
        $Items = if ($FolderPath) {
            Get-PnPListItem -List $LibraryName -FolderServerRelativeUrl $FolderPath -PageSize 1000
        } else {
            Get-PnPListItem -List $LibraryName -PageSize 1000
        }

        foreach ($Item in $Items) {
            try {
                if ($Item.FileSystemObjectType -eq "Folder") {
                    $SubFolderPath = $Item["FileRef"]
                    Cleanup-DuplicateVersions -LibraryName $LibraryName -FolderPath $SubFolderPath
                }
                elseif ($Item.FileSystemObjectType -eq "File" -and $Item["FileRef"]) {
                    $File = Get-PnPFile -Url $Item["FileRef"] -AsListItem -ErrorAction Stop

                    if ($File) {
                        Get-PnPProperty -ClientObject $File -Property Versions -ErrorAction Stop

                        if ($File.Versions.Count -gt 1) {  # change 1 to how many verison need to kept  
                            $VersionGroups = $File.Versions | Group-Object { $_.Size, $_.CheckInComment }

                            foreach ($Group in $VersionGroups) {
                                if ($Group.Count -gt 1) {
                                    $VersionsToDelete = $Group.Group | Sort-Object Created -Descending | Select-Object -Skip 1 #  change 1 to how many verison need to kept so that much version will skip
                                    foreach ($Version in $VersionsToDelete) {
                                        Write-Host "Deleting duplicate version '$($Version.VersionLabel)' of file '$($File.Name)' at '$($Item["FileRef"])'"
                                        $Version.DeleteObject()

                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Host "Error processing item $($Item["FileRef"]): $($_.Exception.Message)"
            }
        }
    } catch {
        Write-Host "Error in Cleanup-DuplicateVersions: $($_.Exception.Message)"
    }
} 
# Run the cleanup
Cleanup-DuplicateVersions -LibraryName $LibraryName
# Disconnect
Disconnect-PnPOnline

 