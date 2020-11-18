SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [onetoone].[get_user_stats_live] (@fed_code VARCHAR(10))

as


DECLARE @fin_year INT,
		@fin_month INT
		--,@fed_code VARCHAR(10) = '4664'


SELECT DISTINCT @fin_year = fin_year, @fin_month = fin_month_no
-- select *
FROM dbo.dim_date 
WHERE calendar_date = CAST(GETDATE() AS DATE)

DROP TABLE IF EXISTS #matterscapableofclosure_data
DROP TABLE IF EXISTS #matterscapableofclosure
DROP TABLE IF EXISTS #NumberOfFiles
DROP TABLE IF EXISTS #WIP
DROP TABLE IF EXISTS #dibs
DROP TABLE IF EXISTS #Client_balances
DROP TABLE IF EXISTS #debt
DROP TABLE IF EXISTS #exceptionsdata
DROP TABLE IF EXISTS #Exceptions


-- Matters capable of closure

SELECT * INTO #matterscapableofclosure_data
FROM OPENROWSET
('SQLNCLI','Server=svr-liv-dw-01;Trusted_Connection=yes;',
     'EXEC reporting.[dataservices].[claims_files_to_be_closed]')
	 ;

-- Exceptions


SELECT * INTO #exceptionsdata
FROM OPENROWSET
('SQLNCLI','Server=svr-liv-dw-01;Trusted_Connection=yes;',
     'EXEC reporting.[dbo].[MI_Exception_Summary_firm_wide] ''(select dim_fed_hierarchy_history_key from dim_fed_hierarchy_history)''
	 
		 WITH RESULT SETS
	(
	  (
	   employeeid  varchar(200), Buisnessline varchar(200), PracticeArea varchar(200), team varchar(200), name varchar(200), fed_code varchar(200), windowsusername varchar(200),
	   no_of_open_cases_with_exceptions int, no_of_open_exceptions int, total_open_cases int, no_of_closed_cases_with_exceptions int, 
	   no_of_closed_exceptions int, total_closed_cases int, no_of_cases_with_exceptions int,
       no_of_exceptions int, total_cases int, closed_critria_cases int, open_critria_cases int, critria_cases int
	  )
	)'
) ;


-- WIP
	SELECT 'YTD' fin_month, fed_code, SUM(wip_value) wip_value		
		 INTO #WIP
		-- select *
	FROM dbo.fact_agg_kpi_monthly_rollup 
	INNER JOIN dim_date ON fact_agg_kpi_monthly_rollup.dim_gl_date_key = dim_date.dim_date_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_kpi_monthly_rollup.dim_fed_hierarchy_history_key
	WHERE dim_gl_date_key IN (SELECT MAX(dim_gl_date_key) FROM fact_agg_kpi_monthly_rollup WHERE wip_value IS NOT NULL)
	AND dim_date.fin_year = @fin_year
	AND fed_code = @fed_code
	GROUP BY fed_code


-- NumberOfFiles 

	SELECT 'YTD' fin_month, fed_code, [Claim concluded but costs outstanding] Claim_concluded_but_costs_outstanding, 
			[Claim and costs concluded but recovery outstanding] Claim_and_costs_concluded_but_recovery_outstanding, 
			[Claim and costs outstanding] Claim_and_costs_outstanding,
			[Final bill sent - unpaid] Final_bill_sent_unpaid, 
			[Present Position Blank] Present_Position_Blank, 
			[Final bill due - claim and costs concluded] Final_bill_due_claim_and_costs_concluded, 
			[To be closed/minor balances to be clear] To_be_closed_minor_balances_to_be_clear
			INTO #NumberOfFiles
		FROM (
					SELECT fed_code, ISNULL(dim_detail_core_details.present_position, 'Present Position Blank') present_position, COUNT(master_fact_key) cnt
					-- select *
					FROM dbo.dim_detail_core_details
					INNER JOIN dbo.fact_dimension_main ON fact_dimension_main.dim_detail_core_detail_key = dim_detail_core_details.dim_detail_core_detail_key
					INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
					INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
					WHERE reporting_exclusions = 0
					AND fed_code = @fed_code
					AND date_opened_case_management IS NOT NULL AND date_closed_practice_management IS NULL
					GROUP BY (dim_detail_core_details.present_position), fed_code
			)  AS Files
	PIVOT
		(
		MAX(cnt)
		FOR present_position IN ([Claim concluded but costs outstanding], [Claim and costs concluded but recovery outstanding], [Claim and costs outstanding],
						[Final bill sent - unpaid], [Present Position Blank], [Final bill due - claim and costs concluded], [To be closed/minor balances to be clear]) 
		) AS PivotTable


-- Client_balances 
	SELECT 'YTD' fin_month, fed_code, SUM(client_account_balance_of_matter) Client_balance
	INTO #Client_balances
	-- select last_bill_date, DATEDIFF(dd, last_bill_date, GETDATE())
	FROM dbo.fact_matter_summary_current
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_matter_summary_current.dim_fed_hierarchy_history_key 
	WHERE client_account_balance_of_matter > 0
	AND fed_code = @fed_code
	AND DATEDIFF(dd, last_bill_date, GETDATE()) > 29
	GROUP BY fed_code



-- Matterscapableofclosure 

	SELECT 	'YTD' fin_month, fed_code, [Bill Balance] bill_balance, [Client and Bill Balance] client_and_bill_balance, [Client Balance] client_balance, [To be closed] to_be_closed
	INTO #Matterscapableofclosure
	FROM (
		SELECT fed_code, status, COUNT(*) cnt
		FROM #matterscapableofclosure_data
		WHERE fed_code = @fed_code
		GROUP BY status, fed_code
		) x
	PIVOT
		(
		MAX(cnt)
		FOR status IN ([Bill Balance], [Client and Bill Balance], [Client Balance], [To be closed]) 
		) AS PivotTable



-- Dibs 
	SELECT 'YTD' fin_month, fed_code,
		[Disb 0 - 30 Days] [Disb_0_30_Days], 
		[Disb 31 - 90 days] [Disb_31_90_Days], 
		[Disb Greater than 90 Days] [Disb_90_Days]
	INTO #dibs
	FROM (
		SELECT dim_fed_hierarchy_history.fed_code,	
			 CASE WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 0 AND 30 THEN 'Disb 0 - 30 Days'  
			 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 31 AND 90     THEN 'Disb 31 - 90 days'  
			 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) > 90                  THEN 'Disb Greater than 90 Days' 
			 END  AS [Days_Banding],	 
			 SUM(total_unbilled_disbursements) DisbAmount
		FROM red_dw.dbo.fact_disbursements_detail AS a    
		INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) ON a.client_code=dim_matter_header_current.client_code AND a.matter_number=dim_matter_header_current.matter_number   
		INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK) ON dim_matter_header_current.fee_earner_code= fed_code collate database_default AND dss_current_flag='Y'   
		WHERE dim_bill_key=0  
		AND total_unbilled_disbursements <> 0  
		AND dim_fed_hierarchy_history.fed_code = @fed_code
		GROUP BY dim_fed_hierarchy_history.fed_code,  CASE WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 0 AND 30 THEN 'Disb 0 - 30 Days'  
			 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 31 AND 90     THEN 'Disb 31 - 90 days'  
			 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) > 90                  THEN 'Disb Greater than 90 Days' 
			 END) x
	PIVOT
			(
			MAX(DisbAmount)
			FOR [Days_Banding] IN ([Disb 0 - 30 Days], [Disb 31 - 90 days], [Disb Greater than 90 Days]) 
			) AS PivotTable


-- Debt

	SELECT 'YTD' fin_month, fed_code,
		PivotTable.Debt_180_Days,
		PivotTable.Debt_31_180_Days,
		PivotTable.Debt_0_30_Days
	INTO #debt
	FROM (

			SELECT dim_fed_hierarchy_history.fed_code,	
			 CASE WHEN DATEDIFF(DAY,cast(cast(f.dim_bill_date_key as varchar(10)) as date),GETDATE()) BETWEEN 0 AND 30 THEN 'Debt_0_30_Days'  
			 WHEN DATEDIFF(DAY,cast(cast(f.dim_bill_date_key as varchar(10)) as date),GETDATE()) BETWEEN 31 AND 180     THEN 'Debt_31_180_Days'  
			 WHEN DATEDIFF(DAY,cast(cast(f.dim_bill_date_key as varchar(10)) as date),GETDATE()) > 180                  THEN 'Debt_180_Days' 
			 END  AS [Days_Banding],	 
			 SUM(f.amount_outstanding) Debt
			FROM red_dw.dbo.fact_bill f
			INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) ON dim_matter_header_current.dim_matter_header_curr_key = f.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK) ON dim_matter_header_current.fee_earner_code= fed_code collate database_default AND dss_current_flag='Y'   
			WHERE f.bill_number != 'PURGE'
			and dim_fed_hierarchy_history.fed_code = @fed_code
			AND f.amount_outstanding > 0
			GROUP BY dim_fed_hierarchy_history.fed_code,  
			CASE WHEN DATEDIFF(DAY,cast(cast(f.dim_bill_date_key as varchar(10)) as date),GETDATE()) BETWEEN 0 AND 30 THEN 'Debt_0_30_Days'  
			 WHEN DATEDIFF(DAY,cast(cast(f.dim_bill_date_key as varchar(10)) as date),GETDATE()) BETWEEN 31 AND 180     THEN 'Debt_31_180_Days'  
			 WHEN DATEDIFF(DAY,cast(cast(f.dim_bill_date_key as varchar(10)) as date),GETDATE()) > 180                  THEN 'Debt_180_Days' 
			 END
		 
		 ) x
	PIVOT
			(
			MAX(Debt)
			FOR [Days_Banding] IN ([Debt_0_30_Days], [Debt_31_180_Days], [Debt_180_Days]) 
			) AS PivotTable



-- Exceptions

	SELECT 	'YTD' fin_month, fed_code, SUM(no_of_exceptions) Total_Exceptions, 
		ROUND(IIF(SUM(critria_cases) IS NULL OR SUM(critria_cases) < 1, 0, CAST (SUM(no_of_exceptions) AS FLOAT) / SUM(critria_cases)), 2) AVG_Exceptions
	INTO #Exceptions
	-- select *
	FROM #exceptionsdata
	WHERE fed_code = @fed_code
	GROUP BY fed_code



SELECT payrollid fed_code, 'YTD' fin_month,
	WIP.wip_value,
    NumberOfFiles.Claim_concluded_but_costs_outstanding,
    NumberOfFiles.Claim_and_costs_concluded_but_recovery_outstanding,
    NumberOfFiles.Claim_and_costs_outstanding,
    NumberOfFiles.Final_bill_sent_unpaid,
    NumberOfFiles.Present_Position_Blank,
    NumberOfFiles.Final_bill_due_claim_and_costs_concluded,
    NumberOfFiles.To_be_closed_minor_balances_to_be_clear,
	Client_balances.Client_balance outstanding_client_balance,
    Matterscapableofclosure.bill_balance,
    Matterscapableofclosure.client_and_bill_balance,
    Matterscapableofclosure.client_balance,
    Matterscapableofclosure.to_be_closed,
	[Disb_0_30_Days], 
	[Disb_31_90_Days], 
	[Disb_90_Days],
    Debt.Debt_180_Days,
    Debt.Debt_31_180_Days,
    Debt.Debt_0_30_Days,
	Total_Exceptions,
	AVG_Exceptions

FROM dbo.dim_employee main
LEFT OUTER JOIN #WIP WIP ON WIP.fed_code = main.payrollid 
LEFT OUTER JOIN #NumberOfFiles NumberOfFiles ON NumberOfFiles.fed_code = main.payrollid 
LEFT OUTER JOIN #Client_balances Client_balances ON Client_balances.fed_code = main.fed_login 
LEFT OUTER JOIN #Matterscapableofclosure Matterscapableofclosure ON Matterscapableofclosure.fed_code COLLATE Latin1_General_BIN = main.payrollid
LEFT OUTER JOIN #Dibs Dibs ON Dibs.fed_code = main.payrollid 
LEFT OUTER JOIN #Debt Debt ON Debt.fed_code = main.payrollid
LEFT OUTER JOIN #Exceptions ON #Exceptions.fed_code COLLATE Latin1_General_BIN = main.payrollid 
WHERE main.payrollid = @fed_code

GO
