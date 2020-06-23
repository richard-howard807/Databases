SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











--EXEC [CommercialRecoveries].[MIBCollectionsReport] '2020-06-19','2020-06-19','First Placement'

CREATE PROCEDURE [CommercialRecoveries].[MIBCollectionsReport]
--
(@StartDate AS DATE
,@EndDate AS DATE
,@Placement AS NVARCHAR(50)

)
AS
BEGIN
SELECT  CASE WHEN RTRIM(txtDefSur)='' THEN Associates.contSurname ELSE txtDefSur END AS defendant
      , usrAlias + ' / ' +  ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS agentref
      , txtClaimRef AS claimnumber
      , CASE WHEN [red_dw].[dbo].[datetimelocal](dbFile.Created) <'2019-02-01' THEN 15 ELSE 22.5 END AS commission
      , curOriginalBal AS instructedvalue
      , curOriginalBal AS totalinstructedvalue
      , curAgent AS paidtoagent
      , curClient AS paidtoclient
      ,curCurrentBal AS CurrentBalance
	  ,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END  AS [ADA28]
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS DateOpened
,ISNULL(ComRecClientBalance,0) AS ClientBalance
,RTRIM(clNo)+'-'+RTRIM(fileNo) AS [3e Reference]
,udCRLedgerSL.NoCleared
,udCRLedgerSL.NoPending
FROM (SELECT udCRLedgerSL.fileID
,SUM(CASE WHEN cboPayType='PAY015' THEN curClient ELSE 0 END) AS curClient 
,SUM(CASE WHEN cboPayType='PAY015' THEN 0 ELSE curClient END) AS curAgent 
,SUM(CASE WHEN cboCatDesc='5' THEN 1 ELSE 0 END)AS NoCleared
,SUM(CASE WHEN cboCatDesc='6' THEN 1 ELSE 0 END)AS NoPending
FROM [MS_PROD].dbo.udCRLedgerSL
INNER JOIN [MS_PROD].config.dbfile
 ON udCRLedgerSL.FileID=dbfile.FileID
WHERE fileType='2038' AND cboCatDesc  IN ('5','6')
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @ENdDate
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
LEFT OUTER JOIN dbo.ComRecClientBalances
 ON  ComRecClientBalances.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT DISTINCT fileID,contTitle,contChristianNames,contSurname FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
INNER JOIN [MS_PROD].dbo.dbContactIndividual
 ON dbContactIndividual.contID = dbContact.contID
LEFT OUTER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
 WHERE assocType='DEFENDANT'
 AND cboDefendantNo='1') AS Associates
  ON Associates.fileID = dbFile.fileID
WHERE clNo='M1001'
AND CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END=@Placement
END
GO
