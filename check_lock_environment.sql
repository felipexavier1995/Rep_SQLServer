
--- Query a seguir é para verificar se existe alguma sessão lockada no momento.
--- Query follow is for check if exist some locks in environment.

USE [master]
GO
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

 

if ( Select count(1) From master.dbo.sysprocesses
Where blocked = 0 and spid in (select blocked from master.dbo.sysprocesses WITH (NOLOCK) Where blocked > 0 and waittime >3000) -->1min
)=0
select 'OK, Não há cenário de Lock >1min' as [Situacao],'========' as [Spid], '========' as [Blocked] ,'========' as [Hostname],'========' as [Nt_Domain],'========' as [loginame],'========' as [Program_Name],'========' as [WaitTime_Seg],'========' as [Open_Tran],'========' as [status],'========' as [DB_Name],'========' as [Sql_Cmd]
else
Select 'Ofensor' as [Situacao] ,Spid, Blocked, Hostname=left(hostname,20),Nt_Domain,loginame, Program_Name=left(Program_Name,25),
WaitTime_Seg = convert(int,(waittime/1000)) ,last_batch,Open_Tran, status,DB_Name(dbid)as DB_Name,(select text from master.sys.dm_exec_sql_text(sql_handle)) as [Sql_Cmd]
From master.dbo.sysprocesses
Where blocked = 0 and spid in (select blocked from master.dbo.sysprocesses WITH (NOLOCK) Where blocked > 0)
UNION ALL
Select 'Bloqueado' as [Situacao] ,Spid, Blocked, Hostname=left(hostname,20),Nt_Domain,Loginame, Program_Name=left(PROGRAM_NAME,25),
WaitTime_Seg = convert(int,(waittime/1000)) ,last_batch,Open_Tran, status,DB_Name(dbid)as DB_Name,(select text from master.sys.dm_exec_sql_text (sql_handle)) as [Sql_Cmd]
From master.dbo.sysprocesses
Where blocked > 0
order by [Situacao]Desc,WaitTime_Seg Desc
END

 

 


-- Caso necessite matar a sessao
-- If need kill a session.

--PS: type [kill] and after the number session
  KILL 80
 


-- The follow some systems command to check the environment

sp_who

 

sp_who2

 

sp_who3

 

sp_whoisactive
