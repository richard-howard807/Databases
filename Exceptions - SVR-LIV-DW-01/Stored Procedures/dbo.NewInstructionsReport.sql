SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[NewInstructionsReport]
( 
@StartDate AS DATE
,@EndDate AS DATE
)
AS 


BEGIN



SELECT AllData.Ref AS [Client and matter number]
,ClientName
,PatronClient AS [Patron Client]
,AllData.[Matter Description] AS [Matter description]
,AllData.[Matter Owner] AS [Matter owner]
,AllData.Team AS [Team]
,Division
,AllData.Department AS [Department]
,AllData.calendar_date AS [Date opened]
,AllData.[Work Type] AS [Matter type]
,AllData.[Fee Arrangement] AS [Fee arrangement]
,fixed_fee_amount AS  [Fixed fee amount]

FROM
(

		SELECT DISTINCT RTRIM(fact_dimension_main.client_code)+'-'+dim_matter_header_current.matter_number AS [Ref]
		, fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_matter_header_current.matter_description AS [Matter Description]
		, dim_date.calendar_date
		, dim_matter_header_current.date_opened_case_management AS [Date Opened]
		, dim_date.fin_month_name AS [Month Name]
		, dim_date.fin_month_no AS [Month]
		, dim_date.fin_month
		, dim_date.fin_year
		, dim_date.current_fin_month
		, CAST(fin_year-1 AS VARCHAR)+'/'+CAST(fin_year AS VARCHAR) AS [Year]
		, cal_week_in_year AS [Week Number]
		, CAST(DATEADD(dd, -(DATEPART(dw, dim_matter_header_current.date_opened_case_management)-1), dim_matter_header_current.date_opened_case_management) AS DATE) [Week Start]
		, trading_days_in_mth AS [Working Days in Month]
		, dim_fed_hierarchy_history.[hierarchylevel2hist] AS [Division]
		, dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department]
		, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
		, dim_fed_hierarchy_history.[name] AS [Matter Owner]
		, [hierarchy_current].[hierarchylevel4hist] AS [Current Team]
		, [hierarchy_current].[name] AS [Current Matter Owner]
		, ISNULL(dim_client.client_group_name, dim_client.client_name) AS [Client Group Name]
		, segment AS [Segment]
		, sector AS [Sector]
		, dim_instruction_type.instruction_type AS [Instruction Type]
		, dim_detail_core_details.referral_reason AS [Referral Reason]
		, dim_matter_worktype.work_type_name AS [Work Type] 
		, CASE
           WHEN dim_matter_worktype.[work_type_name] IN ('NHSLA - Breach of DPA','NHSLA - Breach of HRA') THEN     
				'PL All'
		   WHEN dim_matter_worktype.[work_type_name] LIKE '%NHSLA%' THEN
               'NHSLA'
           WHEN dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN
               'PL All'
           WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - Pol%' THEN
               'PL Pol'
           WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - OL%' THEN
               'PL OL'
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
		  ELSE ISNULL([MatterGroupList].[Matter Group],  'Other')
       END [Matter Group]
		, dim_matter_worktype.work_type_group AS [Work Type Group]
		, proceedings_issued AS [Proceedings Issued]
		, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement]
		, dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud]
		, CASE WHEN dim_client.client_group_code='00000067' THEN dim_client.client_group_name --Ageas
			WHEN dim_client.client_group_code='00000013' THEN dim_client.client_group_name --AIG
			WHEN dim_client.client_group_code='00000131' THEN dim_client.client_group_name --Aviva
			WHEN dim_client.client_group_code='00000007' THEN dim_client.client_group_name --Axa CS
			WHEN dim_client.client_group_code='00000079' THEN dim_client.client_group_name --BAI Insurance
			--WHEN dim_client.client_group_code='00000017' THEN dim_client.client_group_name --Capita
			WHEN dim_client.client_group_code='00000004' THEN dim_client.client_group_name --Co-operative Group
			WHEN dim_client.client_group_code='00000022' THEN dim_client.client_group_name --Crawford & Co
			WHEN dim_client.client_group_code='00000010' THEN dim_client.client_group_name --Gallagher Bassett
			WHEN dim_client.client_group_code='00000126' THEN dim_client.client_group_name --Go Ahead
			WHEN dim_client.client_group_code='00000038' THEN dim_client.client_group_name --Liberty
			WHEN dim_client.client_group_code='00000018' THEN dim_client.client_group_name --Metropolitan Police
			WHEN dim_client.client_group_code='00000002' THEN dim_client.client_group_name --MIB
			WHEN dim_client.client_group_code='00000006' THEN dim_client.client_group_name --Royal Mail
			WHEN dim_client.client_group_code='00000070' THEN dim_client.client_group_name --Sabre
			WHEN dim_client.client_group_code='00000068' THEN dim_client.client_group_name --Severn Trent
			WHEN dim_client.client_group_code='00000100' THEN dim_client.client_group_name --Surrey Police
			WHEN dim_client.client_group_code='00000030' THEN dim_client.client_group_name --Sussex Police
			WHEN dim_client.client_group_code='00000053' THEN dim_client.client_group_name --Tradex
			WHEN dim_client.client_group_code='00000009' THEN dim_client.client_group_name --Travelers
			WHEN dim_client.client_group_code='00000032' THEN dim_client.client_group_name --Veolia
			WHEN dim_client.client_group_code='00000197' THEN dim_client.client_group_name --Vinci
			WHEN dim_client.client_group_code='00000001' THEN dim_client.client_group_name --Zurich
			WHEN dim_client.client_group_code='00000003' THEN dim_client.client_group_name --NHS Resolution

			WHEN dim_client.client_name='British Transport Police' THEN dim_client.client_name --British Transport Police
			WHEN dim_client.client_name='Cambridgeshire Constabulary' THEN dim_client.client_name --Cambridgeshire Constabulary
			WHEN dim_client.client_name IN ('Capita Insurance Services Ltd','Capita','Chester Street Insurance Holdings Ltd', 'Capita Insurance Services Ltd','Capita Insurance')    THEN dim_client.client_name --Capita Insurance Services Ltd
			WHEN dim_client.client_name='Coris UK Limited' THEN dim_client.client_name --Coris UK Limited
			WHEN dim_client.client_name='Covea Insurance Plc' THEN dim_client.client_name --Covea Insurance Plc
			WHEN dim_client.client_name='DHL' THEN dim_client.client_name --DHL
			WHEN dim_client.client_name='Municipal Mutual Insurance Limited' THEN dim_client.client_name --Municipal Mutual Insurance Limited
			WHEN dim_client.client_name='Pro Insurance Solutions Ltd' THEN dim_client.client_name --Octagon Insurance Company Limited
			WHEN dim_client.client_name='Octagon Insurance Company Limited' THEN dim_client.client_name --Octagon Insurance Company Limited
			WHEN dim_client.client_name='Tesco' THEN dim_client.client_name --Tesco
			WHEN dim_client.client_name='TCS Claims t/a Endsleigh Insurance Services Limited' THEN dim_client.client_name --TCS Claims t/a Endsleigh Insurance Services Limited
			WHEN dim_client.client_name='Van Ameyde UK Ltd' THEN dim_client.client_name --Van Ameyde UK Ltd
			WHEN dim_client.client_name='Vericlaim UK Limited' THEN dim_client.client_name --Vericlaim UK Limited
			ELSE 'Other' END AS [Key Clients]
		 , CASE WHEN dim_matter_header_current.date_opened_case_management<=(SELECT DATEADD(DAY,-1,MIN(calendar_date)) AS [CurrentWeekCommencing]  -- Removed 1 days as this is a sunday tableau goes from sunday to sat

									FROM red_dw.dbo.dim_date
									WHERE current_cal_week='Current') THEN 'Weekly' ELSE 'Monthly' END AS [Filter]
									, 1 AS [Number of Matters]
		
		
				, CASE WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)=0 THEN '£0'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=50000 THEN '£1-£50,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=100000 THEN '£50,000-£100,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=250000 THEN '£100,000-£250,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=1000000 THEN '£250,000-£1m'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=3000000 THEN '£1m-£3m'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)>3000000 THEN '>£3m' ELSE '£0' END AS [Damages Banding]
		
		, CASE 
		WHEN (
				CASE 
					WHEN LOWER(work_type_name)='claims handling' THEN 
						COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve])  
					WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
						fact_finance_summary.[damages_reserve]
					WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
						fact_detail_reserve_detail.initial_damages_reserve
					ELSE
						fact_finance_summary.damages_paid
					END) <= 25000 THEN 
			'Fast Track'
		WHEN (
				CASE 
					WHEN LOWER(work_type_name)='claims handling' THEN 
						COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
					WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
						fact_finance_summary.[damages_reserve]
					WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
						fact_detail_reserve_detail.initial_damages_reserve
					ELSE
						fact_finance_summary.damages_paid
				END) <= 100000 THEN 
			'£25,000-£100,000'
		WHEN (
				CASE 
					WHEN LOWER(work_type_name)='claims handling' THEN 
						COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
					WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
						fact_finance_summary.[damages_reserve]
					WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
						fact_detail_reserve_detail.initial_damages_reserve
					ELSE
						fact_finance_summary.damages_paid
				END) <= 500000 THEN 
			'£100,001-£500,000'
		WHEN (
				CASE
					WHEN LOWER(work_type_name)='claims handling' THEN 
						COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
					WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
						fact_finance_summary.[damages_reserve]
					WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
						fact_detail_reserve_detail.initial_damages_reserve
					ELSE
						fact_finance_summary.damages_paid 
				END) <= 1000000 THEN 
			'£500,001-£1m'
		WHEN (
				CASE 
					WHEN LOWER(work_type_name)='claims handling' THEN 
						COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
					WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
						fact_finance_summary.[damages_reserve]
					WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
						fact_detail_reserve_detail.initial_damages_reserve
					ELSE
						fact_finance_summary.damages_paid 
				END) <= 3000000 THEN 
			'£1m-£3m'
		WHEN dim_detail_core_details.referral_reason NOT LIKE 'Dispute%' THEN 
			'Other Instructions'
		ELSE
			'No Reserve' 
	END					AS [Damages Banding - Extended Version]
	,CASE WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Ageas' then 'Ageas'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='AIG' then 'AIG'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='AXA XL' then 'AXA XL'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Co-op/Markerstudy' then 'Co-op/Markerstudy'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Hiscox Group' then 'Hiscox Group'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Markel' then 'Markel'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='NHS Resolution' then 'NHS Resolution'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Northern Powergrid' then 'Northern Powergrid'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='pwc' then 'pwc'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Royal Mail' then 'Royal Mail'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Sabre' then 'Sabre'
WHEN ISNULL(dim_client.client_group_name, dim_client.client_name)='Zurich' then 'Zurich'
WHEN dim_client.client_code='00134912' then 'Medical Protection Society'
WHEN dim_client.client_code='T15069' then 'Medical Protection Society'
WHEN dim_client.client_code='00756630' then 'Clarion Housing Group'
WHEN dim_client.client_code='91958C' then 'Clarion Housing Group'
WHEN dim_client.client_code='T3003' then 'Tesco'
WHEN dim_client.client_code='00004908' then 'Hastings Direct'
else '* Non-Patron Clients'
END AS PatronClient
,ISNULL(CASE WHEN dim_client.client_group_name='' THEN NULL ELSE dim_client.client_group_name END , dim_client.client_name) AS ClientName
	,fact_finance_summary.fixed_fee_amount AS fixed_fee_amount
 FROM red_dw.dbo.dim_matter_header_current
 LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
 ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history_key_original_matter_owner_dopm=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
--AND dim_matter_header_history.dss_version=1
--AND date_opened_case_management BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
--ON dim_matter_header_history.fee_earner_code = dim_fed_hierarchy_history.fed_code
--AND dim_matter_header_history.date_opened_case_management BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
 LEFT OUTER JOIN red_dw.dbo.dim_date 
 ON calendar_date=CAST(dim_matter_header_current.date_opened_case_management AS DATE)
 LEFT OUTER JOIN red_dw.dbo.dim_client 
 ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
 LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
 LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
 LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
 ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
 LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
 LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
 LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome 
 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
 --AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
 LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS [hierarchy_current]
 ON hierarchy_current.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
 LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
 ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
 LEFT JOIN Reporting.[dbo].[MatterGroupList]
ON dim_matter_worktype.[work_type_name] = [MatterGroupList].[Matter Type] COLLATE DATABASE_DEFAULT

 WHERE dim_matter_header_current.date_opened_case_management>='2019-01-01'
 AND dim_matter_header_current.date_opened_case_management<=(SELECT DATEADD(DAY,-1,MIN(calendar_date)) AS [CurrentWeekCommencing]  -- Removed 1 days as this is a sunday tableau goes from sunday to sat
									FROM red_dw.dbo.dim_date
									WHERE current_cal_week='Current')

 AND dim_fed_hierarchy_history.hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
 --AND name ='Natasha Jordan'
-- AND hierarchylevel3hist='Casualty'
 --AND hierarchylevel4hist='Litigation Leeds'
 --AND dim_matter_header_current.date_opened_case_management >= '2020-10-01' 
 --AND dim_matter_header_current.date_opened_case_management <= '2020-05-30'
 AND reporting_exclusions=0    
--AND fact_dimension_main.client_code='00451638' AND fact_dimension_main.matter_number='00004477'--00451638-00004477
--excluded as bulk opened thousands of matters, BH
AND NOT dim_matter_worktype.work_type_name IN ('Wills Archive','Deeds Archive')

) AS AllData
WHERE AllData.calendar_date BETWEEN @StartDate AND @EndDate


END
GO
