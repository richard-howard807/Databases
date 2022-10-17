SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Covea_CoveaInstructionsCreditHire]

AS

SELECT 

 [Date Case Opened] = date_opened_case_management
,[Client Code] = dim_matter_header_current.master_client_code
,[Matter Number] = cast(dim_matter_header_current.master_matter_number as int)
,[Matter Description] = matter_description
,[Case Manager] = dim_fed_hierarchy_history.name
,[Covea Reference] = COALESCE(dim_client_involvement.[insurerclient_reference], client_reference)

/*"Closed" if dim_detail_core_details[present_position] is final bill due/ final bill sent or to be closed else "open" */
,[Open/Closed] = 

CASE WHEN date_closed_case_management IS NOT NULL THEN 'Closed'
     WHEN TRIM(dim_detail_core_details.[present_position])
IN ('Final bill due - claim and costs concluded','Final bill sent - unpaid', 'To be closed/minor balances to be clear' ) 
THEN 'Closed' ELSE 'Open' END

,[Present position] = dim_detail_core_details.[present_position] 
,[Referral Reason] =  dim_detail_core_details.[referral_reason]

,date_closed_case_management AS Closed_Date
,dim_detail_core_details.[credit_hire] AS [Credit Hire]
,dim_detail_core_details.[does_claimant_have_personal_injury_claim] AS [Does Claimant have a Personal Injury Claim?]
,CASE WHEN dim_detail_core_details.does_claimant_have_personal_injury_claim='No' AND dim_detail_core_details.credit_hire='Yes' THEN 'Credit Hire Only'
WHEN dim_detail_core_details.does_claimant_have_personal_injury_claim='Yes' and dim_detail_core_details.credit_hire='Yes' THEN 'PI and Credit Hire'
WHEN dim_detail_core_details.does_claimant_have_personal_injury_claim='Yes' THEN 'PI Only' 
WHEN dim_detail_core_details.does_claimant_have_personal_injury_claim='No' AND dim_detail_core_details.credit_hire='No' THEN 'Other' END AS [Claim Type]
,CASE WHEN dim_detail_core_details.credit_hire='Yes' THEN dim_detail_core_details.[clients_claims_handler_surname_forename] ELSE NULL END AS [Client's Claims Handler]




FROM red_dw.dbo.fact_dimension_main 
JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key


WHERE 1 = 1 

AND dim_matter_header_current.master_client_code = 'W15396'
AND (date_opened_case_management >= '2020-01-01' OR (dim_detail_core_details.credit_hire='Yes' AND CASE WHEN date_closed_case_management IS NOT NULL THEN 'Closed'
     WHEN TRIM(dim_detail_core_details.[present_position])
IN ('Final bill due - claim and costs concluded','Final bill sent - unpaid', 'To be closed/minor balances to be clear' ) 
THEN 'Closed' ELSE 'Open' END='Open'))
AND (reporting_exclusions = 0 OR dim_detail_outcome.[outcome_of_case]= 'Returned to Client')

ORDER BY   date_opened_case_management
GO
