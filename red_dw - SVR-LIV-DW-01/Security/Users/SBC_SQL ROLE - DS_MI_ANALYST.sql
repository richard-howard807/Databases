IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SQL ROLE - DS_MI_ANALYST')
CREATE LOGIN [SBC\SQL ROLE - DS_MI_ANALYST] FROM WINDOWS
GO
CREATE USER [SBC\SQL ROLE - DS_MI_ANALYST] FOR LOGIN [SBC\SQL ROLE - DS_MI_ANALYST]
GO
