IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\6237')
CREATE LOGIN [SBC\6237] FROM WINDOWS
GO
CREATE USER [SBC\6237] FOR LOGIN [SBC\6237]
GO
REVOKE CONNECT TO [SBC\6237]
