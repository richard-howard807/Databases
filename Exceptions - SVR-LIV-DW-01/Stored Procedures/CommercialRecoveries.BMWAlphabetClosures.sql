SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





--EXEC CommercialRecoveries.BMWAlphabetClosures 'BMW' ,'2020-08-01','2020-09-03'
CREATE PROCEDURE [CommercialRecoveries].[BMWAlphabetClosures]
(
 @Client AS NVARCHAR(50)
,@StartDate AS  DATE
,@EndDate  AS DATE
)
AS

BEGIN
--DECLARE @Client AS NVARCHAR(MAX)
--SET @Client='BMW'

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2020-08-01'
--SET @EndDate='2020-09-03'

SELECT txtCliRef AS [Account Number]
,clNo +'-' + fileNo  AS [Weightmans Reference]
,dbFile.Created AS [Date Instructred]
,Defendant.Defendant AS [Customer's Name]
,cdDesc AS [Closure Type]
,fileClosed AS [Date of Closure]
,RecoverableCosts.[Recoverable Costs]
,RecoverableDisbursements.[Recoverable Disbursements]
,TotalCollections AS [Total payments collected to date]
,unrecoverableCosts.unrecoverableCosts
,curOriginalBal AS [Balance for recovery on instruction]
,Bills.defence_costs_billed_composite
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.udCRBMWAlphabet
 ON udCRBMWAlphabet.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.dbCodeLookup
 ON cboClosureType=cdCode AND cdType='CLOSURE3'
 LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS [Recoverable Costs]
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='2'
GROUP BY fileID) AS RecoverableCosts
 ON RecoverableCosts.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS [Recoverable Disbursements]
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='1'
GROUP BY fileID) AS RecoverableDisbursements
 ON RecoverableDisbursements.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curClient) AS TotalCollections
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='5'
GROUP BY fileID) AS TotalPayments
 ON TotalPayments.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS unrecoverableCosts
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='7'
GROUP BY fileID) AS unrecoverableCosts
 ON unrecoverableCosts.fileID = dbFile.fileID
 LEFT OUTER JOIN 
(
SELECT ms_fileid,defence_costs_billed_composite FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code IN 
(
'FW30085','FW22135','341077','FW22352' ,'FW22135','FW22135','FW22613' ,'W15335' ,'W20110','FW23557'
) 
) AS Bills
 ON dbFile.fileID=Bills.ms_fileid
WHERE (CASE WHEN clNo IN ('FW30085','FW22135') THEN 'BMW' 
WHEN clNo='341077' THEN 'Land Rover'
WHEN clNo='FW22352' THEN 'Rover'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22275%' THEN 'MG'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22222%' THEN 'R&B'
WHEN clNo='FW22613' THEN 'Mini'
WHEN clNo='W15335' THEN 'Alphera'
WHEN clNo IN ('W20110','FW23557') THEN 'Alphabet' 
END)=@Client
AND fileClosed BETWEEN @StartDate AND @EndDate

END 
GO
