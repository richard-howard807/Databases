SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Orlagh Kelly >
-- Create date: <2018-12-05>
-- Description:	<Replacement for 2008 CO-OP all claims dashboard Data. >
-- =============================================
CREATE PROCEDURE [dbo].[allclaimsdataCOOP]
@Team AS NVARCHAR(200) 

AS
BEGIN



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT ListValue  INTO #Team FROM Reporting.dbo.udt_TallySplit(',',@Team)
--
SELECT fact_dimension_main.client_code AS [Client Code],
       fact_dimension_main.matter_number AS [Matter Number],
       RTRIM(dim_matter_header_current.master_client_code) + '-' + RTRIM(dim_matter_header_current.matter_number) AS [3E Reference],
       CASE
           WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
               'Converge'
           WHEN dim_detail_client.[coop_master_reporting] = 'Yes'
                OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool' THEN
               'MLT'
           WHEN dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - LTA' THEN
               'Commercial'
           ELSE
               'Insurance'
       END AS [Work Source],
       red_dw.dbo.dim_matter_header_current.billing_arrangement_description [3E Rate Arrangeement],
       CASE
           WHEN RTRIM(LOWER(dim_detail_core_details.[present_position])) = 'final bill due - claim and costs concluded'
                AND ISNULL(fact_finance_summary.unpaid_bill_balance, 0) > 0 THEN
               'Closed'
           WHEN RTRIM(LOWER(dim_detail_core_details.[present_position])) = 'to be closed/minor balances to be clear' THEN
               'Closed'
           WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN
               'Closed'
           ELSE
               'Open'
       END AS [File Status],
       dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Co-op Handler],
       insurerclient_reference AS [CIS Reference],
       dim_detail_core_details.[coop_client_branch] AS [Client Branch],
       RTRIM(dim_matter_header_current.client_code) + '-' + dim_matter_header_current.matter_number AS [Weightmans Reference],
       LTRIM(RTRIM(matter_description)) AS [Name of Case],
       name [Fee Earner Name],
       hierarchylevel4hist AS [Team],
       coop_guid_reference_number AS [GUID Reference Number ],
       incident_date AS [Date of Accident],
       accident_location AS [Accident Location],
       CASE
           WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
               COALESCE(
                           dim_detail_core_details.date_instructions_received,
                           dim_matter_header_current.date_opened_case_management
                       )
           ELSE
               dim_matter_header_current.date_opened_case_management
       END AS [Date File Opened],
       dim_matter_header_current.date_closed_case_management AS [Date File Closed],
       dim_detail_critical_mi.date_reopened AS [Date File Reopened ],
       dim_matter_header_current.date_closed_practice_management AS [Date Closed 3E],
       CASE
           WHEN (CASE
                     WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
                         COALESCE(
                                     dim_detail_critical_mi.date_closed,
                                     dim_matter_header_current.date_closed_case_management
                                 )
                     ELSE
                         dim_matter_header_current.date_closed_case_management
                 END
                ) IS NULL THEN
               DATEDIFF(
                           DAY,
                           (CASE
                                WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
                                    COALESCE(
                                                dim_detail_core_details.date_instructions_received,
                                                dim_matter_header_current.date_opened_case_management
                                            )
                                ELSE
                                    dim_matter_header_current.date_opened_case_management
                            END
                           ),
                           GETDATE()
                       )
           ELSE
               DATEDIFF(
                           DAY,
                           (CASE
                                WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
                                    COALESCE(
                                                dim_detail_core_details.date_instructions_received,
                                                dim_matter_header_current.date_opened_case_management
                                            )
                                ELSE
                                    dim_matter_header_current.date_opened_case_management
                            END
                           ),
                           (CASE
                                WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
                                    COALESCE(
                                                dim_detail_critical_mi.date_closed,
                                                dim_matter_header_current.date_closed_case_management
                                            )
                                ELSE
                                    dim_matter_header_current.date_closed_case_management
                            END
                           )
                       )
       END AS [Elapsed Days],
       red_dw.dbo.dim_detail_core_details.is_this_the_lead_file AS [Is this the lead file?],
       is_this_a_linked_file AS [Linked File],
       associated_matter_numbers AS [Associated Matter Numbers],
       lead_file_matter_number_client_matter_number AS [Lead File Matter Reference ],
       work_type_name AS [Work Type ],
       dim_detail_core_details.referral_reason AS [Referral Reason ],
       COALESCE(
                   dim_detail_claim.[claimants_solicitors_firm_name ],
                   dim_claimant_thirdparty_involvement.claimantsols_name
               ) AS [Claimants Solictors],
       dim_detail_claim.number_of_claimants AS [Potential Number of Claimants],
       dim_detail_core_details.proceedings_issued AS [Proceedings Issued],
       red_dw.dbo.dim_detail_court.date_of_trial AS [Trial Date],
       dim_detail_core_details.delegated AS [Delegated ],
       dim_detail_core_details.track AS [Track],
       dim_matter_header_current.fee_arrangement AS [Fee Arrangement],
       dim_detail_core_details.fixed_fee AS [Fixed Fee],
       dim_matter_header_current.fixed_fee_amount AS [Fixed Fee Amount ],
       suspicion_of_fraud AS [Suspicion of Fraud ],
       dim_detail_client.[coop_fraud_status_text] AS [Fraud Status],
       does_claimant_have_personal_injury_claim AS [Does Claimant Have a PI Claim],
       credit_hire AS [Credit Hire],
       has_the_claimant_got_a_cfa AS [Has the Claimant got a CFA],
       red_dw.dbo.dim_detail_core_details.present_position [Present Position ],
       CASE
           WHEN
           (
               red_dw.dbo.dim_detail_client.coop_master_reporting = 'Yes'
               OR red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
           ) THEN
               DATEADD(
                          d,
                          360,
                          (CASE
                               WHEN department_code = '0027' THEN
                                   COALESCE(
                                               red_dw.dbo.dim_detail_core_details.date_instructions_received,
                                               red_dw.dbo.dim_matter_header_current.date_opened_case_management
                                           )
                               ELSE
                                   red_dw.dbo.dim_matter_header_current.date_opened_case_management
                           END
                          )
                      )
           ELSE
               dim_detail_core_details.coop_target_settlement_date
       END AS [Target Settlement Date ],
       CASE
           WHEN department_code = '0027' THEN
               red_dw.dbo.fact_detail_reserve_detail.general_damages_reserve_current
           ELSE
               red_dw.dbo.fact_finance_summary.damages_reserve
       END AS [Damages Reserve Held (Before Payment)],
       CASE
           WHEN department_code = '0027' THEN
               ISNULL(
                         COALESCE(
                                     fact_detail_paid_detail.[personal_injury_paid],
                                     fact_detail_client.[zurich_general_damages_psla_only]
                                 ),
                         0
                     )
           ELSE
               ISNULL(fact_finance_summary.[damages_interims], 0) + ISNULL(fact_finance_summary.[damages_paid], 0)
       END AS [Damages Payments To Date],
       CASE
           WHEN dim_detail_core_details.[present_position] IN ( 'Final bill sent - unpaid',
                                                                'To be closed/minor balances to be clear'
                                                              ) THEN
               NULL
           ELSE
               ISNULL(   CASE
                             WHEN department_code = '0027' THEN
                                 fact_detail_reserve_detail.[general_damages_reserve_current]
                             ELSE
                                 fact_finance_summary.[damages_reserve]
                         END,
                         0
                     )
               - ISNULL(
                           CASE
                               WHEN department_code = '0027' THEN
                                   ISNULL(
                                             COALESCE(
                                                         fact_detail_paid_detail.[personal_injury_paid],
                                                         fact_detail_client.[zurich_general_damages_psla_only]
                                                     ),
                                             0
                                         )
                               ELSE
                                   ISNULL(fact_finance_summary.[damages_interims], 0)
                                   + ISNULL(fact_finance_summary.[damages_paid], 0)
                           END,
                           0
                       )
       END AS [Damages Reserve Outstanding],
       fact_detail_reserve_detail.claimant_costs_reserve_current AS [Opponents Costs Reserve Held before payments ],
       CASE
           WHEN red_dw.dbo.dim_matter_header_current.department_code = '0027' THEN
               ISNULL(fact_detail_paid_detail.claimants_profit_costs_settled, 0)
               + ISNULL(red_dw.dbo.fact_finance_summary.claimants_costs_paid, 0)
           ELSE
       (CASE
            WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
                ISNULL(red_dw.dbo.fact_detail_paid_detail.interim_costs_payments, 0)
                + ISNULL(fact_detail_paid_detail.interim_costs_payments_by_client_pre_instruction, 0)
            ELSE
                ISNULL(fact_finance_summary.claimants_costs_paid, 0)
                + ISNULL(fact_finance_summary.detailed_assessment_costs_paid, 0)
                + ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant, 0)
                + ISNULL(fact_finance_summary.other_defendants_costs_paid, 0)
        END
       )
       END [Opponents Costs Paid To Date],
       ISNULL(fact_detail_reserve_detail.claimant_costs_reserve_current, 0)
       - (CASE
              WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
                  ISNULL(fact_detail_paid_detail.claimants_profit_costs_settled, 0)
                  + ISNULL(fact_finance_summary.claimants_costs_paid, 0)
              ELSE
       (CASE
            WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
                ISNULL(fact_detail_paid_detail.interim_costs_payments, 0)
                + ISNULL(fact_detail_paid_detail.interim_costs_payments_by_client_pre_instruction, 0)
            ELSE
                ISNULL(fact_finance_summary.claimants_costs_paid, 0)
                + ISNULL(fact_finance_summary.detailed_assessment_costs_paid, 0)
                + ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant, 0)
                + ISNULL(fact_finance_summary.other_defendants_costs_paid, 0)
        END
       )
          END
         ) AS [Opponents Cost Reserve Outstanding],
       CASE
           WHEN (
                    dim_detail_client.[coop_master_reporting] = 'Yes'
                    OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
                )
                AND ISNULL(dim_detail_core_details.[is_this_the_lead_file], 'No') = 'Yes' THEN
               ISNULL(fact_finance_summary.[defence_costs_reserve], 0)
           WHEN
           (
               dim_detail_client.[coop_master_reporting] = 'Yes'
               OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
           ) THEN
               0
           ELSE
               ISNULL(fact_finance_summary.[defence_costs_reserve], 0)
       END AS [Defence Costs Reserve Held (before payments)], --LEADLINKED


       ISNULL(   (CASE WHEN (
                               dim_detail_client.[coop_master_reporting] = 'Yes'
                               OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
                           )
                           AND ISNULL(dim_detail_core_details.[is_this_the_lead_file], 'No') = 'Yes' THEN
                          ISNULL(fact_finance_summary.[defence_costs_reserve], 0) WHEN
                      (
                          dim_detail_client.[coop_master_reporting] = 'Yes'
                          OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
                      ) THEN
                          0
                      ELSE
                          ISNULL(fact_finance_summary.[defence_costs_reserve], 0)
                  END
                 ),
                 0
             ) - ISNULL(   (CASE
                        WHEN (
                                 dim_detail_client.[coop_master_reporting] = 'Yes'
                                 OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
                             )
                             AND ISNULL(dim_detail_core_details.[is_this_the_lead_file], 'No') = 'Yes' THEN
                            ISNULL(defence_costs_billed, 0)
                        WHEN
                        (
                            dim_detail_client.[coop_master_reporting] = 'Yes'
                            OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
                        ) THEN
                            0
                        ELSE
                            defence_costs_billed
                    END
                   ),
                   0
               ) AS [Defence Costs Reserve Outstanding],
       total_amount_billed [Total paid to date  ],
       total_outstanding_reserve [Total Outstanding Reserve],
       CASE
           WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
               dim_detail_client.outcome_category
           ELSE
               dim_detail_outcome.outcome_of_case
       END AS [Outcome],
       coop_fraud_outcome [Fraud Outcome ],
       CASE
           WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
       (CASE
            WHEN
            (
                dim_matter_header_current.date_opened_case_management <= '2010-01-01'
                AND ISNULL(dim_detail_outcome.date_claim_concluded, '') = ''
            ) THEN
                DATEADD(dd, 14, dim_matter_header_current.date_opened_case_management)
            WHEN dim_matter_header_current.date_opened_case_management <= '2011-06-06' THEN
                DATEADD(dd, 14, dim_matter_header_current.date_opened_case_management)
            ELSE
                dim_detail_outcome.date_claim_concluded
        END
       )
           ELSE
               dim_detail_outcome.date_claim_concluded
       END AS [Date Damages Concluded],
       CASE
           WHEN dim_detail_outcome.outcome_of_case LIKE '%Won%'
                OR dim_detail_outcome.outcome_of_case LIKE '%won%'
                OR dim_detail_outcome.outcome_of_case LIKE '%struck%'
                OR dim_detail_outcome.outcome_of_case LIKE '%Struck%'
                OR dim_detail_outcome.outcome_of_case LIKE '%Disc%'
                OR dim_detail_outcome.outcome_of_case LIKE '%disc%' THEN
               'Yes'
           ELSE
               'No'
       END AS [Claim Repudiated],
       CASE
           WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
               dim_detail_claim.date_claimants_costs_agreed
           ELSE
               dim_detail_outcome.date_costs_settled
       END AS [Date Costs Settled],
       red_dw.dbo.fact_finance_summary.tp_total_costs_claimed AS [Opponent Total Costs Claimed],
       red_dw.dbo.fact_finance_summary.claimants_costs_paid AS [Opponents Total Costs Paid],
       CASE
           WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN
               fact_detail_paid_detail.mib_disbursements_settled
           ELSE
               fact_finance_summary.opponents_disbursements_paid
       END AS [Opponents Disbursements Paid],
       CASE
           WHEN
           (
               (fact_finance_summary.opponents_disbursements_paid > 0)
               OR (fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution > 0)
               OR (fact_finance_summary.recovery_defence_costs_via_third_party_contribution > 0)
           ) THEN
               'Yes'
           ELSE
               dim_detail_outcome.are_we_pursuing_a_recovery
       END AS [Are we Pursuing a Recovery?],
       ISNULL(fact_finance_summary.opponents_disbursements_paid, 0)
       + ISNULL(fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution, 0)
       + ISNULL(fact_finance_summary.recovery_defence_costs_via_third_party_contribution, 0) AS [Total Recovered],
       last_time_transaction_date [Date of Last Time Transaction],
       defence_costs_billed [Profit Costs Indiviudal ],
       CASE
           WHEN (
                    dim_detail_client.coop_master_reporting = 'Yes'
                    OR red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
                )
                AND ISNULL(dim_detail_core_details.is_this_the_lead_file, 'No') = 'Yes' THEN
               ISNULL(defence_costs, 0)
           WHEN
           (
               dim_detail_client.coop_master_reporting = 'Yes'
               OR red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'
           ) THEN
               0
           ELSE
               defence_costs_billed
       END AS [Profit Costs Billed To Date (net of VAT)],
       vat_amount [VAT],
       fact_detail_paid_detail.total_cost_of_counsel [Counsel Fees],
       ISNULL(disbursements_billed, 0) [Disbursement Costs Billed To Date (inc VAT)],
       ISNULL(total_unbilled_disbursements_vat, 0) [Unbilled Disbursements],
       fact_finance_summary.disbursement_balance [disbalance],
       ISNULL(red_dw.dbo.fact_finance_summary.unbilled_time, 0) [Unbilled WIP],
       ISNULL(total_amount_billed, 0) [Total Billed To Date ],
       last_bill_date [Date of Last Bill ],
       fact_matter_summary_current.last_bill_total [Last Bill amount ],
       indemnity_reason [Indemnity Issue ],
       claimants_date_of_birth [Clients DOB],
       dim_detail_core_details.[injury_type] [Injury Type ],
       dim_detail_core_details.[date_initial_report_sent] [Initial Report Date Sent ],
       dim_detail_core_details.[date_subsequent_sla_report_sent] [Subsequent Report Date],
       dim_detail_health.[date_of_service_of_proceedings] [Date of Service],
       dim_detail_court.[date_proceedings_issued] [Date of Issue ],
       fact_finance_summary.[cru_reserve] [CRU Reserve],
       fact_detail_reserve_detail.[future_care_reserve_current] [Future Care Reserve ],
       fact_detail_reserve_detail.[future_loss_misc_reserve_current] [Future loss misc reserve],
       fact_detail_reserve_detail.[future_loss_of_earnings_reserve_current] [Future Loss of Earnings Reserve],
       fact_detail_reserve_detail.[nhs_charges_reserve_current] [NHS Charges Reserve],
       fact_detail_reserve_detail.[general_damages_non_pi_misc_reserve_current] [General damages non PI misc reserve],
       fact_detail_reserve_detail.[past_care_reserve_current] [Past Care Reserve],
       fact_detail_reserve_detail.[past_loss_of_earnings_reserve_current] [Past Loss of Earnings Reserve],
       fact_detail_cost_budgeting.[personal_injury_reserve_current] [Personal Injury Reserve],
       fact_finance_summary.[special_damages_miscellaneous_reserve] [Special Damages Misc Reserve],
       fact_detail_reserve_detail.damages_reserve [Total Damages Reserve],
       fact_finance_summary.total_reserve [Total Reserve Current ],
       fact_detail_paid_detail.[cru_costs_paid] [CRU Costs Paid ],
       fact_detail_paid_detail.[cru_offset] [CRU Offset against Damages ],
       fact_detail_paid_detail.[future_care_paid] [Future Care Paid ],
       fact_detail_paid_detail.[future_loss_misc_paid] [Future Loss - Misc Paid ],
       fact_detail_paid_detail.[nhs_charges_paid_by_client] [NHS Charges Paid by client ],
       fact_detail_paid_detail.[general_damages_misc_paid] [General damages non PI misc paid],
       fact_detail_paid_detail.[past_care_paid] [Past Care Paid ],
       fact_detail_paid_detail.[personal_injury_paid] [Personal Injury Paid],
       fact_detail_paid_detail.[past_loss_of_earnings_paid] [Past Loss of Earnings Paid],
       [Special damages misc paid] = fact_finance_summary.[special_damages_miscellaneous_paid],
       [Total damages paid] = total_damages_paid,
       [Will Gross Reserve Exceed 500k] = dim_detail_core_details.[will_total_gross_reserve_on_the_claim_exceed_500000],
       [% Liability Agreed to Instruction] = fact_detail_client.[percent_of_clients_liability_agreed_prior_to_instruction],
       [% Liability Agreed Post Instruction] = fact_detail_client.[percent_of_clients_liability_awarded_agreed_post_insts_applied],
       [% Contributory Negligence Agreed] = fact_detail_client.[percent_of_contributory_negligence_agreed],
       ll00_have_we_had_an_extension_for_the_initial_report [Have we had an extension on the initial report ],
       fact_detail_paid_detail.future_loss_of_earnings_paid [Future Loss of Earnings Paid],
       fact_detail_future_care.earnings [Earnings],
       fact_detail_future_care.care [Care],
       fact_detail_future_care.mobility [Mobility],
       fact_detail_future_care.[pwca_disease_only] [PWCA Disease only ],
       dc.[No. Times Damages Changed] [No. Times Damages Changed],
       cc.[No. Times Claimants Costs Changed] [No. Times Claimants Costs Changed],
       dfc.[No.Times Defence Costs Changed ] [No. Times Defence Costs Changed]
FROM red_dw.dbo.dim_client
    INNER JOIN red_dw.dbo.fact_dimension_main
        ON dim_client.client_code = fact_dimension_main.client_code
		
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
			INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = dim_fed_hierarchy_history.hierarchylevel4hist COLLATE database_default
	
    INNER JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
        ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
        ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
    LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
        ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
    LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
        ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
        ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi
        ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
    LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
        ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
        ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
    LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
        ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_matter_group
        ON dim_matter_group.dim_matter_group_key = dim_matter_header_current.dim_matter_group_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_court
        ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_client
        ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_client
        ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
        ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
        ON fact_detail_recovery_detail.master_fact_key = fact_detail_client.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_health
        ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
        ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
        ON dim_detail_claim.client_code = dim_matter_header_current.client_code
           AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
    LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
        ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care
        ON fact_detail_future_care.master_fact_key = fact_detail_client.master_fact_key

    --- join to the sub select for getting the number of times Damages have changed 
    LEFT OUTER JOIN
    (
        SELECT client_code,
               curdamrescur.matter_number,
               SUM(changes) AS [No. Times Damages Changed]
        FROM
        (
            SELECT dim_client.client_code,
                   matter_number,
                   COUNT(*) - 1 changes,
                   'fed' AS source_system
            FROM red_dw.dbo.dim_client
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.client_code = dim_client.client_code
                       AND
                       (
                           dim_matter_header_current.date_closed_case_management IS NULL
                           OR dim_matter_header_current.date_closed_case_management >= '2017-01-01'
                       )
                INNER JOIN red_dw.dbo.ds_sh_axxia_casdet
                    ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id
                       AND deleted_flag = 'N'
                       AND case_detail_code = 'TRA076'
                       AND case_value IS NOT NULL
            WHERE dim_client.client_group_code = '00000004'
            --AND dim_client.client_code = '00046018'
            --AND matter_number = '00002739'
            GROUP BY dim_client.client_code,
                     matter_number
            UNION
            SELECT dim_client.client_code,
                   matter_number,
                   COUNT(*) - 1 changes,
                   'ms' AS source_system
            FROM red_dw.dbo.dim_client
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.client_code = dim_client.client_code
                       AND
                       (
                           dim_matter_header_current.date_closed_case_management IS NULL
                           OR dim_matter_header_current.date_closed_case_management >= '2017-01-01'
                       )
                INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history
                    ON fileid = ms_fileid
                       AND curdamrescur IS NOT NULL
            WHERE dim_client.client_group_code = '00000004'
            --AND dim_client.client_code = '00046018'
            --AND matter_number = '00002739'
            GROUP BY dim_client.client_code,
                     matter_number
        ) curdamrescur
        GROUP BY curdamrescur.client_code,
                 curdamrescur.matter_number
    ) dc
        ON dc.client_code = red_dw.dbo.fact_dimension_main.client_code
           AND dc.matter_number = red_dw.dbo.fact_dimension_main.matter_number
    ------------------------------------------------------------------------------
    LEFT OUTER JOIN
    (
        SELECT client_code,
               curdamrescur.matter_number,
               SUM(changes) AS [No. Times Claimants Costs Changed]
        FROM
        (
            SELECT dim_client.client_code,
                   matter_number,
                   COUNT(*) - 1 changes,
                   'fed' AS source_system
            FROM red_dw.dbo.dim_client
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.client_code = dim_client.client_code
                       AND
                       (
                           dim_matter_header_current.date_closed_case_management IS NULL
                           OR dim_matter_header_current.date_closed_case_management >= '2017-01-01'
                       )
                INNER JOIN red_dw.dbo.ds_sh_axxia_casdet
                    ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id
                       AND deleted_flag = 'N'
                       AND case_detail_code = 'TRA080'
                       AND case_value IS NOT NULL
            WHERE dim_client.client_group_code = '00000004'
            --AND dim_client.client_code = '00046018'
            --AND matter_number = '00002739'
            GROUP BY dim_client.client_code,
                     matter_number
            UNION
            SELECT dim_client.client_code,
                   matter_number,
                   COUNT(*) - 1 changes,
                   'ms' AS source_system
            FROM red_dw.dbo.dim_client
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.client_code = dim_client.client_code
                       AND
                       (
                           dim_matter_header_current.date_closed_case_management IS NULL
                           OR dim_matter_header_current.date_closed_case_management >= '2017-01-01'
                       )
                INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history
                    ON fileid = ms_fileid
                       AND curclacostrecur IS NOT NULL
            WHERE dim_client.client_group_code = '00000004'
            --AND dim_client.client_code = '00046018'
            --AND matter_number = '00002739'
            GROUP BY dim_client.client_code,
                     matter_number
        ) curdamrescur
        GROUP BY curdamrescur.client_code,
                 curdamrescur.matter_number
    ) cc
        ON cc.client_code = red_dw.dbo.fact_dimension_main.client_code
           AND cc.matter_number = fact_dimension_main.matter_number
    LEFT OUTER JOIN
    (
        SELECT client_code,
               curdamrescur.matter_number,
               SUM(changes) [No.Times Defence Costs Changed ]
        FROM
        (
            SELECT dim_client.client_code,
                   matter_number,
                   COUNT(*) - 1 changes,
                   'fed' AS source_system
            FROM red_dw.dbo.dim_client
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.client_code = dim_client.client_code
                       AND
                       (
                           dim_matter_header_current.date_closed_case_management IS NULL
                           OR dim_matter_header_current.date_closed_case_management >= '2017-01-01'
                       )
                INNER JOIN red_dw.dbo.ds_sh_axxia_casdet
                    ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id
                       AND deleted_flag = 'N'
                       AND case_detail_code = 'TRA080'
                       AND case_value IS NOT NULL
            WHERE dim_client.client_group_code = '00000004'
            --AND dim_client.client_code = '00046018'
            --AND matter_number = '00002739'
            GROUP BY dim_client.client_code,
                     matter_number
            UNION
            SELECT dim_client.client_code,
                   matter_number,
                   COUNT(*) - 1 changes,
                   'ms' AS source_system
            FROM red_dw.dbo.dim_client
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.client_code = dim_client.client_code
                       AND
                       (
                           dim_matter_header_current.date_closed_case_management IS NULL
                           OR dim_matter_header_current.date_closed_case_management >= '2017-01-01'
                       )
                INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history
                    ON fileid = ms_fileid
                       AND curclacostrecur IS NOT NULL
            WHERE dim_client.client_group_code = '00000004'
            --AND dim_client.client_code = '00046018'
            --AND matter_number = '00002739'
            GROUP BY dim_client.client_code,
                     matter_number
        ) curdamrescur
        GROUP BY curdamrescur.client_code,
                 curdamrescur.matter_number
    ) AS dfc
        ON dfc.client_code = red_dw.dbo.fact_dimension_main.client_code
           AND dfc.matter_number = red_dw.dbo.fact_dimension_main.matter_number

WHERE dim_client.client_group_code = '00000004' --name='Co-operative Group'
      AND
     (
          dim_matter_header_current.date_closed_case_management IS NULL
          OR 
		  dim_matter_header_current.date_closed_case_management >= '2017-01-01'
      )
      AND reporting_exclusions = 0
      AND LOWER(ISNULL(outcome_of_case, '')) NOT IN ( 'exclude from reports', 'returned to client' )

	    --AND dim_client.client_code = '00046018'
     --   ----AND fact_dimension_main.matter_number = '00002739'



END;



GO
