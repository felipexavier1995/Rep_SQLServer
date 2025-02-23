set nocount on;

Print ' 1 - Instancie startup'
Print''
select @@SERVERNAME as [server_name], GETDATE() as [current_time], create_date as sql_start_time from sys.databases where name = 'tempdb'

Print ' 2 - Version of SQL Server'
Print''
SELECT SERVERPROPERTY('Edition') as [Edicao], SERVERPROPERTY ('productversion') as [Versao], SERVERPROPERTY ('productlevel') as [Service Pack]

Print ' 3 - Status Database '
Print''

select name, state_desc, user_access_desc, recovery_model_desc from sys.databases

Print ' 4 - Size file of Log'
Print''

dbcc sqlperf (logspace)

Print ' 5 - Connections database '
Print''

CREATE TABLE #sp_who2 (SPID INT,Status VARCHAR(255),
      Login  VARCHAR(255),HostName  VARCHAR(255), 
      BlkBy  VARCHAR(255),DBName  VARCHAR(255), 
      Command VARCHAR(255),CPUTime INT, 
      DiskIO INT,LastBatch VARCHAR(255), 
      ProgramName VARCHAR(255),SPID2 INT, 
      REQUESTID INT) 
INSERT INTO #sp_who2 EXEC sp_who2
SELECT      * 
FROM        #sp_who2
-- Add any filtering of the results here :
WHERE       DBName <> 'master'
-- Add any sorting of the results here :
ORDER BY    DBName ASC
DROP TABLE #sp_who2

Print ' 6 - Status Jobs'
Print''

Declare @data as varchar(10) 
SET @data = convert(varchar, dateadd(hh,-72,getdate()), 112)  
SELECT	DISTINCT SJ.name 'Nome do Job',   
Isnull(Substring(CONVERT(VARCHAR(8), run_date), 1, 4) + '-' +
                       Substring(CONVERT(VARCHAR
                                 (8), run_date), 5, 2) + '-' +
                Substring(CONVERT(VARCHAR(
                          8), run_date), 7, 2), '')
         AS
         [Run DATE],
         Isnull(Substring(CONVERT(VARCHAR(7), run_time+1000000), 2, 2) + ':'
                 +
                       Substring(CONVERT(VARCHAR(7), run_time+1000000), 4, 2
                        )
                +
                ':' +
                Substring(CONVERT(VARCHAR(7), run_time+1000000), 6, 2), '')
         AS
         [Run TIME],
         Isnull(Substring(CONVERT(VARCHAR(7), run_duration+1000000), 2, 2) +
                 ':' +
                       Substring(CONVERT(VARCHAR(7), run_duration+1000000),
                       4,
                       2)
                + ':' +
                Substring(CONVERT(VARCHAR(7), run_duration+1000000), 6, 2),
         ''
         ) AS
         [Duration],
		CASE run_status 
		WHEN 0 THEN 'ERRO'
		WHEN 3 THEN 'CANCELADO' 
		ELSE 'EXECUTADO'  
		END STATUS,
		SH.message  
 FROM  msdb..sysjobhistory SH  
 INNER JOIN msdb..sysjobs SJ  ON   SH.job_id = SJ.job_id 
 WHERE 
	(run_status in (0,3) AND SH.run_date >= @data AND SJ.name not LIKE '%DHC%') AND
	(run_status in (0,3) AND SH.run_date >= @data AND SJ.name not LIKE 'UOLDIVEO%') AND 
	(run_status in (0,3) AND SH.run_date >= @data AND SJ.name not  LIKE '%BACKUP%') AND
	(run_status in (0,3) AND SH.run_date >= @data AND SJ.name not  LIKE '%Executa%') AND
	(run_status in (0,3) AND SH.run_date >= @data AND SJ.name not  LIKE '%Automatico%')
ORDER BY 3

Print ' 7 - Block Processes'
Print''

select spid, blocked, hostname=left(hostname,20), program_name=left(program_name,20)
	,WaitTime_Seg = convert(int,(waittime/1000))  ,open_tran, status
       ,ISNULL((SELECT TEXT FROM ::fn_get_sql(sql_handle)),'') AS SQL_Command
	From master.dbo.sysprocesses
	where blocked > 0 and waittime > 10
	order by spid

Print ' 8 - Space is disk'
Print''

exec xp_fixeddrives

Print ' 9 - Status of services '
Print''

DECLARE @ServiceStatus TABLE
(ServerName nvarchar(50)
,ServiceName nvarchar(50)
,StatusOfService nvarchar(20)
,StatusAsOn datetime)

INSERT INTO @ServiceStatus (StatusOfService)  
EXEC master..xp_servicecontrol 'QueryState', 'MSSQL'
UPDATE @ServiceStatus 
  SET ServerName=@@SERVERNAME
  ,ServiceName='MSSQL Server'
  ,StatusAsOn=GETDATE() 
WHERE ServerName IS NULL

INSERT INTO @ServiceStatus (StatusOfService)  
EXEC master..xp_servicecontrol 'QueryState', 'SQLAgent'
UPDATE @ServiceStatus 
  SET ServerName=@@SERVERNAME
  ,ServiceName='SQL Server Agent'
  ,StatusAsOn=GETDATE() 
WHERE ServerName IS NULL

INSERT INTO @ServiceStatus (StatusOfService)  
EXEC master..xp_servicecontrol 'QueryState', 'SQLBrowser'
UPDATE @ServiceStatus 
  SET ServerName=@@SERVERNAME
  ,ServiceName='SQL Server Browser'
  ,StatusAsOn=GETDATE() 
WHERE ServerName IS NULL

SELECT * FROM @ServiceStatus

  
Print ' 10 - Error Logs '
Print''

Create table #tb_LogError (LogDate datetime, Processinfo varchar(100),Mensagem varchar(max)) --varchar(8000)
 	insert into #tb_LogError	exec xp_readerrorlog 0 , 1 , "Error";
	insert into #tb_LogError	exec sp_readerrorlog 0 , 1 , "node";
 	insert into #tb_LogError	exec sp_readerrorlog 0 , 1 , 'failed';
SELECT LogDate, Processinfo, Mensagem from #tb_LogError 
where LogDate > dateadd(hh,-72,getdate()) 
and Mensagem <> 'Error: 10982, Severity: 16, State: 1.' 
and Mensagem <> 'Error: 8525, Severity: 16, State: 1.' 
and Mensagem <> 'Error: 8522, Severity: 18, State: 1.' 
and Mensagem not like 'Failed to run resource governor%' 
order by LogDate 
	Drop Table #tb_LogError
