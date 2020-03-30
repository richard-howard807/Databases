SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [CommercialRecoveries].[NewLedgerView] --'M1001','29785'
(
@Client AS NVARCHAR(12)
,@Matter AS NVARCHAR(12)
)
AS
BEGIN
SELECT MS_Prod.dbo.udCRLedgerSL.fileID
,clNo AS [Client]
,clName AS [Client Name]
,fileNo AS [Matter]
,fileDesc AS [Matter Description]
,curCurrentBal AS [Current Balance]
,ISNULL(SUM(CASE WHEN cboCatDesc='2' THEN curOffice ELSE NULL END),0) AS [Recoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc IN ('1') THEN curOffice ELSE NULL END),0) AS [Recoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='0' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='7' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc='4' THEN curOffice ELSE NULL END),0) AS [Interest]
,ISNULL(SUM(CASE WHEN cboCatDesc='5' AND ISNULL(cboPayType,'') <>'PAY016' THEN curClient ELSE NULL END),0) AS [Payments]
,ISNULL(SUM(CASE WHEN cboCatDesc='6' THEN curClient ELSE NULL END),0) AS [Receipta awaiting clearance]
,ISNULL(SUM(CASE WHEN cboCatDesc='3' THEN curOffice ELSE NULL END),0) AS [Original Balance]
FROM [MS_PROD].dbo.udCRLedgerSL
INNER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = udCRLedgerSL.fileID
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
WHERE clNo=@Client AND fileNo=@Matter
GROUP BY udCRLedgerSL.fileID
,clNo 
,clName 
,fileNo 
,fileDesc 
,curCurrentBal
END
GO
