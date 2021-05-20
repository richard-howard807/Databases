SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<orlagh Kelly >
-- Create date: <2018-10-11>
-- Description:	<General Data file to be used for all general queries firm wide. ,,>
-- =============================================
-- LD 2019/04/11 Moved the date columns so that they appear first and renamed total_reserve to be total_reserve_calc as per #16076
-- LD 20190417 Added in the Total_current_reserve detail 
-- ES 20190610 Added broker name and TP account name, 22692
-- ES 20190611 Added revenue and hours billed 2019/2020, 22996
-- ES 20190613 Added logic to only show Legal Ops - Claims and Legal Ops - LTA, 23377
-- LD 20191004 Added logic to include the latest archive record , 33758
-- ES 20200217 Added type of instruction, requested by JS
-- ES 20200220 Added MS key dates, 26576
-- RH 20200526 Amended Revenue & Hours billed for all years to use composite billing #45295 & Added Chargeable hours #45295 & changed rolling 3 years to last 3 full financial years
-- RH 20200526 Added financial year on various dates #59250 && #57252
-- RH 20200604 Removed reporting exclusions from where clause and added as a column instead so revenue balances, #57252
-- RH 20200604 Added cost handler revenue #55807
-- JB 20200611 Added is_this_part_of_a_campaign #61388
-- ES 20200622 Amended disbursements billed query as code was incorrect #61966
-- JB 20200825 Added date claim concluded date last changed #68418
-- MT 20210127 Updated logic for Credit Hire Organisation
-- OK 20210205 Added new costs estimates
-- MT 20210520 Corrected issue with 2022 in Pivots 

CREATE PROCEDURE  [dbo].[Self Service]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 -- exec [dbo].[Self Service]

    DECLARE @CurrentYear AS DATETIME = '2017-01-01',
         --   @nDate AS DATETIME = DATEADD(YYYY, -3, GETDATE());
			 @nDate AS DATETIME = (SELECT MIN(dim_date.calendar_date) FROM red_dw..dim_date WHERE dim_date.fin_year = (SELECT fin_year - 5 FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = CAST(GETDATE() AS DATE)))

		--	SELECT DATEADD(YYYY, -3, GETDATE());

    IF OBJECT_ID('Reporting.dbo.selfservice') IS NOT NULL
        DROP TABLE dbo.selfservice;


    SET NOCOUNT ON;





-- New Revenue & Billed hours Query as fact_bill_detail doesn't match fact_bill_activity
DROP TABLE IF EXISTS #Revenue

		SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			   PVIOT.[2022],
			   PVIOT.[2021],
			   PVIOT.[2020],
			   PVIOT.[2019],
			   PVIOT.[2018],
			   PVIOT.[2017],
			   PVIOT.[2016]
			   INTO #Revenue
		FROM (

			SELECT fact_bill_activity.client_code, fact_bill_activity.matter_number, dim_bill_date.bill_fin_year bill_fin_year, SUM(fact_bill_activity.bill_amount) Revenue
			FROM red_dw.dbo.fact_bill_activity
			INNER JOIN red_dw.dbo.dim_bill_date ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_fin_year IN (2017,2018,2019,2020,2021, 2022)
			GROUP BY fact_bill_activity.client_code, fact_bill_activity.matter_number, bill_fin_year
			) AS revenue
		PIVOT	
			(
			SUM(Revenue)
			FOR bill_fin_year IN ([2016],[2017],[2018],[2019],[2020],[2021],[2022])
			) AS PVIOT


DROP TABLE IF EXISTS #Billed_hours
	SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			   PVIOT.[2022],
			   PVIOT.[2021],
			   PVIOT.[2020],
			   PVIOT.[2019],
			   PVIOT.[2018],
			   PVIOT.[2017],
			   PVIOT.[2016]
			   INTO #Billed_hours
		FROM (

			SELECT dim_matter_header_current.client_code, dim_matter_header_current.matter_number, dim_bill_date.bill_fin_year bill_fin_year, SUM(fact_bill_billed_time_activity.minutes_recorded) Billed_hours
			FROM red_dw.dbo.fact_bill_billed_time_activity
			INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_bill_date ON fact_bill_billed_time_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_fin_year IN (2016, 2017,2018,2019,2020,2021,2022)
			GROUP BY client_code, matter_number, bill_fin_year
			) AS billedhours
		PIVOT	
			(
			SUM(Billed_hours)
			FOR bill_fin_year IN ([2016],[2017],[2018],[2019],[2020],[2021],[2022])
			) AS PVIOT

-- Added Chargeable hours #45295
DROP TABLE IF EXISTS #Chargeable_hours
		SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			   PVIOT.[2022],
			   PVIOT.[2021],
			   PVIOT.[2020],
			   PVIOT.[2019],
			   PVIOT.[2018],
			   PVIOT.[2017],
			   PVIOT.[2016]
			   INTO #Chargeable_hours
		FROM (

			SELECT dim_matter_header_current.client_code, dim_matter_header_current.matter_number, dim_bill_date.bill_fin_year bill_fin_year, SUM(fact_billable_time_activity.minutes_recorded) Billed_hours
			FROM red_dw.dbo.fact_billable_time_activity
			INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_billable_time_activity.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_bill_date ON fact_billable_time_activity.dim_orig_posting_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_fin_year IN (2016, 2017,2018,2019,2020,2021, 2022)
			GROUP BY client_code, matter_number, bill_fin_year
			) AS revenue
		PIVOT	
			(
			SUM(Billed_hours)
			FOR bill_fin_year IN ([2016],[2017],[2018],[2019],[2020],[2021], [2022])
			) AS PVIOT


DROP TABLE IF EXISTS #Disbursements
--Added disbursements #61966
		SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			   PVIOT.[2022],
			   PVIOT.[2021],
			   PVIOT.[2020],
			   PVIOT.[2019],
			   PVIOT.[2018],
			   PVIOT.[2017],
			   PVIOT.[2016]
			   INTO #Disbursements
		FROM (

						SELECT client_code, matter_number, dim_bill_date.bill_fin_year bill_fin_year, SUM(bill_total_excl_vat) Disbursements
			FROM red_dw.dbo.fact_bill_detail
			INNER JOIN red_dw.dbo.dim_bill_date ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_fin_year IN (2017,2018,2019,2020,2021, 2022)
			AND charge_type='disbursements'
	GROUP BY client_code,
             matter_number,
             bill_fin_year
			) AS disbursements
		PIVOT	
			(
			SUM(Disbursements)
			FOR bill_fin_year IN ([2016],[2017],[2018],[2019],[2020],[2021],[2022])
			) AS PVIOT


SELECT DISTINCT
    dim_matter_header_current.date_opened_case_management AS [Date Case Opened],
	(SELECT fin_year FROM red_dw..dim_date WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)) [Fin Year Opened],
    dim_matter_header_current.date_closed_case_management AS [Date Case Closed],	
	(SELECT fin_year FROM red_dw..dim_date WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_closed_case_management AS DATE)) [Fin Year Closed],
    dim_matter_header_current.ms_only AS [MS Only],
    RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number AS [Weightmans Reference],
    fact_dimension_main.client_code AS [Client Code],
    fact_dimension_main.matter_number AS [Matter Number],
    REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') AS [Mattersphere Client Code],
    REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Matter Number],
    REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'
    + REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Weightmans Reference],
    dim_matter_header_current.[matter_description] AS [Matter Description],

	dim_fed_hierarchy_history.[name] AS [Case Manager],
	matter_owner_full_name [Matter Owner Full Name],
	matter_partner_full_name [Matter Partner],
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
    dim_client.[sector] AS [Client Sector],
	ia_sic_code,
	dim_client.sub_sector AS [Client Sub-Sector],
	dim_client.segment AS  [Client Segment ],
    dim_client.client_partner_name AS [Client Partner Name],
	dim_client.client_type AS [Client Type],
    dim_client_involvement.[insurerclient_reference] AS [Insurer Client Reference FED],
    dim_client_involvement.[insurerclient_name] AS [Insurer Name FED],
    dim_detail_core_details.clients_claims_handler_surname_forename AS [Clients Claim Handler ],
    dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference FED],
    dim_client_involvement.[insuredclient_name] AS [Insured Client Name FED],
    dim_detail_core_details.insured_sector AS [Insured Sector],
    dim_detail_core_details.[insured_departmentdepot] AS [Insured Department],
    dim_detail_core_details.insured_departmentdepot_postcode AS [Insured Department Depot Postcode],

    dim_detail_critical_mi.date_closed AS [Converge Date Closed],
    RTRIM(dim_detail_core_details.present_position) AS [Present Position],
    dim_detail_critical_mi.claim_status AS [Converge Claim Status],
    dim_detail_core_details.date_instructions_received AS [Date Instructions Received],
    dim_detail_core_details.status_on_instruction AS [Status On Instruction],
    dim_detail_core_details.referral_reason AS [Referral Reason],
    dim_detail_core_details.proceedings_issued AS [Proceedings Issued],
    dim_detail_core_details.date_proceedings_issued AS [Date Proceedings Issued],
    dim_detail_litigation.reason_for_litigation AS [Reason For Litigation],
    dim_court_involvement.court_reference AS [Court Reference],
    dim_court_involvement.court_name AS [Court Name],
    dim_detail_core_details.track AS [Track],
    dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?],
    COALESCE(
                dim_detail_fraud.[fraud_initial_fraud_type],
                dim_detail_fraud.[fraud_current_fraud_type],
                dim_detail_fraud.[fraud_type_ageas],
                dim_detail_fraud.[fraud_current_secondary_fraud_type],
                dim_detail_client.[coop_fraud_current_fraud_type],
                dim_detail_fraud.[fraud_type],
                dim_detail_fraud.[fraud_type_disease_pre_lit]
            ) AS [Fraud Type],
    dim_detail_core_details.credit_hire AS [Credit Hire],

    COALESCE(IIF(dim_detail_hire_details.[credit_hire_organisation_cho] = 'Other', NULL, dim_detail_hire_details.[credit_hire_organisation_cho]), dim_detail_hire_details.[other]
,dim_agents_involvement.cho_name) AS [Credit Hire Organisation], --dim_agents_involvement.cho_name AS [Credit Hire Organisation] 27/01/2021 - MT as per 86052,

CASE WHEN credit_hire_organisation_cho = 'Other                                                       ' THEN 
other WHEN other IS NULL 
THEN 'Other'
WHEN (other IS NULL AND credit_hire_organisation_cho IS NULL ) THEN 
 COALESCE(cho, hirecompany_name) END AS [Credit Hire Org HF], 


    dim_detail_hire_details.[cho] AS [Credit Hire Organisation Detail],
	dim_detail_core_details.[brief_details_of_claim] [Brief Details of Claim], 

    dim_claimant_thirdparty_involvement.[claimant_name] AS [Claimant Name],
    dim_detail_claim.[number_of_claimants] AS [Number of Claimants],
	defendant.defendant AS [Defendant Name],
    fact_detail_client.number_of_defendants AS [Number of Defendants ],
    dim_detail_core_details.does_claimant_have_personal_injury_claim AS [Does the Claimant have a PI Claim? ],
    dim_detail_core_details.[brief_description_of_injury] AS [Description of Injury],
	dim_experts_involvement.medicalexpert_name [Claimant's medical expert],
    CASE
        WHEN
        (
            dim_client.client_code = '00041095'
            AND dim_matter_worktype.[work_type_code] = '0023'
        ) THEN
            'Regulatory'
        WHEN dim_matter_worktype.[work_type_name] LIKE 'EL%'
            OR dim_matter_worktype.[work_type_name] LIKE 'PL%'
            OR dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN
            'Risk Pooling'
        WHEN
        (
            (
                dim_matter_worktype.[work_type_name] LIKE 'NHSLA%'
                OR dim_matter_worktype.[work_type_code] = '0005'
            )
            AND dim_client_involvement.[insuredclient_name] LIKE '%Pennine%'
            OR dim_matter_header_current.[matter_description] LIKE '%Pennine%'
        ) THEN
            'Litigation'
    END AS [Litigation / Regulatory],
    dim_detail_core_details.[is_there_an_issue_on_liability] AS [Liability Issue],
    dim_detail_core_details.delegated AS [Delegated],
    dim_detail_core_details.[fixed_fee] AS [Fixed Fee],
    ISNULL(fact_finance_summary.[fixed_fee_amount], 0) AS [Fixed Fee Amount],
    RTRIM(ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0)) AS [Fee Arrangement],
    dim_detail_finance.[output_wip_percentage_complete] AS [Percentage Completion],
    dim_detail_core_details.is_this_a_linked_file AS [Linked File?],
    dim_detail_health.leadfollow AS [Lead Follow],
    dim_detail_core_details.lead_file_matter_number_client_matter_number AS [Lead File Matter Number],
    dim_detail_core_details.[associated_matter_numbers] AS [Associated Matter Numbers],
    dim_detail_core_details.grpageas_motor_moj_stage AS [MoJ stage],
    dim_detail_core_details.incident_date AS [Incident Date],
    dim_detail_core_details.[incident_location] AS [Incident Location],
    dim_detail_core_details.has_the_claimant_got_a_cfa AS [Has the Claimant got a CFA? ],
    dim_detail_claim.cfa_entered_into_before_1_april_2013 AS [CFA entered into before 1 April 2013],
	dim_detail_claim.[dst_claimant_solicitor_firm ] AS[Claimant's Solicitor (Data Service)],
    dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant's Solicitor],
	RTRIM(LTRIM(dim_involvement_full.forename))+' '+  RTRIM(LTRIM(dim_involvement_full.name)) [Claimants Representative],
	--dim_claimant_thirdparty_involvement.claimantrep_name AS [Claimants Representative ],
    ClaimantsAddress.[claimant1_postcode] AS [Claimant's Postcode],
	-- Ld 20190411 amended name from Total Reserve
    fact_finance_summary.total_reserve AS [Total Reserve Calc],
	-- ld 20190417 added the total current reserve detail TRA098
	fact_detail_reserve_detail.total_current_reserve [total_current_reserve],
    ISNULL(fact_detail_reserve_detail.converge_disease_reserve, 0) AS [Converge Disease Reserve],
		fact_finance_summary.[damages_reserve_initial] [Damages Reserve (Initial)],
    fact_finance_summary.damages_reserve AS [Damages Reserve Current ],
    fact_detail_paid_detail.hire_claimed AS [Hire Claimed ],
	fact_finance_summary.[tp_costs_reserve_initial]  [Claimant Costs Reserve Current (Initial)],
    fact_detail_reserve_detail.claimant_costs_reserve_current AS [Claimant Costs Reserve Current ],
	fact_finance_summary.[defence_costs_reserve_initial] AS [Defence Cost Reserve (Initial )], 
    fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve Current],
    CASE
        WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL
            AND dim_matter_header_current.date_closed_case_management IS NOT NULL THEN
            0
        ELSE
            fact_finance_summary.[other_defendants_costs_reserve]
    END AS [Other Defendant's Costs Reserve (Net)],
    fact_detail_future_care.disease_total_estimated_settlement_value AS [Disease Total Estimated Settlement Value ],
    RTRIM(dim_detail_outcome.[outcome_of_case]) AS [Outcome of Case],
    dim_detail_outcome.[ll00_settlement_basis] AS [Settlement basis],

	dim_detail_court.[date_of_first_day_of_trial_window] AS [Date of first day of trial window],
    dim_detail_court.[date_of_trial] AS [Date of Trial],

    dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded],
	(SELECT fin_year FROM red_dw..dim_date WHERE dim_date.calendar_date = CAST(date_claim_concluded AS DATE)) AS [Fin Year Claim Concluded],
	dim_detail_outcome.date_claim_concluded_date_last_changed		AS [Date "Date Claim Concluded" Last Changed],
    fact_finance_summary.damages_interims AS [Interim Damages],
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
    END AS [Damages Paid by Client ],
    fact_detail_paid_detail.[total_nil_settlements] AS [Outsource Damages Paid (WPS278+WPS279+WPS281)],
    fact_detail_paid_detail.personal_injury_paid AS [Personal Injury Paid],
    fact_detail_paid_detail.amount_hire_paid AS [Hire Paid ],
    CASE
        WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL
            AND fact_detail_paid_detail.[total_nil_settlements] IS NULL THEN
            NULL
        ELSE
    (CASE
        WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL THEN
    (CASE
        WHEN ISNULL(dim_detail_claim.[our_proportion_percent_of_damages], 0) = 0 THEN
            NULL
        ELSE
    (ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
    + ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
    )
    / dim_detail_claim.[our_proportion_percent_of_damages]
    END
    )
        ELSE
            fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties]
    END
    )
    END AS [Damages Paid (all parties) - Disease],
    dim_detail_outcome.date_referral_to_costs_unit AS [Date Referral to Costs Unit],
    dim_detail_outcome.[date_claimants_costs_received] AS [Date Claimants Costs Received],
    dim_detail_outcome.date_costs_settled AS [Date Costs Settled],
	(SELECT fin_year FROM red_dw..dim_date WHERE dim_date.calendar_date = CAST(dim_detail_outcome.date_costs_settled AS DATE)) AS [Fin Year Costs Settled],
    dim_detail_client.date_settlement_form_sent_to_zurich AS [Date Settlement form Sent to Zurich WPS386 VE00571],
    fact_detail_paid_detail.interim_costs_payments AS [Interim Costs Payments],
    fact_detail_claim.[claimant_sols_total_costs_sols_claimed] AS [Total third party costs claimed (the sum of TRA094+NMI599+NMI600)],
    fact_finance_summary.[total_tp_costs_paid] AS [Total third party costs paid (sum of TRA072+NMI143+NMI379)],
    fact_finance_summary.tp_total_costs_claimed AS [Claimants Total Costs Claimed against Client],
    CASE
        WHEN fact_finance_summary.[claimants_costs_paid] IS NULL
            AND fact_detail_paid_detail.[claimants_costs] IS NULL THEN
            NULL
        ELSE
            COALESCE(fact_finance_summary.[claimants_costs_paid], fact_detail_paid_detail.[claimants_costs])
    END AS [Claimant's Costs Paid by Client - Disease],
    red_dw.dbo.fact_detail_paid_detail.claimants_costs AS [Outsource Claimants Costs],
    fact_finance_summary.detailed_assessment_costs_claimed_by_claimant AS [Detailed Assessment Costs Claimed by Claimant],
    fact_finance_summary.detailed_assessment_costs_paid AS [Detailed Assessment Costs Paid],
    fact_finance_summary.[costs_claimed_by_another_defendant] AS [Costs Claimed by another Defendant],
    fact_detail_cost_budgeting.[costs_paid_to_another_defendant] AS [Costs Paid to Another Defendant],
    ISNULL(fact_finance_summary.[claimants_total_costs_paid_by_all_parties], 0) AS [Claimants Total Costs Paid by All Parties],
    red_dw.dbo.dim_detail_outcome.are_we_pursuing_a_recovery [Are we pursuing a recovery?],
    fact_finance_summary.total_recovery AS [Total Recovery (NMI112,NMI135,NMI136,NMI137)],
    fact_detail_recovery_detail.monies_received AS [Outsource Recovery Paid],
    fact_bill_detail_summary.bill_total AS [Total Bill Amount - Composite (IncVAT )],
    fact_finance_summary.[defence_costs_billed] AS [Revenue Costs Billed],
    fact_bill_detail_summary.disbursements_billed_exc_vat AS [Disbursements Billed ],
    fact_finance_summary.vat_billed AS [VAT Billed],
    fact_finance_summary.wip AS [WIP],
    --    fact_finance_summary.[unpaid_disbursements] AS [Unpaid Disbursements],
    fact_finance_summary.disbursement_balance AS [Unbilled Disbursements],
	fact_finance_summary.[revenue_estimate_net_of_vat] [Revenue Estimate net of VAT],
	fact_finance_summary.[disbursements_estimate_net_of_vat] [Disbursements net of VAT],
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
	(SELECT fin_year FROM red_dw..dim_date WHERE dim_date.calendar_date = CAST(fact_bill_matter.last_bill_date AS DATE)) [Fin Year Of Last Bill],
    fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting],
	(SELECT fin_year FROM red_dw..dim_date WHERE dim_date.calendar_date = CAST(fact_matter_summary_current.[last_time_transaction_date] AS DATE)) AS [Fin Year Of Last Time Posting],
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
    NonPartnerHours AS [Total Non-Partner Hours Recorded],
    PartnerHours AS [Total Partner Hours Recorded],
    AssociateHours AS [Total Associate Hours Recorded],
    OtherHours AS [Total Other Hours Recorded],
    ParalegalHours AS [Total Paralegal Hours Recorded],
    [Partner/ConsultantTime] AS [Total Partner/Consultant Hours Recorded],
    [Solicitor/LegalExecTimeHours] AS [Total Solicitor/LegalExec Hours Recorded],
    TraineeHours AS [Total Trainee Hours Recorded],
    dim_detail_finance.[damages_banding] AS [Damages Banding],
    fact_detail_elapsed_days.[elapsed_days_live_files] AS [Elapsed Days Live Files],
    DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_outcome.date_costs_settled) AS [Elapsed Days to Costs Settlement],
		   	DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.[date_claim_concluded])  AS  [Elapsed Days to Damages Concluded],
    fact_detail_cost_budgeting.[initial_costs_estimate] AS [Initial Costs Estimate],
	red_dw.dbo.fact_finance_summary.commercial_costs_estimate [Current Costs Estimate],
	fact_finance_summary.revenue_and_disb_estimate_net_of_vat,
	fact_finance_summary.revenue_estimate_net_of_vat,
	fact_finance_summary.disbursements_estimate_net_of_vat,
    red_dw.dbo.fact_finance_summary.recovery_claimants_damages_via_third_party_contribution [Recovery Claimants Damages Via Third Party Contribution],
    red_dw.dbo.fact_finance_summary.recovery_defence_costs_from_claimant [Recovery Defence Costs From Claimant ],
    red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution [Recovery Claimants via Third Party Contribution ],
    red_dw.dbo.fact_finance_summary.recovery_defence_costs_via_third_party_contribution [Defence Costs via Third Party Contribution],
	dim_detail_claim.[dst_insured_client_name] AS [Insured Client Name],
	red_dw.dbo.dim_detail_property.commercial_bl_status [Commerical BI Status],
	dim_client_involvement.[broker_name] AS [Broker Name],
	dim_claimant_thirdparty_involvement.[tpaccount_name] AS [TP Account Name],
	red_dw.dbo.dim_claimant_thirdparty_involvement.tpstorereccomp_name [Third party storage and recovery company],
	GETDATE() AS update_time

	--,[Revenue 2015/2016]
	--,[Revenue 2016/2017]
	--,[Revenue 2017/2018]---- Added Per Request 8366
	--,[Revenue 2018/2019]
	--,[Revenue 2019/2020]
	--,[Hours Billed 2015/2016]
	--,[Hours Billed 2016/2017]
	--,[Hours Billed 2017/2018]
	--,[Hours Billed 2018/2019]
	--,[Hours Billed 2019/2020]

	, Revenue.[2016] [Revenue 2015/2016]
	, Revenue.[2017] [Revenue 2016/2017]
	, Revenue.[2018] [Revenue 2017/2018]
	, Revenue.[2019] [Revenue 2018/2019]
	, Revenue.[2020] [Revenue 2019/2020]
	, Revenue.[2021] [Revenue 2020/2021]
	, Revenue.[2022] [Revenue 2021/2022]

	 , Billed_hours.[2016] [Hours Billed 2015/2016]
	 , Billed_hours.[2017] [Hours Billed 2016/2017]
	 , Billed_hours.[2018] [Hours Billed 2017/2018]
	 , Billed_hours.[2019] [Hours Billed 2018/2019]
	 , Billed_hours.[2020] [Hours Billed 2019/2020]
	 , Billed_hours.[2021] [Hours Billed 2020/2021]
	 , Billed_hours.[2022] [Hours Billed 2021/2022]

	 , Chargeable_hours.[2016] [Chargeable Hours Posted 2015/2016]
	 , Chargeable_hours.[2017] [Chargeable Hours Posted 2016/2017]
	 , Chargeable_hours.[2018] [Chargeable Hours Posted 2017/2018]
	 , Chargeable_hours.[2019] [Chargeable Hours Posted 2018/2019]
	 , Chargeable_hours.[2020] [Chargeable Hours Posted 2019/2020]
	 , Chargeable_hours.[2021] [Chargeable Hours Posted 2020/2021]
	 , Chargeable_hours.[2022] [Chargeable Hours Posted 2021/2022]

	, Disbursements.[2016] [Disbursements Billed 2015/2016]
	, Disbursements.[2017] [Disbursements Billed 2016/2017]
	, Disbursements.[2018] [Disbursements Billed 2017/2018]
	, Disbursements.[2019] [Disbursements Billed 2018/2019]
	, Disbursements.[2020] [Disbursements Billed 2019/2020]
	, Disbursements.[2021] [Disbursements Billed 2020/2021]
	, Disbursements.[2022] [Disbursements Billed 2021/2022]

	,dim_detail_claim.[stw_work_type] [STW Work Type]
	,fact_finance_summary.minutes_recorded_cost_handler
	,fact_finance_summary.time_charge_value_cost_handler 
	, cost_handler_revenue.cost_handler_revenue
	,ClientAssocRef AS [Client Ref]
	,dim_detail_claim.[date_recovery_concluded] AS date_recovery_concluded
	,[Counsel ex VAT] AS [Counsel Fees Billed ex VAT]
	,[Counsel inc VAT] AS [Counsel Fees Billed inc VAT]
	,dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS  [Date of receipt of clients file of papers]
	,[cboClientReqRep].[Do clients require an initial report] AS [Do clients require an initial report]
	,dim_detail_core_details.[date_initial_report_sent] AS [Date initial report sent]
	,dim_detail_core_details.[date_initial_report_due] AS [[Date_initial_report_due]
	,dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an extension for the initial report]
	,[Final Bill Date]
	, dim_matter_header_current.[latest_archive_date]
	,dim_matter_header_current.[latest_archive_status] 
	,dim_matter_header_current.[latest_archive_type]
	,dim_detail_core_details.[trust_type_of_instruction] AS [Trust Type of Instruction]
	,dim_detail_core_details.[covid_reason] [Covid Reason]
    ,dim_detail_core_details.[covid_other] [Covid Other]

	--key dates
	, [Acknowledgement of Service]
	, [Defence Due]
	, [Directions Questionnaire]
	, [CMC]
	, [Disclosure]
	, [Exchange of witness statements]
	, [Exchange of medical reports]
	, [Pre-trial checklist]
	, [Trial date]
	, dim_detail_court.date_of_trial [date of trial not KD]

	, dim_detail_core_details.is_this_part_of_a_campaign		AS [Is This Part of a Campaign?]

	, dim_detail_claim.[tier_1_3_case] -- Added as per request via HF 20210203 - MT

---------------------------------------------------
,dim_detail_core_details.[inter_are_there_any_international_elements_to_this_matter] AS [International elements]
,will_total_gross_reserve_on_the_claim_exceed_500000 AS [LL Damages £350k+]
, ISNULL(dim_matter_header_current.reporting_exclusions, 0) reporting_exclusions

INTO Reporting.dbo.selfservice

----------------------------------------------------
FROM red_dw.dbo.fact_dimension_main
        --inner join PFC on PFC.client_code = fact_dimension_main.client_code and PFC.matter_number = fact_dimension_main.matter_number
        --inner join FIND on FIND.client_code = fact_dimension_main.client_code and FIND.matter_number = fact_dimension_main.matter_number
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

	LEFT JOIN red_dw.dbo.dim_involvement_full ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimantrep_1_key 
		LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
		LEFT OUTER JOIN (SELECT fileID,CASE WHEN cboClientReqRep='Y' THEN 'Yes'
								WHEN cboClientReqRep='N' THEN 'No' ELSE cboClientReqRep END  AS [Do clients require an initial report] 
								FROM MS_Prod.dbo.udMICoreGeneral 
								WHERE cboClientReqRep IS NOT NULL) AS cboClientReqRep
									ON ms_fileid=cboClientReqRep.fileID

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

-- New Revenue & Billed hours Query as fact_bill_detail doesn't match fact_bill_activity
LEFT OUTER JOIN #Revenue Revenue
 ON dim_matter_header_current.client_code=Revenue.client_code
AND dim_matter_header_current.matter_number=Revenue.matter_number

LEFT OUTER	JOIN #Billed_hours Billed_hours ON dim_matter_header_current.client_code=Billed_hours.client_code
			AND dim_matter_header_current.matter_number=Billed_hours.matter_number 


-- Added Chargeable hours #45295
LEFT OUTER JOIN #Chargeable_hours Chargeable_hours  ON dim_matter_header_current.client_code=Chargeable_hours.client_code
			AND dim_matter_header_current.matter_number=Chargeable_hours.matter_number 

-- Added Disbursements #61966
LEFT OUTER JOIN #Disbursements Disbursements  ON dim_matter_header_current.client_code=Disbursements.client_code
			AND dim_matter_header_current.matter_number=Disbursements.matter_number 


	LEFT JOIN
	(
	SELECT fileID, defendant = STUFF((SELECT N'; ' + contName 
	  FROM  
	(SELECT DISTINCT fileID, contName 
	FROM MS_Prod.config.dbAssociates 
	INNER JOIN  MS_Prod.config.dbContact ON dbContact.contID = dbAssociates.contID
	WHERE assocType = 'DEFENDANT' ) AS assoc_def 
	   WHERE assoc_def.fileID = p.fileID 
	   ORDER BY contName
	   FOR XML PATH(N'')), 1, 2, N'')
	FROM (SELECT DISTINCT fileID, contName 
	FROM MS_Prod.config.dbAssociates 
	INNER JOIN  MS_Prod.config.dbContact ON dbContact.contID = dbAssociates.contID
	WHERE assocType = 'DEFENDANT' ) AS p
	GROUP BY fileID

	)

	defendant
	ON dim_matter_header_current.ms_fileid = defendant.fileID

	/* Counsel Fees*/
	LEFT OUTER JOIN (
	SELECT fileID, ClientAssocRef = STUFF((SELECT N'; ' + assocRef 
	  FROM  
	(	SELECT DISTINCT fileID, assocRef 
		FROM MS_Prod.config.dbAssociates 
		WHERE assocType = 'CLIENT' AND assocRef IS NOT NULL ) AS assoc_def 
		   WHERE assoc_def.fileID = p.fileID 
		   ORDER BY assocRef
		   FOR XML PATH(N'')), 1, 2, N'')
		FROM (SELECT DISTINCT fileID, assocRef 
		FROM MS_Prod.config.dbAssociates 
		WHERE assocType = 'CLIENT' 
		AND assocRef IS NOT NULL ) AS p
		GROUP BY fileID
	) AS ClientAssociate
	ON dim_matter_header_current.ms_fileid = ClientAssociate.fileID
	LEFT OUTER JOIN (SELECT client_code_bill_item AS [client_code]
	,matter_number_bill_item AS [matter_number]
	,SUM(bill_total) AS  [Counsel inc VAT]
	,SUM(bill_total_excl_vat)AS  [Counsel ex VAT] 
	FROM red_dw.dbo.fact_bill_detail
	INNER JOIN red_dw.dbo.dim_bill_cost_type
	 ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
	WHERE charge_type='disbursements'
	AND UPPER(cost_type_description) LIKE '%COUNSEL%'
	GROUP BY client_code_bill_item
	,matter_number_bill_item ) AS CounselFees
	 ON dim_matter_header_current.client_code=CounselFees.client_code
	AND dim_matter_header_current.matter_number=CounselFees.matter_number

	/* Final Bill Date Logic */
	LEFT OUTER JOIN (

	SELECT x.client_code, x.matter_number,MIN(x.a) [Final Bill Date]
	FROM
    (
               SELECT fact_dimension_main.client_code,
			fact_dimension_main.matter_number
			,dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] a 
		 FROM red_dw.dbo.fact_dimension_main
		INNER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		WHERE   (
                      dim_matter_header_current.date_closed_case_management >= '20160101'
                      OR dim_matter_header_current.date_closed_case_management IS NULL
                  ) 
		AND [mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL
        UNION
        SELECT fact_dimension_main.client_code
			,fact_dimension_main.matter_number
			,dim_detail_health.[zurichnhs_date_final_bill_sent_to_client] a 
		 FROM red_dw.dbo.fact_dimension_main		
		INNER JOIN  red_dw.dbo.dim_detail_health ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
		INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		WHERE   (
                      dim_matter_header_current.date_closed_case_management >= '20160101'
                      OR dim_matter_header_current.date_closed_case_management IS NULL
                  ) 
		AND [zurichnhs_date_final_bill_sent_to_client] IS NOT NULL

		) x
		GROUP BY x.client_code, x.matter_number
	) AS minval ON minval.client_code = dim_client.client_code AND minval.matter_number = dim_detail_finance.matter_number




	--Key Dates
	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Acknowledgement of Service] 
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE' AND tskDesc ='Acknowledgement of Service due - today'
	GROUP BY fileID) AS [KD_Acknowledgement] ON [KD_Acknowledgement].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Defence Due] FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc='Defences due - today'GROUP BY fileID) AS [KD_Defence] ON [KD_Defence].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Directions Questionnaire]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='AQ/Directions Questionnaire - today'
	GROUP BY fileID) AS [KD_DirectionsQuest] ON [KD_DirectionsQuest].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [CMC]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='CMC due - today'
	GROUP BY fileID) AS [KD_CMC] ON [KD_CMC].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Disclosure]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Disclosure - today'
	GROUP BY fileID) AS [KD_Disclosure] ON [KD_Disclosure].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Exchange of witness statements]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Exchange of witness statements - today'
	GROUP BY fileID) AS [KD_Witness] ON [KD_Witness].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Exchange of medical reports]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Exchange of medical reports Due - today'
	GROUP BY fileID) AS [KD_Medical] ON [KD_Medical].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Pre-trial checklist]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Pre-trial checklist due - today'
	GROUP BY fileID) AS [KD_PreTrial] ON [KD_PreTrial].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Trial date]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Trial date - today'
	GROUP BY fileID) AS [KD_TrialDate] ON [KD_TrialDate].fileID=ms_fileid

	LEFT OUTER JOIN (SELECT fact_bill_activity.client_code, fact_bill_activity.matter_number, SUM(fact_bill_activity.bill_amount) cost_handler_revenue
					FROM red_dw..fact_bill_activity
					INNER JOIN red_dw..dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
					WHERE dim_fed_hierarchy_history.cost_handler = 1
					GROUP BY fact_bill_activity.client_code, fact_bill_activity.matter_number) cost_handler_revenue
					ON cost_handler_revenue.client_code = dim_matter_header_current.client_code
					AND cost_handler_revenue.matter_number = dim_matter_header_current.matter_number

LEFT OUTER JOIN red_dw.dbo.dim_client_matter_summary 
 ON dim_client.dim_client_key=dim_client_matter_summary.dim_client_key
--- Final WHERE Clause -------------------------------------------------------------------------------------------------

WHERE dim_matter_header_current.matter_number <> 'ML'
          AND dim_client.client_code NOT IN ( '00030645', '95000C', '00453737' )
          --AND dim_matter_header_current.reporting_exclusions = 0
          AND
          (
              dim_matter_header_current.date_closed_case_management >= @nDate
              OR dim_matter_header_current.date_closed_case_management IS NULL
          )
		  AND hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA', 'Business Services','Client Relationships') -- Added Business Services as requested by A-M 20190920
--AND dim_matter_header_current.date_opened_case_management >= '2015-01-01'
--AND( dim_matter_worktype.work_type_name LIKE 'El%' OR dim_matter_worktype.work_type_name LIKE 'NHSLA%' OR dim_matter_worktype.work_type_name LIKE 'PL%')



END;


GO
