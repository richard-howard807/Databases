IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\jbonne')
CREATE LOGIN [SBC\jbonne] FROM WINDOWS
GO
CREATE USER [SBC\jbonne] FOR LOGIN [SBC\jbonne] WITH DEFAULT_SCHEMA=[SBC\jbonne]
GO
REVOKE CONNECT TO [SBC\jbonne]
