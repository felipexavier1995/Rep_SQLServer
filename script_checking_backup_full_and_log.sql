-- Script para verificação dos ultimos backup full e backup log.

use msdb
go
set nocount on
	declare @db varchar(128),
			@bkpIni datetime,
			@bkpFin datetime,
			@bkpIni_log datetime,
			@bkpFin_log datetime,
			@num_log varchar(64),
			@statusfull varchar(64),
			@statuslog varchar(64)
create table #db (nome varchar(128)) 

create table #dbresult (BANCO varchar(128),
		     BACKUP_FULL_START DATETIME,
			 BACKUP_FULL_FINISH DATETIME, 
			 RECOVERY varchar(64),
			 BACKUP_LOG_START DATETIME, 
			 BACKUP_LOG_FINISH DATETIME, 
			 QTD_BKP_LOG int, 
			 STATUS_BKP_FULL VARCHAR(64), 
			 STATUS_BKP_LOG VARCHAR(64)) 

-- Insere os bancos de dados na tabela temporário #db
insert into #db
    select name from master..sysdatabases
    where name not in ('tempdb')
	while (select COUNT(nome) from #db) > 0
begin

 

    select top 1 @db =  nome from #db

    -- Armazena a data do ultimo backup full nas variaveis
    select    @bkpIni = MAX(backup_start_date),
            @bkpFin = MAX(backup_finish_date)
    from backupset
    where database_name = @db
        and type in ('I' ,'D')

    if (@bkpFin >= dateadd(day, -1, getdate()))    
        begin
        SELECT @statusfull = 'OK'
        end
    else
        begin
        SELECT @statusfull = 'NOK'
        end
    if (DATABASEPROPERTYEX(@db, 'Recovery') != 'SIMPLE') -- Verifica o tipo de recovery model
    begin -- Bloco de instrucoes para bancos em recovery model full ou bulk-logged

        -- Se o banco fizer backup de log ele armazena a data do último backup de log
        select    @bkpIni_log = MAX(backup_start_date),
                @bkpFin_log = MAX(backup_finish_date)
        from backupset
        where database_name = @db 
            and type = 'L'

        if (@bkpFin_log >= dateadd(minute, -75, getdate()))    
            begin
            SELECT @statuslog = 'OK'
            end
        else
            begin
            SELECT @statuslog = 'NOK'
            end

        -- Conta quantos backups de log foram feitos desde o ultimo backup full
        select @num_log = count(backup_start_date)
        from backupset
        where database_name = @db
            and type = 'L'
            and backup_start_date > @bkpFin

        -- Insere todas as informacoes na tabela temporária #dbresult
        insert into #dbresult
        select @db as BANCO, 
            @bkpIni as BACKUP_FULL_START, 
            @bkpFin as BACKUP_FULL_FINISH, 
            convert(char(10),databasepropertyex(@db,'recovery')) as recovery, 
            @bkpIni_log as BACKUP_LOG_START, 
            @bkpFin_log as BACKUP_LOG_FINISH, 
            @num_log as qtd_log,
            @statusfull as STATUS_BKP_FULL,
            @statuslog as STATUS_BKP_LOG
        -- dropa o banco que esta no while da tabela #db 
        delete from #db
        where nome = @db
        --select ''
    end
    else -- Bloco de instrucoes para bancos em recovery model simple
        -- Insere todas as informacoes na tabela temporária #dbresult
        insert into #dbresult
        select @db as BANCO, @bkpIni as BACKUP_FULL_START, @bkpFin as BACKUP_FULL_FINISH, convert(char(10),databasepropertyex(@db,'recovery')) as recovery, 0,0,0, @statusfull,'-'

        -- dropa o banco que esta no while da tabela #db 
        delete from #db
        where nome = @db

    --select ''
    end -- fim if
    --select BANCO,
select @@servername as INSTANCIA, BANCO, STATUS_BKP_FULL, STATUS_BKP_LOG, RECOVERY, BACKUP_FULL_FINISH, BACKUP_LOG_FINISH, QTD_BKP_LOG from #dbresult    
drop table #db
drop table #dbresult
set nocount off
