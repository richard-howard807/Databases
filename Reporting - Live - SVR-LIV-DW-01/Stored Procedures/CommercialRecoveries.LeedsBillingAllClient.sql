SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--EXEC [CommercialRecoveries].[LeedsBillingAllClient] '2020-03-06', '2020-03-06'

CREATE PROCEDURE [CommercialRecoveries].[LeedsBillingAllClient]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT clNo +'-'+fileNo AS [Matter]
,clName AS [Client Name]
, MS_Prod.dbo.dbBranch.brName AS [Office]
,CASE 
WHEN (CRSystemSourceID  LIKE '33832-%' OR cboLeedsCC='LC1') THEN 'Business Rates'
WHEN (CRSystemSourceID  LIKE '31991-%' OR cboLeedsCC='LC2') THEN 'Section 146 Leasehold Charges'
WHEN (CRSystemSourceID  LIKE '3600%'   OR cboLeedsCC='LC3') THEN 'Council Tax, Housing Benefit & Sundry Income' 


END AS [Client Type(LCC & UPS)]

,usrFullName AS [Posted By]
,CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) AS [Posted Date]
,CASE WHEN cboCatDesc='0' THEN 'Unrecoverable Disbursement'
WHEN cboCatDesc='1' THEN 'Recoverable Disbursement'
WHEN cboCatDesc='2' THEN 'Recoverable Cost'
WHEN cboCatDesc='7' THEN 'Unrecoverable Cost' END AS [Disbursment/Cost Type]
,txtItemDesc AS [Item Description]
,cboItemCode AS [Item Code]
,curOffice AS Amount
,curVAT AS [Vat Amount]
,cboVATCat AS [Vatable]
,ISNULL(AssociateRef,txtCliRef) AS AssociateRef
,ISNULL(UnbilledDisb,0) AS UnbilledDisb
,LastBillDate AS LastBill
FROM ms_prod.config.dbFile
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN MS_Prod.dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
 LEFT OUTER JOIN MS_Prod.dbo.dbUser
  ON MS_Prod.dbo.udCRLedgerSL.usrID=dbuser.usrid
LEFT OUTER JOIN MS_Prod.dbo.udCRCore
 ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.dbBranch
 ON dbBranch.brID = dbfile.brID
LEFT OUTER JOIN (SELECT dbAssociates.fileID,assocRef  AS AssociateRef FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = dbAssociates.fileID
WHERE assocType='CLIENT'AND assocRef IS NOT NULL
AND assocOrder=0
AND fileType='2038') AS AssociateRef
 ON AssociateRef.fileID = dbFile.fileID
 LEFT OUTER JOIN dbo.ComRecUnbilledDisbs
 ON  ComRecUnbilledDisbs.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,MAX(InvDate) AS LastBillDate
FROM TE_3E_Prod.dbo.ARDetail
INNER JOIN MS_Prod.config.dbFile
 ON Matter=fileExtLinkID
WHERE ARList IN ('Bill','BillRev')
AND fileType='2038'
GROUP BY fileID) AS LastBill
 ON LastBill.fileID = dbfile.fileID



WHERE cboCatDesc IN ('0','1','7')
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
AND clNo <>'30645'
AND brName='Leeds'
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103) BETWEEN @StartDate AND @EndDate
AND clNo NOT IN 
(
'FW22135','FW22613','W15335' --BMW
,'W15374' --  CarCashPoint Limited
,'W15410' --  The Borough Council of Dudley
,'FW27456'--  Stratford On Avon District Council
,'W15354' --  Basildon Borough Council
,'W15495' --  M.K.M Building Supplies Limited'
,'W15471' --  LCC
,'W17055' --  Energas'
,'FW13329'--  UPS
)
ORDER BY CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) DESC 
END 
GO
