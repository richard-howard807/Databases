SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MIBPossibleReturns]
AS
BEGIN
SELECT 'WTMS' AS [Recovery agent]
,MIL07 AS [Date returned from agent]
,MIL07 AS [Date allocated to the MIB]
,MIB_ClaimNumber AS [MIB reference]
,MIL04 AS [Policy/Claim Number]
,'UNI' AS [Claim Class]
,Forename  + ' ' + Surname AS [Defended]
,CurrentBalance AS [Amount]
,NULL AS [Recovery Handler]
,MIL06 AS [Insurers]

FROM VFile_Streamlined.dbo.AccountInformation AS a
INNER JOIN VFile_Streamlined.dbo.ClientScreens
 ON a.mt_int_code=ClientScreens.mt_int_code
LEFT OUTER JOIN (SELECT mt_int_code,CONVERT(DATE, ud_field##7, 103)  AS MIL07,ud_field##4 AS [MIL04],ud_field##6 AS [MIL06] FROM VFile_Streamlined.dbo.uddetail WHERE uds_type='MIL') AS MIL
 ON a.mt_int_code=MIL.mt_int_code
LEFT OUTER JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType='Primary Debtor') AS Debtor
 ON a.mt_int_code=Debtor.mt_int_code
WHERE ClientName='MIB'
AND MIL07 <>'1900-01-01'

ORDER BY MIL07
END
GO
