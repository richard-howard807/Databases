IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\ExceptionsRedSVC')
CREATE LOGIN [SBC\ExceptionsRedSVC] FROM WINDOWS
GO
CREATE USER [SBC\ExceptionsRedSVC] FOR LOGIN [SBC\ExceptionsRedSVC]
GO
GRANT VIEW DEFINITION TO [SBC\ExceptionsRedSVC]
