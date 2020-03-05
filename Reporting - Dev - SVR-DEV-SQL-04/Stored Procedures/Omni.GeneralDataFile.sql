SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		General Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
CREATE PROCEDURE [Omni].[GeneralDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--INSERT INTO Omni.ProcTiming (Procname, TimeStart)
--VALUES ('[Omni].[GeneralDataFile]', GETDATE())

---Varable to determine historic vs current

              DECLARE @CurrentDate Date =  getdate()
              DECLARE @CurrentYear int

              IF datepart(mm,@currentdate)> 4
              BEGIN
                     SET @CurrentYear = datepart(yyyy,@currentdate)
              END
              ELSE
              BEGIN
                     SET @CurrentYear = datepart(yyyy,dateadd(yyyy,-1,@currentdate))
              END

       
        

SELECT

  RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, fact_dimension_main.client_code AS [Client Code]
		--, dim_matter_header_current.ms_client_code AS [MS Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.client_code),'0',' ') ),' ','0') AS [Client Code Trimmed]
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.matter_number),'0',' ') ),' ','0') AS [Matter Number Trimmed]
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.client_code),'0',' ') ),' ','0')+'-'+REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.matter_number),'0',' ') ),' ','0') AS [Weightmans Reference Trimmmed]
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]),'0',' ') ),' ','0') AS [Mattersphere Client Code]
		, REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]),'0',' ') ),' ','0') AS [Mattersphere Matter Number]
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]),'0',' ') ),' ','0')+'-'+REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]),'0',' ') ),' ','0') AS [Mattersphere Weightmans Reference]
		, dim_matter_header_current.[matter_description] AS [Matter Description]
		, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
		, dim_matter_header_current.date_opened_practice_management AS OpenedCaseDate_Finance
		, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
		--, dim_matter_header_current.date_closed_practice_management AS ClosedCaseDate_Finance
		, dim_detail_critical_mi.status_2 [Open/Closed Status]
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Open/Closed Case Status]
		, dim_detail_core_details.date_instructions_received AS [Date Instructions Received]
		, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
		, dim_detail_outcome.claim_status AS [Claim Concluded Status]
		, dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
		, dim_fed_hierarchy_history.[display_name] AS [Case Manager Name]
		, dim_fed_hierarchy_history.[name] AS [Case Manager]
		, dim_fed_hierarchy_history.fte AS [FTE]
		, dim_fed_hierarchy_history.[worksforname] AS [Team Manager]
		, dim_detail_practice_area.[bcm_name] AS [BCM Name]
		, dim_fed_hierarchy_history.[reportingbcmname] AS [BCM]
		, dim_fed_hierarchy_history.[hierarchylevel2hist] [Business Line]
		, dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Practice Area]
		, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
		, dim_matter_header_current.[branch_name] AS [Branch Name]
		, dim_department.[department_code] AS [Department Code]
		, dim_department.[department_name] AS [Department]
		, dim_matter_worktype.[work_type_code] AS [Work Type Code]
		, dim_matter_worktype.[work_type_name] AS [Work Type]
		, dim_client.client_group_name AS [Client Group Name]
		, dim_client.client_name AS [Client Name]
		, dim_client.[sector] AS [Client Sector]
		, dim_client.segment AS [Segment]
		, dim_client.sub_sector AS [Client Sub-sector]
		, dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant's Solicitor]
		, dim_detail_core_details.claimants_solicitors_name AS [Claimant's Solicitors Name]
		, dim_detail_core_details.[name_of_claimants_firm] AS [Name of Claimant's Firm]
		, dim_claimant_thirdparty_involvement.[claimant_name] AS [Claimant Name]
		, dim_detail_core_details.[claimants_date_of_birth] AS [Claimant's DOB]
		, ClaimantsAddress.[claimant1_postcode] AS [Claimant's Postcode]
		, dim_detail_claim.[number_of_claimants] AS [Number of Claimants]
		, dim_detail_core_details.zurich_policy_holdername_of_insured AS [Policy Holder Name]
		, dim_client_involvement.[insurerclient_name] AS [Insurer Name]
		, dim_client_involvement.[insurerclient_reference] AS [Insurer Client Reference]
		, dim_detail_core_details.[insured_departmentdepot] AS [Insured Department]
		, dim_detail_core_details.insured_departmentdepot_postcode AS [Insured Department Depot Postcode]
		, dim_client_involvement.[insuredclient_name] AS [Insured Client Name]
		, dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference]
		, dim_court_involvement.court_name AS [Court Name]
		, dim_court_involvement.court_reference AS [Court Reference]
		, dim_detail_core_details.present_position AS [Present Position]
		, dim_detail_core_details.track AS [Track]
		, dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?]
		, dim_detail_core_details.referral_reason AS [Referral Reason]
		, dim_detail_core_details.[fixed_fee] AS [Fixed Fee]
		, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_core_details.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_claim.accident_location AS [Accident Location]
		, dim_detail_core_details.incident_date AS [Incident Date]
		, dim_detail_core_details.[incident_location] AS [Incident Location]
		, dim_detail_core_details.injury_type AS [Type of Injury]
		, dim_detail_incident.[description_of_injury_v] AS [Injury Type]
		, dim_detail_core_details.[brief_description_of_injury] AS [Description of Injury]
		, dim_experts_involvement.engineer_name AS [Engineer Name]
		, dim_detail_core_details.credit_hire AS [Credit Hire]
		, dim_agents_involvement.cho_name AS [Credit Hire Organisation]
		, dim_detail_hire_details.[cho] AS [Credit Hire Organisation Detail]
		, dim_detail_hire_details.cho_hire_start_date AS [Hire Start Date]
		, dim_detail_hire_details.chp_hire_end_date AS [Hire End Date]
		, dim_detail_health.leadfollow AS [Lead Follow]
		, dim_detail_core_details.is_this_a_linked_file AS [Linked File?]
		, dim_detail_core_details.[is_this_the_lead_file] AS [Lead File?]
		, dim_detail_core_details.lead_file_matter_number_client_matter_number AS [Lead File Matter Number]
		, dim_detail_core_details.[associated_matter_numbers] AS [Associated Matter Numbers]
		, dim_detail_claim.is_this_a_work_referral AS [Work Referral?]
		, dim_detail_claim.[number_of_claimants] AS [Number of Claimants]
		, dim_detail_client.[coop_fraud_status] AS [Fraud Status]
		, dim_detail_client.weightmans_comments AS [Weightmans Comments]
		, dim_detail_core_details.date_of_current_estimate_to_complete_retainer AS [Date of Current Estimate to Complete Retainer]
		, dim_detail_core_details.date_letter_of_claim AS [Date Letter of Claim]
		, dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
		, dim_detail_core_details.[date_pre_trial_report] AS [Date of Pre-Trial Report]
		, dim_detail_court.[date_of_trial] AS [Date of Trial]
		, dim_detail_court.[trial_window] AS [Trial Window]
		, dim_detail_core_details.[date_start_of_trial_window] AS [Date Start of Trial Window]
		, dim_detail_court.[date_end_of_trial_window] AS [Date End Of Trial Window]
		, dim_detail_court.[infant_approval] AS [Infant Approval]
		, dim_detail_core_details.grpageas_motor_moj_stage AS [MoJ stage]
		, dim_detail_core_details.sabre_reason_for_instructions AS [Reason for Instruction]
		, dim_detail_core_details.date_subsequent_sla_report_sent AS [Sub Report]
		, dim_detail_core_details.date_the_closure_report_sent AS [Closure Report]
		, dim_detail_core_details.[is_there_an_issue_on_liability] AS [Liability Issue]
		, dim_detail_core_details.delegated AS Delegated
		, dim_detail_core_details.ccnumber AS [Live Claim]
		, dim_detail_claim.live_case_status AS [Live Case Status]
		, dim_detail_litigation.litigated AS [Litigated]
		, dim_detail_critical_mi.claim_status AS [Converge Claim Status]
		, dim_detail_critical_mi.closure_reason AS [Converge Closure Reason]
		, dim_detail_outcome.[date_claimants_costs_received] AS [Date Claimants Costs Received]
		, dim_detail_outcome.date_costs_settled AS [Date Costs Settled]
		, fact_detail_elapsed_days.[elapsed_days_live_files] AS [Elapsed Days Live Files]
		, fact_detail_elapsed_days.[elapsed_days_conclusion] AS [Elapsed Days Conclusion]
		, fact_detail_paid_detail.interim_costs_payments AS [Interim Costs Payments]
		, fact_detail_paid_detail.fraud_savings AS [Fraud Savings]
		--, fact_matter_summary_current.[last_financial_transaction_date] AS [Last Actioned]
		, dim_detail_client.case_type_classification AS [Case Classification]
		, dim_detail_critical_mi.date_closed AS [Converge Date Closed]
		, dim_detail_core_details.status_on_instruction
		, dim_detail_litigation.reason_for_litigation
		, dim_employee.levelidud AS [Level]
		, dim_employee.postid AS [Post ID]
		, dim_employee.payrollid AS [Payroll ID]
		, fact_employee_days_fte.fte AS [FTE]
		, dim_employee.locationidud AS [Office]
		, dim_employee.postid AS Grade
		, fact_matter_summary_current.[number_of_exceptions_mi] AS [Total MI Exceptions]
		, fact_matter_summary_current.[critical_exceptions_mi] AS [Total Critical MI Exceptions]
		, dim_detail_outcome.final_bill_date_grp
		--, fact_all_time_activity.minutes_recorded AS [Time Recorded]
		, CASE WHEN(fact_matter_summary_current.last_bill_date)='1753-01-01' THEN NULL ELSE fact_matter_summary_current.last_bill_date END AS [Last Bill Date]
		, dim_matter_header_current.[final_bill_date] AS [Date of Final Bill]
		, CASE WHEN dim_fed_hierarchy_history.[leaver]=1 THEN 'Yes' ELSE 'No' END AS [Leaver?]
		, fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting]
		, fact_matter_summary_current.[client_account_balance_of_matter] AS [Client Account Balance of Matter]
		, 1 AS [Number of Records]
		, dim_matter_header_current.ms_only AS [MS Only]
		, 'Qtr' +' '+ CAST(dim_open_case_management_date.open_case_management_fin_quarter_no AS VARCHAR) AS [Financial Quarter Opened]
		, cast(dim_open_case_management_date.open_case_management_fin_year - 1 as varchar) + '/' + cast(dim_open_case_management_date.open_case_management_fin_year as varchar) AS [Financial Year Opened] 
		, 'Qtr' +' '+ CAST(dim_closed_case_management_date.closed_case_management_fin_quarter_no AS VARCHAR) AS [Financial Quarter Closed]
		, cast(dim_closed_case_management_date.closed_case_management_fin_year - 1 as varchar) + '/' + cast(dim_closed_case_management_date.closed_case_management_fin_year as varchar) AS [Financial Year Closed] 
		, CASE WHEN fact_detail_elapsed_days.[elapsed_days_live_files] <=100 THEN '0-100'
				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=200 THEN '101-200'
				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=300 THEN '201-300'
				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=400 THEN '301-400'
				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=600 THEN '401-600'
				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]>600 THEN '601+' END AS [Elapsed Days Live Bandings]
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL AND dim_detail_outcome.date_claim_concluded IS NULL THEN 1 ELSE 0 END AS [Number of Live Instructions]
		--, ROW_NUMBER() OVER(PARTITION BY RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number ORDER BY RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number,dim_client_involvement.[insurerclient_reference] DESC) AS [Multiple Claimant]
		--, dim_date_last_time.last_time_calendar_date
		--, [Total Time Billed]
		, DATEADD(wk, DATEDIFF(wk, 0, dim_detail_core_details.date_instructions_received), 0) AS [Week Commencing] --Monday of each week
		, CAST(DATEPART(wk, dim_detail_core_details.date_instructions_received) AS CHAR (2)) +'/'+ CAST(DATEPART(YEAR,dim_detail_core_details.date_instructions_received) AS CHAR (4)) AS [Week Number]  
		, DATEADD(yy,-4,GETDATE()) AS [GetDate 4 Years] -- this is 4 years from today
		, CASE WHEN dim_matter_worktype.[work_type_name] LIKE '%NHSLA%' THEN 'NHSLA'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN 'PL All'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - Pol%' THEN 'PL Pol'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - OL%' THEN 'PL OL'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Prof Risk%' THEN 'Prof Risk'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'EL %' THEN 'EL'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Motor%' THEN 'Motor'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN 'Disease'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'OI%' THEN 'OI'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'LMT%' THEN 'LMT'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Recovery%' THEN 'Recovery'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Insurance/Costs%' THEN 'Insurance Costs'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Education%' THEN 'Education'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Healthcare%' THEN 'Healthcare'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' THEN 'Claims Handling'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Health and %' THEN 'Health and Safety'
					ELSE 'Other'
			END	[Worktype Group]
		, CONVERT(VARCHAR(3),(dim_matter_header_current.date_opened_case_management)) + '-' + 
                        CONVERT(VARCHAR(4),YEAR(dim_matter_header_current.date_opened_case_management)) AS YearPeriod_MMYY
		, CASE     WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear THEN 1               -- current may to dec
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) > @CurrentYear THEN 1               -- current jan to apr
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear THEN 2               -- historic1  (last year may to dec)
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-1 THEN 2             -- historic1  (last year jan to apr)
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-1 THEN 3             -- historic2  (2 years ago may to dec)
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-2 THEN 3             -- historic2  (2 years ago jan to apr)
                   ELSE 4
                   END 'PeriodType' 
		, CASE WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=3 THEN 'Qtr1'
				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=6 THEN 'Qtr2'
				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=9 THEN 'Qtr3'
				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=12 THEN 'Qtr4'
				ELSE NULL END AS [Calendar Quarter Received]
		, CASE WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=3 THEN 'Qtr1'
				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=6 THEN 'Qtr2'
				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=9 THEN 'Qtr3'
				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=12 THEN 'Qtr4'
				ELSE NULL END AS [Calendar Quarter Opened]
		, CASE WHEN dim_detail_core_details.present_position in ('To be closed/minor balances to be clear','Final bill sent - unpaid')
								or (dim_matter_header_current.date_closed_case_management is not null ) THEN 'Closed' ELSE 'Open' END AS [Status]
		, REPLACE(REPLACE(REPLACE(REPLACE(dim_matter_worktype.[work_type_name],char(9),' '),CHAR(10),' '),CHAR(13), ' '), 'DO NOT USE','') AS [All Work Types]
		, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management) [Date Received/Opened]
		, TimeRecorded.MinutesRecorded AS [Minutes Recorded]
		, TimeRecorded.HoursRecorded AS [Hours Recorded]
		, CASE WHEN dim_detail_outcome.date_costs_settled is not null or dim_matter_header_current.date_closed_case_management is not null THEN 1 ELSE 0 END AS [Sum Total of Concluded Matters]
		, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_costs_settled) as [Conclusion Days]
		, DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_costs_settled) AS [Elapsed Days to Costs Settlement]
		, DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_claim_concluded) AS [Elapsed Days to Outcome]

		, CASE WHEN dim_detail_core_details.[motor_status] = 'Cancelled' THEN 'Closed'
               WHEN --MaxFinalBillPaidDate >= ISNULL(MaxInterimBillDate,MaxFinalBillPaidDate)OR 
					dim_matter_header_current.date_closed_case_management IS NOT NULL 
                   OR (dim_detail_client.[europcartransferred_file]='Yes') THEN 'Closed'
               ELSE 'Open' END AS [Filestatus]

		, dim_instruction_type.instruction_type AS [Instruction Type]
		, CASE WHEN dim_detail_core_details.date_instructions_received BETWEEN DATEADD(Month,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))  AND DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) THEN 1 ELSE 0 END [Rolling 12 Months Concluded]
		, CASE WHEN dim_matter_header_current.date_opened_case_management BETWEEN DATEADD(Month,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))  AND DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) THEN 1 ELSE 0 END [Rolling 12 Months Opened]
		, CASE WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Exclude from reports' THEN  'Exclude from reports'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Discontinued%'THEN 'Repudiated'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Won at trial%'THEN 'Repudiated'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Struck out%'THEN 'Repudiated'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Settled%'THEN 'Settled'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Lost at trial%'THEN 'Settled'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Assessment of damages%'THEN 'Settled'
				ELSE NULL END [Repudiation - outcome]
		, CASE WHEN TimeRecorded.MinutesRecorded<=12 THEN 'Free 12 mins'
				WHEN TimeRecorded.MinutesRecorded<=60 THEN '12 – 60 mins'
				WHEN TimeRecorded.MinutesRecorded<=120 THEN '1 - 2 hours'
				WHEN TimeRecorded.MinutesRecorded<=180 THEN '2 - 3 hours'
				WHEN TimeRecorded.MinutesRecorded<=240 THEN '3 - 4 hours'
				WHEN TimeRecorded.MinutesRecorded<=300 THEN '4 – 5 hours'
				WHEN TimeRecorded.MinutesRecorded>300 THEN 'Over 5 hours'
			ELSE NULL END AS [Time Recorded (Banded)]
		, CASE WHEN TimeRecorded.MinutesRecorded >=12 THEN 'Yes' ELSE 'No' END AS [Free 12 mins Used?]
		, CASE WHEN TimeRecorded.MinutesRecorded <=12 THEN 0 
			WHEN TimeRecorded.MinutesRecorded>12 THEN TimeRecorded.MinutesRecorded-12 END AS [Chargeable Time]
		, ((CASE WHEN TimeRecorded.MinutesRecorded <=12 THEN 0 
			WHEN TimeRecorded.MinutesRecorded>12 THEN TimeRecorded.MinutesRecorded-12 END)*115)/60 AS [Legal Spend exc (VAT)]
		, PartnerHours AS [Total Partner Hours Recorded]
		, NonPartnerHours AS [Total Non-Partner Hours Recorded]
		, [Partner/ConsultantTime] AS [Total Partner/Consultant Hours Recorded]
	    , AssociateHours AS [Total Associate Hours Recorded]
	    , [Solicitor/LegalExecTimeHours] AS [Total Solicitor/LegalExec Hours Recorded]
		, ParalegalHours AS [Total Paralegal Hours Recorded]
		, TraineeHours AS [Total Trainee Hours Recorded]
        , OtherHours AS  [Total Other Hours Recorded]
, CASE WHEN (dim_client.client_code = '00041095' AND dim_matter_worktype.[work_type_code] = '0023') THEN 'Regulatory'
			   WHEN dim_matter_worktype.[work_type_name] LIKE 'EL%' OR dim_matter_worktype.[work_type_name] LIKE 'PL%' OR dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN 'Risk Pooling'
			   WHEN ((dim_matter_worktype.[work_type_name] LIKE 'NHSLA%' OR dim_matter_worktype.[work_type_code] = '0005')
					AND dim_client_involvement.[insuredclient_name] LIKE '%Pennine%' 
					OR dim_matter_header_current.[matter_description] LIKE '%Pennine%') THEN 'Litigation'
			 END AS [Litigation / Regulatory]
		, COALESCE(dim_detail_fraud.[fraud_initial_fraud_type], dim_detail_fraud.[fraud_current_fraud_type], dim_detail_fraud.[fraud_type_ageas], dim_detail_fraud.[fraud_current_secondary_fraud_type], dim_detail_client.[coop_fraud_current_fraud_type], dim_detail_fraud.[fraud_type],dim_detail_fraud.[fraud_type_disease_pre_lit]) AS [Fraud Type]
		, DATEDIFF(DAY,dim_detail_outcome.[date_claimants_costs_received], dim_detail_outcome.date_costs_settled) AS [Days from Date receipt of Claimant's Costs to Date Costs Settled]
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management,dim_matter_header_current.[final_bill_date])
			ELSE NULL END AS [Days from Date opened in FED to date of last bill on file (closed matters)]
		, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_critical_mi.date_closed) AS [Days from Date opened in FED to Converge Date Closed]
		, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management,dim_detail_client.[date_settlement_form_sent_to_zurich]) AS [Days from Date opened in FED to Date Settlement Form Sent to Zurich]
		, CAST((CASE WHEN MONTH(dim_matter_header_current.date_opened_case_management) >= 5 THEN CAST(YEAR(dim_matter_header_current.date_opened_case_management) as varchar) + '/' + CAST((YEAR(dim_matter_header_current.date_opened_case_management) + 1) AS varchar)
                 ELSE CAST((YEAR(dim_matter_header_current.date_opened_case_management) - 1) AS VARCHAR) + '/' + CAST(YEAR(dim_matter_header_current.date_opened_case_management) AS VARCHAR) 
                   END) AS VARCHAR) [Whitbread Year Period]
		, CASE WHEN dim_detail_critical_mi.[litigated]='Yes' OR dim_detail_core_details.[proceedings_issued]='Yes' THEN 'Litigated' ELSE 'Pre-Litigated' END AS [Litigated/Proceedings Issued]
		
		--amended as requested by Ann-Marie 230096
		--, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL AND (dim_detail_outcome.[outcome_of_case] IS NOT NULL OR dim_detail_outcome.[date_claim_concluded] IS NOT NULL) THEN 'Damages Only Settled'
		--	WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL OR dim_detail_outcome.[date_costs_settled] IS NOT NULL OR dim_detail_client.[date_settlement_form_sent_to_zurich] IS NOT NULL  THEN 'Closed' ELSE 'Live' END AS [Status - Disease]
		, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed'
				WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL AND (dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL) THEN 'Damages Only Settled'
				WHEN dim_detail_outcome.[date_claim_concluded] IS NULL AND dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL THEN 'Live'
				ELSE NULL END AS [Status - Disease]
		, COALESCE(dim_detail_core_details.[track],dim_detail_core_details.[zurich_track]) AS [Track - Disease]

		, CASE WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs concluded but recovery outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'Yes' THEN 'PP3 Lead' 
               WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'Yes' THEN 'PP1 Lead'
               WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs concluded but recovery outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'No' THEN 'PP3 Linked'
               WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'No' THEN 'PP1 Linked' END [PP Description]
		, CASE WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] Like '%Credit Hire%' THEN FLOOR(60 * fact_employee_days_fte.fte)	
				WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE 'Motor Multi Track%' THEN FLOOR(40 * fact_employee_days_fte.fte)
                WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) LIKE 'fast track%' THEN FLOOR(50 * fact_employee_days_fte.fte)
				WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) LIKE 'motor%' THEN FLOOR(55 * fact_employee_days_fte.fte)
                WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) LIKE 'multi%' THEN FLOOR(55 * fact_employee_days_fte.fte)
                WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) = 'disease fraud' THEN FLOOR(50 * fact_employee_days_fte.fte)
                WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] IN ('Disease Birmingham','Disease Dartford','Disease Leicester','Disease Liverpool','Disease Midlands')  THEN FLOOR(40 * fact_employee_days_fte.fte)
                WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] IN ('Disease Pre Lit Birmingham','Disease Pre Lit Liverpool') THEN FLOOR(250 * fact_employee_days_fte.fte)
				ELSE FLOOR(30 * fact_employee_days_fte.fte) 
                END [Optimum Case Level]
		, CASE WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] Like '%Credit Hire%' THEN FLOOR(30 * fact_employee_days_fte.fte)	
				ELSE FLOOR(30 * fact_employee_days_fte.fte) 
                END [Fraud Optimum Case Level]
		, CASE WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] Like '%Credit Hire%' THEN FLOOR(60 * fact_employee_days_fte.fte)	
				ELSE FLOOR(30 * fact_employee_days_fte.fte) 
                END [Credit Hire Optimum Case Level]

		, COALESCE(dim_detail_claim.[claimants_solicitors_firm_name ], dim_claimant_thirdparty_involvement.claimantsols_name) AS [Claimant's Solicitors Firm]
		, CAST([DateClaimConcluded].fin_year-1 AS VARCHAR)+'/'+CAST([DateClaimConcluded].fin_year AS VARCHAR) AS [FY Date Claim Concluded]
		, CAST([DateCostsSettled].fin_year-1 AS VARCHAR)+'/'+CAST([DateCostsSettled].fin_year  AS VARCHAR) AS [FY Date Costs Settled]
		, CAST([DateInstructionsReceived].fin_year-1 AS VARCHAR)+'/'+CAST([DateInstructionsReceived].fin_year  AS VARCHAR) AS [FY Date Instructions Received]
		, fact_matter_summary_current.time_billed/60 time_billed
		
--into ss.GeneralDataFile
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON red_dw.dbo.dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement ON red_dw.dbo.dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_incident ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_litigation ON dim_detail_litigation.dim_detail_litigation_key = fact_dimension_main.dim_detail_litigation_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_experts_involvement ON dim_experts_involvement.dim_experts_involvemen_key = fact_dimension_main.dim_experts_involvemen_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND getdate() BETWEEN dss_start_date AND dss_end_date 
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary ON red_dw.dbo.fact_matter_summary.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_last_bill_date ON dim_last_bill_date.dim_last_bill_date_key=fact_matter_summary.dim_last_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key=fact_dimension_main.dim_detail_critical_mi_key 
LEFT OUTER JOIN red_dw.dbo.dim_open_case_management_date  ON dim_open_case_management_date.calendar_date = dim_matter_header_current.date_opened_case_management
LEFT OUTER JOIN red_dw.dbo.dim_closed_case_management_date  ON dim_closed_case_management_date.calendar_date = dim_matter_header_current.date_closed_case_management
LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
--LEFT OUTER JOIN [red_dw].[dbo].[fact_all_time_activity] ON fact_all_time_activity.master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key=fact_dimension_main.dim_detail_fraud_key
LEFT OUTER JOIN red_dw.[dbo].[dim_instruction_type] ON [dim_instruction_type].[dim_instruction_type_key]=dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.fact_employee_days_fte ON fact_employee_days_fte.dim_fed_hierarchy_history_key=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key

LEFT OUTER JOIN (SELECT fact_dimension_main.master_fact_key [fact_key], 
						dim_client.contact_salutation [claimant1_contact_salutation],
						dim_client.addresse [claimant1_addresse],
						dim_client.address_line_1 [claimant1_address_line_1],
						dim_client.address_line_2 [claimant1_address_line_2],
						dim_client.address_line_3 [claimant1_address_line_3],
						dim_client.address_line_4 [claimant1_address_line_4],
						dim_client.postcode [claimant1_postcode]
				FROM red_dw.dbo.dim_claimant_thirdparty_involvement
				INNER join red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
				INNER join red_dw.dbo.dim_involvement_full ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
				INNER join red_dw.dbo.dim_client ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
				WHERE dim_client.dim_client_key != 0 ) AS ClaimantsAddress ON fact_dimension_main.master_fact_key=ClaimantsAddress.fact_key
		LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
								,SUM(minutes_recorded) AS [MinutesRecorded]
								,SUM(minutes_recorded)/60 AS [HoursRecorded]
						FROM red_dw.dbo.fact_chargeable_time_activity
						INNER join red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
						WHERE  minutes_recorded<>0
						AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
						GROUP BY client_code,matter_number,fact_chargeable_time_activity.master_fact_key
		) AS TimeRecorded ON TimeRecorded.master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key


		LEFT OUTER JOIN (		SELECT    client_code
                                          , matter_number
										  , master_fact_key
										  , ISNULL(SUM(PartnerTime),0)/60 AS PartnerHours
                                          , ISNULL(SUM(NonPartnerTime),0)/60 AS NonPartnerHours
                                          , ISNULL(SUM([Partner/ConsultantTime]),0)/60 AS [Partner/ConsultantTime]
										  , ISNULL(SUM(AssociateTime),0)/60 AS AssociateHours
										  , ISNULL(SUM([Solicitor/LegalExecTime]),0)/60 AS [Solicitor/LegalExecTimeHours]
										  , ISNULL(SUM(ParalegalTime),0)/60 AS ParalegalHours
										  , ISNULL(SUM(TraineeTime),0)/60 AS TraineeHours
                                          , ISNULL(SUM(OtherTime),0)/60 AS OtherHours
                                  FROM      ( SELECT    client_code 
                                                        , matter_number 
														, master_fact_key

														, ( CASE WHEN Partners.jobtitle LIKE '%Partner%' THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS PartnerTime 
                                                        , ( CASE WHEN Partners.jobtitle NOT LIKE '%Partner%' OR jobtitle IS NULL THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS NonPartnerTime
                                                        , ( CASE WHEN Partners.jobtitle LIKE '%Partner%' OR Partners.jobtitle LIKE '%Consultant%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS  [Partner/ConsultantTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Associate%' THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS AssociateTime
														, ( CASE WHEN Partners.jobtitle LIKE 'Solicitor%' OR Partners.jobtitle LIKE '%Legal Executive%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [Solicitor/LegalExecTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Paralegal%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [ParalegalTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Trainee Solicitor%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [TraineeTime]

                                                        , ( CASE WHEN Partners.jobtitle NOT LIKE '%Partner%' 
														AND Partners.jobtitle NOT LIKE '%Consultant%' 
														AND Partners.jobtitle NOT LIKE '%Associate%' 
														AND Partners.jobtitle NOT LIKE '%Solicitor%'
														AND Partners.jobtitle NOT LIKE '%Legal Executive%' 
														AND Partners.jobtitle NOT LIKE '%Paralegal%' 
														AND Partners.jobtitle NOT LIKE '%Trainee%' 
														OR  jobtitle IS NULL THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS OtherTime
                                              FROM      red_dw.dbo.fact_chargeable_time_activity
                                              LEFT OUTER JOIN ( SELECT DISTINCT dim_fed_hierarchy_history_key
																			 , jobtitle
																FROM red_dw.dbo.dim_fed_hierarchy_history 
														) AS Partners ON Partners.dim_fed_hierarchy_history_key = fact_chargeable_time_activity.dim_fed_hierarchy_history_key
											  LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key        
                                              WHERE     minutes_recorded<>0
														AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
                                              GROUP BY  client_code, matter_number, master_fact_key, Partners.jobtitle
                                            ) AS AllTime
                                  GROUP BY  AllTime.client_code, AllTime.matter_number, AllTime.master_fact_key)  AS [Partner/NonPartnerHoursRecorded] ON [Partner/NonPartnerHoursRecorded].master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateClaimConcluded] ON CAST(dim_detail_outcome.date_claim_concluded AS DATE) = [DateClaimConcluded].calendar_date
		LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateCostsSettled] ON CAST(dim_detail_outcome.date_costs_settled AS DATE) = [DateCostsSettled].calendar_date
		LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateInstructionsReceived] ON CAST(dim_detail_core_details.date_instructions_received  AS DATE) = [DateInstructionsReceived].calendar_date
		--LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key

WHERE 

ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.matter_number <>'ML'
AND dim_client.client_code  NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
--AND dim_client.client_code='W15419' AND dim_matter_header_current.matter_number='00000464'

GROUP BY
  RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number 
		, fact_dimension_main.client_code 
		--, dim_matter_header_current.ms_client_code
		, fact_dimension_main.matter_number 
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.client_code),'0',' ') ),' ','0') 
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.matter_number),'0',' ') ),' ','0')
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.client_code),'0',' ') ),' ','0')+'-'+REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.matter_number),'0',' ') ),' ','0')
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]),'0',' ') ),' ','0')
		, REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]),'0',' ') ),' ','0') 
		, REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]),'0',' ') ),' ','0')+'-'+REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]),'0',' ') ),' ','0') 
		, dim_matter_header_current.[matter_description] 
		, dim_matter_header_current.date_opened_case_management 
		, dim_matter_header_current.date_opened_practice_management 
		, dim_matter_header_current.date_closed_case_management 
		, dim_matter_header_current.date_closed_practice_management 
		, dim_detail_critical_mi.status_2
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END
		, dim_detail_core_details.date_instructions_received 
		, dim_detail_outcome.date_claim_concluded 
		, dim_detail_outcome.claim_status
		, dim_detail_outcome.[outcome_of_case] 
		, dim_fed_hierarchy_history.[display_name] 
		, dim_fed_hierarchy_history.[name]
		, dim_fed_hierarchy_history.fte
		, dim_fed_hierarchy_history.[worksforname]
		, dim_detail_practice_area.[bcm_name]
		, dim_fed_hierarchy_history.[reportingbcmname] 
		, dim_fed_hierarchy_history.[hierarchylevel2hist] 
		, dim_fed_hierarchy_history.[hierarchylevel3hist]
		, dim_fed_hierarchy_history.[hierarchylevel4hist] 
		, dim_matter_header_current.[branch_name] 
		, dim_department.[department_code]
		, dim_department.[department_name] 
		, dim_matter_worktype.[work_type_code] 
		, dim_matter_worktype.[work_type_name] 
		, dim_client.client_group_name
		, dim_client.client_name 
		, dim_client.[sector]
		, dim_client.segment 
		, dim_client.sub_sector
		, dim_claimant_thirdparty_involvement.claimantsols_name 
		, dim_detail_core_details.claimants_solicitors_name 
		, dim_detail_core_details.[name_of_claimants_firm]
		, dim_claimant_thirdparty_involvement.[claimant_name] 
		, dim_detail_core_details.[claimants_date_of_birth]
		, ClaimantsAddress.[claimant1_postcode]
		, dim_detail_claim.[number_of_claimants] 
		, dim_detail_core_details.zurich_policy_holdername_of_insured 
		, dim_client_involvement.[insurerclient_name]
		, dim_client_involvement.[insurerclient_reference] 
		, dim_detail_core_details.insured_departmentdepot_postcode
		, dim_detail_core_details.[insured_departmentdepot] 
		, dim_client_involvement.[insuredclient_name]
		, dim_client_involvement.[insuredclient_reference]
		, dim_court_involvement.court_name 
		, dim_court_involvement.court_reference 
		, dim_detail_core_details.present_position 
		, dim_detail_core_details.track 
		, dim_detail_core_details.suspicion_of_fraud 
		, dim_detail_core_details.referral_reason 
		, dim_detail_core_details.[fixed_fee] 
		, dim_detail_core_details.proceedings_issued 
		, dim_detail_core_details.date_proceedings_issued 
		, dim_detail_claim.accident_location 
		, dim_detail_core_details.incident_date 
		, dim_detail_core_details.[incident_location] 
		, dim_detail_core_details.injury_type 
		, dim_detail_incident.[description_of_injury_v] 
		, dim_detail_core_details.[brief_description_of_injury]
		, dim_experts_involvement.engineer_name 
		, dim_detail_core_details.credit_hire 
		, dim_agents_involvement.cho_name
		, dim_detail_hire_details.[cho] 
		, dim_detail_hire_details.cho_hire_start_date 
		, dim_detail_hire_details.chp_hire_end_date 
		, dim_detail_health.leadfollow 
		, dim_detail_core_details.is_this_a_linked_file 
		, dim_detail_core_details.[is_this_the_lead_file]
		, dim_detail_core_details.lead_file_matter_number_client_matter_number 
		, dim_detail_core_details.[associated_matter_numbers]
		, dim_detail_claim.is_this_a_work_referral 
		, dim_detail_claim.[number_of_claimants]
		, dim_detail_client.[coop_fraud_status] 
		, dim_detail_client.weightmans_comments 
		, dim_detail_core_details.date_of_current_estimate_to_complete_retainer
		, dim_detail_core_details.date_letter_of_claim 
		, dim_detail_core_details.[date_initial_report_sent] 
		, dim_detail_core_details.[date_pre_trial_report] 
		, dim_detail_court.[date_of_trial] 
		, dim_detail_court.[trial_window] 
		, dim_detail_core_details.[date_start_of_trial_window] 
		, dim_detail_court.[date_end_of_trial_window] 
		, dim_detail_court.[infant_approval] 
		, dim_detail_core_details.grpageas_motor_moj_stage 
		, dim_detail_core_details.sabre_reason_for_instructions 
		, dim_detail_core_details.date_subsequent_sla_report_sent 
		, dim_detail_core_details.date_the_closure_report_sent 
		, dim_detail_core_details.[is_there_an_issue_on_liability] 
		, dim_detail_core_details.delegated 
		, dim_detail_core_details.ccnumber 
		, dim_detail_claim.live_case_status
		, dim_detail_litigation.litigated 
		, dim_detail_critical_mi.claim_status 
		, dim_detail_critical_mi.closure_reason
		, dim_detail_outcome.[date_claimants_costs_received] 
		, dim_detail_outcome.date_costs_settled 
		, fact_detail_elapsed_days.[elapsed_days_live_files] 
		, fact_detail_elapsed_days.[elapsed_days_conclusion] 
		, fact_detail_paid_detail.interim_costs_payments 
		, fact_detail_paid_detail.fraud_savings
		, dim_detail_client.case_type_classification 
		--, fact_matter_summary_current.[last_financial_transaction_date]
		, dim_detail_critical_mi.date_closed 
		, dim_detail_core_details.status_on_instruction
		, dim_matter_header_current.[final_bill_date]
		, dim_detail_outcome.final_bill_date_grp 
		--, fact_matter_summary.[last_time_transaction_date] 
		--, fact_all_time_activity.minutes_recorded 
		, dim_detail_litigation.reason_for_litigation
		, dim_employee.levelidud
		, dim_employee.postid
		, dim_employee.payrollid
		, fact_employee_days_fte.fte
		, dim_employee.locationidud
		, fact_matter_summary_current.[number_of_exceptions_mi] 
		, fact_matter_summary_current.[critical_exceptions_mi]
		, fact_matter_summary_current.[client_account_balance_of_matter]
		, dim_matter_header_current.ms_only
		, 'Qtr' +' '+ CAST(dim_open_case_management_date.open_case_management_fin_quarter_no AS VARCHAR) 
		, cast(dim_open_case_management_date.open_case_management_fin_year - 1 as varchar) + '/' + cast(dim_open_case_management_date.open_case_management_fin_year as varchar) 
		, 'Qtr' +' '+ CAST(dim_closed_case_management_date.closed_case_management_fin_quarter_no AS VARCHAR) 
		, cast(dim_closed_case_management_date.closed_case_management_fin_year - 1 as varchar) + '/' + cast(dim_closed_case_management_date.closed_case_management_fin_year as varchar) 
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL AND dim_detail_outcome.date_claim_concluded IS NULL THEN 1 ELSE 0 END
		, DATEADD(wk, DATEDIFF(wk, 0, dim_detail_core_details.date_instructions_received), 0) 
		, CAST(DATEPART(wk, dim_detail_core_details.date_instructions_received) AS CHAR (2)) +'/'+ CAST(DATEPART(YEAR,dim_detail_core_details.date_instructions_received) AS CHAR (4)) 
		, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management)
		,  CASE WHEN dim_matter_worktype.[work_type_name] LIKE '%NHSLA%' THEN 'NHSLA'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN 'PL All'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - Pol%' THEN 'PL Pol'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - OL%' THEN 'PL OL'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Prof Risk%' THEN 'Prof Risk'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'EL %' THEN 'EL'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Motor%' THEN 'Motor'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN 'Disease'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'OI%' THEN 'OI'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'LMT%' THEN 'LMT'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Recovery%' THEN 'Recovery'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Insurance/Costs%' THEN 'Insurance Costs'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Education%' THEN 'Education'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Healthcare%' THEN 'Healthcare'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' THEN 'Claims Handling'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Health and %' THEN 'Health and Safety'
					ELSE 'Other'
					END
		, CONVERT(VARCHAR(3),(dim_matter_header_current.date_opened_case_management)) + '-' + 
                        CONVERT(VARCHAR(4),YEAR(dim_matter_header_current.date_opened_case_management))  
	, CASE     WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear THEN 1               -- current may to dec
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) > @CurrentYear THEN 1               -- current jan to apr
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear THEN 2               -- historic1  (last year may to dec)
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-1 THEN 2             -- historic1  (last year jan to apr)
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-1 THEN 3             -- historic2  (2 years ago may to dec)
                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-2 THEN 3             -- historic2  (2 years ago jan to apr)
                   ELSE 4
                   END 
	, CASE WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=3 THEN 'Qtr1'
				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=6 THEN 'Qtr2'
				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=9 THEN 'Qtr3'
				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=12 THEN 'Qtr4'
				ELSE NULL END
	, CASE WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=3 THEN 'Qtr1'
				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=6 THEN 'Qtr2'
				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=9 THEN 'Qtr3'
				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=12 THEN 'Qtr4'
				ELSE NULL END
	, CASE WHEN dim_detail_core_details.present_position in ('To be closed/minor balances to be clear','Final bill sent - unpaid')
								or (dim_matter_header_current.date_closed_case_management is not null ) THEN 'Closed' ELSE 'Open' END 
	, REPLACE(REPLACE(REPLACE(REPLACE(dim_matter_worktype.[work_type_name],char(9),' '),CHAR(10),' '),CHAR(13), ' '), 'DO NOT USE','')
	, TimeRecorded.MinutesRecorded 
	, TimeRecorded.HoursRecorded
	, CASE WHEN dim_detail_outcome.date_costs_settled is not null or dim_matter_header_current.date_closed_case_management is not null THEN 1 ELSE 0 END 
	, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_costs_settled) 
	, DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_costs_settled) 
	, DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_claim_concluded) 
	, CASE WHEN dim_detail_core_details.[motor_status] = 'Cancelled' THEN 'Closed'
               WHEN --MaxFinalBillPaidDate >= ISNULL(MaxInterimBillDate,MaxFinalBillPaidDate)OR 
					dim_matter_header_current.date_closed_case_management IS NOT NULL 
                   OR (dim_detail_client.[europcartransferred_file]='Yes') THEN 'Closed'
               ELSE 'Open' END
	, dim_instruction_type.instruction_type
	, CASE WHEN dim_detail_core_details.date_instructions_received BETWEEN DATEADD(Month,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))  AND DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) THEN 1 ELSE 0 END 
	, CASE WHEN dim_matter_header_current.date_opened_case_management BETWEEN DATEADD(Month,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))  AND DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) THEN 1 ELSE 0 END 
	, CASE WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Exclude from reports' THEN  'Exclude from reports'
		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Discontinued%'THEN 'Repudiated'
		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Won at trial%'THEN 'Repudiated'
		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Struck out%'THEN 'Repudiated'
		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Settled%'THEN 'Settled'
		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Lost at trial%'THEN 'Settled'
		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Assessment of damages%'THEN 'Settled'
	ELSE NULL END
	,CASE WHEN TimeRecorded.MinutesRecorded<=12 THEN 'Free 12 mins'
				WHEN TimeRecorded.MinutesRecorded<=60 THEN '12 – 60 mins'
				WHEN TimeRecorded.MinutesRecorded<=120 THEN '1 - 2 hours'
				WHEN TimeRecorded.MinutesRecorded<=180 THEN '2 - 3 hours'
				WHEN TimeRecorded.MinutesRecorded<=240 THEN '3 - 4 hours'
				WHEN TimeRecorded.MinutesRecorded<=300 THEN '4 – 5 hours'
				WHEN TimeRecorded.MinutesRecorded>300 THEN 'Over 5 hours'
			ELSE NULL END
		, CASE WHEN TimeRecorded.MinutesRecorded >=12 THEN 'Yes' ELSE 'No' END 
		, CASE WHEN TimeRecorded.MinutesRecorded <=12 THEN 0 
			WHEN TimeRecorded.MinutesRecorded>12 THEN TimeRecorded.MinutesRecorded-12 END 
		, ((CASE WHEN TimeRecorded.MinutesRecorded <=12 THEN 0 
			WHEN TimeRecorded.MinutesRecorded>12 THEN TimeRecorded.MinutesRecorded-12 END)*115)/60 
		, PartnerHours
		, NonPartnerHours
		, [Partner/ConsultantTime] 
	    , AssociateHours 
	    , [Solicitor/LegalExecTimeHours] 
		, ParalegalHours 
		, TraineeHours 
        , OtherHours 
, CASE WHEN (dim_client.client_code = '00041095' AND dim_matter_worktype.[work_type_code] = '0023') THEN 'Regulatory'
			   WHEN dim_matter_worktype.[work_type_name] LIKE 'EL%' OR dim_matter_worktype.[work_type_name] LIKE 'PL%' OR dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN 'Risk Pooling'
			   WHEN ((dim_matter_worktype.[work_type_name] LIKE 'NHSLA%' OR dim_matter_worktype.[work_type_code] = '0005')
					AND dim_client_involvement.[insuredclient_name] LIKE '%Pennine%' 
					OR dim_matter_header_current.[matter_description] LIKE '%Pennine%') THEN 'Litigation'
			 END
		, COALESCE(dim_detail_fraud.[fraud_initial_fraud_type], dim_detail_fraud.[fraud_current_fraud_type], dim_detail_fraud.[fraud_type_ageas], dim_detail_fraud.[fraud_current_secondary_fraud_type], dim_detail_client.[coop_fraud_current_fraud_type], dim_detail_fraud.[fraud_type],dim_detail_fraud.[fraud_type_disease_pre_lit])
		, DATEDIFF(DAY,dim_detail_outcome.[date_claimants_costs_received], dim_detail_outcome.date_costs_settled) 
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management,dim_matter_header_current.[final_bill_date])
			ELSE NULL END 
		, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_critical_mi.date_closed)
		, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management,dim_detail_client.[date_settlement_form_sent_to_zurich]) 
		, CASE WHEN dim_detail_critical_mi.[litigated]='Yes' OR dim_detail_core_details.[proceedings_issued]='Yes' THEN 'Litigated' ELSE 'Pre-Litigated' END 
		, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed'
				WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL AND (dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL) THEN 'Damages Only Settled'
				WHEN dim_detail_outcome.[date_claim_concluded] IS NULL AND dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL THEN 'Live'
				ELSE NULL END 
		, COALESCE(dim_detail_core_details.[track],dim_detail_core_details.[zurich_track]) 
		,  CASE WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs concluded but recovery outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'Yes' THEN 'PP3 Lead' 
               WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'Yes' THEN 'PP1 Lead'
               WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs concluded but recovery outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'No' THEN 'PP3 Linked'
               WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'No' THEN 'PP1 Linked' END
		, COALESCE(dim_detail_claim.[claimants_solicitors_firm_name ], dim_claimant_thirdparty_involvement.claimantsols_name) 
		, CAST([DateClaimConcluded].fin_year-1 AS VARCHAR)+'/'+CAST([DateClaimConcluded].fin_year AS VARCHAR) 
		, CAST([DateCostsSettled].fin_year-1 AS VARCHAR)+'/'+CAST([DateCostsSettled].fin_year  AS VARCHAR) 
		, CASE WHEN dim_fed_hierarchy_history.[leaver]=1 THEN 'Yes' ELSE 'No' END
		,fact_matter_summary_current.last_bill_date
		,fact_matter_summary_current.last_time_transaction_date
		,fact_matter_summary_current.time_billed
				, CAST([DateInstructionsReceived].fin_year-1 AS VARCHAR)+'/'+CAST([DateInstructionsReceived].fin_year  AS VARCHAR) 

--INSERT INTO Omni.ProcTiming (Procname, TimeEnd)
--VALUES ('[Omni].[GeneralDataFile]', GETDATE())

END


GO
