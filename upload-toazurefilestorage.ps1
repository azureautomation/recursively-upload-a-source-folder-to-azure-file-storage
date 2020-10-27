<# 
.SYNOPSIS  
     Recursively uploads a Source Folder to Azure File Storage

.DESCRIPTION 
    This function will recursively upload a Source folder to Azure File Storage. Requires an Azure File Storage Account

    Details - http://azure.microsoft.com/en-gb/documentation/articles/storage-introduction/

    Will overwrite files unless the -Confirm Switch is used

.PARAMETER AzureSubscriptionName
        The name of the Azure Subscription. 

.PARAMETER StorageAccountName      
        The name of the Azure Storage Account. 
        
.PARAMETER AzureShare
        The Name of the share on the Azure Storage Account. It will be created if it doesn't exist

.PARAMETER AzureDirectory
        The Name of the Directory on the Azure Share to upload files to.It will be created if it doesn't exist

.PARAMETER Source
        The Source directory containing the files to upload

.PARAMETER Confirm
        A switch to choose confirm for file overwrites. The script will default
        to overwrite files if this is not chosen

.EXAMPLE 
    Add-AzureAccount $Cred
    Upload-ToAzureFileStorage -AzureSubscriptionName SubName -StorageAccountName StorageName -AzureShare data -AzureDirectory AppName -Source C:\temp\TestUpload 

    Connects to Azure using the credentials stored in $Cred. Uploads all files and folders in the C:\temp\TestUpload folder to the AppName directory on the data share in the StorageName storage account and will overwrite any files already in existence

.EXAMPLE 
    Add-AzureAccount $Cred
    Upload-ToAzureFileStorage -AzureSubscriptionName SubName -StorageAccountName StorageName -AzureShare data -AzureDirectory AppName -Source C:\temp\TestUpload -Confirm

    Connects to Azure using the credentials stored in $Cred. Uploads all files and folders in the C:\temp\TestUpload folder to the AppName directory on the data share in the StorageName storage account and will ask for confirmation before overwriting files

.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 01/02/2015 


#> 
function Upload-ToAzureFileStorage
{

    param 
        (
        [Parameter(Mandatory=$true)]
        [string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,
        [Parameter(Mandatory=$true)]
        [string]$AzureShare,
        [Parameter(Mandatory=$true)]
        [string]$AzureDirectory,
        [Parameter(Mandatory=$true)]
        [string]$Source,
        [Parameter(Mandatory=$false)]
        [switch]$Confirm
        )
#Select Azure Subscription
Select-AzureSubscription -SubscriptionName $AzureSubscriptionName

# Get the Storage Account Key
$StorageAccountKey = (Get-AzureStorageKey -StorageAccountName $StorageAccountName).Primary

# create a context for account and key
$ctx=New-AzureStorageContext $StorageAccountName $StorageAccountKey

#Check for Share Existence

$S = Get-AzureStorageShare -Context $ctx -ErrorAction SilentlyContinue|Where-Object {$_.Name -eq $AzureShare}

if (!$S.Name)
    {
    # create a new share
    $s = New-AzureStorageShare $AzureShare -Context $ctx
    }

# Check for directory
$d = Get-AzureStorageFile -Share $s -ErrorAction SilentlyContinue|select Name
if ($d.Name -notcontains $AzureDirectory)
    {
    # create a directory in the share
    $d = New-AzureStorageDirectory -Share $s -Path $AzureDirectory
    }

# get all the folders in the source directory
$Folders = Get-ChildItem -Path $Source -Directory -Recurse

$S = Get-AzureStorageShare -Name $AzureShare -Context $ctx
foreach($Folder in $Folders)
    {
    $f = ($Folder.FullName).Substring(($source.Length))
    $Path = $AzureDirectory + $f
    # create a directory in the share for each folder
    New-AzureStorageDirectory -Share $s -Path $Path -ErrorAction SilentlyContinue
    }

#Get all the files in the source directory
$files = Get-ChildItem -Path $Source -Recurse -File
foreach($File in $Files)
    {
        $f = ($file.FullName).Substring(($Source.Length))
        $Path = $AzureDirectory + $f
        #upload the files to the storage

        if($Confirm)
            {
            Set-AzureStorageFileContent -Share $s -Source $File.FullName -Path $Path -Confirm
            }
        else
            {
            Set-AzureStorageFileContent -Share $s -Source $File.FullName -Path $Path -Force
            }
    }

}
