SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Emily Smith
-- Create date: 20200327
-- Description:	New Instructions
-- =============================================
CREATE PROCEDURE [Tableau].[NewInstructionsWeekly]

AS
BEGIN

	SET NOCOUNT ON;

		SELECT DISTINCT RTRIM(fact_dimension_main.client_code)+'-'+dim_matter_header_current.matter_number AS [Ref]
		, fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_matter_header_current.matter_description AS [Matter Description]
		, dim_matter_header_current.date_opened_practice_management AS [Date Opened]
		, cal_week_in_year AS [Week Number]
		, CAST(DATEADD(dd, -(DATEPART(dw, dim_matter_header_current.date_opened_practice_management)-1), dim_matter_header_current.date_opened_practice_management) AS DATE) [Week Start]
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
		 , CASE WHEN dim_matter_header_current.date_opened_practice_management<=(SELECT DATEADD(DAY,-1,MIN(calendar_date)) AS [CurrentWeekCommencing]  -- Removed 1 days as this is a sunday tableau goes from sunday to sat

									FROM red_dw.dbo.dim_date
									WHERE current_cal_week='Current') THEN 'Weekly' ELSE 'Monthly' END AS [Filter]
									, 1 AS [Number of Matters]
			

 FROM red_dw.dbo.dim_matter_header_current
 LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
 ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history_key_original_matter_owner_dopm=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
--AND dim_matter_header_history.dss_version=1
--AND date_opened_practice_management BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
--ON dim_matter_header_history.fee_earner_code = dim_fed_hierarchy_history.fed_code
--AND dim_matter_header_history.date_opened_practice_management BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
 LEFT OUTER JOIN red_dw.dbo.dim_date 
 ON calendar_date=CAST(dim_matter_header_current.date_opened_practice_management AS DATE)
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


 WHERE dim_matter_header_current.date_opened_practice_management>='2019-01-01'
 AND dim_matter_header_current.date_opened_practice_management<=(SELECT DATEADD(DAY,-1,MIN(calendar_date)) AS [CurrentWeekCommencing]  -- Removed 1 days as this is a sunday tableau goes from sunday to sat
									FROM red_dw.dbo.dim_date
									WHERE current_cal_week='Current')

 AND dim_fed_hierarchy_history.hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
 --AND name ='Natasha Jordan'
-- AND hierarchylevel3hist='Casualty'
 --AND hierarchylevel4hist='Litigation Leeds'
 --AND dim_matter_header_current.date_opened_practice_management >= '2020-10-01' 
 --AND dim_matter_header_current.date_opened_practice_management <= '2020-05-30'
 AND reporting_exclusions=0    
--AND fact_dimension_main.client_code='00451638' AND fact_dimension_main.matter_number='00004477'--00451638-00004477
--excluded as bulk opened thousands of matters, BH
and NOT dim_matter_worktype.work_type_name IN ('Wills Archive','Deeds Archive')

END

GO
