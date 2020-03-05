IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\sparke01')
CREATE LOGIN [SBC\sparke01] FROM WINDOWS
GO
CREATE USER [SBC\sparke01] FOR LOGIN [SBC\sparke01]
GO
REVOKE CONNECT TO [SBC\sparke01]
