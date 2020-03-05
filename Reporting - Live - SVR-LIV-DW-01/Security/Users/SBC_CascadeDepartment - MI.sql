IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\CascadeDepartment - MI')
CREATE LOGIN [SBC\CascadeDepartment - MI] FROM WINDOWS
GO
CREATE USER [SBC\CascadeDepartment - MI] FOR LOGIN [SBC\CascadeDepartment - MI]
GO
