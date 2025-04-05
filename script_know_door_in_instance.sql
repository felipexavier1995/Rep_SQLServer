-- Script for know what door and IP the instance have.

print '' 
print '--ips e portas utilizadas' 
print '' 
use master 
go 
xp_readerrorlog 0, 1, N'server is listening on' 
go 
print '' 
go
