IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - Technical Services Read only')
CREATE LOGIN [SBC\SQL - Technical Services Read only] FROM WINDOWS
GO
CREATE USER [SBC\SQL - Technical Services Read only] FOR LOGIN [SBC\SQL - Technical Services Read only]
GO
