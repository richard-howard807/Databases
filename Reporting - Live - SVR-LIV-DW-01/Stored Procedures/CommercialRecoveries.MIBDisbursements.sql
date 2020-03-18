SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [CommercialRecoveries].[MIBDisbursements]
(@StartDate AS DATE
,@EndDate AS DATE
,@Placement AS NVARCHAR(50)
)
AS
BEGIN


SELECT
txtClaimRef AS [Account Number]
,ISNULL(CRSystemSourceID,RTRIM(clNo)+'-'+RTRIM(fileNo)) AS [Matter Code]
,ISNULL(txtDefTitle,'') + ' ' + ISNULL(txtDefFor,'') + ' ' + ISNULL(txtDefSur,'') AS [Debtor Name]
,ISNULL(CRSystemSourceID,RTRIM(clNo)+'-'+RTRIM(fileNo)) AS [Weightmans Ref]
,curOffice AS [Amount of Disbursement (£)]
,txtItemDesc AS [Disbursement Description]
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Posted Date]
,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END AS [Placement]
,RTRIM(clNo)+'-'+RTRIM(fileNo) AS [3e Reference]
FROM [MS_PROD].dbo.udCRLedgerSL
INNER JOIN [MS_PROD].config.dbFile
 ON dbFile.fileID = udCRLedgerSL.fileID
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
WHERE clNo='M1001'
AND cboCatDesc IN ('0','1')
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate	
AND CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END=@Placement
END
GO
