IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\sreeve01')
CREATE LOGIN [SBC\sreeve01] FROM WINDOWS
GO
CREATE USER [SBC\sreeve01] FOR LOGIN [SBC\sreeve01]
GO
