SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [Config].[uspAuditStart]
(
@PackageName varchar(100),
@PackageStart datetime,
@TaskName VARCHAR(100),
@CreatedBy varchar(100),
@DestinationTable VARCHAR(100),
@ExtractFilename varchar(400),
@ExtractFolder varchar(200),
@ParentAuditID int
)
AS
IF @ExtractFolder IS NOT NULL
BEGIN
SET @ExtractFilename = @ExtractFolder + @ExtractFilename
END

INSERT INTO [Config].Audit(AuditDate, AuditPackage, AuditTask, AuditTable, AuditStartTime, AuditRowInserted, AuditCreatedDate, AuditCreatedBy, AuditSource, ParentAuditID
)
VALUES (@PackageStart, @PackageName, @TaskName, @DestinationTable, GETDATE(),0, GETDATE(), @CreatedBy, @ExtractFilename,@ParentAuditID
)

SELECT @@IDENTITY AS AuditID




GO
