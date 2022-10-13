SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-11
-- Description:	#66654, Board Client SLA dashboard
-- =============================================
-- ES #68393, added client debt over 180 days
-- ==============================================
CREATE PROCEDURE [dbo].[ClientDashboard]
	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @FinYear AS INT
DECLARE @FinYearPrev AS INT
DECLARE @FinMonthNo AS INT
DECLARE @FinMonth AS INT
DECLARE @FinMonthPrev AS INT

SET @FinYear=(SELECT fin_year FROM red_dw.dbo.dim_date
WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(MONTH,-1,GETDATE()),103))

SET @FinYearPrev=@FinYear-1

SET @FinMonthNo=(SELECT fin_month_no FROM red_dw.dbo.dim_date
WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(MONTH,-1,GETDATE()),103))

SET @FinMonth=(SELECT fin_month FROM red_dw.dbo.dim_date
WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(MONTH,-1,GETDATE()),103))

SET @FinMonthPrev=(SELECT fin_month FROM red_dw.dbo.dim_date
WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,DATEADD(MONTH,-1,GETDATE())),103))

SELECT DISTINCT
	dim_client.client_group_name AS [Client Group Name]
	, YTDRevenue.[YTD Revenue]
	, PYYTDRevenue.[PY YTD Revenue]
	, Debt.[Debt Over 180 Days]
	, [PY Debt].[PY Debt Over 180 Days]
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
							WHERE bill_fin_year=@FinYear
							AND bill_fin_month_no<=@FinMonthNo
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
							WHERE bill_fin_year=@FinYearPrev
							AND bill_fin_month_no<=@FinMonthNo
							GROUP BY client_group_name) AS [PYYTDRevenue] ON PYYTDRevenue.client_group_name = dim_client.client_group_name

LEFT OUTER JOIN (SELECT client_group_name
			, COUNT(DISTINCT dim_matter_header_current.client_code+dim_matter_header_current.matter_number) AS [No. Instructions]
		FROM red_dw.dbo.dim_matter_header_current
		INNER JOIN red_dw.dbo.dim_date
		ON calendar_date=CAST(date_opened_case_management AS DATE)
		AND fin_year=@FinYear
		AND dim_date.fin_month_no<=@FinMonthNo
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
		--AND date_opened_case_management<(SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date
		--								WHERE current_fin_month='Current')
		AND reporting_exclusions=0
		AND hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
		GROUP BY client_group_name) AS [YTDInstructions] ON YTDInstructions.client_group_name = dim_client.client_group_name

LEFT OUTER JOIN (SELECT client_group_name
			, COUNT(DISTINCT dim_matter_header_current.client_code+dim_matter_header_current.matter_number) AS [No. Instructions]
		FROM red_dw.dbo.dim_matter_header_current
		INNER JOIN red_dw.dbo.dim_date
		ON calendar_date=CAST(date_opened_case_management AS DATE)
		AND fin_year=@FinYearPrev
		AND dim_date.fin_month_no<=@FinMonthNo
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
		--AND date_opened_case_management<(SELECT DATEADD(YEAR,-1,MIN(calendar_date)) FROM red_dw.dbo.dim_date
		--								WHERE current_fin_month='Current')
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

LEFT OUTER JOIN (SELECT client_group_name
					, SUM(outstanding_total_bill) AS [Debt Over 180 Days]
				FROM red_dw.dbo.fact_debt_monthly
				LEFT OUTER JOIN red_dw.dbo.dim_days_banding
				ON dim_days_banding.dim_days_banding_key = fact_debt_monthly.dim_days_banding_key
				INNER JOIN red_dw.dbo.dim_client
				ON dim_client.dim_client_key = fact_debt_monthly.dim_client_key
				AND dim_client.client_group_code IN ('00000001' --Zurich
											,'00000003' --NHS Resolution   
											,'00000002' --MIB
											,'00000006' --Royal Mail
											,'00000067' --Ageas
											,'00000013' --AIG
											,'00000142' --pwc
											)
				INNER JOIN red_dw.dbo.dim_date
				ON dim_transaction_date_key=dim_date_key
				AND fact_debt_monthly.debt_month=@FinMonth

				WHERE  daysbanding='Greater than 180 Days'

				GROUP BY client_group_name) AS [Debt] ON Debt.client_group_name = dim_client.client_group_name

LEFT OUTER JOIN (SELECT client_group_name
					, SUM(outstanding_total_bill) AS [PY Debt Over 180 Days]
				FROM red_dw.dbo.fact_debt_monthly
				LEFT OUTER JOIN red_dw.dbo.dim_days_banding
				ON dim_days_banding.dim_days_banding_key = fact_debt_monthly.dim_days_banding_key
				INNER JOIN red_dw.dbo.dim_client
				ON dim_client.dim_client_key = fact_debt_monthly.dim_client_key
				AND dim_client.client_group_code IN ('00000001' --Zurich
											,'00000003' --NHS Resolution   
											,'00000002' --MIB
											,'00000006' --Royal Mail
											,'00000067' --Ageas
											,'00000013' --AIG
											,'00000142' --pwc
											)
				INNER JOIN red_dw.dbo.dim_date
				ON dim_transaction_date_key=dim_date_key
				AND fact_debt_monthly.debt_month=@FinMonthPrev

				WHERE  daysbanding='Greater than 180 Days'

				GROUP BY client_group_name) AS [PY Debt] ON [PY Debt].client_group_name = dim_client.client_group_name

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
