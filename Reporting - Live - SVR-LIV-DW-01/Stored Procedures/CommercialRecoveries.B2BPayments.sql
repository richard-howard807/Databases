SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [CommercialRecoveries].[B2BPayments] --EXEC [CommercialRecoveries].[B2BPayments] '2019-12-01','2019-12-06','723152'
(
@StartDate AS DATE
,@EndDate AS DATE
,@ClientName AS NVARCHAR(100)
)
AS
BEGIN
SELECT 
dbFile.fileID
,'MBC' + ' / ' + ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS [Weightmans Reference]
,NULL AS [Client Reference]
,ISNULL(Defendant,fileDesc) AS [Debtor]
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Payment Date]
,PaymentType.cdDesc AS [Payment Type]
,txtSubClient AS [Sub Client]
,curclient AS [PaymentAmount]
,ISNULL(txtClientName,clName) AS [Client]
,ISNULL(ComRecClientBalance,0) AS ClientBalance
,clNo +'-' + fileNo AS [3E Reference]

FROM MS_PROD.config.dbFile
INNER JOIN MS_PROD.dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
INNER JOIN MS_PROD.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN MS_PROD.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_PROD.dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udCRSOLCDE
 ON udCRSOLCDE.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT * FROM MS_PROD.dbo.dbCodeLookup WHERE cdType='PAYTYPEALL') AS PaymentType
 ON cboPayType=PaymentType.cdCode
LEFT OUTER JOIN dbo.ComRecClientBalances
 ON  ComRecClientBalances.fileID = dbFile.fileID
WHERE fileType='2038'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
AND clNo=@ClientName
AND cboCatDesc='5'
END
GO
