SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





--EXEC [CommercialRecoveries].[MIBCollectionsReport] '2019-12-01','2019-12-02','First Placement'

CREATE PROCEDURE [CommercialRecoveries].[MIBCollectionsReport]
--
(@StartDate AS DATE
,@EndDate AS DATE
,@Placement AS NVARCHAR(50)

)
AS
BEGIN
SELECT  txtDefSur AS defendant
      , usrAlias + ' / ' +  ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS agentref
      , txtClaimRef AS claimnumber
      , CASE WHEN [red_dw].[dbo].[datetimelocal](dbFile.Created) <'2019-02-01' THEN 15 ELSE 22.5 END AS commission
      , curOriginalBal AS instructedvalue
      , curOriginalBal AS totalinstructedvalue
      , curClient AS paidtoagent
      , 0 AS paidtoclient
      ,curCurrentBal AS CurrentBalance
	  ,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END  AS [ADA28]
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS DateOpened
FROM (SELECT udCRLedgerSL.fileID,SUM(curClient) AS curClient 
FROM [MS_PROD].dbo.udCRLedgerSL
INNER JOIN [MS_PROD].config.dbfile
 ON udCRLedgerSL.FileID=dbfile.FileID
WHERE fileType='2038' AND cboCatDesc ='5'
AND CONVERT(DATE,dtePosted,103) BETWEEN @StartDate AND @ENdDate
GROUP BY udCRLedgerSL.fileID) AS udCRLedgerSL
INNER JOIN [MS_PROD].config.dbfile
 ON dbFile.fileID = udCRLedgerSL.fileID
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = udCRLedgerSL.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = udCRLedgerSL.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = udCRLedgerSL.fileID
LEFT OUTER JOIN [MS_PROD].dbo.dbUser
 ON filePrincipleID=usrID
WHERE clNo='M1001'
AND CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END=@Placement
END
GO
