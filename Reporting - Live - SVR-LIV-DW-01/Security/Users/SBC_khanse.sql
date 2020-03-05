IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\khanse')
CREATE LOGIN [SBC\khanse] FROM WINDOWS
GO
CREATE USER [SBC\khanse] FOR LOGIN [SBC\khanse]
GO
