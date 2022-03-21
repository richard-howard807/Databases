IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - Workflow Team Exceptions Access')
CREATE LOGIN [SBC\SQL - Workflow Team Exceptions Access] FROM WINDOWS
GO
CREATE USER [SBC\SQL - Workflow Team Exceptions Access] FOR LOGIN [SBC\SQL - Workflow Team Exceptions Access]
GO
