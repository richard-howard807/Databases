SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [CommercialRecoveries].[LCCCashCollections] --EXEC [CommercialRecoveries].[LCCCashCollections] '2019-11-01','2020-02-20'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT 
ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS [Our Referece]
,clNo
,txtCliRef AS [Client Reference]	
,Defendant AS [Debtor Name]	
,curClient AS [Amount Recovered (£)]	
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Date of Payment]
,dtePosted
 FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
 WHERE cboCatDesc='5' 
 AND [red_dw].[dbo].[datetimelocal](dtePosted) BETWEEN @StartDate AND @EndDate
 AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
 AND (CRSystemSourceID LIKE '3600%' OR clNo='W15471')
 ORDER BY [red_dw].[dbo].[datetimelocal](dtePosted)
END
GO
