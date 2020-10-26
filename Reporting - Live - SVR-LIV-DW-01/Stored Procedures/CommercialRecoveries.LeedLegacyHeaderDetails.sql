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
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[MAFILE] 
LEFT OUTER JOIN [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[FEFILE] AS FE
 ON MAEACT=FE.feidnm


WHERE RTRIM(CAST(maclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(mamatn AS NVARCHAR(20))) =@SourceSystemID 

END 
GO
