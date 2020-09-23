IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\BluePrismService1')
CREATE LOGIN [SBC\BluePrismService1] FROM WINDOWS
GO
CREATE USER [SBC\BluePrismService1] FOR LOGIN [SBC\BluePrismService1]
GO
