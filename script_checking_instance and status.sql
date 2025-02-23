--- Query para verificar a instancia e seus status.
--- query for check a instance and status


set nocount on
select @@servername as Instancia, host_name() as Hostname, 'Bancos no Ar a ' + Cast(datediff(mi, login_time, getdate()) /60 as VarChar) + ' Horas' as 'STATUS do Ambiente', getdate() as 'Horário Atual'
FROM master..sysprocesses WHERE spid = 1
select SERVERPROPERTY('edition') as SQL_Edition,SERVERPROPERTY('productversion') as SQL_Version,SERVERPROPERTY('productlevel') as SQL_ServicePack
select COUNT(*) as 'NUMERO DE SESSÕES EM LOCK NO AMBIENTE' from sys.sysprocesses where blocked <> 0
SELECT RESUMO= 'Neste momento há ' + CONVERT(VARCHAR(5), QT) + ' Databases ' + CONVERT(VARCHAR(20), STATUS) FROM (
select SUM(1) QT, DatabasePropertyEx(name,'Status') "STATUS" FROM sys.sysdatabases
GROUP BY DatabasePropertyEx(name,'Status')) A
if exists (select * from sys.database_mirroring where mirroring_guid is not null)
select name as Database_Name,
isnull(mirroring_state_desc, 'Não é um Mirroring') "MIRRORING_STATUS",
DatabasePropertyEx(name,'Status') as Database_Status,
isnull(MIRRORING_ROLE_DESC, 'Não é um Mirroring') "MIRROR/PRINCIPAL",
isnull(MIRRORING_PARTNER_INSTANCE, 'Não é um Mirroring') "PARTNER"
 from sys.sysdatabases a left outer join sys.database_mirroring b
on a.name = db_name(b.database_id)
ELSE
select name as Database_Name, DatabasePropertyEx(name,'Status') as Database_Status from sys.sysdatabases
