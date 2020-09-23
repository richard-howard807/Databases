IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - Blueprism execute specific MS_PROD')
CREATE LOGIN [SBC\SQL - Blueprism execute specific MS_PROD] FROM WINDOWS
GO
CREATE USER [SBC\SQL - Blueprism execute specific MS_PROD] FOR LOGIN [SBC\SQL - Blueprism execute specific MS_PROD]
GO
