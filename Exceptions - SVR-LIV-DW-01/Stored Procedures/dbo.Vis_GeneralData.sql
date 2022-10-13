SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2018-06-05
Description:		Claims Division MI to drive the Tableau Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
CREATE PROCEDURE [dbo].[Vis_GeneralData]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT 

RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_matter_header_current.[matter_description] AS [Matter Description]
		, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
		, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Open/Closed Case Status]
		, dim_instruction_type.instruction_type AS [Instruction Type]
		, dim_detail_core_details.date_instructions_received AS [Date Instructions Received]
		, dim_detail_outcome.date_costs_settled AS [Date Costs Settled]
		, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
		, dim_fed_hierarchy_history.[name] AS [Case Manager]
		, dim_employee.locationidud AS [Office]
		, dim_fed_hierarchy_history.[hierarchylevel2hist] [Division]
		, dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department]
		, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
		, dim_department.department_name AS [Matter Category]
		, dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
		, dim_detail_core_details.status_on_instruction AS [Status On Instruction]
		, dim_detail_core_details.[is_there_an_issue_on_liability] AS [Issue On Liability]
		, dim_detail_core_details.delegated AS Delegated
		, fact_finance_summary.[fixed_fee_amount] AS [Fixed Fee Amount]
		, dim_detail_finance.[output_wip_fee_arrangement] AS [Output WIP Fee Arrangement]
		, dim_detail_finance.[output_wip_percentage_complete] AS [Output WIP % Complete]
		, dim_detail_core_details.is_this_a_linked_file AS [Linked File]
		, dim_detail_core_details.lead_file_matter_number_client_matter_number [Lead File Client Matter Number]
		, dim_detail_core_details.[associated_matter_numbers] [Associated Matter Number]
		, dim_detail_core_details.clients_claims_handler_surname_forename AS [Clients Claim Handler Full Name]
		, dim_matter_worktype.[work_type_code] AS [Work Type Code]
		, dim_matter_worktype.[work_type_name] AS [Work Type]
		, dim_matter_worktype.[work_type_group] AS [Work Type Group]
		, dim_client.client_group_name AS [Client Group Name]
		, dim_client.client_name AS [Client Name]
		, dim_client.segment AS [Client Segment]
		, dim_client.[sector] AS [Client Sector]
		, dim_client.sub_sector AS [Client Sub-sector]
		, dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant's Solicitor]
		, dim_client_involvement.[insurerclient_name] AS [Insurer Client Name]
		, dim_client_involvement.[insuredclient_name] AS [Insured Client Name]
		, dim_client_involvement.insurerclient_reference AS [Insurer Client Reference]
		, dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference]
		, dim_detail_core_details.insured_sector AS [Insured Sector]
		, dim_detail_core_details.present_position AS [Present Position]
		, dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
		, dim_detail_core_details.track AS [Track]
		, dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?]
		, dim_detail_core_details.referral_reason AS [Referral Reason]
		, dim_detail_core_details.[fixed_fee] AS [Fixed Fee]
		, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_core_details.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.credit_hire AS [Credit Hire]
		, dim_detail_claim.accident_location AS [Accident Location]
		, dim_detail_core_details.incident_date AS [Incident Date]
		, dim_detail_core_details.[brief_description_of_injury] AS [Description of Injury]
		, TimeRecorded.HoursRecorded AS [Hours Recorded]
		, fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting]
		, fact_matter_summary_current.last_bill_date AS [Last Bill Date]
		, dim_matter_header_current.[final_bill_date] AS [Date of Final Bill]
		, dim_detail_claim.[cfa_entered_into_before_1_april_2013] AS [CFA Entered before 1st April 2013]
		, fact_finance_summary.total_reserve AS [Total Reserve]
		, fact_finance_summary.[total_reserve_net] AS [Total Reserve (Net)]
		, fact_finance_summary.damages_reserve AS [Damages Reserve]
		, fact_finance_summary.tp_costs_reserve AS [TP Costs Reserve]
		, fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
		, fact_finance_summary.[other_defendants_costs_reserve] AS [Other Defendants Costs Reserve]
		, fact_finance_summary.damages_paid AS [Damages Paid]
		, dim_detail_outcome.date_referral_to_costs_unit AS [Date Referral to Costs Unit]
		, fact_detail_claim.[claimant_sols_total_costs_sols_claimed] AS [Total third party costs claimed (the sum of TRA094+NMI599+NMI600)]
		, fact_finance_summary.[total_tp_costs_paid] AS [Total third party costs paid (sum of TRA072+NMI143+NMI379)]
		, fact_finance_summary.[detailed_assessment_costs_claimed_by_claimant] AS [Detailed Assessment Costs Claimed by Claimant]
		, fact_finance_summary.detailed_assessment_costs_paid AS [Detailed Assessment Costs Paid]
		, fact_finance_summary.[costs_claimed_by_another_defendant] AS [Costs Claimed by another Defendant]
		--, fact_detail_cost_budgeting.[costs_paid_to_another_defendant] AS [Costs Paid to Another Defendant]
		, fact_finance_summary.[total_recovery] AS [Total Recovery (sum of NMI112+NMI135+NMI136+NMI137)]
		, fact_detail_paid_detail.[amount_hire_paid] AS [Hire Paid]
		, fact_finance_summary.[total_paid] AS [Total Paid]
		, fact_finance_summary.[total_amount_billed] AS [Total Amount Billed]
		, fact_finance_summary.[defence_costs_billed] AS [Defence Costs Billed]
		, fact_finance_summary.[disbursements_billed] AS [Disbursements Billed]
		, fact_matter_summary_current.[client_account_balance_of_matter] AS [Client Account Balance of Matter]
		, fact_detail_elapsed_days.[elapsed_days_live_files] AS [Elapsed Days Live Files]
		, DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_claim_concluded) AS [Elapsed Days to Outcome]
		--, CASE WHEN(fact_matter_summary_current.last_bill_date)='1753-01-01' THEN NULL ELSE fact_matter_summary_current.last_bill_date END AS [Last Bill Date]
		--, CASE WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Exclude from reports' THEN  'Exclude from reports'
		--		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Discontinued%' THEN 'Repudiated'
		--		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Won at trial%' THEN 'Repudiated'
		--		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Struck out%' THEN 'Repudiated'
		--		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Settled%' THEN 'Settled'
		--		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Lost at trial%' THEN 'Settled'
		--		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Assessment of damages%' THEN 'Settled'
		--		ELSE NULL END [Repudiation - outcome]
		, CASE  WHEN dim_fed_hierarchy_history.[leaver]=1 THEN 'Yes' ELSE 'No' END AS [Leaver?]
		, fact_matter_summary_current.time_billed/60 AS [Time Billed]
		, [Partner/ConsultantTime] AS [Total Partner/Consultant Hours Recorded]
	    , AssociateHours AS [Total Associate Hours Recorded]
	    , [Solicitor/LegalExecTimeHours] AS [Total Solicitor/LegalExec Hours Recorded]
		, ParalegalHours AS [Total Paralegal Hours Recorded]
		, TraineeHours AS [Total Trainee Hours Recorded]
        , OtherHours AS  [Total Other Hours Recorded]
		, dim_court_involvement.court_name AS [Court Name]

--INTO generaldatafile20180810



FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key=fact_dimension_main.dim_fed_hierarchy_history_key --AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND getdate() BETWEEN dss_start_date AND dss_end_date 

LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON red_dw.dbo.dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.[dbo].[dim_instruction_type] ON [dim_instruction_type].[dim_instruction_type_key]=dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement ON red_dw.dbo.dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
				  ,SUM(minutes_recorded)/60 AS [HoursRecorded]
				  FROM red_dw.dbo.fact_chargeable_time_activity
				  INNER join red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
				  WHERE  minutes_recorded<>0
				  AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE())  OR dim_matter_header_current.date_closed_case_management IS NULL)
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
WHERE 
LOWER(ISNULL(dim_detail_outcome.outcome_of_case,'')) <> 'exclude from reports'
--AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND dim_matter_header_current.matter_number <>'ML'
AND dim_client.client_code  NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
END

GO
