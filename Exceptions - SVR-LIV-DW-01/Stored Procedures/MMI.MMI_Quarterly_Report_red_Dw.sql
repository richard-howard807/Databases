SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Sgrego
-- Create date: 14/03/2019
-- Description:	MMI new report by WPS332  reference
-- =============================================
CREATE PROCEDURE [MMI].[MMI_Quarterly_Report_red_Dw]

AS
BEGIN

	SET NOCOUNT ON;
	SELECT 
dim_client.client_code client,
name  [Fee Earner],
dim_fed_hierarchy_history.linemanagername ,
dim_fed_hierarchy_history.reportingbcmname [Supervising Partner],
CASE WHEN dim_client.client_code = 'M00001' THEN 'MMI' ELSE 'Zurich' END [Nature of instruction],
CASE WHEN ISNULL(Rtrim(WPS275),'') = '' THEN insuredclient_reference ELSE WPS275 end [MMI Ref],
'N/A' [Zurich Ref],
RTRIM(dim_client.client_code) +'-'+ dim_matter_header_current.matter_number  [Panel Firm Ref],
CASE WHEN dim_client.client_code = 'M00001' THEN dim_detail_core_details.[delegated] ELSE 'Yes' END [Delegated Authority],
CASE WHEN ISNULL(dim_detail_claim.[policyholder_name_of_insured],'') = '' THEN insurerclient_name  ELSE dim_detail_claim.[policyholder_name_of_insured] end [MMI Insured],
defendant_name [Defendant],
dim_claimant_thirdparty_involvement.claimant_name,
claimantsols_name [Claimant Solicitor],
REPLACE(REPLACE(CASE WHEN dim_client.client_code = 'M00001' and  LOWER(work_type_name) LIKE '%disease%' THEN REPLACE(work_type_name,'Disease - ','')
	 WHEN dim_client.client_code  = 'M00001' AND ( (work_type_code >= '1254' AND work_type_code <= '1263') OR (work_type_code >= '1274' AND work_type_code <= '1277 ') OR work_type_code = '1571' ) THEN 'Abuse'
	 WHEN dim_client.client_code  <> 'M00001' THEN REPLACE(dim_detail_core_details.[injury_type],'Disease - ','') ELSE 'Other' END,'D17 Industrial deafness','Industrial deafness'),'D31 VWF/Reynauds phenomenon','VWF/Reynauds phenomenon') [Claim Type],
work_type_name [Work_type], 
matter_description [matter_description],
dim_detail_core_details.[present_position] [Present position],
--FTR454.case_text 
'' [Job Role],
--LIT1218.case_text 
'' [Risk Type],
dim_detail_core_details.[incident_location] [Risk location],
--LIT1219.case_text 
'' [Risk descriptor (Abuser)],
--LIT1220.case_text 
'' [Abuse Codes],
--LIT1221.case_text 
'' [Allegation TYPE],
dim_detail_critical_mi.[period_of_exposure] [Exposure / Abuse period (s)],
CASE WHEN dim_detail_claim.[our_proportion_percent_of_damages] IS null THEN fact_detail_claim.[disease_insurer_clients_contrib_damages] ELSE dim_detail_claim.[our_proportion_percent_of_damages] END /100  [MMI’s % - Damages],
fact_detail_paid_detail.[indemnity_savings] [MMI’s % - CRU ],
CASE WHEN dim_detail_claim.[our_proportion_percent_of_costs] IS null THEN fact_detail_claim.[disease_insurer_clients_contrib_costs] ELSE dim_detail_claim.[our_proportion_percent_of_costs] END /100  [MMI’s % - Costs],
--NMI997.case_value /100 
'' [MMI’s % - Defence costs],
CASE WHEN dim_detail_core_details.[is_this_the_lead_file] = 'No' OR dim_detail_health.[leadfollow] = 'Follow' THEN 'No' ELSE 'Yes' end [MMI Lead],
date_opened_case_management [Open Date],
dim_detail_core_details.[date_letter_of_claim] [Date of LoC],
dim_detail_core_details.[date_of_cfa] [Date of CFA/DBA],
dim_detail_court.[date_proceedings_issued] [Issue Date],
dim_detail_health.[date_of_service_of_proceedings] [Service Date],
dim_detail_core_details.[zurich_grp_rmg_was_litigation_avoidable] Avoidable,
--LIT1217.case_text 
'' [Litigation cause],
NULL [Gross Estimate],
CASE WHEN (dim_detail_outcome.[outcome_of_case] IS NOT NULL OR dim_detail_outcome.[date_claim_concluded] IS NOT NULL) THEN 0 ELSE fact_finance_summary.[cru_reserve] END [Reserve CRU],
--LIT1223.case_value 
'' [Reserve Claimant’s Costs],
--LIT1225.case_value 
'' [Reserve Own Costs],
--LIT1224.case_value 
'' [Total O/S Reserve],
case WHEN dim_client.client_code <> 'M00001' then fact_detail_paid_detail.[general_damages_paid] + fact_detail_paid_detail.[special_damages_paid] ELSE 0 end [Paid Damages],
CASE WHEN dim_client.client_code <> 'M00001' THEN fact_detail_paid_detail.[cru_paid] /* else NMI122.case_value*/  end [Paid CRU],
case WHEN dim_client.client_code <> 'M00001' then fact_detail_paid_detail.[claimants_costs]  ELSE 0 END [Paid Claimant’s Costs],
case WHEN dim_client.client_code <> 'M00001' then fact_detail_paid_detail.[fee_billed_by_panel] + fact_detail_paid_detail.[own_disbursements] ELSE 0 END [Paid Own Costs],
NULL AS [Total Paid],
NULL AS [Net O/S Reserve],
--LIT1214.case_value 
'' [Claimant’s P36],
--LIT1215.case_value 
'' [Defendant’s P36],
CASE WHEN date_closed_case_management IS not NULL OR dim_detail_client.[date_settlement_form_sent_to_zurich] IS NOT NULL THEN 'Closed' ELSE 'Open' end  [Status], 
--LIT1216.case_text 
'' [Present Position / Barriers to settlement],
dim_detail_outcome.[date_claim_concluded] [Date Damages Settled],
dim_detail_outcome.[date_costs_settled] [Date Costs Agreed],
CASE WHEN dim_detail_client.[date_settlement_form_sent_to_zurich] IS NULL THEN date_closed_case_management ELSE dim_detail_client.[date_settlement_form_sent_to_zurich] END [Closed Date],
dim_detail_core_details.[associated_matter_numbers] [Litigated Matter Number]

,CAST(YEAR(date_opened_case_management) AS NVARCHAR(4)) + '-Q' + CAST(DATEPART(Quarter,date_opened_case_management) AS NVARCHAR(1))  AS [Quarter Received]
,CASE WHEN proceedings_issued ='Yes' THEN 'Litigated' ELSE 'Pre-lit' END AS [Litigated]
,CASE WHEN outcome_of_case IN 
(
'Won at trial','Struck out','Discontinued - post-lit with no costs order','Discontinued - post-lit with costs order','Discontinued - pre-lit'
,'Discontinued','Struck Out','Won at Trial','Discontinued - indemnified by third party','Discontinued - indemnified by 3rd party'
,'discontinued - pre-lit','Won','Withdrawn','Discontinued - post lit with no costs order'
) THEN 'Repudiated'
WHEN outcome_of_case IN (
'Settled'
,'Settled - JSM'
,'Lost at trial'
,'Settled - infant approval'
,'Assessment of damages'
,'Lost at Trial'
,'Settled - mediation'
,'settled'
,'Assessment of damages (damages exceed claimant''s P36 offer)'
,'Assessment of damages (claimant fails to beat P36 offer)'
,'Lost at trial (damages exceed claimant''s P36 offer)'
,'Damages assessed'
) THEN 'Settled'
 

ELSE NULL 
END 

AS [Repudiated/Settled]
,incident_location_postcode AS [IncidentPostcode]
,dim_detail_core_details.referral_reason [Referral Reason]
,date_settlement_form_sent_to_zurich [Date Settlement Form sent to Zurich]
, WPS277
FROM red_Dw.dbo.fact_dimension_main
LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_Dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_Dw.dbo.dim_defendant_involvement ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
LEFT JOIN red_Dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
LEFT JOIN red_Dw.dbo.fact_detail_claim ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_Dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_detail_health ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT JOIN red_Dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_Dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_Dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
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
               WPS386,
               WPS387,
			   WPS277
        FROM
        (
            SELECT client_code,
                   matter_number,
                   sequence_no,
                   dim_parent_key,
                   zurich_rsa_claim_number AS WPS275
            FROM red_dw.dbo.dim_parent_detail
            WHERE client_code IN ( 'Z00002', 'Z00004', 'Z00018', 'Z00006', 'Z00008', 'Z00014', 'Z1001' )
        ) AS Parent
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
				
             LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       current_reserve AS WPS277
                FROM red_dw.dbo.fact_child_detail
				where current_reserve is not null
            ) AS WPS277
                ON Parent.dim_parent_key = WPS277.dim_parent_key
				WHERE WPS275 IS NOT NULL

				
    ) AS ClaimDetails
        ON RTRIM(fact_dimension_main.client_code) = RTRIM(ClaimDetails.client_code)
           AND RTRIM(fact_dimension_main.matter_number) = RTRIM(ClaimDetails.matter_number)

		   WHERE 
(date_closed_case_management >= '2018-01-01' OR date_closed_case_management IS NULL) and 
(date_settlement_form_sent_to_zurich >= '2018-01-01' OR date_settlement_form_sent_to_zurich IS NULL) and
(dim_client.client_code = 'M00001' OR ( dim_detail_claim.[wp_type] IS NOT NULL AND  dim_detail_claim.[wp_type] = 'MMI') )
ORDER BY dim_client.client_code , dim_matter_header_current.matter_number


END
GO
