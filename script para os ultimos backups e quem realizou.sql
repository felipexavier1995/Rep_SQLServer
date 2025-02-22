select top 500 BS.user_name, 
@@SERVERNAME as Servername, 
@@SERVICENAME as InstanceName, 
DB.name as DatabaseName, 
case BF.device_type when 2 then 'Disco' 
when 7 then 'Fita' 
else 'Outro' end 'Onde', 
backup_start_date, 
case BS.type when 'D' then 'Full' 
when 'L' then 'TransactionLog' 
when 'I' then 'Diferencial' 
else 'Outro' end 'Tipo', 
convert(varchar(10),BS.backup_finish_date - BS.backup_start_date,108) time, 
CAST(CAST(backup_size as float)/1024/1024/1024 as decimal(12,3)) 'BD_Size_GB', 
CAST(CAST(backup_size as float)/1024/1024 as decimal(12,2)) 'BD_Size_MB', 
--(compressed_backup_size/1024)/1024 'Bkp_Compressed_Mb', --somente para versão >sql2005 
BS.first_lsn, 
BS.last_lsn, 
is_copy_only, 
BF.physical_device_name 
from master..sysdatabases DB 
inner join msdb..backupset BS 
on DB.name = BS.database_name collate Latin1_General_CI_AS 
inner join msdb..backupmediafamily BF 
on BS.media_set_id = BF.media_set_id 
and BS.first_family_number = BF.family_sequence_number 
where BS.type in ('D','I','L') 
	-- D é igual a Full
	-- I é igual a Diferencial 
	-- L é igual a TransactionLog
	
	
-- and DB.name = 'NOME DA BASE' --nome do Banco 
-- and DB.name not in ('uoldiveo_dba', 'msdb', 'model', 'master') 
-- and BF.device_type = 7 --2 Disco , 7 fita 
and backup_start_date >= getdate()-1 and backup_start_date < getdate() -- quantidades de dias para ver analisado
order by database_name desc 
GO
