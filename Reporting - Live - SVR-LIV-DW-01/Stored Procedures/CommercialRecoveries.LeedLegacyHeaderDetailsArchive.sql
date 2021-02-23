SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE PROCEDURE [CommercialRecoveries].[LeedLegacyHeaderDetailsArchive]
(
@SourceSystemID AS NVARCHAR(100)
)
AS 
BEGIN

SELECT  RTRIM(CAST(arclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(armatn AS NVARCHAR(20))) AS SourceSystemID 
,arfile.armnam AS MatterDescription
,arfile.arsrep AS MatterOwner
,ardtop AS DateOpened
,arfile.ardtcl AS [DateClosed]
,arfile.ardtds AS [DestructionDate]
,arfile.arloct AS [Archivelocation]
,'\\svr-liv-fs-09\Arcdocs\' + TRIM(CAST(arclin AS NVARCHAR(5))) + '\' +TRIM(CAST(armatn AS NVARCHAR(5)))+'\pms\pms_archive.rtf' AS MatterDocs
,CAST(arfile.arnumb AS NVARCHAR(MAX)) AS [ArchiveNumber]
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].fwact.dbo.arfile AS arfile
--LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[FEFILE] AS FE
-- ON arfile.areact=FE.feidnm


WHERE RTRIM(CAST(arfile.arclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(armatn AS NVARCHAR(20))) =@SourceSystemID 

END 
GO
