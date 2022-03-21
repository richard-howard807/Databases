IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\lnksvrdatareader_ext')
CREATE LOGIN [SBC\lnksvrdatareader_ext] FROM WINDOWS
GO
CREATE USER [SBC\lnksvrdatareader_ext] FOR LOGIN [SBC\lnksvrdatareader_ext]
GO
