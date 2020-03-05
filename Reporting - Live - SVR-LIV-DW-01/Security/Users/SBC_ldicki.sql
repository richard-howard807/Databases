IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\ldicki')
CREATE LOGIN [SBC\ldicki] FROM WINDOWS
GO
CREATE USER [SBC\ldicki] FOR LOGIN [SBC\ldicki]
GO
REVOKE CONNECT TO [SBC\ldicki]
