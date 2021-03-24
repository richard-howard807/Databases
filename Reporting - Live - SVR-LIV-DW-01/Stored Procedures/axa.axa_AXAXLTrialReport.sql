SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Max Taylor
-- Create date: 24/03/2021
-- Ticket Number: 93236
-- Description:	New datasource for the AXA XL - Trial Report
   
------------ =============================================
CREATE PROCEDURE [axa].[axa_AXAXLTrialReport]
AS
BEGIN


    SELECT DISTINCT
	
	
		   [Client Ref] = ISNULL(dim_client_involvement.insurerclient_reference,dim_involvement_full.reference),
           [AXA XL Handler] = dim_detail_core_details.clients_claims_handler_surname_forename,
		   [Matter Description] = dim_matter_header_current.matter_description,
           [Weightmans Ref] = dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number,
		   [Weightmans Handler] = dim_fed_hierarchy_history.name
		   ,dim_detail_outcome.[date_claim_concluded]
		   ,dim_detail_core_details.[does_claimant_have_personal_injury_claim]
		   ,dim_detail_core_details.[suspicion_of_fraud] 
           ,[Date of Trial] = COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key))
		   ,dim_matter_header_current.date_opened_case_management
		
    FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.client_code = dim_matter_header_current.client_code
               AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history 
            ON dim_fed_hierarchy_history .dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement 
            ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail fact_detail_paid_detail
            ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
            ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
		LEFT JOIN red_dw.dbo.dim_involvement_full 
			ON dim_involvement_full .dim_involvement_full_key = dim_client_involvement.insurerclient_1_key
		LEFT JOIN red_dw.dbo.dim_detail_outcome 
			ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT JOIN red_dw.dbo.dim_key_dates 
			ON dim_key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND  dim_key_dates.description = 'Date of Trial'
		LEFT JOIN red_dw.dbo.dim_detail_court
			ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
 
 WHERE ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
          AND dim_matter_header_current.matter_number <> 'ML'
          AND dim_matter_header_current.master_client_code = 'A1001'
          AND dim_matter_header_current.reporting_exclusions = 0
          AND dim_detail_outcome.[date_claim_concluded] IS NULL
		  AND (dim_detail_core_details.[does_claimant_have_personal_injury_claim] = 'Yes' OR dim_detail_core_details.[suspicion_of_fraud] = 'Yes' ) 
		  AND COALESCE(dim_detail_court.[date_of_trial], dim_key_dates.key_date) > GETDATE()
		
      
		  
   
   



END;

GO
