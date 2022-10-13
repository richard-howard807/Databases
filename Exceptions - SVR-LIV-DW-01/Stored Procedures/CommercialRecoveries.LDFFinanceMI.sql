SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [CommercialRecoveries].[LDFFinanceMI] 
AS 

BEGIN 

SELECT  name AS [F/e]
, Ref.assocRef AS [Matter No]
, matter_description AS [Debtor]
, RTRIM(master_client_code) +'-'+RTRIM(master_matter_number)  AS [Your Ref(s)]
, curOriginalBal AS [Debt]
, Ledger.Interest AS [Interest to date]
, Ledger.[Recoverable Disbursements] AS [Court Fees to date]
, Ledger.[Recoverable Costs] AS [Recoverable Fixed Costs to date]
, Ledger.Payments AS [Recoveries to date]
, defence_costs_billed_composite AS [Costs Billed to date]
, disbursements_billed AS [Dibs Billed to date]
, wip AS [Current o/s WIP]
, disbursement_balance AS [Current o/s Dibs]
, NULL AS [% Value Costs Billed to date > Debt]
, CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END  AS [Status]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN ms_prod.dbo.udCRAccountInformation
 ON ms_fileid=fileID
LEFT OUTER JOIN 
(SELECT fileID
,ISNULL(SUM(CASE WHEN cboCatDesc='2' THEN curOffice ELSE NULL END),0) AS [Recoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc IN ('1') THEN curOffice ELSE NULL END),0) AS [Recoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='0' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='7' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc='4' THEN curOffice ELSE NULL END),0) AS [Interest]
,ISNULL(SUM(CASE WHEN cboCatDesc='5' AND ISNULL(cboPayType,'') <>'PAY016' THEN curClient ELSE NULL END),0) AS [Payments]
,ISNULL(SUM(CASE WHEN cboCatDesc='6' THEN curClient ELSE NULL END),0) AS [Receipta awaiting clearance]
,ISNULL(SUM(CASE WHEN cboCatDesc='3' THEN curOffice ELSE NULL END),0) AS [Original Balance]
FROM [MS_PROD].dbo.udCRLedgerSL
GROUP BY fileID
) AS Ledger
 ON Ledger.fileID = udCRAccountInformation.fileID
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT DISTINCT fileID,assocRef FROM ms_prod.config.dbAssociates WHERE assocType='CLIENT' AND assocRef IS NOT NULL) AS Ref
ON ms_fileid=Ref.fileID
WHERE master_client_code IN('W24815','W25103', 'W25612')
AND reporting_exclusions=0
AND master_matter_number <>'1'

END 
GO
