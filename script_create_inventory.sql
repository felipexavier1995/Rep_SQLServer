set nocount on;
set ansi_warnings off;
go
use master
go
print 'Documentacao do servidor sql server ' +@@servername
print 'Data:' + convert (varchar, getdate(), 109)
print ''
print '***********************************************************************'
print '*																	  *'
print '*  ATENÇÃO ABORTE A MUDANÇA SE NÃO EXISTIR BACKUP NOS ÚLTIMOS 3 DIAS  *'
print '*																	  *'
print '***********************************************************************'
print ''

select  substring(@@servername,1,30) as servername, substring(@@servicename,1,25) as servicename, 
		substring(host_name(),1,25) as hostname, substring(@@version,1,160) as versao
print ''
select
cast( serverproperty( 'machinename' ) as varchar( 30 ) ) as machinename ,
cast( ISNULL(SERVERPROPERTY('InstanceName'), 'MSSQLSERVER') as varchar( 30 ) ) as instance , 
cast( serverproperty( 'productversion' ) as varchar( 30 ) ) as productversion ,
cast( serverproperty( 'productlevel' ) as varchar( 30 ) ) as productlevel ,
cast( serverproperty( 'edition' ) as varchar( 30 ) ) as edition ,
( case serverproperty( 'engineedition')
when 1 then 'personal or desktop'
when 2 then 'standard'
when 3 then 'enterprise'
end ) as enginetype ,
cast( serverproperty( 'licensetype' ) as varchar( 30 ) ) as licensetype ,
serverproperty( 'numlicenses' ) as #licenses;
print ''
print ''

print '--uptime da instancia'
use master;
declare @starttime datetime
set @starttime = (select crdate from sysdatabases where name = 'tempdb' )
 
declare @currenttime datetime
set @currenttime = getdate()
 
declare @difference_dd int
declare @difference_hh int
declare @difference_mi int
 
set @difference_mi = (select datediff(mi, @starttime, @currenttime))
set @difference_dd = (@difference_mi/60/24)
set @difference_mi = @difference_mi - (@difference_dd*60)*24
set @difference_hh = (@difference_mi/60)
set @difference_mi = @difference_mi - (@difference_hh*60)
 
print 'uptime: ' 
+ convert(varchar, @difference_dd) + ' days, ' 
+ convert(varchar, @difference_hh) + ' hours and ' 
+ convert(varchar, @difference_mi) + ' minutes.'  
print ''

print ''
print 'DBCC TRACESTATUS'
print ''
DBCC TRACESTATUS ()
go

print '--informacoes do ambiente'
exec master..xp_msver
print ''
go

print ''
print '--informacoes do modo de autenticacao'
use master
go
select case serverproperty('isintegratedsecurityonly') when 0 then 'mixed mode' when 1 then 'windows authentication mode' end as [currently used sql server authentication mode]
print ''
go

print '--sp_configure (show advanced)'
exec sp_configure 'show advanced', 1
reconfigure with override
go

print ''
exec sp_configure
go
exec sp_configure 'show advanced', 0
reconfigure with override
print ''
go

print ''
print '--collate'
print ''
exec sp_helpsort
go
print 'or'
SELECT CONVERT (varchar, SERVERPROPERTY('collation'));
go
print ''
go

print ''
print '--drivers'
print ''
exec xp_fixeddrives
print ''
go

print ''
print '--caminho arquivos de log e dados'
print ''
select 
db_name(database_id) as [db_name],name  as logic_name,
mf.size * 8 / 1024 as [size_mb],
mf.growth,
mf.max_size,
mf.type_desc,
mf.state,
mf.physical_name
from sys.master_files mf
go

print ''
print '--lista banco de dados'
select name, state_desc, collation_name, user_access_desc, recovery_model_desc,page_verify_option_desc,is_auto_close_on,is_auto_shrink_on from sys.databases
go

print ''
print '--informacoes - banco de dados'
create table #bddsc (dbname sysname,dbsize nvarchar(13) null,owner sysname null,dbid smallint,
created nvarchar(11),dbdesc	nvarchar(600)	null,cmptlevel tinyint)
insert into #bddsc exec sp_helpdb
select mf.database_id, db.name as name,substring(mf.physical_name,1,80)as physical_name, 
mf.size, mf.max_size, mf.growth,substring(suser_sname(sid),1,10) as suser_sname, db.cmptlevel, db.crdate 
from master.sys.master_files as mf
inner join master.dbo.sysdatabases as db on mf.database_id = db.dbid
left join #bddsc as dsc on db.dbid = dsc.dbid
drop table #bddsc
go

print ''
print '--informacoes - configuracao banco de dados'
select * from sys.databases

print ''
print '--lista de usuarios'
print ''

select pr.principal_id, pr.name, pr.type_desc, pr.default_language_name, pe.state_desc, pe.permission_name from sys.server_principals as pr join sys.server_permissions as pe on pe.grantee_principal_id = pr.principal_id;
print ''
print '--lista de usuarios com direito sysadmin'
exec sp_helpsrvrolemember 'sysadmin'
print ''
go

print ''
print '--configuracao do cluster'
print ''
print ''
print '--cluster - server name'
print ''
select substring(srvname,1,25) as srvname,substring(providername,1,25) as providername,substring(datasource,1,25) as datasource,substring(srvnetname,1,25) as srvnetname
from sys.sysservers where srvid = 0

print ''
print '--cluster - nome do no'
print ''
select substring(nodename,1,30) as nodename from ::fn_virtualservernodes()

print ''
print '--cluster - discos utilizados'
print ''
select * from fn_servershareddrives()
print ''
go

print ''
print '--ips e portas utilizadas'
print ''
use master
go
xp_readerrorlog 0, 1, N'server is listening on' 
go
print ''
go

print ''
print '--backup device last 3 days'
print ''
SELECT  
 CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
 msdb.dbo.backupset.database_name,  
 msdb.dbo.backupset.backup_start_date,  
 msdb.dbo.backupset.backup_finish_date, 
 msdb.dbo.backupset.expiration_date, 
 CASE msdb..backupset.type  
   WHEN 'D' THEN 'Database'  
   WHEN 'L' THEN 'Log'  
 END AS backup_type,  
 msdb.dbo.backupset.backup_size,  
 msdb.dbo.backupmediafamily.logical_device_name,  
 msdb.dbo.backupmediafamily.physical_device_name,   
 msdb.dbo.backupset.name AS backupset_name, 
 msdb.dbo.backupset.description 
FROM   msdb.dbo.backupmediafamily  
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 3)  
ORDER BY  
  msdb.dbo.backupset.database_name, 
  msdb.dbo.backupset.backup_finish_date
IF @@ROWCOUNT = 0  
PRINT '*******: ATENÇÃO ABORTE A MUDANÇA NÃO HÁ BACKUP NOS ÚLTIMOS 3 DIAS :*******';  
GO

print ''
print '--linkdservers'
print ''
select substring(name,1,25) as name,substring(provider,1,25) as provider,substring(product,1,25) as product, 
substring(data_source,1,25) as data_source, substring(provider_string,1,25) as provider_string,
substring(location,1,25) as location,substring(catalog,1,25) as catalog
from sys.servers where server_id <> 0 order by 1
print ''
go 

print ''
print '--providers'
print ''
exec sp_msset_oledb_prop
go

print ''
print '--jobs'
print ''
use msdb ;
go
exec dbo.sp_help_job ;
print ''
go

print ''
print '--credential'
print ''
select 'create credential ' + name + ' with identity = ''' + credential_identity + ''', secret = ''<put password here>'';' from sys.credentials order by name;
go
print ''

print '--conexoes sql'
print ''
select  spid,
        sp.[status],
        loginame [login],
        hostname, 
        blocked blkby,
        sd.name dbname, 
        cmd command,
        cpu cputime,
        physical_io diskio,
        last_batch lastbatch,
        [program_name] programname   
from master.dbo.sysprocesses sp 
join master.dbo.sysdatabases sd on sp.dbid = sd.dbid
order by spid

print ''
print '--logshipping'
print ''
use master
go
exec sp_help_log_shipping_monitor
go

print ''
print '--verificar se ha analysys services rodando'
print ''
select spid, ecid, blocked, cmd, loginame, db_name(dbid) db, nt_username, net_library, hostname, physical_io, login_time, last_batch, cpu, status, open_tran, program_name from master.dbo.sysprocesses where spid > 50 and loginame <> 'sa' and program_name like '%analysis%' order by physical_io desc 
go

print ''
print '--verificar se ha report services rodando'
print ''
select spid, ecid, blocked, cmd, loginame, db_name(dbid) db, nt_username, net_library, hostname, physical_io, login_time, last_batch, cpu, status, open_tran, program_name from master.dbo.sysprocesses where spid > 50 and loginame <> 'sa' and program_name like '%report%' order by physical_io desc 
go

print ''
print '--mirror status'
print ''
select db.name, m.mirroring_role_desc, mirroring_partner_instance, mirroring_partner_name, mirroring_state_desc from sys.database_mirroring m join sys.databases db on db.database_id=m.database_id where mirroring_role_desc='principal' or mirroring_role_desc='mirror' order by mirroring_role_desc desc
go

print '--replicacao'
print ''
if exists (select name from master.sys.databases where name = N'[distribution]')
begin
select
     p.[publication]   as [publication name]
    ,a.[publisher_db]  as [database name]
    ,a.[article]       as [article name]
    ,a.[source_owner]  as [schema]
    ,a.[source_object] as [table]
from
    [distribution].[dbo].[msarticles] as a
    inner join [distribution].[dbo].[mspublications] as p
        on (a.[publication_id] = p.[publication_id])
order by
    p.[publication], a.[article]
end
else
print 'nao tem replicacao'
go

print '--log de erros da instancia'
print ''
CREATE TABLE #errorLog (LogDate DATETIME, ProcessInfo VARCHAR(64), [Text] VARCHAR(MAX));
INSERT INTO #errorLog
EXEC sp_readerrorlog 6 -- specify the log number or use nothing for active error log
SELECT * 
FROM #errorLog a
WHERE EXISTS (SELECT * 
              FROM #errorLog b
              WHERE [Text] like 'Error:%'
                AND a.LogDate = b.LogDate
                AND a.ProcessInfo = b.ProcessInfo)
DROP TABLE #errorLog;
