SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Kevin Hansen
-- Create date: 02.04.19
-- Description:	New report for Request 15232
-- =============================================
CREATE PROCEDURE [dbo].[MMIMatterListingsNonM00001]
AS
BEGIN
SELECT DISTINCT 
name AS [Fee Earner – Case Manager]
,matter_partner_full_name AS [Supervising Partner – Matter Partner]
,'Zurich' AS [Nature of instruction – default to “MMI”]
,RTRIM(WPS275) AS [MMI Ref – Reference from Insurer Client Associate]
,NULL AS [Zurich Ref – leave blank]
,RTRIM(dim_matter_header_current.client_code) +'.' + CAST(CAST(red_dw.dbo.dim_matter_header_current.matter_number AS INT) AS NVARCHAR(MAX)) AS [Panel Firm Ref – Weightmans Client/Matter]
,dim_detail_core_details.[delegated] AS [Delegated Authority - TRA115 cboDelegated]
,CASE
	   WHEN  ISNULL(WPS344,'') <> ''  THEN WPS344  
           WHEN UPPER(dim_detail_claim.[policyholder_name_of_insured]) IS NULL THEN
               UPPER(RTRIM(dim_detail_core_details.[zurich_policy_holdername_of_insured]))
           ELSE
               UPPER(RTRIM(dim_detail_claim.[policyholder_name_of_insured]))
       END AS [MMI Insured – Name from Insured Client Associate]
,CASE
	   WHEN  ISNULL(WPS344,'') <> ''  THEN WPS344  
           WHEN UPPER(dim_detail_claim.[policyholder_name_of_insured]) IS NULL THEN
               UPPER(RTRIM(dim_detail_core_details.[zurich_policy_holdername_of_insured]))
           ELSE
               UPPER(RTRIM(dim_detail_claim.[policyholder_name_of_insured]))
       END AS [Defendant – Name from Defendant Associate]
,UPPER(RTRIM(dim_detail_claim.[zurich_claimants_name]))  AS [Claimant First Name]
,UPPER(RTRIM(dim_detail_claim.[zurich_claimants_name]))  AS [Claimant Surname]
,ms_only AS [ms_only]
,UPPER(RTRIM(dim_detail_client.[zurich_claimants_sols_firm])) AS [Claimant Solicitor – Name from Claimant Solicitor Associate]
,CASE
           WHEN RTRIM(dim_detail_core_details.[injury_type_code]) LIKE 'D17%' THEN
               'NIHL'
           WHEN RTRIM(dim_detail_core_details.[injury_type_code]) LIKE 'D31%' THEN
               'HAVS'
           ELSE
               RTRIM(dim_detail_core_details.[injury_type])
       END AS [Claim Type]
,dim_detail_core_details.[occupation] AS [Job Role]
,NULL AS [Risk Type]
,UPPER(RTRIM(dim_detail_claim.[location_of_claimants_workplace])) AS [Risk location]
,NULL AS [Risk descriptor]
,NULL AS [Abuse Codes]
,NULL AS [Allegation type]
,dim_detail_critical_mi.[period_of_exposure] AS [Exposure / Abuse period]
,CAST(WPS283 AS VARCHAR(250)) + '%' AS [MMI’s % - Damages]
,NULL AS [MMI’s % - CRU]
,CAST(WPS284 AS VARCHAR(250)) + '%' AS [MMI’s % - Costs]
,NULL AS [MMI’s % - Defence costs - NMI997]
,RTRIM(WPS276)  AS [MMI Lead]
,dim_matter_header_current.date_opened_case_management AS [Open Date]
,dim_detail_core_details.referral_reason  AS [Referral reason (internal only)]
,dim_detail_core_details.[date_letter_of_claim]  AS [Date of LoC]
,dim_detail_core_details.[has_the_claimant_got_a_cfa] AS [Has the Claimant got a CFA? (internal only)]
,dim_detail_core_details.[date_of_cfa] AS [Date of CFA/DBA]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued (Internal only)]
,dim_detail_court.[date_proceedings_issued] AS [Issue Date]
,dim_detail_health.[date_of_service_of_proceedings] AS [Service Date]
,dim_detail_core_details.[zurich_grp_rmg_was_litigation_avoidable] AS [Avoidable]
,NULL AS [Litigation cause - LIT1217]
,NULL AS [Total Incurred]
,NULL AS [Reserve Damages (Gross) (Internal only)]
,NULL AS [Reserve Damages (Net)]
,NULL AS [Reserve CRU (Gross)(Internal only)]
,NULL AS [Reserve CRU (Net)]
,NULL AS [Reserve Claimant’s Costs (Gross) (Internal only)]
,NULL AS [Reserve Claimant’s Costs (Net)]
,NULL AS [Reserve Own Costs (Gross)]
,NULL AS [Reserve Own Costs (Net)]
,WPS277 AS [Total O/S Reserve]
,NULL AS [Damages Paid (inc. CRU) (Internal only)]
,NULL AS [Interim Damages Paid (Internal only) - FTR049 curIntDamsPreIn + NMI065 curInDamPayPo]
,ISNULL(WPS278,0) + ISNULL(WPS279,0)  AS [Paid Damages]
,WPS281 AS [Paid CRU]
,NULL AS [Interim Costs Paid (Internal only) - FTR049 curIntDamsPreIn + NMI066 curIntCoPayPost]
,WPS280 AS [Paid Claimant’s Costs]
,ISNULL(WPS340, 0) + ISNULL(WPS341, 0) AS [Paid Own Costs]
,(ISNULL(WPS278,0) + ISNULL(WPS279,0) +ISNULL(WPS280,0) + ISNULL(WPS281,0) 
	   + ISNULL(WPS340,0)+ ISNULL(WPS341,0) - ISNULL(WPS282,0) ) AS [Total Paid - Sum of columns “Paid Damages” + “Paid CRU” + “Paid Claimant’s Costs” + “Paid Own Costs”]
,WPS282 AS [Total Recovery]
,fact_detail_claim.[mmi_claimants_part_36_offer] AS [Claimant’s P36 - LIT1214]
,fact_detail_claim.[mmi_defendants_part_36_offer] AS [Defendant’s P36 - LIT1215]
,outcome_of_case AS [Outcome (Internal only) – TRA068 cboOutcomeCase]
, CASE
			WHEN WPS387 IS NOT NULL THEN RTRIM(WPS387)
           WHEN dim_detail_critical_mi.[claim_status] IS NULL THEN
               'Open'
           WHEN dim_detail_critical_mi.[claim_status] IN ( 'Re-opened', 'Re-Opened' ) THEN
               'Open'
           ELSE
               RTRIM(dim_detail_critical_mi.[claim_status])
           END AS [Status]
,dim_detail_core_details.present_position AS [Present Position (Internal only)]
,NULL AS [Present Position / Barriers to settlement - LIT1216]
,date_claim_concluded AS [Date Damages Settled]
,date_costs_settled AS [Date Costs Agreed]
,last_bill_date AS [Date Final Bill Issued]
,date_settlement_form_sent_to_zurich AS [Closed Date]
,dim_detail_client.[old_zurich_reporting_category]
,red_dw.dbo.fact_finance_summary.total_amount_billed AS [TotalBilled (internal only)]
,red_dw.dbo.fact_finance_summary.claimants_total_costs_paid_by_all_parties	AS [Damages Paid (all parties) (internal only)]
,fact_detail_paid_detail.total_settlement_value_of_the_claim_paid_by_all_the_parties AS [Claimant’s Costs Paid (all parties) (internalonly)]
,CASE 
WHEN red_dw.dbo.dim_detail_outcome.outcome_of_case  = 'Exclude fromreports' THEN 'Cancelled'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 THEN 'Closed - Paid Claim'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Discontinued','Won at trial','Struck out') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties =0 THEN 'Closed – Repudiated'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Discontinued','Won at trial','Struck out') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties =0 THEN 'Open – Repudiated'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 AND date_costs_settled IS NOT NULL THEN 'Open – CostsSettled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 AND fact_finance_summary.[claimants_costs_paid] >0THEN 'Open – CostsSettled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 AND date_costs_settled IS NULL AND fact_finance_summary.[claimants_costs_paid] = NULL OR fact_finance_summary.[claimants_costs_paid] =0 THEN 'Open – DamagesSettled'  
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND date_costs_settled IS NOT NULL THEN 'Open – Costs Settled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND date_claim_concluded IS NOT NULL THEN 'Open – Damages Settled'
WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL AND red_dw.dbo.dim_detail_claim.referral_reason = 'Advice only'THEN 'Closed – Advice only'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_claim.referral_reason = 'Advice only'THEN 'Open – Advice only'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND dim_detail_core_details.present_position IN   ('To be closed/minor balances to be clear', 'Final bill sent– unpaid','Final bill due – claim and costs concluded', 'Claim and costsconcluded but recovery outstanding') THEN 'Open - Costs Settled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND dim_detail_core_details.present_position IN ('Claim concluded but costs outstanding') THEN 'Open -Damages Settled'
ELSE 'Live'
END AS [Status (Internal Only)]
,fact_matter_summary_current.last_bill_date

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
    LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
        ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
    INNER JOIN red_dw.dbo.fact_finance_summary
        ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
        ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
        ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
        ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_health
        ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
        ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
        ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_litigation
        ON dim_detail_litigation.dim_detail_litigation_key = fact_dimension_main.dim_detail_litigation_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
        ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
    LEFT OUTER JOIN red_dw.dbo.dim_employee
        ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
        ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
   LEFT OUTER JOIN  red_dw.dbo.fact_detail_paid_detail 
		 ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
   LEFT OUTER JOIN
    (
        SELECT client_code,
               matter_number,
               Reporting.dbo.Concatenate(ClaimNumber, ',') AS LitigatedRef,
               SUM(NumberClaimants) AS NoRef
        FROM
        (
            SELECT invol_full.client_code,
                   invol_full.matter_number,
                   ISNULL(RTRIM(thisfirm_reference), '') AS ClaimNumber,
                   1 AS NumberClaimants
            FROM red_dw.dbo.dim_involvement_full AS invol_full
                INNER JOIN red_dw.dbo.dim_defendant_involvement invol
                    ON invol.thisfirm_1_key = invol_full.dim_involvement_full_key
            WHERE invol_full.capacity_code = 'THISFIRM'
                  AND invol_full.entity_code IS NOT NULL
                  AND invol_full.entity_code <> '        '
                  AND invol_full.client_code IN ( 'Z00002', 'Z00004', 'Z00018', 'Z00006', 'Z00008', 'Z00014', 'Z1001' )
        ) AS AllData
        GROUP BY AllData.client_code,
                 AllData.matter_number
    ) AS LitigatedRef
        ON fact_dimension_main.client_code = LitigatedRef.client_code
           AND fact_dimension_main.matter_number = LitigatedRef.matter_number
    LEFT OUTER JOIN
    (
        
        SELECT Parent.client_code,
               Parent.matter_number,
               sequence_no,
               Parent.dim_parent_key,
               ROW_NUMBER() OVER (PARTITION BY Parent.client_code,
                                               Parent.matter_number
                                  ORDER BY Parent.client_code,
                                           Parent.matter_number,
                                           Parent.sequence_no,
                                           Parent.dim_parent_key ASC
                                 ) AS xorder,
               WPS275,
               WPS276,
               WPS277,
               WPS278,
               WPS279,
               WPS280,
               WPS281,
               WPS282,
               WPS283,
               WPS284,
               WPS340,
               WPS344,
               WPS341,
               WPS332,
               WPS335,
               WPS386,
               WPS387
        FROM
        (
            SELECT client_code,
                   matter_number,
                   sequence_no,
                   dim_parent_key,
				   ms_only,
                   zurich_rsa_claim_number AS WPS275
            FROM red_dw.dbo.dim_parent_detail
            WHERE client_code IN ( 'Z00002', 'Z00004', 'Z00018', 'Z00006', 'Z00008', 'Z00014', 'Z1001' )
        ) AS Parent
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       lead_follow AS WPS276
                FROM red_dw.dbo.dim_child_detail
				where lead_follow is not null 
            ) AS WPS276
                ON Parent.dim_parent_key = WPS276.dim_parent_key
            /*--------*/
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       current_reserve AS WPS277
                FROM  red_dw.dbo.fact_child_detail  
				where current_reserve is not null
            ) AS WPS277
                ON Parent.dim_parent_key = WPS277.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       general_damages_paid AS WPS278
                FROM red_dw.dbo.fact_child_detail
				where general_damages_paid is not null
            ) AS WPS278
                ON Parent.dim_parent_key = WPS278.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       special_damages_paid AS WPS279
                FROM red_dw.dbo.fact_child_detail
				where special_damages_paid is not null
            ) AS WPS279
                ON Parent.dim_parent_key = WPS279.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       claimants_costs_paid AS WPS280					  
                FROM red_dw.dbo.fact_child_detail
				 where claimants_costs_paid is not null
            ) AS WPS280
               ON Parent.dim_parent_key = WPS280.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       cru_paid AS WPS281
                FROM red_dw.dbo.fact_child_detail
				where cru_paid is not null
            ) AS WPS281
                ON Parent.dim_parent_key = WPS281.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       monies_recovered_if_applicable AS WPS282
                FROM red_dw.dbo.fact_child_detail
				where monies_recovered_if_applicable is not null
            ) AS WPS282
                ON Parent.dim_parent_key = WPS282.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       our_proportion_per_of_damages AS WPS283
                FROM red_dw.dbo.fact_child_detail
				where our_proportion_per_of_damages is not null
            ) AS WPS283
                ON Parent.dim_parent_key = WPS283.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       our_proportion_per_of_costs AS WPS284
                FROM red_dw.dbo.fact_child_detail
				where our_proportion_per_of_costs is not null
            ) AS WPS284
                ON Parent.dim_parent_key = WPS284.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       fee_billed_by_panel AS WPS340
                FROM red_dw.dbo.fact_child_detail
				where fee_billed_by_panel is not null
            ) AS WPS340
                ON Parent.dim_parent_key = WPS340.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       own_disbursements AS WPS341
                FROM red_dw.dbo.fact_child_detail
				where own_disbursements is not null
            ) AS WPS341
                ON Parent.dim_parent_key = WPS341.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       policy_holder_name_of_insured AS WPS344
                FROM red_dw.dbo.dim_child_detail
				where policy_holder_name_of_insured is not null
            ) AS WPS344
                ON Parent.dim_parent_key = WPS344.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       wp_type AS WPS332
                FROM red_dw.dbo.dim_child_detail
				where wp_type is not null
            ) AS WPS332
                ON Parent.dim_parent_key = WPS332.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       mfu AS WPS335
                FROM red_dw.dbo.dim_child_detail
				where mfu is not null
            ) AS WPS335
                ON Parent.dim_parent_key = WPS335.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       date_settlement_form_sent_to_zurich AS WPS386
                FROM red_dw.dbo.dim_child_detail
				where date_settlement_form_sent_to_zurich is not null
            ) AS WPS386
                ON Parent.dim_parent_key = WPS386.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       claim_status AS WPS387
                FROM red_dw.dbo.dim_child_detail
				where claim_status is not null
            ) AS WPS387
                ON Parent.dim_parent_key = WPS387.dim_parent_key
				LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code = Parent.client_code
				AND dim_matter_header_current.client_code = Parent.client_code
				WHERE WPS275 IS NOT NULL
                AND Parent.ms_only IS NOT null
				
    ) AS ClaimDetails
        ON RTRIM(fact_dimension_main.client_code) = RTRIM(ClaimDetails.client_code)
           AND RTRIM(fact_dimension_main.matter_number) = RTRIM(ClaimDetails.matter_number)
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
WHERE (
		(
          dim_matter_header_current.client_code IN ( 'Z1001','Z00002', 'Z00004', 'Z00018', 'Z00014' )
		  or		  
			red_dw.dbo.dim_matter_header_current.case_id IN 
			(22358,25009,20520,20691,20916,23882,21282,
									21380,24414,25488,24735,21367,21361,21602,
									24893,21867,23579,22159,22500,22245,22321
								   ,374091,395458,406599,410799,415781,415815
									,382964,389385,393324,411937)
									)
         
             AND dim_detail_client.[zurich_instruction_type] LIKE 'Outsource%'
             AND dim_detail_client.[zurich_instruction_type] <> 'Outsource - Mesothelioma'
      
      AND reporting_exclusions =0
      AND
      (
          dim_detail_client.[zurich_data_admin_exclude_from_reports] = 'No'
          OR dim_detail_client.[zurich_data_admin_exclude_from_reports] IS NULL
      )
	  		OR ms_fileid IN (
		4867697,4867731,4867770,4867821,4867837,4867868,4867866,4867886,4867910,4867963,4867965,4867983,4867986,4875783,4867970,4867814,4867843,4867846,4867891,4867844,4867681,4880231,4872876,4872946,4872978,4846633,4880416,4880569,4880623,4873223,4880692,4889902,4859810,4885808,4885809,4885810,4885824,4885811,4885818,4885919,
		4885920,4885921,4885922,4885923,4885924,4885925,4885926,4885927,4885928,4885819,4885930,4885931,4885932,4885933,4885934,4885935,4885936,4885937,4885938,4885939,4885820,4885942,4885943,4885944,4885945,4885946,4885947,4885948,4885949,4885952,4885953,4885954,4885955,4885956,4885957,4885958,4885959,4885960,4885961,4885822,
		4885963,4885964,4885965,4885966,4885967,4885968,4885969,4885970,4885971,4885972,4885823,4885975,4885977,4885978,4885979,4885980,4885981,4885982,4885983,4885984,4885986,4885987,4885988,4885989,4885990,4885991,4885992,4885993,4885994,4885995,4885825,4885997,4885998,4885999,4886000,4886001,4886002,4886003,4886004,4886005,
		4886006,4885826,4886008,4886009,4886010,4886011,4886012,4886013,4886014,4886015,4886016,4886017,4885827,4886019,4886020,4886021,4886022,4886023,4886024,4886025,4886026,4886027,4886028,4885829,4886030,4886031,4886032,4886033,4886034,4886035,4886036,4886037,4886038,4886039,4885830,4886041,4886042,4886043,4886044,4886045,
		4886046,4886047,4886048,4886049,4886050,4886052,4886053,4886054,4886055,4886056,4886059,4886060,4886061,4886063,4886064,4886065,4886066,4886067,4886068,4886069,4886070,4886071,4886072,4885833,4886074,4886075,4886076,4886077,4886078,4886079,4886080,4886081,4886082,4886083,4885834,4885836,4885837,4885841,4885843,4885844,
		4885845,4885846,4885847,4885848,4885849,4885851,4885852,4885854,4885855,4885856,4885857,4885858,4885859,4885860,4885812,4885864,4885865,4885866,4885867,4885868,4885869,4885870,4885871,4885872,4885873,4885813,4885875,4885876,4885877,4885878,4885879,4885880,4885881,4885882,4885883,4885884,4885814,4885886,4885888,4885889,
		4885890,4885891,4885892,4885893,4885894,4885895,4885897,4885898,4885900,4885901,4885902,4885903,4885904,4885905,4885906,4885908,4885909,4885910,4885911,4885912,4885913,4885914,4885915,4885916,4885917,4885821,4886057,4886086,4886087,4886088,4886089,4886090,4886091,4886092,4886093,4886094,4886095,4886097,4886098,4886099,
		4886100,4886101,4886103,4886104,4886105,4886108,4886109,4886110,4886111,4886112,4886113,4886114,4886115,4886116,4886117,4886119,4886120,4886121,4886122,4886123,4886124,4886125,4886126,4886127,4886128,4886130,4886131,4886132,4886133,4886134,4886135,4886136,4886137,4886138,4886142,4886144,4886145,4886146,4886147,4886148,
		4886149,4886150,4886152,4886153,4886154,4886155,4886157,4886158,4886159,4886160,4886163,4886164,4886165,4886166,4886167,4886169,4886170,4886172,4886174,4886175,4886176,4886177,4886178,4886179,4886180,4886181,4886182,4886183,4886185,4886186,4886187,4886188,4886189,4886190,4886191,4886192,4886193,4886194,4886197,4886198,
		4886199,4886200,4886201,4886202,4886203,4886204,4886205,4886206,4886208,4886209,4886210,4886211,4886212,4886213,4886215,4886216,4886217,4886219,4886220,4886221,4886222,4886223,4886224,4886225,4886226,4886227,4886228,4886230,4886231,4886232,4886233,4886234,4886235,4886236,4886237,4886238,4886239,4886241,4886242,4886243,
		4886245,4886246,4886247,4886248,4886252,4886253,4886254,4886255,4886256,4886257,4886258,4886259,4886260,4886261,4886263,4886264,4886265,4886266,4886267,4886268,4886269,4886270,4886271,4886272,4886275,4886276,4886277,4886278,4886279,4886280,4886281,4886282,4886285,4886290,4886058,4886161,4860926,4886214,4886288,4886289,
		4886291,4886294,4886292,4886293,4886310,4886311,4886326,4886312,4886313,4886323,4886314,4886315,4886316,4886317,4886319,4886321,4886322,4886320,4886324,4886327,4886328,4886330,4886331,4886332,4886333,4886334,4886325,4886343,4886335,4886336,4886337,4886338,4886339,4886344,4886341,4886345,4886342,4886346,4886347,4886348,
		4886349,4886350,4886352,4886353,4886354,4886355,4886356,4886357,4886358,4886359,4886360,4886361,4886363,4886364,4886365,4886366,4886367,4886368,4886369,4886370,4886371,4886372,4886374,4886375,4886376,4886377,4886378,4886379,4886380,4886381,4886391,4862112,4886382,4886383,4886385,4886386,4886387,4886388,4886389,4886390,
		4886392,4886393,4886394,4886397,4886398,4886399,4886400,4886401,4886402,4886403,4886404,4886405,4886407,4886408,4886410,4886411,4886412,4886419,4886413,4886415,4886414,4886416,4886420,4886421,4886422,4886423,4886424,4886426,4886427,4886428,4886425,4886430,4886435,4886431,4886432,4886433,4886436,4886437,4886438,4886439,
		4886441,4886442,4886443,4886444,4886445,4886446,4886447,4886448,4886449,4886450,4886453,4886454,4886461,4886455,4886456,4886457,4886458,4886459,4886460,4886463,4886464,4886466,4886467,4886465,4886468,4886469,4886470,4886471,4886472,4886474,4886475,4886476,4886477,4886478,4886479,4886480,4886481,4886483,4886482,4886485,
		4886486,4886487,4886488,4886489,4886490,4886491,4886492,4886493,4886494,4886496,4886498,4886497,4886499,4886500,4886501,4886502,4886503,4886504,4886505,4886507,4886508,4886509,4886510,4886511,4886512,4886514,4886515,4886516,4886518,4886519,4886520,4886521,4886522,4886523,4886524,4886525,4886526,4886527,4886530,4886531,
		4886532,4886533,4886534,4886535,4886536,4886537,4886538,4886539,4886542,4886543,4886544,4886545,4886546,4886547,4886548,4886549,4886550,4886552,4886553,4886554,4886555,4886556,4886557,4886558,4886559,4886560,4886561,4886563,4886564,4886565,4886566,4886567,4886568,4886569,4886570,4886571,4886572,4886574,4886578,4886575,
		4886576,4886577,4886579,4886580,4886581,4886582,4886583,4886585,4886586,4886587,4886588,4886589,4886590,4886591,4886596,4886592,4886593,4886594,4886597,4886598,4886599,4886600,4886601,4886602,4886603,4886604,4886605,4886607,4886608,4886609,4886610,4886612,4886611,4886613,4886614,4886615,4886616,4886618,4886619,4886620,
		4886621,4886622,4886623,4886624,4981851,4984089,4985408,4886002,4859922,4849998,4861830,4886061,4886336,4865908,4860354)
		
		) 
		AND UPPER(WPS332)  LIKE '%MMI%'	
		AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2018-01-01')

		END
GO
