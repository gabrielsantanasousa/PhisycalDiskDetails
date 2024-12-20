# Apaga relatório CSV caso exista
$valida = Test-Path "$($env:USERPROFILE)\documents\Discos$($env:COMPUTERNAME).csv"
if ($valida -eq "true")
{
    Remove-Item "$($env:USERPROFILE)\documents\Discos$($env:COMPUTERNAME).csv" -Force -Verbose
}


# Valida se o mpclaim.exe está instalado
$validampcalim = Test-Path "C:\Windows\System32\mpclaim.exe"


$DiskPartitions = Get-Partition | ? {$_.PartitionNumber -eq 2} | Select-Object -property DiskNumber, Guid | Sort-Object -Property DiskNumber
$disks = $DiskPartitions.DiskNumber
foreach ($PartitionDiskNumber in $disks)
{
    
    # Valida partition GUID, adicionada tratativa para discos com partição MBR
	
    $DiskPartInfo = Get-Partition | ? {$_.DiskNumber -eq $PartitionDiskNumber -and $_.PartitionNumber -eq 2} | Select-Object -property DiskNumber, Type, Guid, AccessPaths
    $DiskGuid = $DiskPartInfo.Guid
    if($DiskGuid)
    {
      $DiskGuid =  $DiskGuid -replace "{","" -replace "}",""
    }
    else
    {
        $DiskGuid = ($DiskPartInfo.AccessPaths[1]).ToString() -replace "{","" -replace "}","" -replace "Volume","" -replace "\\" -replace "\?"
    }

    #DiskDevices

    $DiskDevices = Get-CimInstance Win32_DiskDrive | ? {$_.name -ilike "*PHYSICALDRIVE$($PartitionDiskNumber)"} | Select-Object -Property SysTemName,Name,Model,SCSIPort,SCSIBus,SCSITargetId,SCSILogicalUnit,SerialNumber,Size

    $DevicePhyscalName = $DiskDevices.Name
    $DeviceModel = $DiskDevices.Model
    $DeviceSCSIPort = $DiskDevices.SCSIPort
    $DeviceSCSIBus = $DiskDevices.SCSIBus
    $DeviceSCSITargetId = $DiskDevices.SCSITargetId
    $DeviceSCSILogicalUnit = $DiskDevices.SCSILogicalUnit
    $DeviceSerialNumber = $DiskDevices.SerialNumber
    $DeviceSize = $DiskDevices.Size

    #Volume

    $DiskVolume = Get-CimInstance -Class Win32_Volume | ? {$_.DeviceID -ilike "*$DiskGuid*"} | Select-Object -Property name, blocksize
    $VolumeName = $DiskVolume.name
    $VolumeBlockSize = $DiskVolume.blocksize

    #WWNID, Location, OperationalStatus, 

    $DiskInfo = Get-Disk | ? {$_.disknumber -eq $PartitionDiskNumber}| Select-Object -Property UniqueID, Location, OperationalStatus
    $DiskWWNID = $DiskInfo.UniqueID
    $DiskStatus = $DiskInfo.OperationalStatus
    $DiskLocation = $DiskInfo.Location

    ## Multipath
	
	if ($validampcalim -eq "True")
	{
		$MultiPath = Get-CimInstance -Namespace root\wmi -Class mpio_disk_info | select-object -Property driveinfo -ExpandProperty driveinfo | ? {$_.serialnumber -eq "$DiskWWNID"}  | Select-Object -Property name, NumberPaths, serialnumber
		$MPIODisk =  $MultiPath.name
		$MPIOPaths =  $MultiPath.NumberPaths
	}


    $objeto = New-Object psobject
    $objeto | Add-Member -MemberType NoteProperty -Name SysTemName -Value $env:COMPUTERNAME
    $objeto | Add-Member -MemberType NoteProperty -Name DiskID -Value $PartitionDiskNumber
    $objeto | Add-Member -MemberType NoteProperty -Name MPIODisk -Value $MPIODisk
    $objeto | Add-Member -MemberType NoteProperty -Name DiskStatus -Value $DiskStatus
    $objeto | Add-Member -MemberType NoteProperty -Name Model -Value $DeviceModel
    $objeto | Add-Member -MemberType NoteProperty -Name Volume -Value $VolumeName
    $objeto | Add-Member -MemberType NoteProperty -Name BlockSize -Value $VolumeBlockSize
    $objeto | Add-Member -MemberType NoteProperty -Name Size -Value $DeviceSize
    $objeto | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $DeviceSerialNumber
    $objeto | Add-Member -MemberType NoteProperty -Name DiskWWNID -Value $DiskWWNID
    $objeto | Add-Member -MemberType NoteProperty -Name MPIOPaths -Value $MPIOPaths
    $objeto | Add-Member -MemberType NoteProperty -Name MpClaimPahts -Value $StrMpClaimPahts
    $objeto | Add-Member -MemberType NoteProperty -Name SCSIPort -Value $DeviceSCSIPort
    $objeto | Add-Member -MemberType NoteProperty -Name SCSIBus -Value $DeviceSCSIBus
    $objeto | Add-Member -MemberType NoteProperty -Name SCSITargetId -Value $DeviceSCSITargetId
    $objeto | Add-Member -MemberType NoteProperty -Name SCSILogicalUnit -Value $DeviceSCSILogicalUnit
    $objeto | Add-Member -MemberType NoteProperty -Name DiskLocation -Value $DiskLocation
    Write-Output $objeto | export-csv -NoClobber -NoTypeInformation -Delimiter ";" -Append -Path "$($env:USERPROFILE)\documents\Discos$($env:COMPUTERNAME).csv"

    
}