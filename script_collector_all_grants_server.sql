-- It script is for collector all grants that contain in a server.

SELECT 'ALTER SERVER ROLE [' + SP2.[name] + ']' + ' ADD MEMBER [' + SP1.[name] + ']' + 'GO' as 'cmd'
FROM sys.server_principals SP1
	JOIN sys.server_role_members SRM ON SP1.principal_id = SRM.member_principal_id
	JOIN sys.server_principals SP2 ON SRM.role_principal_id = SP2.principal_id
WHERE SP1.[name] not like 'NT %' and SP1.[name] not like 'sa'
ORDER BY SP1.[name], SP2.[name];
