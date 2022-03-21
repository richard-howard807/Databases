IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - DBO access to Non-Sensitive DBs on SVR-LIV-DWH-01')
CREATE LOGIN [SBC\SQL - DBO access to Non-Sensitive DBs on SVR-LIV-DWH-01] FROM WINDOWS
GO
CREATE USER [SBC\SQL - DBO access to Non-Sensitive DBs on SVR-LIV-DWH-01] FOR LOGIN [SBC\SQL - DBO access to Non-Sensitive DBs on SVR-LIV-DWH-01]
GO
