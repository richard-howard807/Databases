IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\esmith01')
CREATE LOGIN [SBC\esmith01] FROM WINDOWS
GO
CREATE USER [SBC\esmith01] FOR LOGIN [SBC\esmith01]
GO
REVOKE CONNECT TO [SBC\esmith01]
