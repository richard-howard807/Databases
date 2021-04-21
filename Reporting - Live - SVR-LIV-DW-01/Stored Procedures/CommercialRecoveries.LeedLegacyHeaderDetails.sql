SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [CommercialRecoveries].[LeedLegacyHeaderDetails]
(
@SourceSystemID AS NVARCHAR(100)
)
AS 
BEGIN

SELECT  RTRIM(CAST(maclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(mamatn AS NVARCHAR(20))) AS SourceSystemID 
,madesc AS MatterDescription
,FE.fename AS MatterOwner
,madtop AS DateOpened
--,LastAction.LastActionDateDate
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[MAFILE] WITH(NOLOCK)
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[FEFILE] AS FE WITH(NOLOCK)
 ON MAEACT=FE.feidnm
--LEFT OUTER JOIN 
--(
--SELECT acclin,acmatn
--,MAX(acdate) AS LastActionDateDate
--FROM [SVR-LIV-SQL-04\LEGACYREADONLY].webdb.dbo.acfile WITH(NOLOCK)
--WHERE RTRIM(CAST(acclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(acmatn AS NVARCHAR(20)))=@SourceSystemID 
--GROUP BY acclin,acmatn
--) AS LastAction
-- ON maclin=LastAction.acclin
-- AND mamatn=LastAction.acmatn
WHERE RTRIM(CAST(maclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(mamatn AS NVARCHAR(20))) =@SourceSystemID 

END 
GO
