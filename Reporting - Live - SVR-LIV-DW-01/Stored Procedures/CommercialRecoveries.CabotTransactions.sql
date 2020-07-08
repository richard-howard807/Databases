SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [CommercialRecoveries].[CabotTransactions]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT 
txtAccNumber AS SupplierRef
,txtClientNum AS ClientRef
,txtAccNumber AS OriginalCreditorRef
,contTitle AS DebtorTitle
,contChristianNames AS DebtorForename
,contSurname AS DebtorSurname
,[red_dw].[dbo].[datetimelocal](dtePosted) AS DateOfTransaction
,curClient AS Payment
,NULL AS Fee
,NULL AS Cost
,NULL AS Interest
,NULL AS Adjustment
,PaymentType.cdDesc AS PaymentMethod
,ISNULL(ComRecClientBalance,0) AS ClientBalance
,clNo + '.' + fileNo AS [OurReference]

FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore
 ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON  udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRSOLCDE
 ON  udCRSOLCDE.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON  udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant],contTitle,contSurname,contChristianNames FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN MS_PROD.dbo.dbContactIndividual
 ON dbContactIndividual.contID = dbContact.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
 LEFT OUTER JOIN (SELECT * FROM MS_PROD.dbo.dbCodeLookup WHERE cdType='PAYTYPEALL') AS PaymentType
 ON udCRLedgerSL.cboPayType=PaymentType.cdCode
LEFT OUTER JOIN dbo.ComRecClientBalances
 ON  ComRecClientBalances.fileID = dbFile.fileID
 
 
WHERE clNo='W15367'
AND cboCatDesc='5'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
END
GO
