SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MIBComplaints] -- EXEC VisualFiles.MIBComplaints '1900-01-01','2020-01-01'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN

SELECT 
MIB_ClaimNumber AS [Client reference number]
,MIL01  AS [Date complaint received]
,MIL02  AS [Nature of complaint]
,MIL03  AS [Action Taken Each Week]
,MIL04  AS [Status - Resolved/Unresolved]
,MIL05  AS [Date final response issued]
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END AS [First/Second Placement]

FROM VFile_Streamlined.dbo.AccountInformation
INNER JOIN (SELECT owner_code AS mt_int_code,CONVERT(DATE,ud_field##1,103) AS MIL01
,ud_field##2 AS MIL02
,ud_field##3 AS MIL03
,ud_field##4 AS MIL04
,CONVERT(DATE,ud_field##5,103) AS MIL05
FROM    [SVR-LIV-VISF-01].[Vfile_Live].[dbo].[uddetail] WITH ( NOLOCK )
                WHERE   uds_type ='MIL') AS MIL
                 ON AccountInformation.mt_int_code=MIL.mt_int_code
 LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens
  ON AccountInformation.mt_int_code=ClientScreens.mt_int_code
 LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON AccountInformation.mt_int_code=ADA.mt_int_code
WHERE ClientName='MIB'
AND MIL01 BETWEEN @StartDate AND @EndDate
AND MIL01>'1900-01-01'
END
GO
