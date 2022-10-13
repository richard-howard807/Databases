SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [CommercialRecoveries].[AlphabetCompositReport]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 

BEGIN

SELECT ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY dbFile.fileID) AS [Number ID]
,dbFile.fileID AS [FileID]
,clNo + '-' + fileNo AS [WeightmansRef]
,COALESCE(assocRef,txtCliRef) AS [F_INV_ACCREF]
,NULL AS [F_INV_EXTERNAL_NUMBER]
,curOffice AS [F_INV_NET_TOTAL]
,curVAT AS [F_INV_VAT_TOTAL]
,txtCliRef AS [F_INV_VEH_ID]
,txtItemDesc AS [NARRATIVE_1]
,txtVehicleReg AS [NARRATIVE_2]
,fileDesc AS [Customer Name]
,CASE WHEN cboCatDesc='7' THEN 'Cost'
WHEN cboCatDesc <> '7' AND UPPER(txtItemDesc) LIKE '%COURT%' THEN 'Court Fee' 
ELSE 'Disbursement' END AS UnrecoverableCostType
,[Original Balance]

FROM ms_prod.config.dbFile
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN ms_prod.dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udCRCore
 ON dbFile.fileID=udcrcore.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant],assocRef FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON dbfile.fileid=Defendant.fileID
 LEFT JOIN 
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
FROM [MS_PROD].dbo.udCRLedgerSL  WITH(NOLOCK)
INNER JOIN ms_prod.config.dbFile  WITH(NOLOCK)
 ON dbFile.fileID = udCRLedgerSL.fileID
INNER JOIN ms_prod.config.dbClient  WITH(NOLOCK)
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.udCRAccountInformation  WITH(NOLOCK)
 ON udCRAccountInformation.fileID = dbFile.fileID
WHERE clNo IN ('W20110','FW23557') 
GROUP BY udCRLedgerSL.fileID
) AS Ledger
 ON Ledger.fileID = dbFile.fileID


WHERE clNo IN ('W20110','FW23557') 
AND fileType='2038'
AND cboCatDesc   IN ('7','0')
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate

END
GO
