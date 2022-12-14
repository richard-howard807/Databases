SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[JCBMatterListings]
AS
BEGIN

	SELECT
		case_id
		   , REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'
    + REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Weightmans Reference]
		, CASE 
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2002-12-30' AND '2004-04-30' THEN 'GB00004225LI02A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2004-05-01' AND '2005-04-30' THEN 'GB00004225LI04A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2005-05-01' AND '2006-04-30' THEN 'GB00004225LI05A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2006-05-01' AND '2007-04-30' THEN 'GB00004225LI06A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2007-05-01' AND '2008-04-30' THEN 'GB00004225LI07A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2008-05-01' AND '2009-04-30' THEN 'GB00004225LI08A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2009-05-01' AND '2010-04-30' THEN 'GB00004225LI09A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2010-05-01' AND '2011-04-30' THEN 'GB00004225LI10A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2011-05-01' AND '2012-04-30' THEN 'GB00004225LI11A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2012-05-01' AND '2013-04-30' THEN 'GB00004225LI12A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2013-05-01' AND '2014-04-30' THEN 'GB00004225LI13A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2014-05-01' AND '2015-04-30' THEN 'GB00004225LI14A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2015-05-01' AND '2016-04-30' THEN 'GB00004225LI15A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2016-05-01' AND '2017-04-30' THEN 'GB00004225LI16A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2017-05-01' AND '2018-04-30' THEN 'GB00004225LI17A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2018-05-01' AND '2019-04-30' THEN 'GB00004225LI18A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2019-05-01' AND '2020-04-30' THEN 'GB00004225LI19A'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2020-05-01' AND '2021-04-30' THEN 'GB00004225LI20A'
			-- JB - Ticket #67845
			WHEN dim_matter_worktype.work_type_name LIKE 'Disease%' THEN 'TBA'
		 END AS [XL reference]
	,name  AS 'WeightmansHandler'
		,CASE 
			WHEN dim_detail_core_details.[incident_date] BETWEEN '1981-05-01' AND '1982-04-30' THEN '1981/1982'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '1984-05-01' AND '1985-04-30' THEN '1984/1985'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2004-05-01' AND '2005-04-30' THEN '2004/2005'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2005-05-01' AND '2006-04-30' THEN '2005/2006'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2006-05-01' AND '2007-04-30' THEN '2006/2007'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2007-05-01' AND '2008-04-30' THEN '2007/2008'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2008-05-01' AND '2009-04-30' THEN '2008/2009'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2009-05-01' AND '2010-04-30' THEN '2009/2010'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2010-05-01' AND '2011-04-30' THEN '2010/2011'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2011-05-01' AND '2012-04-30' THEN '2011/2012'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2012-05-01' AND '2013-04-30' THEN '2012/2013'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2013-05-01' AND '2014-04-30' THEN '2013/2014'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2014-05-01' AND '2015-04-30' THEN '2014/2015'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2015-05-01' AND '2016-04-30' THEN '2015/2016'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2016-05-01' AND '2017-04-30' THEN '2016/2017'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2017-05-01' AND '2018-04-30' THEN '2017/2018'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2018-05-01' AND '2019-04-30' THEN '2018/2019'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2019-05-01' AND '2020-04-30' THEN '2019/2020'
			WHEN dim_detail_core_details.[incident_date] BETWEEN '2020-05-01' AND '2021-04-30' THEN '2020/2021'
			-- JB - Ticket #67845
			WHEN dim_matter_worktype.work_type_name LIKE 'Disease%' THEN 'TBA'
			END AS 'Year of Account'
		, dim_detail_critical_mi.[agency_worker] [Agency worker]
	,claimant_name AS [Claimant Name]
	,dim_detail_claim.[dst_claimant_solicitor_firm ]
	
,claimantsols_name  AS [Claimant Solicitor_directory]
	, dim_detail_core_details.[date_instructions_received] [Date Claim Notified]
		, CASE 
		       WHEN date_closed_case_management IS NULL 
			   OR   RTRIM(dim_detail_core_details.present_position) != 'To be closed/minor balances to be clear'
			   THEN 'Open'
			   ELSE 'Closed' END [Claim Status]
		, date_closed_case_management [Date Closed]
		, dim_detail_core_details.[suspicion_of_fraud] [Fraud Indicators]	
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 1 ELSE 0 END AS openclosed
		, CASE 
				WHEN work_type_name LIKE 'EL%'
				  OR work_type_name LIKE 'Disease%'
				  THEN 'Employers Liability'
				WHEN work_type_name LIKE 'PL%'
				THEN 'Public Liability' 
		  END [Policy Type]
		, dim_detail_core_details.[incident_date] [DOA Incident date]
		, dim_detail_core_details.[is_there_an_issue_on_liability] [Liability Postition]
		, ISNULL(dim_detail_incident.[accident_site], dim_detail_core_details.[jcb_rolls_royce_site]) [Accident site]
	,work_type_name AS [Causes Code]
	, CASE WHEN dim_matter_worktype.work_type_name LIKE 'Disease -%' THEN 'dis' ELSE 'no' END AS disease
		, ISNULL(dim_detail_core_details.[injury_type],dim_detail_hire_details.[description_of_injury] ) [Description of Injury]
	 , dim_detail_core_details.[brief_details_of_claim] [Description of Incident]
		, dim_detail_incident.[body_position] [Body position]
		, dim_detail_incident.[jcb_body_part] [JCB Body part]
		, dim_detail_core_details.[proceedings_issued] [Litigated]
	    , dim_detail_court.[date_proceedings_issued] [Date proceedings issued]


,		
CASE WHEN 

dim_detail_critical_mi.portal_claim IN
(
'no',
'No                                                          '
)
THEN 'No' ELSE 'Yes'END AS  [Portal claim]
, CASE WHEN 


ISNULL(dim_detail_critical_mi.portal_claim, '')IN
(
'no',
'No'                                                  
) THEN 'N/A' ELSE 'Yes' END AS   [Settled within Portal]
		--, LOWER(ISNULL(dim_detail_critical_mi.[portal_claim], 'no')) [Portal claim]
		
	--	, dim_detail_critical_mi.[settled_within_portal] [Settled within Portal]
		, dim_detail_incident.[portal_drop_out_reason] [Portal drop out reason]		
		, dim_detail_core_details.present_position [Current Position]
		, NULL [EL: Own Legal Costs]
		,CASE WHEN RTRIM(dim_detail_core_details.present_position) IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear') 
		      THEN 0 
			  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) -  ISNULL(total_amount_billed,0)  
			  END AS [EL: Own Legal Costs Reserve Original]
		,CASE WHEN RTRIM(dim_detail_core_details.present_position) IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear') 
		      THEN 0 
			  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) -  (ISNULL(total_amount_billed,0)  -ISNULL(vat_billed,0))
			  END AS [EL: Own Legal Costs Reserve]
	, ISNULL(CASE WHEN dim_detail_outcome.[outcome_of_case] IS NOT NULL
       OR dim_detail_outcome.[date_claim_concluded] IS NOT NULL
	   OR date_closed_case_management IS NOT NULL
	   THEN 0
	   ELSE
		        ISNULL(fact_finance_summary.[damages_reserve], 0) 
			                       - 
					                (
										ISNULL(fact_finance_summary.[cru_reserve], 0) + ISNULL(fact_detail_reserve_detail.[nhs_charges_reserve_current], 0)
									)
									- ISNULL(fact_finance_summary.[damages_interims], 0)
			     END, 0)  AS GeneralDamagesReserve
		, 	ISNULL(CASE WHEN dim_detail_outcome.[outcome_of_case] IS NOT NULL
       OR dim_detail_outcome.[date_claim_concluded] IS NOT NULL
	   OR date_closed_case_management IS NOT NULL
     THEN
     ISNULL(fact_finance_summary.[damages_paid], 0) - 
		      (ISNULL(fact_detail_paid_detail.[cru_costs_paid], 0) + ISNULL(fact_detail_paid_detail.[nhs_charges_paid_by_client], 0))
	ELSE fact_finance_summary.[damages_interims]		  
   END, 0) AS GeneralDamagesPayment
		,ISNULL (CASE WHEN dim_detail_outcome.[outcome_of_case] IS NULL 
		     THEN ISNULL(fact_finance_summary.[cru_reserve], 0) + ISNULL(fact_detail_reserve_detail.[nhs_charges_reserve_current], 0)
			 ELSE 0 
		     END, 0) AS SpecialDamagesReserve
		, ISNULL(fact_detail_paid_detail.[cru_costs_paid], 0) + ISNULL(fact_detail_paid_detail.[nhs_charges_paid_by_client], 0) AS SpecialDamagesPayment
		   ,  ISNULL( 
		 CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL
		        OR date_closed_case_management IS NOT NULL
	          THEN 0 
			  ELSE (ISNULL(fact_detail_reserve_detail.[claimant_costs_reserve_current], 0) + ISNULL(fact_finance_summary.[other_defendants_costs_reserve], 0)) - ISNULL(fact_detail_paid_detail.[interim_costs_payments], 0)
			  END, 0) AS TPLegalCostsReserve
		,ISNULL( 
		 CASE WHEN dim_detail_outcome.[date_costs_settled] IS NULL
		        OR date_closed_case_management IS NOT NULL
	          THEN fact_detail_paid_detail.[interim_costs_payments]
		      ELSE ISNULL(ISNULL(fact_finance_summary.[claimants_costs_paid], 0) + ISNULL(fact_finance_summary.[detailed_assessment_costs_paid], 0) + ISNULL(fact_finance_summary.[other_defendants_costs_paid], 0), 0)
			  END, 0) AS TPLegalCostsInsurerPayment
		  ,ISNULL(red_dw.dbo.fact_finance_summary.total_amount_billed,0) - ISNULL(red_dw.dbo.fact_finance_summary.vat_billed,0) AS OwnLegalCostsInsurerPayment 

		, ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution], 0)
		+ ISNULL(fact_finance_summary.[recovery_defence_costs_from_claimant], 0)
		+ ISNULL(fact_detail_recovery_detail.[recovery_claimants_costs_via_third_party_contribution], 0)
		+ ISNULL(fact_finance_summary.[recovery_defence_costs_via_third_party_contribution], 0)  AS TotalRecovered
		, dim_detail_outcome.[outcome_of_case] AS 'Outcome'
		--LD 20171011 Added below
		,fact_detail_claim.[disease_total_estimated_settlement] [total_estimated)settlement_claimant]
		,fact_detail_future_care.[disease_total_estimated_settlement_value] [total_estimated_settlement_damages]
		,ISNULL(fact_detail_claim.[disease_total_estimated_settlement],0) + ISNULL(fact_detail_future_care.[disease_total_estimated_settlement_value],0) TotalApportionedReserve
		,ISNULL(fact_detail_reserve_detail.[total_current_reserve] ,0) Totalreserved
		,total_amount_billed AS  TotalBilled
		,date_claim_concluded AS [Date Calim Concluded] /*1.1 jl*/
		,fact_finance_summary.[damages_paid] AS [Damages Paid] /*1.1 jl*/
		,date_costs_settled AS [Date Costs Settled] /*1.1 jl*/
		,fact_finance_summary.[claimants_costs_paid] AS [Claimant Costs Paid] /*1.1 jl*/

		
		, dim_court_involvement.court_reference [Claim Number]
		--,[Claim Number] = NULL
		,[Insured] = CASE WHEN [insuredclient_name] LIKE '%Excavators%' THEN 'J C Bamford Excavators Limited' ELSE [insuredclient_name] END 
		,dst_insured_client_name AS InsuredNameDetail
		,[Policy #] = insurerclient_reference
		,[Loss Type / coverage code] = NULL
		,[TPA Office location] = NULL
		,[Date Received] =  dim_detail_core_details.[date_instructions_received]

		,[Loss Country] = 'UK'
		,[Currency code] = 'GBP'
		,[Deductible amount (if applicable)] = NULL
		,[SIR Amount (if applicable)] = NULL

		,LastBillDate.bill_date  AS LastBillDate

		,CASE  WHEN  date_closed_case_management IS NULL THEN 1 
			   WHEN  RTRIM(dim_detail_core_details.present_position) != 'To be closed/minor balances to be clear' THEN 1 
		       WHEN LastBillDate.bill_date > ='2017-07-01'  THEN 1
		       ELSE 0 END AS OpenorconcludedLast12Months

			   , LastBillDate.bill_date
			   ,dim_matter_header_current.client_code + '-' + dim_matter_header_current.matter_number AS [Converge Ref]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_department
 ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi
 ON dim_detail_critical_mi.client_code = dim_matter_header_current.client_code
 AND dim_detail_critical_mi.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number    
LEFT OUTER JOIN red_dw.dbo.dim_detail_incident
 ON dim_detail_incident.client_code = dim_matter_header_current.client_code
 AND dim_detail_incident.matter_number = dim_matter_header_current.matter_number  
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
 ON dim_detail_hire_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_hire_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
 ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
 ON fact_detail_recovery_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_recovery_detail.matter_number = dim_matter_header_current.matter_number  
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
 ON fact_detail_claim.client_code = dim_matter_header_current.client_code
 AND fact_detail_claim.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care
 ON fact_detail_future_care.client_code = dim_matter_header_current.client_code
 AND fact_detail_future_care.matter_number = dim_matter_header_current.matter_number
LEFT OUTER  JOIN red_dw.dbo.fact_dimension_main 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
 LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
 LEFT OUTER JOIN red_dw.dbo.dim_court_involvement ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
 
 LEFT JOIN red_dw.[dbo].[dim_client_involvement] ON dim_client_involvement.client_code = dim_matter_header_current.client_code AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number

 --LEFT JOIN red_dw.[dbo].[dim_bill] ON dim_matter_header_current.client_code = dim_claimant_thirdparty_involvement.client_code
 
 LEFT JOIN (SELECT 
ROW_NUMBER() OVER (PARTITION BY dim_matter_header_curr_key ORDER BY bill_date DESC) RN,
        [dim_matter_header_curr_key]
        ,bill_date
  FROM [red_dw].[dbo].[fact_bill_matter_detail_summary]
  ) LastBillDate ON LastBillDate.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key AND RN = 1  

  
	WHERE 1=1
	-- standard exclusions for test cases and Money Laundering matters
		AND dim_matter_header_current.client_code  IN  ('J26479','W15452')
		AND  dim_matter_header_current.matter_number <> 'ML'
		AND dim_department.department_code <> '0027'
		AND  work_type_code!= '0032'	
		AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management >= '2017-07-01')

		AND ISNULL(outcome_of_case,'') <> 'Exclude from reports'
		AND ISNULL(dim_detail_critical_mi.[claim_status], '') != 'Cancelled'
		AND (  work_type_name   LIKE ('PL%')
               OR work_type_name  LIKE ('EL%')
               OR work_type_name  LIKE ('Disease%')
			   

		)

	

		--AND dim_matter_header_current.client_code='J26479' AND dim_matter_header_current.matter_number='00001268'
	

		/* Taken out as required two tabs for open and closed*/
	 --   AND
		--(
		--(date_closed_case_management IS NULL AND RTRIM(ISNULL(dim_detail_core_details.present_position, '')) != 'To be closed/minor balances to be clear')
		--)





ORDER BY dim_matter_header_current.client_code,dim_matter_header_current.matter_number




END
GO
