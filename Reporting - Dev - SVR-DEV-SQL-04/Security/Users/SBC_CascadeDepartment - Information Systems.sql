IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\CascadeDepartment - Information Systems')
CREATE LOGIN [SBC\CascadeDepartment - Information Systems] FROM WINDOWS
GO
CREATE USER [SBC\CascadeDepartment - Information Systems] FOR LOGIN [SBC\CascadeDepartment - Information Systems]
GO
