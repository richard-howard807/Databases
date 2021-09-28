SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--USE [Reporting]
--GO
--/****** Object:  StoredProcedure [dbo].[SelfServiceLTAonly]    Script Date: 25/08/2021 07:52:30 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO






---- LD 2019/04/11 Moved the date columns so that they appear first  as per #16076

CREATE PROCEDURE [dbo].[SelfServiceLTAonly]
AS
BEGIN
    DECLARE @CurrentYear AS DATETIME = '2018-01-01',
            @nDate AS DATETIME = DATEADD(YYYY, -3, GETDATE());


    IF OBJECT_ID('Reporting.dbo.selfserviceLTAonlyData') IS NOT NULL
        DROP TABLE dbo.selfserviceLTAonlyData;
        
     DROP TABLE IF EXISTS #HrsBilled
SELECT dim_matter_header_curr_key,SUM(invoiced_minutes)/60 AS [Hrs Billed]
INTO #HrsBilled
FROM red_dw.dbo.fact_bill_billed_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
WHERE bill_reversed=0
GROUP BY dim_matter_header_curr_key   
        
    SELECT DISTINCT 
           dim_matter_header_current.date_opened_case_management AS [Date Case Opened],
           dim_matter_header_current.date_closed_case_management AS [Date Case Closed],
		   dim_matter_header_current.ms_only AS [MS Only],
           RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number AS [Weightmans Reference],
           fact_dimension_main.client_code AS [Client Code],
           fact_dimension_main.matter_number AS [Matter Number],
           REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') AS [Mattersphere Client Code],
           REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Matter Number],
           REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'
           + REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Weightmans Reference],
           dim_matter_header_current.[matter_description] AS [Matter Description],
		   dim_fed_hierarchy_history.[display_name] AS [Case Manager Name],
           dim_fed_hierarchy_history.[name] AS [Case Manager],
           dim_employee.postid AS [Grade],
           CASE
              WHEN dim_fed_hierarchy_history.[leaver] = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS [Leaver?],
           dim_fed_hierarchy_history.[worksforname] AS [Team Manager],
           dim_detail_practice_area.[bcm_name] AS [BCM Name],
           dim_employee.locationidud AS [Office],
		   
           dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team],
           dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department],
           dim_department.[department_code] AS [Department Code],
           dim_fed_hierarchy_history.[hierarchylevel2hist] [Division],
           dim_matter_worktype.[work_type_name] AS [Work Type],
           dim_matter_worktype.[work_type_code] AS [Work Type Code],
           CASE
               WHEN dim_matter_worktype.[work_type_name] LIKE '%NHSLA%' THEN
                   'NHSLA'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN
                   'PL All'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - Pol%' THEN
                   'PL Pol'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - OL%' THEN
                   'PL OL'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Prof Risk%' THEN
                   'Prof Risk'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'EL %' THEN
                   'EL'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Motor%' THEN
                   'Motor'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN
                   'Disease'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'OI%' THEN
                   'OI'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'LMT%' THEN
                   'LMT'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Recovery%' THEN
                   'Recovery'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Insurance/Costs%' THEN
                   'Insurance Costs'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Education%' THEN
                   'Education'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Healthcare%' THEN
                   'Healthcare'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' THEN
                   'Claims Handling'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Health and %' THEN
                   'Health and Safety'
               ELSE
                   'Other'
           END [Worktype Group],
           dim_instruction_type.instruction_type AS [Instruction Type],
           dim_client.client_name AS [Client Name],
           dim_client.client_group_name AS [Client Group Name],
		   
COALESCE(NULLIF(dim_client.client_group_name,''), dim_client.client_name) [Client Name combined ],
           dim_client.[sector] AS [Client Sector],
		   dim_client.segment AS  [Client Segment ],
           client_partner_name AS [Client Partner Name],
		   dim_client.client_type AS [Client Type],
--           dim_client_involvement.[insurerclient_reference] AS [Insurer Client Reference FED],
--           dim_client_involvement.[insurerclient_name] AS [Insurer Name FED],
--           dim_detail_core_details.clients_claims_handler_surname_forename AS [Clients Claim Handler ],
--           dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference FED],
--           dim_client_involvement.[insuredclient_name] AS [Insured Client Name FED],
--           dim_detail_core_details.insured_sector AS [Insured Sector],
--           dim_detail_core_details.[insured_departmentdepot] AS [Insured Department],
--           dim_detail_core_details.insured_departmentdepot_postcode AS [Insured Department Depot Postcode],
   
--           dim_detail_critical_mi.date_closed AS [Converge Date Closed],
--           dim_detail_core_details.present_position AS [Present Position],
--           dim_detail_critical_mi.claim_status AS [Converge Claim Status],
           dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent],
           dim_detail_core_details.date_instructions_received AS [Date Instructions Received],
		   dim_detail_property.[commercial_bl_status] [Commercial BL Status], 
--           dim_detail_core_details.status_on_instruction AS [Status On Instruction],
--           dim_detail_core_details.referral_reason AS [Referral Reason],
--           dim_detail_core_details.proceedings_issued AS [Proceedings Issued],
--           dim_detail_core_details.date_proceedings_issued AS [Date Proceedings Issued],
--           dim_detail_litigation.reason_for_litigation AS [Reason For Litigation],
--           dim_court_involvement.court_reference AS [Court Reference],
--           dim_court_involvement.court_name AS [Court Name],
--           dim_detail_core_details.track AS [Track],
--           dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?],
--           COALESCE(
--                       dim_detail_fraud.[fraud_initial_fraud_type],
--                       dim_detail_fraud.[fraud_current_fraud_type],
--                       dim_detail_fraud.[fraud_type_ageas],
--                       dim_detail_fraud.[fraud_current_secondary_fraud_type],
--                       dim_detail_client.[coop_fraud_current_fraud_type],
--                       dim_detail_fraud.[fraud_type],
--                       dim_detail_fraud.[fraud_type_disease_pre_lit]
--                   ) AS [Fraud Type],
--           dim_detail_core_details.credit_hire AS [Credit Hire],
--           dim_agents_involvement.cho_name AS [Credit Hire Organisation],
--           dim_detail_hire_details.[cho] AS [Credit Hire Organisation Detail],
--           dim_claimant_thirdparty_involvement.[claimant_name] AS [Claimant Name],
--           dim_detail_claim.[number_of_claimants] AS [Number of Claimants],
--           fact_detail_client.number_of_defendants AS [Number of Defendants ],
--           dim_detail_core_details.does_claimant_have_personal_injury_claim AS [Does the Claimant have a PI Claim? ],
--           dim_detail_core_details.[brief_description_of_injury] AS [Description of Injury],
--           CASE
--               WHEN
--               (
--                   dim_client.client_code = '00041095'
--                   AND dim_matter_worktype.[work_type_code] = '0023'
--               ) THEN
--                   'Regulatory'
--               WHEN dim_matter_worktype.[work_type_name] LIKE 'EL%'
--                    OR dim_matter_worktype.[work_type_name] LIKE 'PL%'
--                    OR dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN
--                   'Risk Pooling'
--               WHEN
--               (
--                   (
--                       dim_matter_worktype.[work_type_name] LIKE 'NHSLA%'
--                       OR dim_matter_worktype.[work_type_code] = '0005'
--                   )
--                   AND dim_client_involvement.[insuredclient_name] LIKE '%Pennine%'
--                   OR dim_matter_header_current.[matter_description] LIKE '%Pennine%'
--               ) THEN
--                   'Litigation'
--           END AS [Litigation / Regulatory],
--           dim_detail_core_details.[is_there_an_issue_on_liability] AS [Liability Issue],
--           dim_detail_core_details.delegated AS [Delegated],
           dim_detail_core_details.[fixed_fee] AS [Fixed Fee],
           ISNULL(fact_finance_summary.[fixed_fee_amount], 0) AS [Fixed Fee Amount],
           ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0) AS [Fee Arrangement],
           dim_detail_finance.[output_wip_percentage_complete] AS [Percentage Completion],
           fact_bill_detail_summary.bill_total AS [Total Bill Amount - Composite (IncVAT )],
		   	dim_claimant_thirdparty_involvement.claimantrep_name AS [Claimants Representative ],
           fact_finance_summary.[defence_costs_billed] AS [Revenue Costs Billed],
           fact_bill_detail_summary.disbursements_billed_exc_vat AS [Disbursements Billed ],
           fact_finance_summary.vat_billed AS [VAT Billed],
           fact_finance_summary.wip AS [WIP],
       --    fact_finance_summary.[unpaid_disbursements] AS [Unpaid Disbursements],
         fact_finance_summary.disbursement_balance AS [Unbilled Disbursements],
		 		   red_dw.dbo.fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded [Total Disbs Budget Agreed/Recorded], 
red_dw.dbo.fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded [Total profit costs agreed/recorded],
         fact_matter_summary_current.[client_account_balance_of_matter] AS [Client Account Balance of Matter],
         fact_finance_summary.unpaid_bill_balance AS [Unpaid Bill Balance],
           CASE
               WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
                   NULL
               ELSE
                   fact_matter_summary_current.last_bill_date
           END AS [Last Bill Date],
           fact_bill_matter.last_bill_date [Last Bill Date Composite ],
         fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting],
           TimeRecorded.HoursRecorded AS [Hours Recorded],
           TimeRecorded.MinutesRecorded AS [Minutes Recorded],
           ((CASE
                 WHEN TimeRecorded.MinutesRecorded <= 12 THEN
                     0
                 WHEN TimeRecorded.MinutesRecorded > 12 THEN
                     TimeRecorded.MinutesRecorded - 12
             END
            ) * 115
           ) / 60 AS [Legal Spend exc (VAT)],
           fact_matter_summary_current.time_billed / 60 AS [Time Billed],
		   [HrsBilled].[Hrs Billed] AS [Hours Billed to Client],
 [Revenue 2015/2016],
[Revenue 2016/2017],
[Revenue 2017/2018],
[Revenue 2018/2019],
[Revenue 2019/2020],
[Hours Billed 2015/2016],
[Hours Billed 2016/2017],
[Hours Billed 2017/2018],
[Hours Billed 2018/2019],
[Hours Billed 2019/2020],
NonPartnerHours AS [Total Non-Partner Hours Recorded],
           PartnerHours AS [Total Partner Hours Recorded],
           AssociateHours AS [Total Associate Hours Recorded],
           OtherHours AS [Total Other Hours Recorded],
           ParalegalHours AS [Total Paralegal Hours Recorded],
           [Partner/ConsultantTime] AS [Total Partner/Consultant Hours Recorded],
           [Solicitor/LegalExecTimeHours] AS [Total Solicitor/LegalExec Hours Recorded],
           TraineeHours AS [Total Trainee Hours Recorded],
--           dim_detail_finance.[damages_banding] AS [Damages Banding],
--           fact_detail_elapsed_days.[elapsed_days_live_files] AS [Elapsed Days Live Files],
--           DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_outcome.date_costs_settled) AS [Elapsed Days to Costs Settlement],
        red_dw.dbo.fact_finance_summary.commercial_costs_estimate [Current Costs Estimate],
	fact_finance_summary.revenue_and_disb_estimate_net_of_vat,
	fact_finance_summary.revenue_estimate_net_of_vat,
	fact_finance_summary.disbursements_estimate_net_of_vat,
--           red_dw.dbo.fact_finance_summary.recovery_claimants_damages_via_third_party_contribution [Recovery Claimants Damages Via Third Party Contribution],
--           red_dw.dbo.fact_finance_summary.recovery_defence_costs_from_claimant [Recovery Defence Costs From Claimant ],
--           red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution [Recovery Claimants via Third Party Contribution ],
--           red_dw.dbo.fact_finance_summary.recovery_defence_costs_via_third_party_contribution [Defence Costs via Third Party Contribution],
 dim_detail_core_details.[inter_are_there_any_international_elements_to_this_matter] AS [International elements]
,GETDATE() AS update_time

------------------------------------------
--,[Revenue 2015/2016]
--,[Revenue 2016/2017]
--,[Revenue 2017/2018]
--,[Revenue 2018/2019]
--,[Hours Billed 2015/2016]
--,[Hours Billed 2016/2017]
--,[Hours Billed 2017/2018]
--,[Hours Billed 2018/2019]
-----------------------------------------------------
INTO dbo.selfserviceLTAonlyData
    FROM red_dw.dbo.fact_dimension_main
        LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement
            ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key
        LEFT OUTER JOIN red_dw.dbo.dim_client
            ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
            ON red_dw.dbo.dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
            ON red_dw.dbo.dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_department
            ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
            ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
            ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
            ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_court
            ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_health
            ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
            ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_incident
            ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_litigation
            ON dim_detail_litigation.dim_detail_litigation_key = fact_dimension_main.dim_detail_litigation_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
        LEFT OUTER JOIN red_dw.dbo.dim_experts_involvement
            ON dim_experts_involvement.dim_experts_involvemen_key = fact_dimension_main.dim_experts_involvemen_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
            ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
            ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
               AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
               AND GETDATE()
               BETWEEN dss_start_date AND dss_end_date
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary
            ON red_dw.dbo.fact_matter_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_last_bill_date
            ON dim_last_bill_date.dim_last_bill_date_key = fact_matter_summary.dim_last_bill_date_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi
            ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
        LEFT OUTER JOIN red_dw.dbo.dim_open_case_management_date
            ON dim_open_case_management_date.calendar_date = dim_matter_header_current.date_opened_case_management
        LEFT OUTER JOIN red_dw.dbo.dim_closed_case_management_date
            ON dim_closed_case_management_date.calendar_date = dim_matter_header_current.date_closed_case_management
        LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
            ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
            ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
            ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
            ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_client
            ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care
            ON fact_detail_future_care.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
            ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
            ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
            ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary
            ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key --added in for Composite Billing JL
        --LEFT OUTER JOIN [red_dw].[dbo].[fact_all_time_activity] ON fact_all_time_activity.master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
            ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
        LEFT OUTER JOIN red_dw.[dbo].[dim_instruction_type]
            ON [dim_instruction_type].[dim_instruction_type_key] = dim_matter_header_current.dim_instruction_type_key
        LEFT OUTER JOIN red_dw.dbo.dim_employee
            ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
        LEFT OUTER JOIN red_dw.dbo.fact_bill_matter
            ON fact_bill_matter.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
		LEFT OUTER JOIN #HrsBilled AS HrsBilled
 ON HrsBilled.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key		

        LEFT OUTER JOIN
        (
            SELECT fact_dimension_main.master_fact_key [fact_key],
                   dim_client.contact_salutation [claimant1_contact_salutation],
                   dim_client.addresse [claimant1_addresse],
                   dim_client.address_line_1 [claimant1_address_line_1],
                   dim_client.address_line_2 [claimant1_address_line_2],
                   dim_client.address_line_3 [claimant1_address_line_3],
                   dim_client.address_line_4 [claimant1_address_line_4],
                   dim_client.postcode [claimant1_postcode]
            FROM red_dw.dbo.dim_claimant_thirdparty_involvement
                INNER JOIN red_dw.dbo.fact_dimension_main
                    ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
                INNER JOIN red_dw.dbo.dim_involvement_full
                    ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
                INNER JOIN red_dw.dbo.dim_client
                    ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
            WHERE dim_client.dim_client_key != 0
        ) AS ClaimantsAddress
            ON fact_dimension_main.master_fact_key = ClaimantsAddress.fact_key
        LEFT OUTER JOIN
        (
            SELECT fact_chargeable_time_activity.master_fact_key,
                   SUM(minutes_recorded) AS [MinutesRecorded],
                   SUM(minutes_recorded) / 60 AS [HoursRecorded]
            FROM red_dw.dbo.fact_chargeable_time_activity
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
            WHERE minutes_recorded <> 0
                  AND
                  (
                      dim_matter_header_current.date_closed_case_management >= '20120101'
                      OR dim_matter_header_current.date_closed_case_management IS NULL
                  )
            GROUP BY client_code,
                     matter_number,
                     fact_chargeable_time_activity.master_fact_key
        ) AS TimeRecorded
            ON TimeRecorded.master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
        LEFT OUTER JOIN
        (
            SELECT client_code,
                   matter_number,
                   master_fact_key,
                   ISNULL(SUM(PartnerTime), 0) / 60 AS PartnerHours,
                   ISNULL(SUM(NonPartnerTime), 0) / 60 AS NonPartnerHours,
                   ISNULL(SUM([Partner/ConsultantTime]), 0) / 60 AS [Partner/ConsultantTime],
                   ISNULL(SUM(AssociateTime), 0) / 60 AS AssociateHours,
                   ISNULL(SUM([Solicitor/LegalExecTime]), 0) / 60 AS [Solicitor/LegalExecTimeHours],
                   ISNULL(SUM(ParalegalTime), 0) / 60 AS ParalegalHours,
                   ISNULL(SUM(TraineeTime), 0) / 60 AS TraineeHours,
                   ISNULL(SUM(OtherTime), 0) / 60 AS OtherHours
            FROM
            (
                SELECT client_code,
                       matter_number,
                       master_fact_key,
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Partner%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS PartnerTime,
                       (CASE
                            WHEN Partners.jobtitle NOT LIKE '%Partner%'
                                 OR jobtitle IS NULL THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS NonPartnerTime,
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Partner%'
                                 OR Partners.jobtitle LIKE '%Consultant%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [Partner/ConsultantTime],
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Associate%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS AssociateTime,
                       (CASE
                            WHEN Partners.jobtitle LIKE 'Solicitor%'
                                 OR Partners.jobtitle LIKE '%Legal Executive%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [Solicitor/LegalExecTime],
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Paralegal%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [ParalegalTime],
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Trainee Solicitor%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [TraineeTime],
                       (CASE
                            WHEN Partners.jobtitle NOT LIKE '%Partner%'
                                 AND Partners.jobtitle NOT LIKE '%Consultant%'
                                 AND Partners.jobtitle NOT LIKE '%Associate%'
                                 AND Partners.jobtitle NOT LIKE '%Solicitor%'
                                 AND Partners.jobtitle NOT LIKE '%Legal Executive%'
                                 AND Partners.jobtitle NOT LIKE '%Paralegal%'
                                 AND Partners.jobtitle NOT LIKE '%Trainee%'
                                 OR jobtitle IS NULL THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS OtherTime
                FROM red_dw.dbo.fact_chargeable_time_activity
                    LEFT OUTER JOIN
                    (
                        SELECT DISTINCT
                               dim_fed_hierarchy_history_key,
                               jobtitle
                        FROM red_dw.dbo.dim_fed_hierarchy_history
                    ) AS Partners
                        ON Partners.dim_fed_hierarchy_history_key = fact_chargeable_time_activity.dim_fed_hierarchy_history_key
                    LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
                        ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
                WHERE minutes_recorded <> 0
                      AND
                      (
                          dim_matter_header_current.date_closed_case_management >= '20120101'
                          OR dim_matter_header_current.date_closed_case_management IS NULL
                      )
                GROUP BY client_code,
                         matter_number,
                         master_fact_key,
                         Partners.jobtitle
            ) AS AllTime
            GROUP BY AllTime.client_code,
                     AllTime.matter_number,
                     AllTime.master_fact_key
        ) AS [Partner/NonPartnerHoursRecorded]
            ON [Partner/NonPartnerHoursRecorded].master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateClaimConcluded]
            ON CAST(dim_detail_outcome.date_claim_concluded AS DATE) = [DateClaimConcluded].calendar_date
        LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateCostsSettled]
            ON CAST(dim_detail_outcome.date_costs_settled AS DATE) = [DateCostsSettled].calendar_date
        LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateInstructionsReceived]
            ON CAST(dim_detail_core_details.date_instructions_received AS DATE) = [DateInstructionsReceived].calendar_date
        --LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key



        LEFT JOIN
        (
            SELECT fact_dimension_main.master_fact_key [fact_key],
                   LTRIM(RTRIM(dim_client.contact_salutation)) [insurer_contact_salutation],
                   LTRIM(RTRIM(dim_client.addresse)) [insurer_addresse],
                   LTRIM(RTRIM(dim_client.address_line_1)) [insurer_address_line_1],
                   LTRIM(RTRIM(dim_client.address_line_2)) [insurer_address_line_2],
                   LTRIM(RTRIM(dim_client.address_line_3)) [insurer_address_line_3],
                   LTRIM(RTRIM(dim_client.address_line_4)) [insurer_address_line_4],
                   LTRIM(RTRIM(dim_client.postcode)) [insurer_postcode]
            FROM red_dw.dbo.dim_client_involvement WITH (NOLOCK)
                INNER JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK)
                    ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
                INNER JOIN red_dw.dbo.dim_involvement_full WITH (NOLOCK)
                    ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insurerclient_1_key
                INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
                    ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
            WHERE dim_client.dim_client_key != 0
        ) AS billingAddress
            ON fact_dimension_main.master_fact_key = billingAddress.fact_key
        LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS [Insurer Name],
                   assocAddressee AS [Addressee],
                   CASE
                       WHEN assocdefaultaddID IS NOT NULL THEN
                           ISNULL(dbAddress1.addLine1, '') + ' ' + ISNULL(dbAddress1.addLine2, '') + ' '
                           + ISNULL(dbAddress1.addLine3, '') + ' ' + ISNULL(dbAddress1.addLine4, '') + ' '
                           + ISNULL(dbAddress1.addLine5, '') + ' ' + ISNULL(dbAddress1.addPostcode, '')
                       ELSE
                           ISNULL(dbAddress2.addLine1, '') + ' ' + ISNULL(dbAddress2.addLine2, '') + ' '
                           + ISNULL(dbAddress2.addLine3, '') + ' ' + ISNULL(dbAddress2.addLine4, '') + ' '
                           + ISNULL(dbAddress2.addLine5, '') + ' ' + ISNULL(dbAddress2.addPostcode, '')
                   END AS [Insurer Address],
                   dbAssociates.assocRef AS [Insurer Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress1 WITH (NOLOCK)
                    ON assocdefaultaddID = dbAddress1.addID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress2 WITH (NOLOCK)
                    ON contDefaultAddress = dbAddress2.addID
            WHERE assocType = 'INSCLIENT'
        )
        --WHERE assocType='INSURERCLIENT' ) 



        AS MSbillingAddress
            ON dim_matter_header_current.ms_fileid = MSbillingAddress.fileID
               AND MSbillingAddress.XOrder = 1
        LEFT JOIN
        ( --Vat Address
            SELECT fact_dimension_main.master_fact_key [fact_key],
                   LTRIM(RTRIM(dim_client.contact_salutation)) [insured_contact_salutation],
                   LTRIM(RTRIM(dim_client.addresse)) [insured_addresse],
                   LTRIM(RTRIM(dim_client.address_line_1)) [insured_address_line_1],
                   LTRIM(RTRIM(dim_client.address_line_2)) [insured_address_line_2],
                   LTRIM(RTRIM(dim_client.address_line_3)) [insured_address_line_3],
                   LTRIM(RTRIM(dim_client.address_line_4)) [insured_address_line_4],
                   LTRIM(RTRIM(dim_client.postcode)) [insured_postcode]
            FROM red_dw.dbo.dim_client_involvement WITH (NOLOCK)
                INNER JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK)
                    ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
                INNER JOIN red_dw.dbo.dim_involvement_full WITH (NOLOCK)
                    ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insuredclient_1_key
                INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
                    ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
            WHERE dim_client.dim_client_key != 0
        ) AS vatAddress
            ON vatAddress.fact_key = fact_dimension_main.master_fact_key
        LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS [Insured Name],
                   assocAddressee AS [Addressee],
                   CASE
                       WHEN assocdefaultaddID IS NOT NULL THEN
                           ISNULL(dbAddress1.addLine1, '') + ' ' + ISNULL(dbAddress1.addLine2, '') + ' '
                           + ISNULL(dbAddress1.addLine3, '') + ' ' + ISNULL(dbAddress1.addLine4, '') + ' '
                           + ISNULL(dbAddress1.addLine5, '') + ' ' + ISNULL(dbAddress1.addPostcode, '')
                       ELSE
                           ISNULL(dbAddress2.addLine1, '') + ' ' + ISNULL(dbAddress2.addLine2, '') + ' '
                           + ISNULL(dbAddress2.addLine3, '') + ' ' + ISNULL(dbAddress2.addLine4, '') + ' '
                           + ISNULL(dbAddress2.addLine5, '') + ' ' + ISNULL(dbAddress2.addPostcode, '')
                   END AS [Insured Address],
                   dbAssociates.assocRef AS [Insured Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress1 WITH (NOLOCK)
                    ON assocdefaultaddID = dbAddress1.addID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress2 WITH (NOLOCK)
                    ON contDefaultAddress = dbAddress2.addID
            WHERE assocType = 'INSUREDCLIENT'
        ) AS MSvatAddress
            ON dim_matter_header_current.ms_fileid = MSvatAddress.fileID
               AND MSvatAddress.XOrder = 1
 ---- below added per request 8366              
LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2015/2016]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2015/2016]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2015-05-01' AND '2016-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2015
 ON dim_matter_header_current.client_code=Revenue2015.client_code
AND dim_matter_header_current.matter_number=Revenue2015.matter_number

LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2016/2017]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2016/2017]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2016-05-01' AND '2017-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2016
 ON dim_matter_header_current.client_code=Revenue2016.client_code
AND dim_matter_header_current.matter_number=Revenue2016.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2017/2018]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2017/2018]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2017-05-01' AND '2018-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2017
 ON dim_matter_header_current.client_code=Revenue2017.client_code
AND dim_matter_header_current.matter_number=Revenue2017.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2018/2019]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2018/2019]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2018-05-01' AND '2019-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2018
 ON dim_matter_header_current.client_code=Revenue2018.client_code
AND dim_matter_header_current.matter_number=Revenue2018.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2019/2020]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2019/2020]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2019-05-01' AND '2020-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2019
 ON dim_matter_header_current.client_code=Revenue2019.client_code
AND dim_matter_header_current.matter_number=Revenue2019.matter_number



    WHERE dim_matter_header_current.matter_number <> 'ML'
    AND dim_fed_hierarchy_history.hierarchylevel2hist IN ('Legal Ops - LTA', 'Client Relationships')
          AND dim_client.client_code NOT IN ( '00030645', '95000C', '00453737' )
          AND dim_matter_header_current.reporting_exclusions = 0
          AND
          (
              dim_matter_header_current.date_closed_case_management >= @nDate
              OR dim_matter_header_current.date_closed_case_management IS NULL
              )
END
GO
