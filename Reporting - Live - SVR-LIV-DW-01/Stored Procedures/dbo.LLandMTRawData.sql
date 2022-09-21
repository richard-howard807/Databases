SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================  
-- Author:  Max Taylor  
-- Create date: 03/03/2021  
-- Description: 90491 - LL and MT raw data Report  

-- Ad-hoc - changes made to proc to speed it up. Tested against previously run report, all correct
-- =============================================  
CREATE PROCEDURE [dbo].[LLandMTRawData] @Team AS NVARCHAR(MAX)  
   
AS  
  
SET NOCOUNT ON

--Testing
--DECLARE @Team  AS NVARCHAR(MAX)  = (SELECT STRING_AGG(CAST(team_data.hierarchylevel4hist AS NVARCHAR(MAX)), '|')	AS teams
--									FROM (
--									SELECT DISTINCT hierarchylevel4hist
--									FROM 
--									red_dw.dbo.dim_fed_hierarchy_history 
--									INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
--									INNER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
--									INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
--									WHERE 1 = 1
--									--dim_client.client_group_code = '00000004'
--									AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')
--									AND hierarchylevel4hist IS NOT NULL AND hierarchylevel4hist <> 'Unknown'
--									  AND
--										  (
--									dim_matter_header_current.date_closed_case_management IS NULL
--									OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'
--										  )
--									) AS team_data)

IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team;  

CREATE TABLE #Team (ListValue NVARCHAR(100) COLLATE Latin1_General_BIN)
INSERT INTO #Team
(
    ListValue
)

SELECT ListValue  FROM  dbo.udt_TallySplit('|', @Team);  


IF OBJECT_ID('tempdb..#reserve_changes') IS NOT NULL DROP TABLE #reserve_changes

SELECT
	all_changes.dim_matter_header_curr_key
    , SUM(all_changes.clm_costs_changes)		AS clm_costs_changes
    , SUM(all_changes.def_costs_changes)		AS def_costs_changes
    , SUM(all_changes.dam_changes)				AS dam_changes
INTO #reserve_changes
FROM (
		SELECT 
			fed_pivot.dim_matter_header_curr_key
			, SUM(IIF(fed_pivot.TRA080 IS NULL, 0, 1)) - 1		AS clm_costs_changes
			, SUM(IIF(fed_pivot.TRA078 IS NULL, 0, 1)) - 1		AS def_costs_changes
			, SUM(IIF(fed_pivot.TRA076 IS NULL, 0, 1)) - 1		AS dam_changes
			, 'fed'		AS source_system
		FROM (
				SELECT 
					dim_matter_header_current.dim_matter_header_curr_key
					, CAST(dim_matter_header_current.dim_matter_header_curr_key AS NVARCHAR(50)) 
						+ CAST(ds_sh_axxia_casdet.case_value AS NVARCHAR(50)) + CAST(ds_sh_axxia_casdet.effective_start_date AS NVARCHAR(50))		AS unique_value
					, ds_sh_axxia_casdet.case_detail_code
					, ds_sh_axxia_casdet.case_value
				FROM red_dw.dbo.dim_matter_header_current  
					INNER JOIN red_dw.dbo.ds_sh_axxia_casdet  
						ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id  
				WHERE 1 = 1   
					AND ISNULL(dim_matter_header_current.date_closed_case_management, '9999-12-31') >='2014-01-01'
					AND RTRIM(dim_matter_header_current.client_code) IN  ('00046018', 'C15332', 'C1001', 'W24438')  
					AND department_code <> '0027'  
					AND ds_sh_axxia_casdet.deleted_flag = 'N'
					AND ds_sh_axxia_casdet.case_detail_code IN ('TRA076', 'TRA078', 'TRA080')
					AND ds_sh_axxia_casdet.case_value IS NOT NULL
			) AS fed_details
		PIVOT (
			MAX(case_value)
			FOR case_detail_code IN (TRA076, TRA078, TRA080)
			) AS fed_pivot
		GROUP BY
			fed_pivot.dim_matter_header_curr_key

		UNION 

		SELECT 
			dim_matter_header_current.dim_matter_header_curr_key
			, SUM(IIF(ds_sh_ms_udmicurrentreserves_history.curclacostrecur IS NULL, 0, 1)) -1		AS clm_costs_changes
			, SUM(IIF(ds_sh_ms_udmicurrentreserves_history.curdefcostrecur IS NULL, 0, 1))	-1	AS def_costs_changes
			, SUM(IIF(ds_sh_ms_udmicurrentreserves_history.curdamrescur IS NULL, 0, 1)) -1		AS dam_changes
			, 'ms'		AS source_system
		FROM red_dw.dbo.dim_matter_header_current  
			INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history  
				ON fileid = ms_fileid    
		WHERE 1 = 1   
			AND ISNULL(dim_matter_header_current.date_closed_case_management, '9999-12-31') >='2014-01-01'
			AND RTRIM(dim_matter_header_current.client_code) IN  ('00046018', 'C15332', 'C1001', 'W24438')  
			AND department_code <> '0027'  
			AND (ds_sh_ms_udmicurrentreserves_history.curdamrescur IS NOT NULL 
					OR ds_sh_ms_udmicurrentreserves_history.curclacostrecur IS NOT NULL
					OR ds_sh_ms_udmicurrentreserves_history.curdefcostrecur IS NOT NULL)
		GROUP BY 
			dim_matter_header_current.dim_matter_header_curr_key
	) AS all_changes
GROUP BY
	all_changes.dim_matter_header_curr_key


SELECT 
	fact_dimension_main.client_code AS [Client Code],  
	fact_dimension_main.matter_number AS [Matter Number],  
	RTRIM(dim_matter_header_current.master_client_code) + '-' + RTRIM(dim_matter_header_current.master_matter_number) AS [3E Reference],  
	CASE  
		--WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
		--'Converge'  
		--WHEN dim_detail_client.[coop_master_reporting] = 'Yes'  
		--OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool' THEN  
		--'MLT'  
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
	red_dw.dbo.dim_matter_header_current.date_opened_case_management,   
	red_dw.dbo.dim_matter_header_current.date_closed_case_management,  
	dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Co-op Handler],  
	insurerclient_reference AS [CIS Reference],  
	dim_detail_core_details.[coop_client_branch] AS [Client Branch],  
	RTRIM(dim_matter_header_current.client_code) + '-' + dim_matter_header_current.matter_number AS [Weightmans Reference],  
	LTRIM(RTRIM(dim_matter_header_current.matter_description)) AS [Name of Case],  
	name [Fee Earner Name],  
	hierarchylevel4hist AS [Team],  
	coop_guid_reference_number AS [GUID Reference Number ],  
	incident_date AS [Date of Accident],  
	accident_location AS [Accident Location],  
	--CASE  
	--	WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--		COALESCE(  
	--		dim_detail_core_details.date_instructions_received,  
	--		dim_matter_header_current.date_opened_case_management  
	--		)  
	--	ELSE  
	--		dim_matter_header_current.date_opened_case_management  
	--	END AS [Date File Opened], 
	dim_matter_header_current.date_opened_case_management			AS [Date File Opened],
	dim_matter_header_current.date_closed_case_management AS [Date File Closed],  
	dim_detail_critical_mi.date_reopened AS [Date File Reopened ],  
	dim_matter_header_current.date_closed_practice_management AS [Date Closed 3E],  
	--CASE  
	--	WHEN (CASE  
	--			WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--				COALESCE(  
	--				dim_detail_critical_mi.date_closed,  
	--				dim_matter_header_current.date_closed_case_management  
	--				)  
	--			ELSE  
	--				dim_matter_header_current.date_closed_case_management  
	--			END  
	--			) IS NULL THEN  
	--				DATEDIFF(  
	--				DAY,  
	--				(CASE  
	--					WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--						COALESCE(  
	--							dim_detail_core_details.date_instructions_received,  
	--							dim_matter_header_current.date_opened_case_management  
	--						)  
	--				ELSE  
	--					dim_matter_header_current.date_opened_case_management  
	--				END  
	--				),  
	--				GETDATE()  
	--				)  
	--	ELSE  
	--		DATEDIFF(  
	--		DAY,  
	--		(CASE  
	--			WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--				COALESCE(  
	--					dim_detail_core_details.date_instructions_received,  
	--					dim_matter_header_current.date_opened_case_management  
	--				)  
	--			ELSE  
	--				dim_matter_header_current.date_opened_case_management  
	--		END),  
	--		(CASE  
	--			WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--				COALESCE(  
	--					dim_detail_critical_mi.date_closed,  
	--					dim_matter_header_current.date_closed_case_management  
	--				)  
	--			ELSE  
	--				dim_matter_header_current.date_closed_case_management  
	--		END)  
	--		)  
	--END																AS [Elapsed Days],
	DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_matter_header_current.date_closed_case_management, GETDATE()))   AS [Elapsed Days],
	red_dw.dbo.dim_detail_core_details.is_this_the_lead_file AS [Is this the lead file?],  
	is_this_a_linked_file AS [Linked File],  
	associated_matter_numbers AS [Associated Matter Numbers],  
	lead_file_matter_number_client_matter_number AS [Lead File Matter Reference ],  
	work_type_name AS [Work Type ],  
	dim_detail_core_details.referral_reason AS [Referral Reason ],  
	COALESCE(dim_detail_claim.[claimants_solicitors_firm_name ], dim_claimant_thirdparty_involvement.claimantsols_name) AS [Claimants Solictors],  
	dim_detail_claim.number_of_claimants AS [Potential Number of Claimants],  
	dim_detail_core_details.proceedings_issued AS [Proceedings Issued], 
	CAST(dim_detail_claim.msg_limitation_date AS DATE)			AS [Limitation Date],
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
	--CASE  
	--	WHEN  (red_dw.dbo.dim_detail_client.coop_master_reporting = 'Yes'OR red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'  ) THEN  
	--		DATEADD( d,360,  
	--		(CASE  
	--			WHEN department_code = '0027' THEN  
	--				COALESCE(  
	--					red_dw.dbo.dim_detail_core_details.date_instructions_received,  
	--					red_dw.dbo.dim_matter_header_current.date_opened_case_management  
	--				)  
	--			ELSE  
	--				red_dw.dbo.dim_matter_header_current.date_opened_case_management  
	--		END)  
	--		)  
	--	ELSE  
	--		dim_detail_core_details.coop_target_settlement_date  
	--END																	AS [Target Settlement Date ], 
	dim_detail_core_details.initial_target_settlement_date			AS [Initial Target Settlement Date],
	dim_detail_core_details.coop_target_settlement_date						AS [Target Settlement Date ], 
	dim_detail_client.msg_likelihood_of_tsd_movement		AS [Likelihood of TSD Movement],

	--CASE  
	--	WHEN department_code = '0027' THEN  
	--		red_dw.dbo.fact_detail_reserve_detail.general_damages_reserve_current  
	--	ELSE  
	--		red_dw.dbo.fact_finance_summary.damages_reserve  
	--END															AS [Damages Reserve Held (Before Payment)], 
	red_dw.dbo.fact_finance_summary.damages_reserve				AS [Damages Reserve Held (Before Payment)], 
	--CASE  
	--	WHEN department_code = '0027' THEN  
	--		ISNULL(COALESCE(fact_detail_paid_detail.[personal_injury_paid],	fact_detail_client.[zurich_general_damages_psla_only]),	0)  
	--	ELSE  
	--		ISNULL(fact_finance_summary.[damages_interims], 0) + ISNULL(fact_finance_summary.[damages_paid], 0)  
	--END															 AS [Damages Payments To Date],  
	ISNULL(fact_finance_summary.[damages_interims], 0) + ISNULL(fact_finance_summary.[damages_paid], 0)			AS [Damages Payments To Date],
	--CASE  
	--	WHEN dim_detail_core_details.[present_position] IN ( 'Final bill sent - unpaid',  
	--						'To be closed/minor balances to be clear'  
	--						) THEN  
	--		NULL  
	--	ELSE  
	--		ISNULL(CASE  
	--					WHEN department_code = '0027' THEN  
	--						fact_detail_reserve_detail.[general_damages_reserve_current]  
	--					ELSE  
	--						fact_finance_summary.[damages_reserve]  
	--				END,  0)  
	--		- ISNULL(CASE  
	--					WHEN department_code = '0027' THEN  
	--						ISNULL(COALESCE(fact_detail_paid_detail.[personal_injury_paid], fact_detail_client.[zurich_general_damages_psla_only]),   0 ) 
	--					ELSE  
	--						ISNULL(fact_finance_summary.[damages_interims], 0)  
	--						+ ISNULL(fact_finance_summary.[damages_paid], 0)  
	--				END, 0)  
	--END																				AS [Damages Reserve Outstanding], 
	CASE  
		WHEN dim_detail_core_details.[present_position] IN ( 'Final bill sent - unpaid',  
							'To be closed/minor balances to be clear'  
							) THEN  
			NULL  
		ELSE  
			ISNULL(fact_finance_summary.[damages_reserve], 0)  
			- (ISNULL(fact_finance_summary.[damages_interims], 0) + ISNULL(fact_finance_summary.[damages_paid], 0))  
	END																				AS [Damages Reserve Outstanding], 
	fact_detail_reserve_detail.claimant_costs_reserve_current AS [Opponents Costs Reserve Held before payments ],  
	--CASE  
	--	WHEN red_dw.dbo.dim_matter_header_current.department_code = '0027' THEN  
	--		ISNULL(fact_detail_paid_detail.claimants_profit_costs_settled, 0)  
	--		+ ISNULL(red_dw.dbo.fact_finance_summary.claimants_costs_paid, 0)  
	--	ELSE  
	--		(CASE  
	--			WHEN dim_detail_outcome.date_costs_settled IS NULL THEN  
	--				ISNULL(red_dw.dbo.fact_detail_paid_detail.interim_costs_payments, 0)  
	--				+ ISNULL(fact_detail_paid_detail.interim_costs_payments_by_client_pre_instruction, 0)  
	--			ELSE  
	--				ISNULL(fact_finance_summary.claimants_costs_paid, 0)  
	--				+ ISNULL(fact_finance_summary.detailed_assessment_costs_paid, 0)  
	--				+ ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant, 0)  
	--				+ ISNULL(fact_finance_summary.other_defendants_costs_paid, 0)  
	--		END)  
	--END																AS [Opponents Costs Paid To Date], 
	
	CASE  
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN  
			ISNULL(red_dw.dbo.fact_detail_paid_detail.interim_costs_payments, 0)  
			+ ISNULL(fact_detail_paid_detail.interim_costs_payments_by_client_pre_instruction, 0)  
		ELSE  
			ISNULL(fact_finance_summary.claimants_costs_paid, 0)  
			+ ISNULL(fact_finance_summary.detailed_assessment_costs_paid, 0)  
			+ ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant, 0)  
			+ ISNULL(fact_finance_summary.other_defendants_costs_paid, 0)   
	END																AS [Opponents Costs Paid To Date],  
	--ISNULL(fact_detail_reserve_detail.claimant_costs_reserve_current, 0)  
	--- (CASE  
	--		WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--			ISNULL(fact_detail_paid_detail.claimants_profit_costs_settled, 0)  
	--			+ ISNULL(fact_finance_summary.claimants_costs_paid, 0)  
	--		ELSE  
	--			(CASE  
	--				WHEN dim_detail_outcome.date_costs_settled IS NULL THEN  
	--					ISNULL(fact_detail_paid_detail.interim_costs_payments, 0)  
	--					+ ISNULL(fact_detail_paid_detail.interim_costs_payments_by_client_pre_instruction, 0)  
	--				ELSE  
	--					ISNULL(fact_finance_summary.claimants_costs_paid, 0)  
	--					+ ISNULL(fact_finance_summary.detailed_assessment_costs_paid, 0)  
	--					+ ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant, 0)  
	--					+ ISNULL(fact_finance_summary.other_defendants_costs_paid, 0)  
	--			END)  
	--	END)																					AS [Opponents Cost Reserve Outstanding],
	ISNULL(fact_detail_reserve_detail.claimant_costs_reserve_current, 0)  
	- (CASE  
			WHEN dim_detail_outcome.date_costs_settled IS NULL THEN  
				ISNULL(fact_detail_paid_detail.interim_costs_payments, 0)  
				+ ISNULL(fact_detail_paid_detail.interim_costs_payments_by_client_pre_instruction, 0)  
			ELSE  
				ISNULL(fact_finance_summary.claimants_costs_paid, 0)  
				+ ISNULL(fact_finance_summary.detailed_assessment_costs_paid, 0)  
				+ ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant, 0)  
				+ ISNULL(fact_finance_summary.other_defendants_costs_paid, 0)  
		END)  																				AS [Opponents Cost Reserve Outstanding], 
	--CASE  
	--	WHEN (  
	--			dim_detail_client.[coop_master_reporting] = 'Yes'  
	--			OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'  
	--			)  
	--			AND ISNULL(dim_detail_core_details.[is_this_the_lead_file], 'No') = 'Yes' THEN  
	--		ISNULL(fact_finance_summary.[defence_costs_reserve], 0)  
	--	WHEN  (  
	--			dim_detail_client.[coop_master_reporting] = 'Yes'  
	--			OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'  
	--			) THEN  
	--		0  
	--	ELSE  
	--		ISNULL(fact_finance_summary.[defence_costs_reserve], 0)  
	--END																	AS [Defence Costs Reserve Held (before payments)], --LEADLINKED  
	ISNULL(fact_finance_summary.[defence_costs_reserve], 0) 									AS [Defence Costs Reserve Held (before payments)], --LEADLINKED  
	ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - ISNULL(total_amount_billed, 0)			AS [Defence Costs Reserve Outstanding],  
	dim_detail_claim.likelihood_of_substantial_reserve_movement			AS [Likelihood of Substantial Reserve Movement],
	vat_billed,  
	vat_amount,  
	total_amount_billed [Total paid to date  ],  
	total_outstanding_reserve [Total Outstanding Reserve],  
	--CASE  
	--	WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--		dim_detail_client.outcome_category  
	--	ELSE  
	--		dim_detail_outcome.outcome_of_case  
	--END																	AS [Outcome],  
	dim_detail_outcome.outcome_of_case  																AS [Outcome],
	coop_fraud_outcome [Fraud Outcome ],  
	--CASE  
	--	WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--		(CASE  
	--			WHEN (  
	--					dim_matter_header_current.date_opened_case_management <= '2010-01-01'  
	--					AND ISNULL(dim_detail_outcome.date_claim_concluded, '') = ''  
	--				) THEN  
	--				DATEADD(dd, 14, dim_matter_header_current.date_opened_case_management)  
	--			WHEN dim_matter_header_current.date_opened_case_management <= '2011-06-06' THEN  
	--				DATEADD(dd, 14, dim_matter_header_current.date_opened_case_management)  
	--			ELSE  
	--				dim_detail_outcome.date_claim_concluded  
	--		END)  
	--	ELSE  
	--		dim_detail_outcome.date_claim_concluded  
	--END																			AS [Date Damages Concluded],
	dim_detail_outcome.date_claim_concluded  																		AS [Date Damages Concluded],
	CASE  
		WHEN LOWER(dim_detail_outcome.outcome_of_case) LIKE '%won%'    
				OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%struck%'  
				OR LOWER(dim_detail_outcome.outcome_of_case) LIKE '%disc%' THEN 
			'Yes' 
		ELSE 
			'No'  
	END																			AS [Claim Repudiated],  
	CAST(dim_detail_outcome.date_claimants_costs_received AS DATE)				AS [Date Claimants Costs Received],  
	--CASE  
	--	WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--		dim_detail_claim.date_claimants_costs_agreed  
	--	ELSE  
	--		dim_detail_outcome.date_costs_settled  
	--END																	AS [Date Costs Settled],  
	dim_detail_outcome.date_costs_settled 														AS [Date Costs Settled],
	red_dw.dbo.fact_finance_summary.tp_total_costs_claimed								AS [Opponent Total Costs Claimed],  
	red_dw.dbo.fact_finance_summary.claimants_costs_paid											AS [Opponents Total Costs Paid],  
	--CASE  
	--	WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
	--		fact_detail_paid_detail.mib_disbursements_settled  
	--	ELSE  
	--		fact_finance_summary.opponents_disbursements_paid  
	--END																					AS [Opponents Disbursements Paid],  
	fact_finance_summary.opponents_disbursements_paid 												AS [Opponents Disbursements Paid],
	dim_detail_outcome.[are_we_pursuing_a_recovery]							AS [Are we Pursuing a Recovery?],  
	fact_finance_summary.total_recovery								AS [Total Recovered],  
	last_time_transaction_date										AS [Date of Last Time Transaction],  
	defence_costs_billed										AS [Profit Costs Indiviudal ],  
	--CASE  
	--	WHEN (
	--			dim_detail_client.coop_master_reporting = 'Yes'  
	--			OR red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'  
	--		) AND ISNULL(dim_detail_core_details.is_this_the_lead_file, 'No') = 'Yes' THEN  
	--		ISNULL(defence_costs, 0)  
	--	WHEN (  
	--			dim_detail_client.coop_master_reporting = 'Yes'  
	--			OR red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool'  
	--			) THEN 
	--		0 
	--	ELSE 
	--		defence_costs_billed 
	--END															AS [Profit Costs Billed To Date (net of VAT)],  
	defence_costs_billed 										AS [Profit Costs Billed To Date (net of VAT)],
	vat_amount [VAT],  
	fact_detail_paid_detail.total_cost_of_counsel					AS [Counsel Fees],  
	ISNULL(disbursements_billed, 0)								AS [Disbursement Costs Billed To Date (inc VAT)],  
	ISNULL(total_unbilled_disbursements_vat, 0)						as [Unbilled Disbursements],  
	fact_finance_summary.disbursement_balance					AS [disbalance],  
	ISNULL(red_dw.dbo.fact_finance_summary.wip, 0)				AS [Unbilled WIP],  
	ISNULL(total_amount_billed, 0)								AS [Total Billed To Date ],  
	last_bill_date														AS [Date of Last Bill ],  
	fact_matter_summary_current.last_bill_total				AS [Last Bill amount ],  
	indemnity_reason											AS [Indemnity Issue ],  
	claimants_date_of_birth											AS [Clients DOB],  
	dim_detail_core_details.[injury_type]					as [Injury Type ],  
	dim_detail_core_details.[date_initial_report_sent]						AS [Initial Report Date Sent ],  
	dim_detail_core_details.[date_subsequent_sla_report_sent]			AS [Subsequent Report Date],  
	dim_detail_health.[date_of_service_of_proceedings]					AS [Date of Service],  
	dim_detail_court.[date_proceedings_issued]									as [Date of Issue ],  
	fact_finance_summary.[cru_reserve]												AS [CRU Reserve],  
	fact_detail_reserve_detail.[future_care_reserve_current]						AS [Future Care Reserve ],  
	fact_detail_reserve_detail.[future_loss_misc_reserve_current]						AS [Future loss misc reserve],  
	fact_detail_reserve_detail.[future_loss_of_earnings_reserve_current]					AS [Future Loss of Earnings Reserve],  
	fact_detail_reserve_detail.[nhs_charges_reserve_current]							AS [NHS Charges Reserve],  
	fact_detail_reserve_detail.[general_damages_non_pi_misc_reserve_current]			AS [General damages non PI misc reserve],  
	fact_detail_reserve_detail.[past_care_reserve_current]								AS [Past Care Reserve],  
	fact_detail_reserve_detail.[past_loss_of_earnings_reserve_current]					AS [Past Loss of Earnings Reserve],  
	fact_detail_cost_budgeting.[personal_injury_reserve_current]						AS [Personal Injury Reserve],  
	fact_finance_summary.[special_damages_miscellaneous_reserve]							AS [Special Damages Misc Reserve],  
	fact_detail_reserve_detail.damages_reserve							AS [Total Damages Reserve],  
	fact_finance_summary.total_reserve									as [Total Reserve Current ],  
	fact_detail_paid_detail.[cru_costs_paid]					AS [CRU Costs Paid ],  
	fact_detail_paid_detail.[cru_offset]							AS [CRU Offset against Damages ],  
	fact_detail_paid_detail.[future_care_paid]							AS [Future Care Paid ],  
	fact_detail_paid_detail.[future_loss_misc_paid]						AS [Future Loss - Misc Paid ],  
	fact_detail_paid_detail.[nhs_charges_paid_by_client]								AS [NHS Charges Paid by client ],  
	fact_detail_paid_detail.[general_damages_misc_paid]										AS [General damages non PI misc paid],  
	fact_detail_paid_detail.[past_care_paid]									AS [Past Care Paid ],  
	fact_detail_paid_detail.[personal_injury_paid]												AS [Personal Injury Paid],  
	fact_detail_paid_detail.[past_loss_of_earnings_paid]								AS [Past Loss of Earnings Paid],  
	[Special damages misc paid] = fact_finance_summary.[special_damages_miscellaneous_paid],  
	[Total damages paid] = fact_finance_summary.[damages_paid],  
	[Will Gross Reserve Exceed 500k] = dim_detail_core_details.[will_total_gross_reserve_on_the_claim_exceed_500000],  
	[% Liability Agreed to Instruction] = fact_detail_client.[percent_of_clients_liability_agreed_prior_to_instruction],  
	[% Liability Agreed Post Instruction] = fact_detail_client.[percent_of_clients_liability_awarded_agreed_post_insts_applied],  
	[% Contributory Negligence Agreed] = fact_detail_client.[percent_of_contributory_negligence_agreed],  
	ll00_have_we_had_an_extension_for_the_initial_report					AS [Have we had an extension on the initial report ],  
	fact_detail_paid_detail.future_loss_of_earnings_paid									AS [Future Loss of Earnings Paid],  
	fact_detail_future_care.earnings									AS [Earnings],  
	fact_detail_future_care.care										AS [Care],  
	fact_detail_future_care.mobility									AS [Mobility],  
	fact_detail_future_care.[pwca_disease_only]							AS [PWCA Disease only ],  
	--dc.[No. Times Damages Changed]											AS [No. Times Damages Changed],  
	--cc.[No. Times Claimants Costs Changed]									AS [No. Times Claimants Costs Changed],  
	--dfc.[No.Times Defence Costs Changed ]										AS [No. Times Defence Costs Changed],  
	IIF(#reserve_changes.dam_changes < 0, NULL, #reserve_changes.dam_changes)		AS [No. Times Damages Changed],  
	IIF(#reserve_changes.clm_costs_changes < 0, NULL, #reserve_changes.clm_costs_changes)		AS [No. Times Claimants Costs Changed],
	IIF(#reserve_changes.def_costs_changes < 0, NULL, #reserve_changes.def_costs_changes)		AS [No. Times Defence Costs Changed],  

	CAST(dim_detail_audit.date_of_audit_coop AS DATE)						AS [Co-op Audit Date],  
  
	--CASE 
	--	WHEN dim_matter_header_current.master_client_code + '-'+ dim_matter_header_current.master_matter_number IN ('W24438-1', 'W24438-40','W24438-41', 'W24438-42' ) THEN 
	--		'Co-op back book'  
	--ELSE 
	--	ms.msg_instruction_type   
	--END												AS [instruction_type],

	CASE 
		WHEN dim_matter_header_current.master_client_code + '-'+ dim_matter_header_current.master_matter_number IN ('W24438-1', 'W24438-40','W24438-41', 'W24438-42' ) THEN 
			'Co-op back book'  
	ELSE 
		dim_detail_claim.msg_instruction_type  
	END												AS [instruction_type],
	dim_detail_outcome.[ll28_provisional_damages_paid]
 
--SELECT COUNT(*)
FROM red_dw.dbo.dim_client  
	INNER JOIN red_dw.dbo.fact_dimension_main  
		ON dim_client.client_code = fact_dimension_main.client_code  
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key  
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
	LEFT OUTER JOIN red_dw.dbo.dim_detail_audit
		ON dim_detail_audit.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
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
	LEFT OUTER JOIN #reserve_changes
		ON #reserve_changes.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	--LEFT OUTER JOIN(  
	--				SELECT client_code,  
	--					curdamrescur.matter_number,  
	--					SUM(changes) AS [No. Times Damages Changed]  
	--				FROM (  
	--						SELECT dim_client.client_code,  
	--							matter_number,  
	--							COUNT(*) - 1 changes,  
	--							'fed' AS source_system  
	--						FROM red_dw.dbo.dim_client  
	--							INNER JOIN red_dw.dbo.dim_matter_header_current  
	--								ON dim_matter_header_current.client_code = dim_client.client_code  
	--									AND(dim_matter_header_current.date_closed_case_management IS NULL  
	--										OR dim_matter_header_current.date_closed_case_management >= '2014-01-01')  
	--							INNER JOIN red_dw.dbo.ds_sh_axxia_casdet  
	--								ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id  
	--									AND deleted_flag = 'N'  
	--										AND case_detail_code = 'TRA076'  
	--											AND case_value IS NOT NULL  
	--						WHERE 1 = 1   
	--							AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
	--							AND department_code <> '0027' 
	--						GROUP BY 
	--							dim_client.client_code,  
	--							matter_number  
							
	--						UNION
							
	--						SELECT dim_client.client_code,  
	--							matter_number,  
	--							COUNT(*) - 1 changes,  
	--							'ms' AS source_system  
	--						FROM red_dw.dbo.dim_client  
	--							INNER JOIN red_dw.dbo.dim_matter_header_current  
	--								ON dim_matter_header_current.client_code = dim_client.client_code  
	--									AND ( 
	--										dim_matter_header_current.date_closed_case_management IS NULL  
	--										OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
	--										)  
	--							INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history  
	--								ON fileid = ms_fileid  
	--									AND curdamrescur IS NOT NULL  
	--						WHERE 1 = 1   
	--							AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
	--							AND department_code <> '0027'  
								
	--						GROUP BY 
	--							dim_client.client_code,  
	--							matter_number  
	--					) AS curdamrescur  
	--				GROUP BY 
	--					curdamrescur.client_code,  
	--					curdamrescur.matter_number  
	--			) AS dc  
	--	ON dc.client_code = red_dw.dbo.fact_dimension_main.client_code  
	--		AND dc.matter_number = red_dw.dbo.fact_dimension_main.matter_number  
	--------------------------------------------------------------------------------  
	--LEFT OUTER JOIN (  
	--					SELECT client_code,  
	--						curdamrescur.matter_number,  
	--						SUM(changes) AS [No. Times Claimants Costs Changed]  
	--					FROM (  
	--							SELECT dim_client.client_code,  
	--								matter_number,  
	--								COUNT(*) - 1 changes,  
	--								'fed' AS source_system  
	--							FROM red_dw.dbo.dim_client  
	--								INNER JOIN red_dw.dbo.dim_matter_header_current  
	--									ON dim_matter_header_current.client_code = dim_client.client_code  
	--										AND (  
	--											dim_matter_header_current.date_closed_case_management IS NULL  
	--											OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
	--											)  
	--								INNER JOIN red_dw.dbo.ds_sh_axxia_casdet  
	--									ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id  
	--										AND deleted_flag = 'N'  
	--											AND case_detail_code = 'TRA080'  
	--												AND case_value IS NOT NULL  
	--							WHERE 1 =1   
	--								AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
	--								AND department_code <> '0027'  
	--							GROUP BY 
	--								dim_client.client_code,  
	--								matter_number  

	--							UNION  
		
	--							SELECT dim_client.client_code,  
	--								matter_number,  
	--								COUNT(*) - 1 changes,  
	--								'ms' AS source_system  
	--							FROM red_dw.dbo.dim_client  
	--								INNER JOIN red_dw.dbo.dim_matter_header_current  
	--									ON dim_matter_header_current.client_code = dim_client.client_code  
	--									AND  
	--									(  
	--									dim_matter_header_current.date_closed_case_management IS NULL  
	--									OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
	--									)  
	--								INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history  
	--									ON fileid = ms_fileid  
	--										AND curclacostrecur IS NOT NULL  
	--							WHERE 1 =1   
	--								AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
	--								AND department_code <> '0027'  
	--							GROUP BY 
	--								dim_client.client_code,  
	--								matter_number  
	--						) curdamrescur  
	--					GROUP BY curdamrescur.client_code,  
	--					curdamrescur.matter_number  
	--				) cc  
	--	ON cc.client_code = red_dw.dbo.fact_dimension_main.client_code  
	--		AND cc.matter_number = fact_dimension_main.matter_number  
	--LEFT OUTER JOIN (  
	--					SELECT client_code,  
	--						curdamrescur.matter_number,  
	--						SUM(changes) [No.Times Defence Costs Changed ]  
	--					FROM (  
	--							SELECT dim_client.client_code,  
	--								matter_number,  
	--								COUNT(*) - 1 changes,  
	--								'fed' AS source_system  
	--							FROM red_dw.dbo.dim_client  
	--								INNER JOIN red_dw.dbo.dim_matter_header_current  
	--									ON dim_matter_header_current.client_code = dim_client.client_code  
	--									AND (  
	--										dim_matter_header_current.date_closed_case_management IS NULL  
	--										OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
	--										)  
	--								INNER JOIN red_dw.dbo.ds_sh_axxia_casdet  
	--									ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id  
	--										AND deleted_flag = 'N'  
	--											AND case_detail_code = 'TRA080'  
	--												AND case_value IS NOT NULL  
	--							WHERE 1 = 1   
	--								AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
	--								AND department_code <> '0027'  
	--							GROUP BY 
	--								dim_client.client_code,  
	--								matter_number  
  
	--							UNION  

	--							SELECT dim_client.client_code,  
	--								matter_number,  
	--								COUNT(*) - 1 changes,  
	--								'ms' AS source_system  
	--							FROM red_dw.dbo.dim_client  
	--								INNER JOIN red_dw.dbo.dim_matter_header_current  
	--									ON dim_matter_header_current.client_code = dim_client.client_code  
	--										AND (  
	--											dim_matter_header_current.date_closed_case_management IS NULL  
	--											OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
	--											)
	--								INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history  
	--									ON fileid = ms_fileid  
	--										AND curclacostrecur IS NOT NULL  
	--							WHERE 1 =1   
	--								AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
	--								AND department_code <> '0027'    
	--							GROUP BY 
	--								dim_client.client_code,  
	--								matter_number  
	--						) curdamrescur  
	--					GROUP BY 
	--						curdamrescur.client_code,  
	--						curdamrescur.matter_number  
	--				) AS dfc  
	--	ON dfc.client_code = red_dw.dbo.fact_dimension_main.client_code  
	--		AND dfc.matter_number = red_dw.dbo.fact_dimension_main.matter_number 
	INNER JOIN #Team AS Team  
	   ON Team.ListValue  = ISNULL(dim_fed_hierarchy_history.hierarchylevel4hist, 'Unknown')  
	WHERE 1 = 1   
		AND reporting_exclusions = 0  
		AND LOWER(ISNULL(outcome_of_case, '')) NOT IN ( 'exclude from reports', 'returned to client' )  
		AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
		AND department_code <> '0027'  
		AND ISNULL(dim_detail_claim.msg_instruction_type, '') <> 'MSG Savings project'
		--------------AND dim_fed_hierarchy_history.hierarchylevel4hist IN (@Team)  
		AND CASE		 
				WHEN dim_detail_client.[coop_master_reporting] = 'Yes' OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool' THEN  
					'MLT'  
				ELSE
					''
			END <> 'MLT'  
		AND ISNULL(dim_matter_header_current.date_closed_case_management, '9999-12-31') >= '2014-01-01'
		--AND (dim_matter_header_current.date_closed_case_management IS NULL  
		--	OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
		--	)  
		--AND hierarchylevel4hist IN (@Team)  
		--AND ms_fileid NOT IN   
		-- (SELECT DISTINCT [fileID] FROM [MS_Prod].[dbo].[udMIClientMSG]  
		--  LEFT JOIN [MS_Prod].[dbo].dbCodeLookup ON cdType = 'MSGINSTYPE' AND cdCode = [cboInsTypeMSG]   
		--  WHERE dbCodeLookup.cdDesc  =  'MSG Savings project'   
		--  AND [fileID] IS NOT NULL  
		--  )

GO
