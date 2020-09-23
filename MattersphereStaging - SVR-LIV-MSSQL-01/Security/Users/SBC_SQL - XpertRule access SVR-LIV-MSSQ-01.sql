IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - XpertRule access SVR-LIV-MSSQ-01')
CREATE LOGIN [SBC\SQL - XpertRule access SVR-LIV-MSSQ-01] FROM WINDOWS
GO
CREATE USER [SBC\SQL - XpertRule access SVR-LIV-MSSQ-01] FOR LOGIN [SBC\SQL - XpertRule access SVR-LIV-MSSQ-01]
GO
