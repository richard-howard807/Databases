SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 20200327
-- Description:	New Instructions
-- =============================================
CREATE PROCEDURE [Tableau].[NewInstructions]

AS
BEGIN

	SET NOCOUNT ON;

	SELECT dim_fed_hierarchy_history.[hierarchylevel2hist] AS [Division]
		, dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department]
		, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
		, dim_client.client_group_name AS [Client Group Name]
		, dim_date.calendar_date	
		, dim_date.fin_month_name AS [Month Name]
		, dim_date.fin_month_no AS [Month]
		, dim_date.fin_month
		, dim_date.fin_year
		, dim_date.current_fin_month
		, CAST(fin_year-1 AS VARCHAR)+'/'+CAST(fin_year AS VARCHAR) AS [Year]
		, 1 AS [Open Practice Management Month]
		, dim_detail_core_details.referral_reason AS [Referral Reason]
		, dim_matter_worktype.work_type_group AS [Work Type Group]
		, proceedings_issued AS [Proceedings Issued]
		, dim_detail_finance.output_wip_fee_arrangement
		, dim_detail_core_details.suspicion_of_fraud
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
			ELSE
				'No Reserve' 
		  END			AS [Damages Banding - Extended Version]
		
		, CASE
			WHEN dim_client.client_group_code='00000067' THEN 
				dim_client.client_group_name --Ageas
			WHEN dim_client.client_group_code='00000013' THEN 
				dim_client.client_group_name --AIG
			WHEN dim_client.client_group_code='00000007' THEN 
				dim_client.client_group_name --Axa XL
			WHEN dim_client.client_group_code='00000004' THEN 
				dim_client.client_group_name --Co-operative Group
			WHEN dim_client.client_group_code='00000002' THEN 
				dim_client.client_group_name --MIB
			WHEN dim_client.client_group_code='00000003' THEN 
				dim_client.client_group_name --NHS Resolution
			WHEN dim_client.client_group_code='00000142' AND dim_detail_core_details.injury_type_code LIKE 'D%' THEN 
				dim_client.client_group_name --PWC
			WHEN dim_client.client_group_code='00000001' THEN 
				dim_client.client_group_name --Zurich
			ELSE
				'Other Clients'
		  END						AS [Patron Clients - Extended Version]
		, IIF(ISNULL(dim_detail_core_details.referral_reason, 0) LIKE 'Dispute%', 'Dispute', 'Other')		AS [Referral Reason Filter - Extended Version]

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
			ELSE 'Other' END						AS [Key Clients],
			CASE WHEN current_fin_year IN (
'Current'
,'Previous'
) AND fin_month_no BETWEEN 1 AND (SELECT fin_month_no - 1 FROM red_dw.dbo.dim_date WHERE calendar_date = CAST(GETDATE() AS DATE))
THEN 1 ELSE 0 END AS showit


 FROM red_dw.dbo.fact_dimension_main
 LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
 LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON red_dw.dbo.dim_matter_header_current.fee_earner_code=fed_code
 AND date_opened_practice_management BETWEEN dss_start_date AND dss_end_date
 LEFT OUTER JOIN red_dw.dbo.dim_date 
 ON calendar_date=CAST(date_opened_case_management AS DATE)
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
 INNER  JOIN red_dw.dbo.dim_detail_outcome 
 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
 AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'

 WHERE date_opened_case_management>='2018-05-01'
 AND reporting_exclusions=0
 AND hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
 AND current_cal_month<>'Current'  
    
END

GO
