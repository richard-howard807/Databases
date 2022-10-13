SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[PaperRiverAuditDocSearchArchive]
(
 @MSDocID AS VARCHAR(255) =  NULL
 ,@QuickDropID AS BIGINT =  NULL

)
AS 

BEGIN

SELECT
filter8 AS [Mattersphere Document ID]
,filter5 AS [Document Description]
,Filter3 AS [Client Number]
,Filter4 AS [Matter Number]
,Employee2.knownas + ' ' + Employee2.surname AS [Matter Manager]
,Scan_datetime AS [Scanned Date/Time]
,dim_employee.knownas + ' ' + dim_employee.surname AS [Scanned BY]
,job_id AS [QuickDrop Document Number]
,docDesc
,dirPath +'\' + docFileName AS [Document Path]
FROM [SVR-LIV-3PTY-01].PaperRiverAudit.dbo.ArchiveAuditLog  AS RecentAuditLog WITH(NOLOCK)

INNER JOIN ms_prod.config.dbDocument WITH(NOLOCK)
 ON RTRIM(filter8)=CAST(docID AS NVARCHAR(MAX))
INNER JOIN MS_PROD.dbo.dbDirectory WITH(NOLOCK)
 ON dbDirectory.dirID = dbDocument.docdirID
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON scan_user=dim_employee.windowsusername COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_employee AS Employee2
 ON Filter2=Employee2.windowsusername COLLATE DATABASE_DEFAULT
WHERE filter8=@MSDocID OR job_id=@QuickDropID



END 
GO
