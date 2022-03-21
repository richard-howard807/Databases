IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\ewilli02')
CREATE LOGIN [SBC\ewilli02] FROM WINDOWS
GO
CREATE USER [SBC\ewilli02] FOR LOGIN [SBC\ewilli02]
GO
