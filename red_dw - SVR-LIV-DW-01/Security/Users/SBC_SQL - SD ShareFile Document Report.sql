IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - SD ShareFile Document Report')
CREATE LOGIN [SBC\SQL - SD ShareFile Document Report] FROM WINDOWS
GO
CREATE USER [SBC\SQL - SD ShareFile Document Report] FOR LOGIN [SBC\SQL - SD ShareFile Document Report]
GO
