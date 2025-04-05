--- What doing in environment ?
--- The line 5, where write session_id > 50, You can delete and just leave 'where'

select db_name(database_id),percent_complete,blocking_session_id,reads,writes, * from sys.dm_exec_requests
where session_id>50
and   session_id<>@@SPID 
and db_name(database_id) <> 'master'
order by [start_time] asc
go
