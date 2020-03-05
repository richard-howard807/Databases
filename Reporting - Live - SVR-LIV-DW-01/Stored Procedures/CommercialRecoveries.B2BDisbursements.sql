SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [CommercialRecoveries].[B2BDisbursements]
(
@StartDate AS DATE
,@EndDate AS DATE
,@ClientName AS NVARCHAR(100)
)
AS
BEGIN
SELECT 
txtClientName AS [Client Name]
,txtSubClient AS [Sub Client Name]
,Defendant AS [Debtor Name]
,txtCliNumRef AS [Client Reference]
,'MBC' + ' / ' + ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS [Weightmans Reference]
,curOffice AS [Amount]
,NULL AS [VAT]
,txtItemDesc AS [Description]
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Date]
,ISNULL(txtClientName,clName) AS [Client]
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRSOLCDE
 ON udCRSOLCDE.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
WHERE fileType='2038'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
AND clNo=@ClientName
AND cboCatDesc  IN ('1','0')


END
GO
