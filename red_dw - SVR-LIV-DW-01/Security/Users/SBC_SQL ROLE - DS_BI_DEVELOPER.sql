IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL ROLE - DS_BI_DEVELOPER')
CREATE LOGIN [SBC\SQL ROLE - DS_BI_DEVELOPER] FROM WINDOWS
GO
CREATE USER [SBC\SQL ROLE - DS_BI_DEVELOPER] FOR LOGIN [SBC\SQL ROLE - DS_BI_DEVELOPER]
GO