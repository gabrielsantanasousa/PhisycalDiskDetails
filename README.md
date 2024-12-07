
Psh_ColetaDiscosDetalhes.ps1

Se você possui um ambiente Windows Server com dezenas de discos conectados através de uma SAN este script vai automatizar a associação do DiskID, Volume, WWNID, Serial Number, SCSI e LUN.

Exemplos de utilização

 - Coleta o DiskID e GUID da partição com get-partition
 - Associa as coletas do Get-CimInstance Win32_DiskDrive, Win32_volune e Get-DISK com o GUID da partiçõa e DiskNumber.

