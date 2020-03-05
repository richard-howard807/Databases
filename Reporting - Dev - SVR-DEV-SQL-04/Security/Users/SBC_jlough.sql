IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\jlough')
CREATE LOGIN [SBC\jlough] FROM WINDOWS
GO
CREATE USER [SBC\jlough] FOR LOGIN [SBC\jlough] WITH DEFAULT_SCHEMA=[SBC\jlough]
GO
REVOKE CONNECT TO [SBC\jlough]
