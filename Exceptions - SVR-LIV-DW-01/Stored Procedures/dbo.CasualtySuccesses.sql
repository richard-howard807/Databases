SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CasualtySuccesses]

AS 

BEGIN


SELECT red_dw.dbo.dim_matter_header_current.client_name AS [Client Name]
,CASE WHEN outcome_of_case LIKE '%Discontinued%' OR outcome_of_case ='Struck out' 
OR outcome_of_case ='Won at trial' THEN 'Claim repudiated' ELSE '% saving against damages reserve is 50% or greater' END   AS [Success Description]
,master_client_code + '-'+master_matter_number AS [Mattersphere Weightmans Reference]
,matter_description AS [Matter Description]
,insuredclient_name AS [Insured Client Name]
,insured_sector AS [Insured Sector]
,name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,work_type_name AS [Work Type]
,dim_detail_core_details.[brief_details_of_claim] AS [Brief details of claim]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve (gross)]
,fact_detail_reserve_detail.[current_indemnity_reserve] AS [Claimant's Costs Reserve (gross)]
,dim_detail_outcome.[outcome_of_case] AS [Outcome]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,fact_finance_summary.[damages_paid] AS [Damages Paid by Client]
,CASE WHEN fact_finance_summary.[damages_reserve] IS NULL OR fact_finance_summary.[damages_reserve]=0 THEN NULL ELSE (ISNULL(fact_finance_summary.[damages_reserve] ,0) - ISNULL(fact_finance_summary.[damages_paid],0))  / fact_finance_summary.[damages_reserve] END AS [% Saving against reserve (Damages)]
,fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid by Client]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
,(ISNULL(fact_finance_summary.[damages_reserve],0) + ISNULL(fact_detail_reserve_detail.[current_indemnity_reserve] ,0))
- (ISNULL(fact_finance_summary.[damages_paid],0) + ISNULL(fact_finance_summary.[claimants_costs_paid],0)) AS [Total Saving on Indemnity Spend]
,CASE WHEN date_claim_concluded BETWEEN DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0) AND DATEADD (dd, -1, DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) + 1, 0)) THEN 1 ELSE 0 END AS TabNo
,outcome_of_case
,sector

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
  ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number 
WHERE hierarchylevel3hist='Casualty'
AND date_claim_concluded BETWEEN  DATEADD(MONTH,-18,GETDATE()) AND GETDATE()
AND
(
outcome_of_case LIKE '%Discontinued%' OR outcome_of_case ='Struck out' 
OR outcome_of_case ='Won at trial'
OR CASE WHEN fact_finance_summary.[damages_reserve] IS NULL OR fact_finance_summary.[damages_reserve]=0 THEN NULL ELSE (ISNULL(fact_finance_summary.[damages_reserve] ,0) - ISNULL(fact_finance_summary.[damages_paid],0))  / fact_finance_summary.[damages_reserve] END>=0.5
)
----------------------Exclusions--------------------------------------
AND sector NOT LIKE '%Education%'
AND sector NOT LIKE '%Emergency Services%'
AND sector NOT LIKE '%Health%'
AND sector NOT LIKE '%Local & Central Government%'
AND insured_sector NOT LIKE '%Ambulance%'
AND insured_sector NOT LIKE '%Education%'
AND insured_sector NOT LIKE '%Fire%'
AND insured_sector NOT LIKE '%Local & Central Government%'
AND insured_sector NOT LIKE '%Police%'
AND insured_sector NOT LIKE '%Healthcare%'
AND insured_sector NOT LIKE '%Social Housing%'
AND insured_sector NOT LIKE '%Societies/political/religious%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Council%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Borough%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%MBC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%LBC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%CC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%BC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%DC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Police%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Constab%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Fire%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Health%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%NHS%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%School%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%University%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%College%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Housing%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Council%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Borough%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%MBC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%LBC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%CC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%BC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%DC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Police%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Constab%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Fire%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Health%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%NHS%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%School%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%University%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%College%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Housing%'
AND ISNULL(outcome_of_case,'')<>'Returned to Client'


END 
GO
