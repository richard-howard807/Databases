IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\jnorto')
CREATE LOGIN [SBC\jnorto] FROM WINDOWS
GO
CREATE USER [SBC\jnorto] FOR LOGIN [SBC\jnorto]
GO
