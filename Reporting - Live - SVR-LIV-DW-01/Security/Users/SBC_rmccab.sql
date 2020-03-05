IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\rmccab')
CREATE LOGIN [SBC\rmccab] FROM WINDOWS
GO
CREATE USER [SBC\rmccab] FOR LOGIN [SBC\rmccab]
GO
