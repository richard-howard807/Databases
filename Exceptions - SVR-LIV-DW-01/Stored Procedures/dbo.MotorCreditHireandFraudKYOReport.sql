SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Author: Max Taylor
Created Date: 20210201
Report: Credit Hire and Fraud KYO Report

*/

CREATE PROCEDURE [dbo].[MotorCreditHireandFraudKYOReport]
(@StartDate AS DATE, @EndDate AS DATE)

AS

BEGIN

SELECT

CASE WHEN red_dw.dbo.dim_client_involvement.insurerclient_name IS NULL 
THEN dim_matter_header_current.client_name ELSE dim_client_involvement.insurerclient_name END AS  [Client Name ]
,RTRIM(dim_matter_header_current.client_code) + '.' +RTRIM(dim_matter_header_current.matter_number) AS [Client Ref]
, dim_fed_hierarchy_history.hierarchylevel4hist [Weightmans Team]
, dim_detail_core_details.suspicion_of_fraud [Suspicion of Fraud]
, dim_fed_hierarchy_history.name [Weightmans Handler]
, dim_matter_header_current.matter_description [Description]
, dim_detail_outcome.date_claim_concluded [Date Claim Concluded]
, dim_detail_outcome.outcome_of_case [Outcome]
, dim_claimant_thirdparty_involvement.claimantsols_name [Claimant Sols]
,COALESCE(IIF(dim_detail_hire_details.[credit_hire_organisation_cho] = 'Other', NULL, 
dim_detail_hire_details.[credit_hire_organisation_cho]),dim_detail_hire_details.[other],dim_agents_involvement.cho_name) [CHO Name]
,dim_detail_hire_details.cho
,dim_detail_core_details.credit_hire [Credit Hire]
,fact_detail_paid_detail.[hire_claimed] [Credit Hire Claimed]
,dim_detail_hire_details.[chv_date_hire_paid] [Credit Hire Paid]
,dim_detail_hire_details.[gta_group_like_for_like] [GTA Group]
,fact_finance_summary.[damages_paid] [Damages Paid]
,dim_detail_outcome.[date_costs_settled] [Date TP Costs Concluded]
, fact_finance_summary.[total_tp_costs_paid_to_date] [TP Costs Paid]
, fact_finance_summary.defence_costs_billed [Defence Costs Paid ]
,NULL AS [Observations]
--this is to remain blank and be quite large to allow for comments 






FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
  LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
   LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
 LEFT JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_detail_reserve_detail.master_fact_key

 LEFT JOIN red_dw.dbo.dim_detail_hire_details ON dim_detail_hire_details.client_code = fact_finance_summary.client_code 
 AND dim_detail_hire_details.matter_number = fact_finance_summary.matter_number
LEFT JOIN red_dw.dbo.dim_agents_involvement ON dim_agents_involvement.client_code = dim_detail_core_details.client_code AND dim_agents_involvement.matter_number = dim_detail_core_details.matter_number
 WHERE 

(( dim_detail_core_details.suspicion_of_fraud IN
(
'YES                                                         ',
'Yes                                                         '
)
)

OR (dim_detail_hire_details.credit_hire = 'Yes')) 
--AND dim_detail_outcome.date_claim_concluded < @LastMonthLastDay
AND date_claim_concluded BETWEEN @StartDate AND @EndDate
/* Update 20210202 from Ticket 86848 - Restricted to teams Motor Fraud and Motor Credit Hire*/
AND  dim_fed_hierarchy_history.hierarchylevel4hist IN ('Motor Fraud', 'Motor Credit Hire')

END
GO
