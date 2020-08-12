SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-11
-- Description:	#66654, Board Client SLA dashboard
-- =============================================
CREATE PROCEDURE [dbo].[ClientDashboard]
	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT DISTINCT
	dim_client.client_group_name AS [Client Group Name]
	, YTDRevenue.[YTD Revenue]
	, PYYTDRevenue.[PY YTD Revenue]
	, YTDInstructions.[No. Instructions] [YTD Instructions]
	, PYYTDInstructions.[No. Instructions] AS [PY YTD Instructions]
	, Exceptions.no_exceptions AS [No. Exceptions]
	, Exceptions.cases AS [No. Cases]
	
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
 INNER  JOIN red_dw.dbo.dim_detail_outcome 
 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
 AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key

LEFT OUTER JOIN (	SELECT client_group_name, SUM(bill_amount) AS [YTD Revenue] 
							FROM red_dw.dbo.fact_bill_activity
							LEFT OUTER JOIN red_dw.dbo.dim_bill_date
							ON dim_bill_date.dim_bill_date_key = fact_bill_activity.dim_bill_date_key
							INNER JOIN red_dw.dbo.dim_client
							ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
							AND client_group_code IN ('00000001' --Zurich
							,'00000003' --NHS Resolution   
							,'00000002' --MIB
							,'00000006' --Royal Mail
							,'00000067' --Ageas
							,'00000013' --AIG
							,'00000142' --pwc
							)
							WHERE bill_fin_year=(SELECT DISTINCT fin_year FROM red_dw.dbo.dim_date
							WHERE current_fin_year='Current')
							AND fact_bill_activity.bill_date<(SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date
										WHERE current_fin_month='Current')
							GROUP BY client_group_name) AS [YTDRevenue] ON YTDRevenue.client_group_name = dim_client.client_group_name

LEFT OUTER JOIN (		SELECT client_group_name, SUM(bill_amount) AS [PY YTD Revenue] 
							FROM red_dw.dbo.fact_bill_activity
							LEFT OUTER JOIN red_dw.dbo.dim_bill_date
							ON dim_bill_date.dim_bill_date_key = fact_bill_activity.dim_bill_date_key
							INNER JOIN red_dw.dbo.dim_client
							ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
							AND client_group_code IN ('00000001' --Zurich
							,'00000003' --NHS Resolution   
							,'00000002' --MIB
							,'00000006' --Royal Mail
							,'00000067' --Ageas
							,'00000013' --AIG
							,'00000142' --pwc
							)
							WHERE bill_fin_year=(SELECT DISTINCT fin_year-1 FROM red_dw.dbo.dim_date
							WHERE current_fin_year='Current')
							AND fact_bill_activity.bill_date<(SELECT DATEADD(YEAR,-1,MIN(calendar_date)) FROM red_dw.dbo.dim_date
										WHERE current_fin_month='Current')
							GROUP BY client_group_name) AS [PYYTDRevenue] ON PYYTDRevenue.client_group_name = dim_client.client_group_name

LEFT OUTER JOIN (SELECT client_group_name
			, COUNT(DISTINCT dim_matter_header_current.client_code+dim_matter_header_current.matter_number) AS [No. Instructions]
		FROM red_dw.dbo.dim_matter_header_current
		INNER JOIN red_dw.dbo.dim_date
		ON calendar_date=CAST(date_opened_case_management AS DATE)
		AND fin_year=(SELECT DISTINCT fin_year FROM red_dw.dbo.dim_date
							WHERE current_fin_year='Current')
		LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		 INNER  JOIN red_dw.dbo.dim_detail_outcome 
		 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		 AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
		WHERE client_group_code IN ('00000001' --Zurich
							,'00000003' --NHS Resolution   
							,'00000002' --MIB
							,'00000006' --Royal Mail
							,'00000067' --Ageas
							,'00000013' --AIG
							,'00000142' --pwc
							)
		AND date_opened_case_management<(SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date
										WHERE current_fin_month='Current')
		AND reporting_exclusions=0
		AND hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
		GROUP BY client_group_name) AS [YTDInstructions] ON YTDInstructions.client_group_name = dim_client.client_group_name

LEFT OUTER JOIN (SELECT client_group_name
			, COUNT(DISTINCT dim_matter_header_current.client_code+dim_matter_header_current.matter_number) AS [No. Instructions]
		FROM red_dw.dbo.dim_matter_header_current
		INNER JOIN red_dw.dbo.dim_date
		ON calendar_date=CAST(date_opened_case_management AS DATE)
		AND fin_year=(SELECT DISTINCT fin_year-1 FROM red_dw.dbo.dim_date
							WHERE current_fin_year='Current')
		LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		 INNER  JOIN red_dw.dbo.dim_detail_outcome 
		 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		 AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
		WHERE client_group_code IN ('00000001' --Zurich
							,'00000003' --NHS Resolution   
							,'00000002'--MIB
							,'00000006' --Royal Mail
							,'00000067' --Ageas
							,'00000013' --AIG
							,'00000142' --pwc
							)
		AND date_opened_case_management<(SELECT DATEADD(YEAR,-1,MIN(calendar_date)) FROM red_dw.dbo.dim_date
										WHERE current_fin_month='Current')
		AND reporting_exclusions=0
		AND hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
		GROUP BY client_group_name) AS [PYYTDInstructions] ON PYYTDInstructions.client_group_name = dim_client.client_group_name

LEFT OUTER JOIN (
			SELECT client_group_name
			, COUNT(*) no_exceptions
			, COUNT(DISTINCT fact_exceptions_update.case_id) cases 
			FROM red_Dw.dbo.fact_exceptions_update
			LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
			ON dim_matter_header_current.dim_matter_header_curr_key = fact_exceptions_update.dim_matter_header_curr_key
			WHERE 
			datasetid = 226
			AND duplicate_flag <> 1
			AND miscellaneous_flag <> 1
			AND client_group_code IN ('00000001' --Zurich
										,'00000003' --NHS Resolution   
										,'00000002' --MIB
										,'00000006' --Royal Mail
										,'00000067' --Ageas
										,'00000013' --AIG
										,'00000142' --pwc
										)
			GROUP BY client_group_name) AS [Exceptions] ON Exceptions.client_group_name = dim_client.client_group_name

WHERE dim_client.client_group_code IN ('00000001' --Zurich
							,'00000003' --NHS Resolution   
							,'00000002' --MIB
							,'00000006' --Royal Mail
							,'00000067' --Ageas
							,'00000013' --AIG
							,'00000142' --pwc
							)


END
GO
