IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL - FinanceSystems')
CREATE LOGIN [SBC\SQL - FinanceSystems] FROM WINDOWS
GO
CREATE USER [SBC\SQL - FinanceSystems] FOR LOGIN [SBC\SQL - FinanceSystems]
GO
GRANT VIEW DEFINITION TO [SBC\SQL - FinanceSystems]
