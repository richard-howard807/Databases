IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\DWH_SSASAdmin')
CREATE LOGIN [SBC\DWH_SSASAdmin] FROM WINDOWS
GO
CREATE USER [SBC\DWH_SSASAdmin] FOR LOGIN [SBC\DWH_SSASAdmin]
GO