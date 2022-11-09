SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-10-20
-- Description:	#174295, new report for Covea Credit Hire
-- =============================================
CREATE PROCEDURE [dbo].[CoveaCreditHire]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT
	dim_detail_core_details.[date_instructions_received] AS [Date of Instruction]
	, dim_client_involvement.insurerclient_reference AS [Covea Reference]
	, dim_matter_header_current.master_matter_number AS [Matter Number]
	, dim_detail_core_details.clients_claims_handler_surname_forename AS [Covea Handler]
	, dim_matter_header_current.matter_owner_full_name AS [Panel Handler]
	, COALESCE(IIF(dim_detail_hire_details.[credit_hire_organisation_cho] = 'Other', NULL, dim_detail_hire_details.[credit_hire_organisation_cho])
		,dim_detail_hire_details.[other],dim_agents_involvement.cho_name)[Credit Hire Company]
	--, dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant Solicitor]
	, dim_detail_claim.dst_claimant_solicitor_firm AS [Claimant Solicitor]
	, dim_detail_hire_details.gta_group_like_for_like AS [Claimant Vehicle ABI GTA Group]
	, dim_detail_hire_details.[credit_hire_vehicle_make_and_model] AS [Hire Vehicle ABI GTA Category]
	, NULL AS [GTA/Non GTA]
	--, fact_detail_client.chg_value_of_pav_repairs AS [Other HoL claimed]
	, NULL AS [Other HoL claimed]
	, NULL AS [Credit Hire Arguments Raised]
	, dim_detail_core_details.track AS [Court Track]
	, Court.[Court Name] AS [Location of Court]
	--, dim_court_involvement.court_name AS [Location of Court]
	, NULL AS [Settlement Stage]
	--, DATEDIFF(DAY, dim_detail_hire_details.hire_start_date, dim_detail_hire_details.hire_end_date) AS [Period of Hire Claimed] 
	, DATEDIFF(DAY, ISNULL(dim_detail_hire_details.[cho_hire_start_date], dim_detail_hire_details.[hire_start_date]),ISNULL(dim_detail_hire_details.[hire_end_date], GETDATE())) AS [Period of Hire Claimed] 
	, NULL AS [Period of Hire Settled]
	, fact_detail_recovery_detail.cht_daily_rate_claimed AS [Credit Hire Rate Claimed]
	, NULL AS [Credit Hire Rate Paid]
	, fact_detail_recovery_detail.cht_daily_rate_claimed AS [Total Credit Hire Claimed]
	, fact_detail_paid_detail.amount_hire_paid AS [Total Credit Hire Paid]
	, NULL AS [Impecuniosity Proved]
	, fact_detail_paid_detail.personal_injury_paid AS [Total General Damages Settlement Amount]
	, ISNULL(fact_finance_summary.damages_paid,0)-ISNULL(fact_detail_paid_detail.personal_injury_paid,0) AS [Total Special Damages Settlement Amount]
	, ISNULL(fact_finance_summary.damages_reserve,0)-ISNULL(fact_finance_summary.damages_paid,0) AS [Total Net Saving Damages]
	, fact_finance_summary.tp_total_costs_claimed AS [Claimant Costs and Disbursements Claimed]
	, fact_finance_summary.claimants_costs_paid AS [Claimant Costs and Disbursements Settlement]
	, ISNULL(fact_finance_summary.tp_total_costs_claimed,0)-ISNULL(fact_finance_summary.claimants_costs_paid,0) AS [Total Net Saving]
	, fact_finance_summary.defence_costs_billed AS [Panel Costs and Disbursements Incurred]
	, ISNULL(fact_finance_summary.recovery_defence_costs_from_claimant,0)+ISNULL(fact_finance_summary.recovery_defence_costs_via_third_party_contribution,0) AS [Costs Recovery]
	, dim_detail_outcome.outcome_of_case AS [Settlement Status]
	, dim_detail_outcome.date_claim_concluded AS [Settlement Date]
	, dim_detail_core_details.does_claimant_have_personal_injury_claim AS [Does the Claimant have a Personal Injury Claim?]
	, fact_finance_summary.damages_reserve AS [Damages Reserve]
	, fact_finance_summary.damages_paid AS [Damages Paid]
	, dim_detail_core_details.referral_reason AS [Referral Reason]
	, dim_detail_core_details.present_position AS [Present Position]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client
ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement
ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
  LEFT JOIN
        (
            SELECT fileID, 
                   assocType,
                   contName AS [Court Name],
                   dbAssociates.assocRef AS [Court Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder desc) AS XOrder--,*
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'COUNTYCRT'
			AND client_code='W15396'
        )

		        AS Court
            ON dim_matter_header_current.ms_fileid = Court.fileID
               AND Court.XOrder = 1

WHERE dim_matter_header_current.reporting_exclusions=0
AND dim_matter_header_current.master_client_code='W15396'
AND dim_detail_core_details.credit_hire='Yes'
AND dim_matter_header_current.date_opened_case_management>='2019-01-01'
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'

END
GO
