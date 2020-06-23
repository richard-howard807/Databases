SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [CommercialRecoveries].[CostCutter]
AS
BEGIN
SELECT clNo +'-'+ fileNo AS [CaseCode] 
,fileDesc AS [CaseDesc]
,Reference AS [AlternativeRef]
,curOriginalBal AS [PrincipalDebt]
,Ledger.Payments AS [SumsRecovered]
,curCurrentBal AS [CurrentBalance]
,txtClaNum2 AS [ClaimNumber]
,txtCurenStatNot AS [Reporting Notes]
,usrFullName AS [WeightmansHandler]
,CASE WHEN fileStatus ='LIVE' THEN 'Open' ELSE 'Closed' END AS FileStatus
,dbFile.Created AS [DateOpened]
,fileClosed AS [DateClosed]
,DATEDIFF(DAY,dbFile.Created,fileClosed) AS [DaysOpened]
,dbFile.fileID
,Defendant.Defendant
,Defendant.Postcode
,Longitude
,Latitude 
,CASE WHEN Defendant.contTypeCode='ORGANISATION' THEN 'Company' WHEN Defendant.contTypeCode='INDIVIDUAL' THEN 'Individual' ELSE 'Other' END AS [Company Or Individual]
,AnnualYTD AS [RecoveredYTD]
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore
 ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRInsolvency 
 ON udCRInsolvency.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udCRIssueDetails
 ON udCRIssueDetails.fileID = dbFile.fileID
LEFT OUTER JOIN 
(
SELECT MS_Prod.dbo.udCRLedgerSL.fileID
,ISNULL(SUM(CASE WHEN cboCatDesc='2' THEN curOffice ELSE NULL END),0) AS [Recoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc IN ('1') THEN curOffice ELSE NULL END),0) AS [Recoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='0' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='7' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc='4' THEN curOffice ELSE NULL END),0) AS [Interest]
,ISNULL(SUM(CASE WHEN cboCatDesc='5' AND ISNULL(cboPayType,'') <>'PAY016' THEN curClient ELSE NULL END),0) AS [Payments]
,ISNULL(SUM(CASE WHEN cboCatDesc='6' THEN curClient ELSE NULL END),0) AS [Receipta awaiting clearance]
,ISNULL(SUM(CASE WHEN cboCatDesc='3' THEN curOffice ELSE NULL END),0) AS [Original Balance]
,ISNULL(SUM(CASE WHEN cboCatDesc='5' AND YEAR(dtePosted)=YEAR(GETDATE()) THEN curClient ELSE NULL END),0) AS AnnualYTD
FROM [MS_PROD].dbo.udCRLedgerSL
INNER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = udCRLedgerSL.fileID
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
GROUP BY udCRLedgerSL.fileID
) AS Ledger
 ON Ledger.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT DISTINCT fileID,assocRef AS [Reference] FROM MS_Prod.config.dbAssociates
WHERE assocType='INSUREDCLIENT'
AND assocRef IS NOT NULL
) AS InsuredREf
 ON InsuredREf.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS Defendant,contTypeCode,addPostcode AS Postcode
,ROW_NUMBER() OVER (PARTITION BY fileID ORDER BY assocID ASC) AS RowNumber
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbAddress
 ON contDefaultAddress=addID
WHERE assocType='DEFENDANT') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN red_dw.dbo.Doogal
 ON Doogal.Postcode = Defendant.Postcode COLLATE DATABASE_DEFAULT
WHERE clNo='W22511' 
AND fileType='2038'


END
GO
