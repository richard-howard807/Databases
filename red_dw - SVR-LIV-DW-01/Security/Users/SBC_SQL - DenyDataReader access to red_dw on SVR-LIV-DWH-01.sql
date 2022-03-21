IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01')
CREATE LOGIN [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01] FROM WINDOWS
GO
CREATE USER [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01] FOR LOGIN [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
