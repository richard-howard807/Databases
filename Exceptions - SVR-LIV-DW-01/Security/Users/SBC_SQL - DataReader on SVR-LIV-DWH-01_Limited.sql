IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited')
CREATE LOGIN [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited] FROM WINDOWS
GO
CREATE USER [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited] FOR LOGIN [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO
