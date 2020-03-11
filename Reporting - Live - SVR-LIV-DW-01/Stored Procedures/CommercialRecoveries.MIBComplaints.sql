SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [CommercialRecoveries].[MIBComplaints] -- EXEC VisualFiles.MIBComplaints '1900-01-01','2020-01-01'
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
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END AS [First/Second Placement]

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
AND AccountInformation.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMattersSuccess)

UNION

SELECT 
txtClaimRef AS [Client reference number]
,[red_dw].[dbo].[datetimelocal](dteComplaint) AS [Date complaint received]
,txtDescCompla  AS [Nature of complaint]
,txtActTaken  AS [Action Taken Each Week]
,CASE WHEN cboStatus='RES' THEN 'Resolved'
WHEN cboStatus='UNRES' THEN 'Unresolved' END  AS [Status - Resolved/Unresolved]
,dteResolved  AS [Date final response issued]
,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END AS [First/Second Placement]

FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM [MS_PROD].dbo.dbCodeLookup WHERE cdType='RETENTION') AS Reason
 ON cboRetReason=Reason.cdCode
WHERE clNo='M1001'
AND fileType='2038'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dteComplaint),103) BETWEEN @StartDate AND @EndDate
AND [red_dw].[dbo].[datetimelocal](dteClosedDate) IS NULL




END
GO
