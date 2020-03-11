SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE   PROCEDURE [CommercialRecoveries].[BMWCollections]
(
@StartDate AS DATE
,@EndDate AS DATE
,@ClientName AS NVARCHAR(100)
)
AS
BEGIN
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE 
--SET @StartDate='2019-11-01'
--SET @EndDate='2019-11-30'

--DECLARE @ClientName AS NVARCHAR(100)
--SET @ClientName='BMW'


SELECT
clNo +'-' + fileNo AS [Client/Matter No]	
,txtCliRef AS [Agreement No]
,Defendant AS [Debtor Name]
,curClient AS [Amount Recovered (£)]	
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Date of Payment]	
,'Paid Direct to Weightmans' AS Narrative
,'Y' AS [Funds Cleared Y/N]	
,curClient AS [Total Cash Collected]	
,cboPaymentPlan AS [Code]
,cddesc AS DescriptionPlan
,CASE WHEN clNo IN ('FW30085','FW22135') THEN 'BMW' 
WHEN clNo='341077' THEN 'Land Rover'
WHEN clNo='FW22352' THEN 'Rover'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22275%' THEN 'MG'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22222%' THEN 'R&B'
WHEN clNo='FW22613' THEN 'Mini'
WHEN clNo='W15335' THEN 'Alphera'
WHEN clNo IN ('W20110','FW23557','890248') THEN 'Alphabet'END AS Client
,ISNULL(ComRecClientBalance,0) AS ClientBalance

FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.dbCodeLookup
 ON cboPaymentPlan=cdCode AND cdType='PAYPLAN'
 LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN dbo.ComRecClientBalances
 ON  ComRecClientBalances.fileID = dbFile.fileID
WHERE cboCatDesc ='5'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
AND cboPayType <>'PAY015' -- Direct Payment Tom asked to be removed from report

AND (CASE WHEN clNo IN ('FW30085','FW22135') THEN 'BMW' 
WHEN clNo='341077' THEN 'BMW'
WHEN clNo='FW22352' THEN 'BMW'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22275%' THEN 'BMW'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22222%' THEN 'BMW'
WHEN clNo='FW22613' THEN 'BMW'
WHEN clNo='W15335' THEN 'Alphera'
WHEN clNo IN ('W20110','FW23557','890248') THEN 'Alphabet'END)=@ClientName

END
GO
