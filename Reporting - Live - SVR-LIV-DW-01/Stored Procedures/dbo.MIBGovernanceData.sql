SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*
===================================================
===================================================
Author:				Emily Smith
Created Date:		2017-06-15
Description:		MIB Governance Data - used for all MIB new contract reports, master query
Current Version:	Initial Create
====================================================
====================================================
LD 20170831  Wrapped some the [mib_claimants_name] field in an ISNULL statement
JL 16-01-2018 - court location has more than one court in fed, so I have used a different table only select court 1 see 1.1 below
ES 23-01-2018 - added hours split by job title
ES 03-07-2018 - removed as requested by HF, as not sure why it was added 
ES 06-07-2018 - added a case statement to use the filter in ssrs
ES 06/08/2018 - Added claimant postcode, DA lifecycle and claimant solicitor from directory
*/
 
CREATE PROCEDURE [dbo].[MIBGovernanceData]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  SELECT   
				CASE WHEN dim_matter_header_current.date_opened_case_management<'2017-07-01' THEN '2015 Contract'
                     WHEN dim_matter_header_current.date_opened_case_management>='2017-07-01' THEN '2017 Contract' END AS [Contract]
			  , RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
			  , fact_dimension_main.client_code AS [Client Code]
              , fact_dimension_main.matter_number AS [Matter Number]
              , dim_instruction_type.instruction_type AS [Instruction Type]
              , dim_detail_client.[service_category] AS [Service Category]
              , dim_matter_header_current.matter_description AS [Matter Description]
              , dim_matter_header_current.date_opened_case_management AS [Date File Opened]
			  , dim_detail_core_details.[date_instructions_received] AS [Date Solicitor Received]
              , dim_matter_header_current.date_closed_case_management AS [Date File Closed]
              , dim_detail_core_details.[motor_date_of_instructions_being_reopened] AS [Date Re-opened]
              , dim_fed_hierarchy_history.[name] AS [Case Manager]
              , dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
              , dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department]
              , dim_fed_hierarchy_history.[hierarchylevel2hist] AS [Division]
			  , dim_detail_core_details.[is_this_the_lead_file] AS [Is this a lead file?]
              , dim_detail_client.[mib_instruction_date] AS [MIB Instruction Date]
              , dim_client_involvement.insurerclient_reference AS [MIB Reference]
              , dim_detail_client.[mib_claim_number] AS [MIB Claim Number]
              , dim_detail_client.[mib_claims_area] AS [MIB Claims Area]
              , dim_detail_core_details.[clients_claims_handler_surname_forename] AS [MIB Handler Name]
              , dim_detail_client.[mib_handler_code] AS [MIB Handler Code]
              , dim_detail_client.[mib_claimants_name] AS [MIB Claimant's Name]
              , dim_detail_core_details.[mib_grp_type_of_injury] AS [MIB Type of Injury]
              , dim_detail_core_details.[mib_solicitor] AS [MIB Solicitor]
              , dim_detail_client.[mib_claimants_solicitors_firm_name] AS [MIB Claimant's Solicitors Firm Name]
              , dim_detail_client.[mib_profile_of_work] AS [MIB Profile of Work]
              , dim_detail_client.[mib_secondary_categories] AS [MIB Secondary Categories]
              , CONVERT(VARCHAR(12),dim_detail_core_details.[claimants_date_of_birth],103) AS [Claimant's DOB]
              , CONVERT(VARCHAR(12),dim_detail_core_details.incident_date,103) AS [Incident Date]
              , COALESCE(dim_detail_core_details.[delegated],dim_detail_core_details.[mib_grp_delegated_authority]) AS [Delegated Authority]
			  , dim_detail_core_details.track AS [Track]
              , dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
              , dim_detail_client.[mib_court_location] AS [MIB Court Location]
              , dim_detail_court.[date_of_trial] AS [Date of Trial]
              , cast(dim_detail_court.[date_of_first_day_of_trial_window]as date) AS [Date of First Trial Window]
			  , cast(dim_detail_court.date_end_of_trial_window as date) AS [Trial Window End]
			  , dim_involvement_full.name AS [Court Name] /*--this selects court 1 as per Helen fox see ticket 285394 1.1 */
              --, dim_court_involvement.court_name AS [Court Name] /*-- not used as has multi courts 1.1*/
              , dim_detail_core_details.present_position AS [Present Position]
              , dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of Fraud]
              , dim_detail_core_details.[credit_hire] AS [Credit Hire]
              , dim_detail_hire_details.[credit_hire_organisation_cho] AS [Credit Hire Organisation]
              , dim_detail_core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler] AS [Date Initial Acknowledgement to Claims Handler]
              , dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
              , dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension for the Initial Report?]
              , dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Date Subsequent Report Sent]
              , dim_detail_core_details.[date_the_closure_report_sent] AS [Date Closure Report Sent]
              , fact_finance_summary.[damages_reserve] AS [FED Damages Reserve]
              , fact_finance_summary.[tp_costs_reserve] AS [FED TP costs Reserve]
              , fact_finance_summary.[defence_costs_reserve] AS [FED Defence Costs Reserve]
              , fact_finance_summary.[total_damages_and_tp_costs_reserve] AS [Total Damages and Claimant's Costs Reserve]
              , fact_detail_reserve_detail.[nhs_mib_reserve_prior_to_settlement] AS [MIB Reserve Prior to Settlement]
              , fact_detail_client.[colossus_valuation] AS [MIB Colossus Valuation]
              , dim_detail_client.[mib_colossus_exception] AS [MIB Colossus Exception]
              , fact_detail_client.[mib_original_colossus] AS [MIB Colossus Original]
              , CASE WHEN RTRIM(dim_detail_client.[mib_colossus_exception])='Detailed assessment' THEN 1
                        WHEN RTRIM(dim_detail_client.[mib_colossus_exception])='Instructed by MIB' THEN 2
                        WHEN RTRIM(dim_detail_client.[mib_colossus_exception])='10% exception case' THEN 3 END AS [Colossus Exception Code]

              , CONVERT(VARCHAR(12),dim_detail_client.[mib_date_base_investigations_completed],103) AS [MIB Date Base Investigations Completed]
              , CASE WHEN dim_detail_client.[mib_date_base_investigations_completed] IS NULL THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, GETDATE())  ELSE DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_client.[mib_date_base_investigations_completed])END AS [SCUElapsedDays]
          , dim_detail_outcome.[date_claim_concluded] AS [Date Claimant's Claim Settled]
              , CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NULL THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_matter_header_current.date_opened_case_management, GETDATE())  ELSE [dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_matter_header_current.date_opened_case_management, dim_detail_outcome.[date_claim_concluded])END AS [Elapsed Working Days]
              , CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NULL THEN DATEDIFF(DAY, dim_detail_core_details.[date_instructions_received], GETDATE())  ELSE DATEDIFF(DAY, dim_detail_core_details.[date_instructions_received], dim_detail_outcome.[date_claim_concluded])END AS [Elapsed Days]
              , CONVERT(VARCHAR(12),dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill],103) AS [MIB Date of Final Bill]
              , dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
              , fact_detail_paid_detail.[personal_injury_paid] AS [MIB Personal Injury Paid]
              , fact_detail_client.[mib_other_damages] AS [MIB Other Damages]
              , ISNULL(fact_detail_paid_detail.[personal_injury_paid],0) + ISNULL(fact_detail_client.[mib_other_damages],0) [Settlement Amount]
              , dim_detail_outcome.[mib_fraud_settlement_basis] AS [MIB Fraud Settlement Basis]
              , CASE WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case concluded pre-trial with own costs only incurred' THEN 1 
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case proceeded to trial with unsuccessful outcome' THEN 2
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case run to trial & successfully defend (cost not recovered)' THEN 3
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case run to trial & successfully defended (costs recovered)' THEN 4
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Settled by negotiation (full/comprise)' THEN 5
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Settled by negotiation (minimal/nuisance)' THEN 6 END AS [Fraud Settlement Basis]
              , fact_detail_client.[mib_periodic_payment_amount] AS [MIB Periodic Payment Amount]
              , fact_detail_paid_detail.[claimants_profit_costs_claimed] AS [MIB Claimant's Costs Claimed]
              , fact_detail_paid_detail.[mib_claimants_disbursements_claimed] AS [MIB Claimant's Disbursements Claimed]
			  , ISNULL(fact_detail_paid_detail.[claimants_profit_costs_claimed],0) + ISNULL(fact_detail_paid_detail.[mib_claimants_disbursements_claimed],0) AS [Total Costs/Disbursements Claimed]
              , dim_detail_outcome.[mib_grp_costs_negotiators_used] AS [MIB Costs Negotiators Used]
              , dim_detail_outcome.[mib_name_of_costs_negotiators] AS [MIB Name of Costs Negotiators]
              , fact_detail_paid_detail.[claimants_profit_costs_settled] AS [MIB Claimant's Costs Settled]
              , fact_detail_paid_detail.[mib_disbursements_settled] AS [MIB Disbursements Settled]
              , ISNULL(fact_detail_paid_detail.[claimants_profit_costs_settled],0) + ISNULL(fact_detail_paid_detail.[mib_disbursements_settled],0) AS [Total Costs/Disbursements Settled]
              , (ISNULL(fact_detail_paid_detail.[claimants_profit_costs_claimed],0) + ISNULL(fact_detail_paid_detail.[mib_claimants_disbursements_claimed],0))-(ISNULL(fact_detail_paid_detail.[claimants_profit_costs_settled],0) + ISNULL(fact_detail_paid_detail.[mib_disbursements_settled],0)) AS [Total Saved on Costs]
              , fact_detail_paid_detail.[amount_hire_paid] AS [Hire Paid]
              , CONVERT(VARCHAR(12),dim_matter_header_current.date_closed_case_management,103) AS [Date Case Closed]
              , CONVERT(VARCHAR(12),dim_detail_outcome.date_costs_settled,103) AS [Date Costs Settled]
              , fact_finance_summary.defence_costs_billed AS [Own Costs- 3E]
              , fact_detail_paid_detail.time_charge_value AS [Unit Total - 3E]
              , Disbs.[Disbursements - 3E] AS [Disbursements - 3E]
              , DIsbs.[Own Counsel Fees - 3E] AS [Own Counsel Fees - 3E]
              , dim_detail_client.[mib_case_appealed] AS [MIB Case Appealed]
              , dim_detail_client.[mib_client_code_exception] AS [MIB Client Code Exception]
              , dim_detail_client.[mib_unit_total_internal] AS [MIB Unit Total Internal]
              , dim_detail_outcome.[mib_unit_total] AS [MIB Unit Total]
              , CASE WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Settled by negotiation (full/comprise)' THEN ISNULL(fact_detail_paid_detail.[personal_injury_paid],0)+ISNULL(fact_detail_client.[mib_other_damages],0) ELSE NULL END AS [Case Settled by Negotiation (full/comprise)]
              , CASE WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Settled by negotiation (minimal/nuisance)' THEN ISNULL(fact_detail_paid_detail.[personal_injury_paid],0)+ISNULL(fact_detail_client.[mib_other_damages],0) ELSE NULL END AS [Case Settled by Negotiation]
              , CASE WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case concluded pre-trial with own costs only incurred' THEN 'Yes'
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])<>'Case concluded pre-trial with own costs only incurred' THEN 'No' ELSE NULL END AS [Case Concluded Pre-trial]
              , CASE WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case run to trial & successfully defended (costs recovered)' THEN 'Yes'
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])<>'Case run to trial & successfully defended (costs recovered)' THEN 'No' ELSE NULL END AS [Case Run to Trial (Own Costs Recovered)]
              , CASE WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case run to trial & successfully defend (cost not recovered)' THEN 'Yes'
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])<>'Case run to trial & successfully defend (cost not recovered)' THEN 'No' ELSE NULL END AS [Case Run to Trial (Own Costs not Recovered)]
              , CASE WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])='Case proceeded to trial with unsuccessful outcome' THEN 'Yes'
                        WHEN RTRIM(dim_detail_outcome.[mib_fraud_settlement_basis])<>'Case proceeded to trial with unsuccessful outcome' THEN 'No' ELSE NULL END AS [Case Proceeded to Trial]
              , fact_detail_client.[mib_our_profit_costs] AS [MIB Our Profit Costs]
			  , fact_detail_paid_detail.[mib_own_disbursements] AS [MIB Own Disbursements]
              , fact_detail_client.[mib_own_counsels_fees] AS [MIB Own Counsel Fees]
              , dim_detail_finance.[payment_descripiton] AS [MIB DA Payment descrip]
              , dim_detail_client.[mib_notes] AS [MIB Notes]
              , fact_detail_client.[mib_da_payment] AS [MIB DA Payment]
              , dim_detail_client.[mib_da_payment_notes] AS [MIB DA Payment Notes]
              , dim_detail_client.[mib_da_payment_date] AS [MIB DA Payment Date]
              , dim_employee.workemail AS [Case Manager's Email]              
              , TimeRecorded.HoursRecorded AS [Hours Recorded]
              , [Partner/NonPartnerHoursRecorded].PartnerHours AS [Partner Hours]
              , [Partner/NonPartnerHoursRecorded].NonPartnerHours AS [Non-Partner Hours]
			  , AssociateHours AS [Associate Hours]
			  , [SolicitorTimeHours] AS [Solicitor Hours]
			  , ParalegalHours AS [Paralegal Hours]
			  , LegalExecHours AS [Legal Executive Hours]
              , OtherHours AS [Other Hours]
              , CASE WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL OR dim_detail_outcome.[date_claim_concluded] IS NOT NULL THEN 1 ELSE 0 END AS [TrialReportExclusion]
              , 'Matter Level' AS [Level]
			 -- , dim_detail_client.[mib_claimants_name
			  , dim_instruction_type.instruction_type
			  , dim_matter_header_current.reporting_exclusions
			  , CASE WHEN (dim_detail_court.[date_of_trial] >=getdate() or dim_detail_court.[date_of_first_day_of_trial_window]>=getdate() )
				AND outcome_of_case is NULL THEN 1 ELSE 0 END AS [Trail Alert Filter]
			  , ClaimantsAddress.[claimant1_postcode] AS [Claimant's Postcode]
			  , dim_detail_client.[mib_notes] AS [DA Lifecycle]
			  --, dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant's Solicitor]
			  , CASE WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'irwin michell%' THEN 'Irwin Mitchell'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'irwin micthell%' THEN 'Irwin Mitchell'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'irwin mitchel%' THEN 'Irwin Mitchell'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'lyons davidson%' THEN 'Lyons Davidson'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'slater gordon%' THEN 'Slater and Gordon'
				WHEN LTRIM(LOWER(dim_claimant_thirdparty_involvement.claimantsols_name)) LIKE 'slater and gordon%' THEN 'Slater and Gordon'
				WHEN LTRIM(LOWER(dim_claimant_thirdparty_involvement.claimantsols_name)) LIKE 'slater and gordan%' THEN 'Slater and Gordon'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'carpenters%' THEN 'Carpenters'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'minster law%' THEN 'Minster Law LTD'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'true solicitors%' THEN 'True Solicitors LLP'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'asons solicitors%' THEN 'Asons Solicitors'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'winn solicitors%' THEN 'Winn Solicitors'
				WHEN LOWER(dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'thompsons%' THEN 'Thompsons Solicitors'
				ELSE dim_claimant_thirdparty_involvement.claimantsols_name
			END AS [Claimant's Solicitor]
			  , Doogal.Longitude AS [Longitude]
			  , Doogal.Latitude AS [Latitude]
			  , fact_finance_summary.[damages_paid] AS [Damages Paid]
			  , CASE WHEN dim_detail_core_details.[present_position]='Claim and costs outstanding' THEN 'Damages Outstanding'
				WHEN dim_detail_core_details.[present_position]='Claim concluded but costs outstanding' THEN 'Costs Outstanding'
				WHEN dim_detail_core_details.[present_position]='Claim and costs concluded but recovery outstanding' THEN 'Recovery'
				WHEN dim_detail_core_details.[present_position]='Final bill due - claim and costs concluded' THEN 'Final Bill'
				WHEN dim_detail_core_details.[present_position]='Final bill sent - unpaid' THEN 'Final Bill'
				WHEN dim_detail_core_details.[present_position]='To be closed/minor balances to be clear' THEN 'Closed' ELSE dim_detail_core_details.[present_position] END AS [Present Position Group]
			, fact_finance_summary.total_reserve AS [Total Reserve]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key=dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
INNER JOIN red_dw..dim_involvement_full ON dim_court_involvement.court_1_key = dim_involvement_full.dim_involvement_full_key 

LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key


LEFT OUTER JOIN (
SELECT  fact_bill_detail.client_code AS [Client Code]
	 , fact_bill_detail.matter_number AS [Matter Number]
	 , SUM(CASE WHEN charge_type='disbursements'  AND cost_type_description<>'Counsel' THEN bill_total_excl_vat ELSE 0 END) AS [Disbursements - 3E]
	 , SUM(CASE WHEN charge_type='disbursements'  AND cost_type_description='Counsel' THEN bill_total_excl_vat ELSE 0 END) AS [Own Counsel Fees - 3E]
FROM red_dw.dbo.fact_bill_detail
LEFT OUTER JOIN red_dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
GROUP BY fact_bill_detail.client_code, fact_bill_detail.matter_number) AS Disbs ON Disbs.[Client Code]=fact_dimension_main.client_code AND Disbs.[Matter Number]=fact_dimension_main.matter_number

		LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
								,SUM(minutes_recorded) AS [MinutesRecorded]
								,SUM(minutes_recorded)/60 AS [HoursRecorded]
						FROM red_dw.dbo.fact_chargeable_time_activity
						INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
						WHERE  minutes_recorded<>0
						AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
						AND master_client_code='M1001'
						GROUP BY client_code,matter_number,fact_chargeable_time_activity.master_fact_key
		) AS TimeRecorded ON TimeRecorded.master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key


LEFT OUTER JOIN (		SELECT    client_code
                                          , matter_number
										  , master_fact_key
										  , ISNULL(SUM(PartnerTime),0)/60 AS PartnerHours
                                          , ISNULL(SUM(NonPartnerTime),0)/60 AS NonPartnerHours
										  , ISNULL(SUM(AssociateTime),0)/60 AS AssociateHours
										  , ISNULL(SUM([SolicitorTime]),0)/60 AS [SolicitorTimeHours]
										  , ISNULL(SUM(ParalegalTime),0)/60 AS ParalegalHours
										  , ISNULL(SUM([LegalExecTime]),0)/60 AS LegalExecHours
                                          , ISNULL(SUM(OtherTime),0)/60 AS OtherHours
                                  FROM      ( SELECT    client_code 
                                                        , matter_number 
														, master_fact_key

														, ( CASE WHEN Partners.jobtitle LIKE '%Partner%' THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS PartnerTime 
                                                        , ( CASE WHEN Partners.jobtitle NOT LIKE '%Partner%' OR jobtitle IS NULL THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS NonPartnerTime
														, ( CASE WHEN Partners.jobtitle LIKE '%Associate%' THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS AssociateTime
														, ( CASE WHEN Partners.jobtitle LIKE 'Solicitor%' THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [SolicitorTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Paralegal%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [ParalegalTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Legal Executive%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [LegalExecTime]

                                                        , ( CASE WHEN Partners.jobtitle NOT LIKE '%Partner%' 
														AND Partners.jobtitle NOT LIKE '%Associate%' 
														AND Partners.jobtitle NOT LIKE '%Solicitor%'
														AND Partners.jobtitle NOT LIKE '%Legal Executive%' 
														AND Partners.jobtitle NOT LIKE '%Paralegal%'  
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
														AND master_client_code='M1001'
											  GROUP BY  client_code, matter_number, master_fact_key, Partners.jobtitle
                                            ) AS AllTime
                                  GROUP BY  AllTime.client_code, AllTime.matter_number, AllTime.master_fact_key)  AS [Partner/NonPartnerHoursRecorded] ON [Partner/NonPartnerHoursRecorded].master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key

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

LEFT OUTER JOIN red_dw.dbo.Doogal ON Doogal.Postcode=ClaimantsAddress.[claimant1_postcode]


WHERE 
--fact_dimension_main.client_code = 'MIB005'
 --and fact_dimension_main.matter_number = '00001779'
 ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND fact_dimension_main.matter_number <>'ML'
AND fact_dimension_main.client_code  NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
----AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
AND fact_dimension_main.master_client_code='M1001'
---- LD wrapped statement in isnull 31/08/2017
AND ISNULL(dim_detail_client.[mib_claimants_name],'') NOT IN ('DELETE- ALREADY SETTLED BY MIB','DELETED','DELETE - DUPLICATE FILE','DELETE','DELETE ERROR')
AND ISNULL(dim_instruction_type.instruction_type,'') NOT IN ('Strategic', 'Corporate','Employment','Real Estate')

--1.2
--AND (dim_detail_court.[date_of_trial] >=getdate()  
-- or dim_detail_court.[date_of_first_day_of_trial_window]>=getdate() )
-- and outcome_of_case is null

--AND fact_dimension_main.matter_number ='00026802'

ORDER BY fact_dimension_main.client_code, fact_dimension_main.matter_number


END



GO
