IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'SBC\SSAS - DWH-02 Cube Readers')
CREATE LOGIN [SBC\SSAS - DWH-02 Cube Readers] FROM WINDOWS
GO
CREATE USER [SBC\SSAS - DWH-02 Cube Readers] FOR LOGIN [SBC\SSAS - DWH-02 Cube Readers]
GO
