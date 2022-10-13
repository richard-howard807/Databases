SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[AntilioMatters]
AS
BEGIN

SELECT master_client_code + '-' + master_matter_number AS [WeightmansReference]
,matter_description AS [MatterDescription]
,matter_owner_full_name AS [Case Manager]
,insurerclient_reference AS [InsurerClientRef]
,dim_detail_core_details.[clients_claims_handler_surname_forename] AS ClientsClaimHandler
,insuredclient_name AS [InsuredClientName]
,date_instructions_received AS [DateInstructionsReceived]
,dim_detail_court.[date_proceedings_issued] AS [Date Proceedings Issued]
,dim_detail_core_details.[track] AS [Track]
,fact_finance_summary.[total_reserve] AS [Total Reserve ]
,dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,fact_finance_summary.[damages_paid_to_date] AS [Damages Paid]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
,fact_finance_summary.[claimants_costs_paid] AS [TP Costs Paid ]
,fact_detail_elapsed_days.[elapsed_days_damages] AS [Elapsed Days to Damages Concluded]

FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number  
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
 ON fact_detail_elapsed_days.client_code = dim_matter_header_current.client_code
 AND fact_detail_elapsed_days.matter_number = dim_matter_header_current.matter_number

 
 
 
WHERE master_client_code='W21348'
AND reporting_exclusions=0
AND proceedings_issued='Yes'
AND date_closed_case_management IS NULL
END
GO
