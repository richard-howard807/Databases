SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Orlagh kelly>
-- Create date: <03/12/2018,,>
-- Description:	<report to drive the new sabre report 2019,,>
-- =============================================
-- LD 20190823  Amended claimant sol to look at data services field first.
--				Added damages banding and credit hire and Scottish claim
-- ES 20200211  Amended Status logic to use present position, 47194

CREATE PROCEDURE [dbo].[SabreListingReport1]
AS
BEGIN

    SET NOCOUNT ON;
    SELECT 
	dim_fed_hierarchy_history.name [FE name],
	dim_matter_header_current.matter_description,
	date_claim_concluded,
	RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number AS [Weightmans Reference],
           dim_client_involvement.insurerclient_reference [Sabre Reference],
           date_instructions_received [Date instructions Recieved],
           CASE
               WHEN dim_employee.locationidud = 'Glasgow' THEN
                   'Scot'
               WHEN dim_detail_claim.referral_reason = 'Infant Approval' THEN
                   'Part 8'
               ELSE
                   'Part 7'
           END AS [Reason For Instruction],
           CASE
               WHEN dim_employee.locationidud = 'Glasgow' THEN
                   'Scottish Claim'
               WHEN dim_detail_core_details.suspicion_of_fraud = 'Yes' THEN
                   LTRIM(RTRIM(dim_detail_core_details.track)) + '/' + 'Fraud '
               WHEN dim_detail_core_details.suspicion_of_fraud = 'No'
                    AND dim_detail_hire_details.[claim_for_hire] = 'Yes' THEN
                   RTRIM(LTRIM(dim_detail_core_details.track)) + '/' + 'C Hire'

               --when Andew Sutton, Amy o Connor, Michelle pearsall , Emma Jevons, Juliet wood 
               WHEN dim_fed_hierarchy_history.fed_code IN ( '642', '1580', '1687', '1590', '1785' ) THEN
                   RTRIM(LTRIM(dim_detail_core_details.track)) + '/' + 'Technical  '
               WHEN dim_detail_core_details.referral_reason = 'Nomination only                                             ' THEN
                   'Nomination'
               ELSE
                   LTRIM(RTRIM(dim_detail_core_details.track)) + '/' + 'Motor'
           END AS [Track],
           CASE WHEN dim_detail_core_details.present_position IN ('Final bill due - claim and costs concluded','Final bill sent - unpaid','To be closed/minor balances to be clear') 
			   THEN'Closed'
               ELSE 'Open'
           END AS [Status],
           --dim_detail_core_details.motor_status ,
           date_of_accident [Date of Accident],
           COALESCE(dim_detail_claim.[dst_claimant_solicitor_firm ],dim_claimant_thirdparty_involvement.claimantsols_name) AS [Claimant Solicitor ],
           dim_detail_core_details.proceedings_issued [Proceedings Issued],
           CASE
               WHEN date_of_complaint IS NOT NULL THEN
                   1
               ELSE
                   0
           END AS Complaintfilter,

           --dim_client.branch = 'Glasgow' THEN 'Scot'

           --dim_detail_core_details[track] - If Weightmans Office is Glasgow then "Scot" or prefix "Part 8" if dim_detail_core_details[referral_reason] = "Infant Approval
           CASE
               WHEN suspicion_of_fraud = 'Yes' THEN
                   'Fraud '
               WHEN dim_detail_core_details.credit_hire = 'Yes' THEN
                   'Claim for hire'
               WHEN does_claimant_have_personal_injury_claim = 'Yes' THEN
                   'Claim for PI'
               ELSE
                   'Liability'
           END AS [Issued For ],
           fact_finance_summary.damages_reserve [Damages Reserve],
           fact_detail_reserve_detail.claimant_costs_reserve_current [TP Costs Reserve Current],
           fact_finance_summary.defence_costs_reserve [Your Costs Reserve (Total)],
           CASE
               WHEN dim_detail_client.date_of_complaint IS NOT NULL THEN
                   1
               ELSE
                   0
           END AS therehasbeenacomplaint,





           CASE 
               WHEN 
			   dim_detail_outcome.[date_claim_concluded] IS NULL   THEN '-' 

WHEN  dim_detail_outcome.[date_claim_concluded] IS NOT NULL 
AND  
			   dim_detail_outcome.outcome_of_case = 'Won at trial' THEN
                   'Trial - Won '
               WHEN 
			   dim_detail_outcome.[date_claim_concluded] IS NOT NULL 
AND 
			   dim_detail_outcome.outcome_of_case = 'Lost at trial' THEN
                   'Trial - Lost'
               WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL 
AND 
			   
			   dim_detail_court.date_of_trial IS NOT NULL THEN
                   'Pre Trial'
               WHEN
               (dim_detail_outcome.[date_claim_concluded] IS NOT NULL 
AND 
                   (dim_detail_claim.date_of_witness_statement_exchange IS NOT NULL
                   OR dim_detail_core_details.date_start_of_trial_window IS NOT NULL)
               ) THEN
                   'Post Allocation'
               ELSE
                   'Pre Allocation'
           END AS [Outcome of Case/ Settled Point],
           red_dw.dbo.dim_matter_header_current.date_closed_case_management AS [Date file closed ],
           date_the_closure_report_sent [Date Of Report Closure ],
           fact_detail_elapsed_days.elapsed_days_damages [Number of days to settlement -measure is case concluded, trial or aceptance of offer/repudation],
           fact_finance_summary.damages_paid [Damages Paid To date],
           fact_finance_summary.total_tp_costs_paid [TP Costs Paid ],
           defence_costs_billed [Revenue Billed],
           disbursements_billed [Disbursements Billed],
           wip [Unbilled Costs ],
           ISNULL(total_unbilled_disbursements_vat, 0) [Unbilled Disbursements],
           dim_detail_core_details.date_instructions_received [Date of Instruction],
           dim_detail_client.date_of_complaint [Date of Complaint ],
           dim_detail_client.date_client_advised_of_complaint [Date Complaint Acknowledged],
           nature_of_complaint [Nature of Complaint],
           complaint_resolved [Complaint Resolved],
           1 AS [Action Taken],
           CASE
               WHEN complaint_resolved IS NOT NULL
                    AND fact_detail_paid_detail.amount_paid_in_respect_of_complaint > 0 THEN
                   'Upheld'
               WHEN complaint_resolved IS NOT NULL
                    AND fact_detail_paid_detail.amount_paid_in_respect_of_complaint = 0 THEN
                   'Rejected'
           END AS [Outcome - Upheld/ Rejected],
           CASE
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') = 'NO                                                          ' THEN
                   1
               ELSE
                   0
           END AS [Total new nomination Count ],
           CASE
               WHEN dim_detail_core_details.sabre_reason_for_instructions = 'NO                                                          '
                    AND ISNULL(dim_detail_core_details.[grpageas_motor_moj_stage], '') <> 'N/A                                                         ' THEN
                   1
               ELSE
                   0
           END AS [Nomination Count MOJ],
           CASE
               WHEN dim_detail_core_details.sabre_reason_for_instructions = 'NO                                                          '
                    AND
                    (
                        dim_detail_core_details.[grpageas_motor_moj_stage] = 'N/A                                                         '
                        OR dim_detail_core_details.[grpageas_motor_moj_stage] IS NULL
                    ) THEN
                   1
               ELSE
                   0
           END AS [Nomination Count NON MOJ],
           CASE
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          ' THEN
                   1
               ELSE
                   0
           END AS [New cases opened],
           CASE
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND dim_detail_core_details.[grpageas_motor_moj_stage] = 'Stage 3                                                     ' THEN
                   1
               ELSE
                   0
           END AS [ MOJ 3],
           CASE
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'Fraud'
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     '
                    AND dim_detail_core_details.track = 'Small Claims                                                ' THEN
                   1
               ELSE
                   0
           END AS [Small Claims ],
           CASE
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'Fraud'
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     '
                    AND dim_detail_core_details.track = 'Fast Track' THEN
                   1
               ELSE
                   0
           END AS [Fast Track],
           CASE
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'Fraud'
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     '
                    AND dim_detail_core_details.track = 'Multi Track                                                 ' THEN
                   1
               ELSE
                   0
           END AS [Multi Track],
           CASE
               WHEN dim_detail_core_details.sabre_reason_for_instructions = 'Fraud'
                    OR dim_detail_core_details.sabre_reason_for_instructions = 'F                                                           '
                       AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     ' THEN
                   1
               ELSE
                   0
           END AS [Fraud ],
           CASE
               WHEN dim_detail_core_details.referral_reason = 'Advice only                                                 ' THEN
                   1
               ELSE
                   0
           END AS [Advice],
           CASE
               WHEN (
                        sabre_reason_for_instructions = 'Declaration'
                        OR sabre_reason_for_instructions = 'DEC                                                         '
                    )
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     ' THEN
                   1
               ELSE
                   0
           END AS [Declaration ],
           CASE
               WHEN dim_detail_core_details.referral_reason = 'Recovery                                                    ' THEN
                   1
               ELSE
                   0
           END AS [Recovery ],
           CASE
               WHEN
               (
                   dim_detail_core_details.referral_reason = 'Infant Approval                                             '
                   OR dim_detail_core_details.referral_reason = 'Infant approval'
               ) THEN
                   1
               ELSE
                   0
           END AS [Infanct Approval],
           CASE
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND dim_detail_outcome.date_costs_settled IS NOT NULL THEN
                   1
               ELSE
                   0
           END AS [Closed (Excluding Nominations Only)],
           CASE
               WHEN red_dw.dbo.dim_detail_client.date_of_complaint IS NOT NULL THEN
                   1
               ELSE
                   0
           END AS [NosComplaints],
           open_date [Open Date],
           cal_year,
           cal_month_name + '-' + CAST(cal_year AS NVARCHAR) year_month_char,
           CASE
               WHEN cal_month_no = MONTH(GETDATE()) THEN
                   1
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -1, GETDATE())) THEN
                   2
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -2, GETDATE())) THEN
                   3
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -3, GETDATE())) THEN
                   4
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -4, GETDATE())) THEN
                   5
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -5, GETDATE())) THEN
                   6
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -6, GETDATE())) THEN
                   7
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -7, GETDATE())) THEN
                   8
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -8, GETDATE())) THEN
                   9
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -9, GETDATE())) THEN
                   10
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -10, GETDATE())) THEN
                   11
               WHEN cal_month_no = MONTH(DATEADD(MONTH, -11, GETDATE())) THEN
                   12
           END AS [month_order],
           CASE
               WHEN (
                        sabre_reason_for_instructions = 'Declaration'
                        OR sabre_reason_for_instructions = 'DEC                                                         '
                    )
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     ' THEN
                   'Declaration'
               WHEN dim_detail_core_details.referral_reason = 'Recovery                                                    ' THEN
                   'Recovery'
               WHEN dim_detail_core_details.sabre_reason_for_instructions = 'Fraud'
                    OR dim_detail_core_details.sabre_reason_for_instructions = 'F                                                           '
                       AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     ' THEN
                   'Fraud'
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND dim_detail_core_details.[grpageas_motor_moj_stage] = 'Stage 3                                                     ' THEN
                   'MOJ 3'
               WHEN
               (
                   dim_detail_core_details.referral_reason = 'Infant Approval                                             '
                   OR dim_detail_core_details.referral_reason = 'Infant approval'
               ) THEN
                   'Infant Approval '
               WHEN dim_detail_core_details.referral_reason = 'Advice only                                                 ' THEN
                   'Advice'
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'Fraud'
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     '
                    AND dim_detail_core_details.track = 'Small Claims                                                ' THEN
                   'Small Claims '
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'Fraud'
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     '
                    AND dim_detail_core_details.track = 'Fast Track' THEN
                   'Fast Track '
               WHEN ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'NO                                                          '
                    AND ISNULL(dim_detail_core_details.sabre_reason_for_instructions, '') <> 'Fraud'
                    AND ISNULL(grpageas_motor_moj_stage, '') <> 'Stage 3                                                     '
                    AND dim_detail_core_details.track = 'Multi Track                                                 ' THEN
                   'Multi Track'
               ELSE
                   dim_detail_core_details.sabre_reason_for_instructions
           END AS [Headlines Reason For Instruction ]
		   , 1 AS count
		   , CASE
		   WHEN  dim_detail_core_details.[grpageas_motor_moj_stage] = 'Stage 3                                                     ' THEN 'MOJ 3 ' 
		   WHEN    dim_detail_core_details.referral_reason ='Costs dispute                                               ' THEN 'Costs '

		   ELSE 'Track '
		   END AS 'TRACKY', 
		   dim_detail_core_details.[sabre_reason_for_instructions] [Issued For new ]

		   , dim_claimant_address.postcode AS [Claimant Postcode]
		   , [Claimant Postcode].Latitude AS [Claimant Latitude]
		   , [Claimant Postcode].Longitude AS [Claimant Longitude]
		   , dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud]
		   --added for Dashboard SLA tab
		   , dim_detail_claim.[date_opened_instructions_received] AS [Date Opened Instructions Received]
		   , dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
		   , dim_detail_core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler] AS [Date Initial Acknowledgment to Claims Handler]
		   , fact_detail_elapsed_days.[elapsed_days_damages] AS [Elapsed Days Damages]
		   , DATEDIFF(DAY,dim_detail_claim.[date_opened_instructions_received], dim_detail_core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler]) AS [Days to Acknowledge Instructions]
		   , [dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_detail_claim.[date_opened_instructions_received], dim_detail_core_details.[date_initial_report_sent]) AS [Days to Initial Report]
		   , fact_detail_elapsed_days.[days_to_subsequent_report]  AS [Days to Subsequent Report]
		   ,dim_detail_core_details.credit_hire [Credit Hire]
		   ,dim_detail_finance.[damages_banding] AS [Damages Banding]
		   ,CASE WHEN branch_name = 'Glasgow' THEN 'Yes' ELSE 'No' END [Scottish Claim]

    FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        INNER JOIN red_dw.dbo.dim_client
            ON dim_client.client_code = fact_dimension_main.client_code
        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
            ON fact_dimension_main.client_code = dim_detail_client.client_code
               AND dim_detail_client.matter_number = fact_dimension_main.matter_number
        INNER JOIN red_dw.dbo.dim_matter_header_current
            ON dim_matter_header_current.client_code = fact_dimension_main.client_code
               AND dim_matter_header_current.matter_number = fact_dimension_main.matter_number
        INNER JOIN red_dw.dbo.fact_detail_client
            ON fact_dimension_main.master_fact_key = fact_detail_client.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
            ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
        LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
            ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
        INNER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
               AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
               AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
        INNER JOIN red_dw.dbo.dim_date
            ON date_instructions_received = calendar_date
        LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details
            ON dim_detail_previous_details.client_code = fact_dimension_main.client_code
               AND dim_detail_previous_details.matter_number = fact_dimension_main.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
            ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
            ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
            ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
            ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_incident
            ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance
            ON dim_detail_compliance.dim_detail_compliance_key = fact_dimension_main.dim_detail_compliance_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_property
            ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_court
            ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
            ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
            ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
            ON fact_detail_paid_detail.master_fact_key = fact_detail_client.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_employee
            ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
            ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_address ON dim_claimant_address.master_fact_key=fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.Doogal [Claimant Postcode] ON [Claimant Postcode].Postcode = dim_claimant_address.postcode

    WHERE dim_client.client_group_code = '00000070'
          AND dim_claimant_thirdparty_involvement.matter_number <> 'ML'
          AND reporting_exclusions = 0
          AND fact_dimension_main.dim_open_case_management_date_key > '20170101'
		  --AND dim_detail_core_details.sabre_reason_for_instructions IS null 
		  
		  ;









----hierarchylevel4hist LIKE '%LTA%'
--     dbo.dim_matter_header_current.date_closed_practice_management IS NULL
--    --  AND fact_dimension_main.dim_open_case_management_date_key <= 01062018
--      AND last_time_transaction_date <= '01-08-2018'
--      AND wip < 50
--      AND
--      (
--          fact_finance_summary.disbursement_balance IS NULL
--          OR fact_finance_summary.disbursement_balance = 0
--      )
--      AND
--      (
--          fact_finance_summary.client_account_balance_of_matter IS NULL
--          OR fact_finance_summary.client_account_balance_of_matter = 0
--      );


END;
GO
