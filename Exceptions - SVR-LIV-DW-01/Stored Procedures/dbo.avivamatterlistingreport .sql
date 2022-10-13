SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[avivamatterlistingreport ]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	











WITH data AS (
SELECT 

                fact_finance_summary.[tp_costs_reserve],
                dim_client_involvement.[insurerclient_reference],
dim_matter_header_current.branch_name,
                dim_client.[client_code],
                dim_matter_header_current.[matter_number],
                dim_matter_header_current.[matter_description],

     dim_fed_hierarchy_history.hierarchylevel4hist [Team],
dim_matter_header_current.date_opened_case_management [Open Date], 
dim_matter_header_current.date_opened_case_management [Closed Date],
               dim_matter_worktype .[work_type_name],
                dim_detail_core_details.[referral_reason],
                dim_claimant_thirdparty_involvement.[claimantsols_name],
                dim_detail_core_details.[proceedings_issued],dim_matter_header_current.final_bill_date,
                dim_detail_core_details.[delegated],
                dim_detail_core_details.[fixed_fee],
                dim_detail_core_details.[suspicion_of_fraud],
                dim_detail_core_details.[does_claimant_have_personal_injury_claim],
                dim_detail_core_details.[credit_hire],
                dim_detail_core_details.[has_the_claimant_got_a_cfa],
                dim_detail_core_details.[present_position],
                --    oustanding reserve      
                fact_finance_summary.[damages_reserve],
                --  claimants cost reserve
                dim_detail_outcome.[outcome_of_case],
                dim_detail_outcome.[date_claim_concluded],
                fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties],
                fact_detail_paid_detail.[personal_injury_paid],
                dim_detail_outcome.[date_costs_settled],
                fact_finance_summary.[tp_total_costs_claimed],
                fact_finance_summary.[claimants_costs_paid],
                dim_detail_outcome.[are_we_pursuing_a_recovery],
                fact_finance_summary.[total_recovery],
                fact_detail_claim.[damages_paid_by_client],
                fact_finance_summary.[defence_costs_billed],
                fact_finance_summary.[disbursements_billed],
                fact_finance_summary.[vat_billed],
                fact_finance_summary.[total_amount_billed],
               dim_matter_header_current.matter_owner_full_name, 
                dim_client.[client_name],
				fact_detail_reserve_detail.[defence_costs_reserve],
                dim_client_involvement.[insuredclient_name],
                dim_client_involvement.[insurerclient_name],
				


       CASE
           WHEN fact_finance_summary.[damages_paid] IS NULL
                AND fact_detail_paid_detail.[general_damages_paid] IS NULL
                AND fact_detail_paid_detail.[special_damages_paid] IS NULL
                AND fact_detail_paid_detail.[cru_paid] IS NULL THEN
               NULL
           ELSE
       (CASE
            WHEN fact_finance_summary.[damages_paid] IS NULL THEN
       (ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
        + ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
       )
            ELSE
                fact_finance_summary.[damages_paid]
        END
       )
       END AS [Damages Paid by Client ]


FROM 

red_dw.dbo.fact_dimension_main 
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
left JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
LEFT JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_matter_branch ON dim_matter_branch.dim_matter_branch_key = fact_dimension_main.dim_branch_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history  ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.fact_detail_claim ON fact_detail_claim.master_fact_key = fact_detail_paid_detail.master_fact_key


	  WHERE (date_closed_case_management >= '2018-01-01' OR date_closed_case_management IS NULL ) 

	AND dim_matter_header_current.reporting_exclusions <> 1 

	  AND 
	(
	(LOWER(dim_client.client_name) LIKE '%aviva%' )OR (LOWER(dim_client.client_name) LIKE '%bibby%' ) OR(LOWER(dim_client.client_name) LIKE '%veolia%') OR  (LOWER(dim_client.client_name) LIKE '%green king%' ) 
	OR 

	(LOWER(dim_client_involvement.insurerclient_name) LIKE '%aviva%' )OR (LOWER(dim_client_involvement.insurerclient_name) LIKE '%bibby%' ) OR(LOWER(dim_client_involvement.insurerclient_name) LIKE '%veolia%') OR  (LOWER(dim_client_involvement.insurerclient_name) LIKE '%green king%' )
	
	)


) 

SELECT dim_date.fin_quarter, COUNT(DISTINCT data.client_code + '-' + data.matter_number), 'No. of matters opened' type
FROM data
INNER JOIN dbo.dim_date ON dim_date.calendar_date = data.[Open Date]
GROUP BY fin_quarter 

UNION ALL


SELECT dim_date.fin_quarter, COUNT(DISTINCT data.client_code + '-' + data.matter_number), 'No. of matters concluded (final billed)' type
FROM data
INNER JOIN dbo.dim_date ON dim_date.calendar_date = data.final_bill_date
GROUP BY fin_quarter

UNION ALL

SELECT dim_date.fin_quarter, COUNT(DISTINCT data.client_code + '-' + data.matter_number), 'No. of matters settled damages' type
FROM data
INNER JOIN dbo.dim_date ON dim_date.calendar_date = data.date_claim_concluded
GROUP BY fin_quarter  

UNION ALL


SELECT dim_date.fin_quarter, COUNT(DISTINCT data.client_code + '-' + data.matter_number), 'No. of matters settled costs' type
FROM data
INNER JOIN dbo.dim_date ON dim_date.calendar_date = data.date_costs_settled
GROUP BY fin_quarter ORDER BY dim_date.fin_quarter
























    -- Insert statements for procedure here
	

















END
GO
