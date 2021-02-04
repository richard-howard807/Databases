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
,NULL AS MatterOwner
,ardtop AS DateOpened
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].fwact.dbo.arfile AS arfile
--LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[FEFILE] AS FE
-- ON arfile.areact=FE.feidnm


WHERE RTRIM(CAST(arfile.arclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(armatn AS NVARCHAR(20))) =@SourceSystemID 

END 
GO
