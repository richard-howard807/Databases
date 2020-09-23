IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\sgrego')
CREATE LOGIN [SBC\sgrego] FROM WINDOWS
GO
CREATE USER [SBC\sgrego] FOR LOGIN [SBC\sgrego] WITH DEFAULT_SCHEMA=[SBC\sgrego]
GO
REVOKE CONNECT TO [SBC\sgrego]
