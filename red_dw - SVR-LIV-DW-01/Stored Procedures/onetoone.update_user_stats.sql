SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [onetoone].[update_user_stats]

AS

DECLARE @fin_year INT,
		@fin_month INT,
		@fin_month_full int

SELECT DISTINCT @fin_year = fin_year, @fin_month = fin_month_no, @fin_month_full = dim_date.fin_month
-- select *
FROM dbo.dim_date 
WHERE calendar_date = CAST(GETDATE()-1 AS DATE)


-- Delete data from table if it exists already
-- select * from [onetoone].[user_stats]
IF (SELECT COUNT(*) FROM [onetoone].[user_stats] WHERE fin_year = @fin_year AND data_for_month = @fin_month) > 0
	BEGIN
		DELETE FROM [onetoone].[user_stats] WHERE fin_year = @fin_year AND data_for_month = @fin_month
	END 



-- Matters capable of closure -- Claims
DROP TABLE IF EXISTS #matterscapableofclosure

SELECT * INTO #matterscapableofclosure
FROM OPENROWSET
('SQLNCLI','Server=svr-liv-dw-01;Trusted_Connection=yes;',
     'EXEC reporting.[dataservices].[claims_files_to_be_closed]')
	 ;

-- Matter 
DROP TABLE IF EXISTS #matterscapableofclosurelta

SELECT * INTO #matterscapableofclosurelta
FROM OPENROWSET
('SQLNCLI','Server=svr-liv-dw-01;Trusted_Connection=yes;',
     'EXEC reporting.[dataservices].[lta_files_to_be_closed]')
	 ;

-- Exceptions
DROP TABLE IF EXISTS #exceptions

SELECT * INTO #exceptions
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




WITH WriteOffs AS (
	SELECT 'YTD' fin_month,  IIF(output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee', 'Fixed Fee', 'Hourly') fixed_fee, 
		SUM(ISNULL(a.time_charge_value,0)) write_off_amt, fed_code
	FROM dbo.fact_all_time_activity a
	LEFT JOIN dbo.dim_all_time_activity t ON a.dim_all_time_activity_key = t.dim_all_time_activity_key
	LEFT JOIN dbo.dim_date d3 ON d3.dim_date_key = a.dim_transaction_date_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = a.dim_fed_hierarchy_history_key
	INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = a.dim_matter_header_curr_key
	INNER JOIN dim_detail_finance ON dim_detail_finance.matter_number = dim_matter_header_current.matter_number AND dim_detail_finance.client_code = dim_matter_header_current.client_code
	WHERE isactive = 1
		--AND fed_code = '4664'
		AND d3.fin_year = @fin_year
		AND d3.calendar_date < DATEADD(m, DATEDIFF(m, 0, GETDATE()), 0)
		AND t.transaction_type = 'Written Off Transaction'
		AND dim_matter_header_current.reporting_exclusions = 0
	GROUP BY IIF(output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee', 'Fixed Fee', 'Hourly'), fed_code
	),


WIP AS (
	SELECT 'YTD' fin_month, fed_code, SUM(wip_value) wip_value,			
		-- Holidays 
		MAX(totalentitlementdays) totalentitlementdays,
		MAX(totalentitlementdays) - SUM(ISNULL(days_year_to_date,0)) remaining,
		MAX(remaining_fte_working_days) remaining_fte_working_days,
		MAX(remaining_fte_working_days_year) yearly_working_days
	-- select *
	FROM dbo.fact_agg_kpi_monthly_rollup 
	INNER JOIN dim_date ON fact_agg_kpi_monthly_rollup.dim_gl_date_key = dim_date.dim_date_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_kpi_monthly_rollup.dim_fed_hierarchy_history_key
	WHERE dim_date.fin_year = @fin_year
	--AND fed_code = '4664'
	AND dim_gl_date_key IN (SELECT MAX(dim_gl_date_key) FROM fact_agg_kpi_monthly_rollup WHERE wip_value IS NOT NULL)
	GROUP BY fed_code
	),

	
WIP_PY AS (
	SELECT 'YTD' fin_month, fed_code, SUM(wip_value) wip_value_py
	
	-- select *
	FROM dbo.fact_agg_kpi_monthly_rollup 
	INNER JOIN dim_date ON fact_agg_kpi_monthly_rollup.dim_gl_date_key = dim_date.dim_date_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_kpi_monthly_rollup.dim_fed_hierarchy_history_key
	WHERE dim_gl_date_key IN (SELECT min(dim_date.dim_date_key) FROM dim_date WHERE fin_year = @fin_year - 1 AND fin_month_no = @fin_month)
	GROUP BY fed_code
	),

TotalBudget AS (
	SELECT 'YTD' fin_month, fed_code, SUM(fed_level_minute_value) Total_Budget_Year
	-- select *
	FROM dbo.fact_agg_kpi_monthly_rollup 
	INNER JOIN dim_date ON fact_agg_kpi_monthly_rollup.dim_gl_date_key = dim_date.dim_date_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_kpi_monthly_rollup.dim_fed_hierarchy_history_key
	WHERE dim_date.fin_year = @fin_year
	--AND  fed_code = '4664'	
	GROUP BY fed_code
	),


NumberOfFiles AS (
	SELECT 'YTD' fin_month, fed_code, [Claim concluded but costs outstanding] Claim_concluded_but_costs_outstanding, 
			[Claim and costs concluded but recovery outstanding] Claim_and_costs_concluded_but_recovery_outstanding, 
			[Claim and costs outstanding] Claim_and_costs_outstanding,
			[Final bill sent - unpaid] Final_bill_sent_unpaid, 
			[Present Position Blank] Present_Position_Blank, 
			[Final bill due - claim and costs concluded] Final_bill_due_claim_and_costs_concluded, 
			[To be closed/minor balances to be clear] To_be_closed_minor_balances_to_be_clear
		FROM (
					SELECT fed_code, ISNULL(dim_detail_core_details.present_position, 'Present Position Blank') present_position, COUNT(master_fact_key) cnt
					-- select *
					FROM dbo.dim_detail_core_details
					INNER JOIN dbo.fact_dimension_main ON fact_dimension_main.dim_detail_core_detail_key = dim_detail_core_details.dim_detail_core_detail_key
					INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
					INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
					WHERE reporting_exclusions = 0
					--AND fed_code = '4664'
					AND date_opened_case_management IS NOT NULL AND date_closed_practice_management IS NULL
					GROUP BY (dim_detail_core_details.present_position), fed_code
			)  AS Files
	PIVOT
		(
		MAX(cnt)
		FOR present_position IN ([Claim concluded but costs outstanding], [Claim and costs concluded but recovery outstanding], [Claim and costs outstanding],
						[Final bill sent - unpaid], [Present Position Blank], [Final bill due - claim and costs concluded], [To be closed/minor balances to be clear]) 
		) AS PivotTable
	),


Client_balances AS (
	
	SELECT  'YTD' fin_month, SUM(ClientBalance) Client_balance
	, fee.usrInits COLLATE DATABASE_DEFAULT	fed_code
	
				
	FROM 
		(SELECT MattIndex, SUM(ClientBalance) AS ClientBalance 
				,COALESCE(MAX(CASE WHEN  PositiveBalance=1  THEN  [post_date] ELSE NULL END)
				,MIN([post_date])) AS [post_date] 
			FROM 
			(
			SELECT MattIndex
			,ClientBalance
			,[post_date]
			,running_sales_amount
			,ZeroBalance
			,LAG(ZeroBalance, 1,0) OVER (PARTITION BY MattIndex ORDER BY [post_date])  AS PositiveBalance
			FROM 
			(

			SELECT      MattIndex AS MattIndex
						,tb.amount AS ClientBalance
						,COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate) [post_date]
						,SUM(tb.amount) OVER (PARTITION BY MattIndex ORDER BY (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) ROWS UNBOUNDED PRECEDING) AS running_sales_amount   
						,CASE WHEN (SUM(tb.amount) OVER (PARTITION BY MattIndex ORDER BY (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) ROWS UNBOUNDED PRECEDING))=0 THEN 1 ELSE 0 END AS ZeroBalance
			
				 FROM [TE_3E_Prod].[dbo].[TrustBalance] tb
				 INNER JOIN [TE_3E_Prod].[dbo].Matter matter ON tb.matter = matter.MattIndex
				 INNER JOIN [TE_3E_Prod].[dbo].Client client ON matter.Client = client.ClientIndex
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustDisbursement] disb ON tb.trustdisbursement = disb.trustdsbmtindex 
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustDisbursementType] tdt ON tdt.code = disb.trustdisbursementtype
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustCheck] tc ON disb.TrustCheck = tc.TrustChkIndex 
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustReceiptDetail] receiptdetail ON receiptdetail.[TrustRcptDetIndex] = tb.trustreceiptdetail 
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustReceipt] receipt ON receipt.trustrcptindex = receiptdetail.trustreceipt
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustReceiptType] receipttype ON receipt.trustreceipttype = receipttype.code
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustAdjustment] adjustment ON adjustment.trustadjindex = tb.trustadjustment 
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustAdjType] adjustmenttype ON adjustment.trustadjtype = adjustmenttype.code
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustTransferDetail] transferdetail ON tb.trusttransferdetail = transferdetail.TrustTransferDetIndex
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustTransfer] transfers ON transfers.trusttrsfindex = transferdetail.TrustTransfer  
				 LEFT JOIN [TE_3E_Prod].[dbo].[TrustTransferType] transfertype ON transfers.trusttransfertype = transfertype.code
				 LEFT JOIN [TE_3E_Prod].[dbo].[BankAcct] bank ON tb.BankAcctTrust = bank.BankAcctIndex
				 --WHERE MattIndex='2170011'
		) AS AllData
		) AS Transactions
		GROUP BY MattIndex
		) AS AllClientBalances
		INNER JOIN MS_Prod.config.dbFile	ON AllClientBalances.MattIndex=dbFile.fileExtLinkID
		INNER JOIN MS_Prod.config.dbClient	ON dbFile.clID=dbClient.clID
		INNER JOIN MS_PROD.dbo.udExtFile	ON dbFile.fileID=udExtFile.fileID
		INNER JOIN MS_PROD.dbo.dbUser fee	ON fee.usrID = dbFile.filePrincipleID
	
		INNER JOIN MS_PROD.dbo.dbUser BCM ON BCM.usrID = dbFile.fileresponsibleID
		LEFT OUTER JOIN (SELECT fed_code
								,hierarchylevel2,hierarchylevel3 AS [Practice Area]
								,hierarchylevel4 AS [Team]
							FROM red_dw.dbo.dim_fed_hierarchy_current
							WHERE dss_current_flag='Y') AS Teams
			 ON fee.usrInits=fed_code COLLATE DATABASE_DEFAULT
		WHERE (ClientBalance <> 0 OR (ClientBalance=0 AND CONVERT(DATE,[post_date],103)=CONVERT(DATE,GETDATE(),103)))
		AND Teams.hierarchylevel2 IN ('Legal Ops - Claims','Legal Ops - LTA')
		AND DATEDIFF(DAY,[post_date],GETDATE()) > 29
		GROUP BY fee.usrInits
	),

RepudiationRate AS (	
	SELECT fed_code, 'YTD' fin_month, 
	iif (COUNT (date_claim_concluded) > 0,
		round ( CAST (	SUM(
			CASE WHEN lower(outcome_of_case) LIKE '%discontinued%' 
					  OR lower(outcome_of_case) LIKE '%struck out%'
					  OR lower(outcome_of_case) LIKE '%won%' THEN 1 END ) AS FLOAT)
					  / 					  
					  COUNT (date_claim_concluded) * 100, 2), NULL) Repudiation_Rate_Percent
	-- select *
	FROM dbo.dim_detail_outcome
	INNER JOIN dbo.fact_dimension_main ON fact_dimension_main.dim_detail_outcome_key = dim_detail_outcome.dim_detail_outcome_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN dim_date ON dim_detail_outcome.date_claim_concluded = dim_date.calendar_date
	WHERE reporting_exclusions = 0      
	-- and fed_code = '4664'
	AND fin_year = @fin_year		
	AND date_claim_concluded IS NOT NULL
    GROUP BY fed_code
	),


RepudiationRate_PY AS (	
	SELECT fed_code, 'YTD' fin_month, 
	iif (COUNT (date_claim_concluded) > 0,
		round ( CAST (	SUM(
			CASE WHEN lower(outcome_of_case) LIKE '%discontinued%' 
					  OR lower(outcome_of_case) LIKE '%struck out%'
					  OR lower(outcome_of_case) LIKE '%won%' THEN 1 END ) AS FLOAT)
					  / 					  
					  COUNT (date_claim_concluded) * 100, 2), NULL) RepudiationRate_PY
	-- select *
	FROM dbo.dim_detail_outcome
	INNER JOIN dbo.fact_dimension_main ON fact_dimension_main.dim_detail_outcome_key = dim_detail_outcome.dim_detail_outcome_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN dim_date ON dim_detail_outcome.date_claim_concluded = dim_date.calendar_date
	WHERE reporting_exclusions = 0      
	-- and fed_code = '4664'
	AND fin_year = @fin_year - 1	
	AND date_claim_concluded IS NOT NULL
    GROUP BY fed_code
	),



Matterscapableofclosure AS (
	SELECT 	'YTD' fin_month, fed_code, [Bill Balance] bill_balance, [Client and Bill Balance] client_and_bill_balance, [Client Balance] client_balance, [To be closed] to_be_closed
	FROM (
		SELECT fed_code, status, COUNT(*) cnt
		FROM #matterscapableofclosure
		--WHERE fed_code = '4664'
		GROUP BY status, fed_code
		) x
	PIVOT
		(
		MAX(cnt)
		FOR status IN ([Bill Balance], [Client and Bill Balance], [Client Balance], [To be closed]) 
		) AS PivotTable
	),


Matterscapableofclosurelta AS (
	SELECT 	'YTD' fin_month, fed_code, [Bill Balance] bill_balance, [Client and Bill Balance] client_and_bill_balance, [Client Balance] client_balance, [To be closed] to_be_closed
	FROM (
		SELECT fed_code, status, COUNT(*) cnt
		-- select *
		FROM #matterscapableofclosurelta
		--WHERE fed_code = '4664'
		GROUP BY status, fed_code
		) x
	PIVOT
		(
		MAX(cnt)
		FOR status IN ([Bill Balance], [Client and Bill Balance], [Client Balance], [To be closed]) 
		) AS PivotTable
	),

Matters AS (
	SELECT 'YTD' fin_month, fee_earner_code fed_code, IIF(output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee', 'Fixed Fee', 'Hourly') fixed_fee, 
		count (dim_detail_finance.matter_number) Matter_Cnt
	-- select distinct output_wip_fee_arrangement
	FROM dbo.dim_detail_finance 
	INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.matter_number = dim_detail_finance.matter_number AND dim_detail_finance.client_code = dim_matter_header_current.client_code
	WHERE dim_matter_header_current.reporting_exclusions = 0
		-- AND fee_earner_code = '4664'
		AND date_closed_practice_management IS null
	GROUP BY IIF(output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee', 'Fixed Fee', 'Hourly'), fee_earner_code
	),


Dibs AS (
	SELECT 'YTD' fin_month, fed_code,
		[Disb 0 - 30 Days] [Disb_0_30_Days], 
		[Disb 31 - 90 days] [Disb_31_90_Days], 
		[Disb Greater than 90 Days] [Disb_90_Days]
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
	--	AND dim_fed_hierarchy_history.fed_code = '4664'
		GROUP BY dim_fed_hierarchy_history.fed_code,  CASE WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 0 AND 30 THEN 'Disb 0 - 30 Days'  
			 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 31 AND 90     THEN 'Disb 31 - 90 days'  
			 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) > 90                  THEN 'Disb Greater than 90 Days' 
			 END) x
	PIVOT
			(
			MAX(DisbAmount)
			FOR [Days_Banding] IN ([Disb 0 - 30 Days], [Disb 31 - 90 days], [Disb Greater than 90 Days]) 
			) AS PivotTable
),


Debt AS (
	SELECT 'YTD' fin_month, fed_code,
		PivotTable.Debt_180_Days,
		PivotTable.Debt_31_180_Days,
		PivotTable.Debt_0_30_Days
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
			-- and dim_fed_hierarchy_history.fed_code = '4664'
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
	),

DebtTarget AS (
	SELECT  'YTD' fin_month, team, fact_team_debt_target.debt_target_ytd
	FROM dbo.fact_team_debt_target
	WHERE fact_team_debt_target.month = @fin_month_full
	),
	
FinalBill AS (	
	SELECT
		'YTD' fin_month,
	    fed_code,
	    AVG(AVG_Elapsed_Days_Closed_Cases) AVG_Elapsed_Days_Closed_Cases
	FROM (
		SELECT fed_code, 'YTD' fin_month, DATEDIFF(d, date_opened_practice_management, last_bill_date) AVG_Elapsed_Days_Closed_Cases,
			 ROW_NUMBER() OVER (PARTITION BY fed_code ORDER BY DATEDIFF(d, date_opened_practice_management, last_bill_date) ASC) AS RowAsc,
			  ROW_NUMBER() OVER (PARTITION BY fed_code ORDER BY DATEDIFF(d, date_opened_practice_management, last_bill_date) DESC) AS RowDesc
		-- select *
		FROM dbo.dim_detail_core_details
		INNER JOIN dbo.fact_dimension_main ON fact_dimension_main.dim_detail_core_detail_key = dim_detail_core_details.dim_detail_core_detail_key
		INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key	
		INNER JOIN dbo.fact_bill_matter ON fact_bill_matter.master_fact_key = dbo.fact_dimension_main.master_fact_key
		INNER JOIN dim_date ON fact_bill_matter.last_bill_date = dim_date.calendar_date
		WHERE reporting_exclusions = 0  
		-- AND fed_code = @fed
		AND fin_year IN (@fin_year)
		AND (dim_detail_core_details.present_position IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')	
			OR  date_closed_practice_management IS NOT NULL)
			) x
	WHERE
	   RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
	GROUP BY fed_code
	),

FinalBill_PY AS (	
	SELECT
		'YTD' fin_month,
	    fed_code,
	    AVG(AVG_Elapsed_Days_Closed_Cases) AVG_Elapsed_Days_Closed_Cases_PY
	FROM (
		SELECT fed_code, 'YTD' fin_month, DATEDIFF(d, date_opened_practice_management, last_bill_date) AVG_Elapsed_Days_Closed_Cases,
			 ROW_NUMBER() OVER (PARTITION BY fed_code ORDER BY DATEDIFF(d, date_opened_practice_management, last_bill_date) ASC) AS RowAsc,
			  ROW_NUMBER() OVER (PARTITION BY fed_code ORDER BY DATEDIFF(d, date_opened_practice_management, last_bill_date) DESC) AS RowDesc
		-- select *
		FROM dbo.dim_detail_core_details
		INNER JOIN dbo.fact_dimension_main ON fact_dimension_main.dim_detail_core_detail_key = dim_detail_core_details.dim_detail_core_detail_key
		INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key	
		INNER JOIN dbo.fact_bill_matter ON fact_bill_matter.master_fact_key = dbo.fact_dimension_main.master_fact_key
		INNER JOIN dim_date ON fact_bill_matter.last_bill_date = dim_date.calendar_date
		WHERE reporting_exclusions = 0  
		-- AND fed_code = @fed
		AND fin_year IN (@fin_year-1)
		AND (dim_detail_core_details.present_position IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')	
			OR  date_closed_practice_management IS NOT NULL)
			) x
	WHERE
	   RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
	GROUP BY fed_code
	),

Median_Fixed_Fee AS (
	SELECT
		'YTD' fin_month,
	   fee_earner_code fed_code,
	   AVG(val) Median_Fixed_Fee
	FROM
	(
		SELECT fee_earner_code, fact_finance_summary.fixed_fee_amount val,
		 ROW_NUMBER() OVER (PARTITION BY fee_earner_code ORDER BY fact_finance_summary.fixed_fee_amount ASC) AS RowAsc,
		  ROW_NUMBER() OVER (PARTITION BY fee_earner_code ORDER BY fact_finance_summary.fixed_fee_amount DESC) AS RowDesc
		FROM dim_detail_finance
		INNER JOIN dbo.fact_dimension_main ON fact_dimension_main.dim_detail_finance_key = dim_detail_finance.dim_detail_finance_key
		INNER JOIN dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		INNER JOIN dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
		INNER JOIN dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		WHERE output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee'
		AND dim_detail_core_details.present_position NOT IN ('Final bill due - claim and costs concluded','Final bill sent - unpaid','To be closed/minor balances to be clear')
		AND ISNUMERIC(fact_finance_summary.fixed_fee_amount) = 1
	) x
	WHERE
	   RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
	GROUP BY fee_earner_code
	),



Exceptions AS (
	SELECT 	'YTD' fin_month, fed_code, SUM(no_of_exceptions) Total_Exceptions, 
		ROUND(IIF(SUM(critria_cases) IS NULL  OR SUM(critria_cases) < 1, 0, CAST (SUM(no_of_exceptions) AS FLOAT) / SUM(critria_cases)), 2) AVG_Exceptions
	-- select *
	FROM #exceptions
	--WHERE fed_code = '2016'
	GROUP BY fed_code
	),

RR_PY AS (

SELECT fed_code, 'YTD' fin_month,	
		IIF(SUM(ISNULL(billed_minutes_recorded,0)) = 0, null, SUM(bill_amount) / SUM(billed_minutes_recorded / 60)) Actual_Recovery_Rate_PY
	
		-- select dim_employee.leftdate
	FROM dbo.fact_agg_kpi_monthly_rollup 
	INNER JOIN dim_date ON fact_agg_kpi_monthly_rollup.dim_gl_date_key = dim_date.dim_date_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_kpi_monthly_rollup.dim_fed_hierarchy_history_key
	WHERE  dim_date.fin_year = 2020 --@fin_year - 1
	AND billed_minutes_recorded IS NOT null
	GROUP BY fed_code
	),

LTA_Exceptions AS (

SELECT dim_fed_hierarchy_history.fed_code, 'YTD' fin_month,
       SUM(   CASE WHEN dim_detail_finance.[output_wip_fee_arrangement] IS NULL THEN 1 ELSE 0 END) AS [Exfeearrangement],
	   SUM(	  CASE WHEN ( (fact_finance_summary.[revenue_estimate_net_of_vat] < 1 AND [output_wip_fee_arrangement] IN ('Hourly Rate','Hourly rate','HOURLY'))
                    OR (fact_finance_summary.[revenue_estimate_net_of_vat] IS NULL AND [output_wip_fee_arrangement] IN ('Hourly Rate','Hourly rate','HOURLY')
						AND  date_opened_case_management < dateAdd(Day,-14,getdate()))) THEN 1 ELSE 0 END) AS [ExRevenueEstimate], 
	   SUM(	  CASE WHEN DATEDIFF(d, dim_matter_header_current.date_opened_case_management, GETDATE()) > 14 AND [output_wip_fee_arrangement] IN ('Hourly Rate','Hourly rate','HOURLY') 
					AND fact_finance_summary.disbursements_estimate_net_of_vat is NULL AND date_opened_case_management < dateAdd(Day,-14,getdate()) and date_opened_case_management > '2021-01-28'                                              
					THEN 1 ELSE 0 END) AS [ExDisbursmentEstimate]

FROM red_dw.dbo.fact_dimension_main
    INNER JOIN red_dw.dbo.fact_finance_summary
        ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    INNER JOIN dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    INNER JOIN red_dw.dbo.dim_detail_finance
        ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
    LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
    LEFT OUTER JOIN dbo.dim_matter_worktype
        ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_property
        ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
WHERE dim_matter_header_current.date_closed_practice_management IS NULL
      AND ISNULL(exclude_from_exceptions_reports, '') <> 'Yes'
      AND hierarchylevel2 = 'Legal Ops - LTA'
      AND reporting_exclusions = 0
	  and matter_description <> 'MIBTEST'
      AND dim_matter_worktype.work_type_code NOT IN ( '1114', '1143', '1101', '1077', '1106' )
      AND reporting_exclusions = 0
      AND ISNULL(dim_detail_property.[commercial_bl_status], '') <> 'Pending                                                     '
      AND ISNULL(output_wip_fee_arrangement, '') IN ( NULL,
                                                      'Hourly Rate                                                 ',
                                                      'Hourly rate                                                 ',
                                                      'HOURLY', '',
                                                      'Fixed Fee/Fee Quote/Capped Fee                              '
                                                    )     
GROUP BY dim_fed_hierarchy_history.fed_code

)




INSERT INTO [onetoone].[user_stats]


SELECT 
	CAST(GETDATE() AS DATE) snapshot_date,
	main.fin_year,
	@fin_month data_for_month,

	  main.fed_code,	  
      IIF(main.fin_month IS NULL,'YTD', 'Month') month_or_ytd,
      main.Billable_target,
      main.Actual_Billed,
      main.Diff_billed,
      main.Diff_billed_percent,
      main.chargable_hours_target,
      main.Actaul_chargable_hours,
      main.Diff_hours,
      main.Diff_hours_percent,
      WIP.totalentitlementdays,
      WIP.remaining,
      WIP.remaining_fte_working_days,
	  WIP.remaining_fte_working_days - ISNULL(WIP.remaining,0) Working_days_left,
	 iif ((WIP.yearly_working_days - ISNULL(WIP.totalentitlementdays,0)) > 0, 
		ISNULL(Total_Budget_Year,0) / (WIP.yearly_working_days -  ISNULL(WIP.totalentitlementdays,0)), NULL) AVG_Hrs_To_Hit_Target_Year,
	  WIP.yearly_working_days,
	  IIF ( (WIP.remaining_fte_working_days - ISNULL(WIP.remaining,0)) > 0, (ISNULL(Total_Budget_Year,0) - ISNULL(main.Actaul_chargable_hours,0)) / 
		 (WIP.remaining_fte_working_days - ISNULL(WIP.remaining,0)), NULL) AVG_Hrs_To_Hit_Target_Month_End,
      main.Target_Recovery_Rate,
      main.Actual_Recovery_Rate,
      main.Recovery_rate_diff,
      main.Recovery_rate_diff_percent,
      WOF_Hourly.write_off_amt write_off_amt_hourly,
	  WOF_Fixed.write_off_amt write_off_amt_fixed,
	  WIP.wip_value,
      NumberOfFiles.Claim_concluded_but_costs_outstanding,
      NumberOfFiles.Claim_and_costs_concluded_but_recovery_outstanding,
      NumberOfFiles.Claim_and_costs_outstanding,
      NumberOfFiles.Final_bill_sent_unpaid,
      NumberOfFiles.Present_Position_Blank,
      NumberOfFiles.Final_bill_due_claim_and_costs_concluded,
      NumberOfFiles.To_be_closed_minor_balances_to_be_clear,
	  Client_balances.Client_balance,
	  Total_Budget_Year,
	  AVG_Elapsed_Days_Closed_Cases,
	  Repudiation_Rate_Percent,
	  Matterscapableofclosure.bill_balance, Matterscapableofclosure.client_and_bill_balance, Matterscapableofclosure.client_balance, Matterscapableofclosure.to_be_closed,

	  FixedMatters.Matter_Cnt Fixed_fee_matters,
	  HourlyMatters.Matter_Cnt Hourly_fee_matters,
	  ISNULL( FixedMatters.Matter_Cnt, 0) + ISNULL(HourlyMatters.Matter_Cnt, 0) TotalMatters,
	  ROUND(IIF(ISNULL( FixedMatters.Matter_Cnt, 0) + ISNULL(HourlyMatters.Matter_Cnt, 0) > 0,
		(CAST(FixedMatters.Matter_Cnt AS FLOAT) / (ISNULL( FixedMatters.Matter_Cnt, 0) + ISNULL(HourlyMatters.Matter_Cnt, 0)) * 100), NULL),2) Percent_fixed_fee_matters,
	 ROUND( IIF(ISNULL( FixedMatters.Matter_Cnt, 0) + ISNULL(HourlyMatters.Matter_Cnt, 0) > 0,
		(CAST(HourlyMatters.Matter_Cnt AS FLOAT) / ((ISNULL( FixedMatters.Matter_Cnt, 0) + ISNULL(HourlyMatters.Matter_Cnt, 0))) * 100), NULL),2) Percent_hourly_fee_matters,



	0 no_of_fixed_fee_matters_to_hit_target,


    Dibs.Disb_0_30_Days,
    Dibs.Disb_31_90_Days,
    Dibs.Disb_90_Days,	

	Debt.Debt_0_30_Days,
	Debt.Debt_31_180_Days,
    Debt.Debt_180_Days,
    
    
	RepudiationRate_PY,
	Exceptions.Total_Exceptions,
	Exceptions.AVG_Exceptions,
	AVG_Elapsed_Days_Closed_Cases_PY,
	DebtTarget.debt_target_ytd,
	RR_PY.Actual_Recovery_Rate_PY,
	WIP_PY.wip_value_py,
	LTA_Exceptions.Exfeearrangement Fee_Arrangment_Exception_Count,
	LTA_Exceptions.ExRevenueEstimate Revenue_Est_Exception_Count,
	LTA_Exceptions.ExDisbursmentEstimate Disb_Est_Exception_Count,
	Matterscapableofclosurelta.bill_balance bill_balance_lta, 
	Matterscapableofclosurelta.client_and_bill_balance client_and_bill_balance_lta, 
	Matterscapableofclosurelta.client_balance client_balance_lta, 
	Matterscapableofclosurelta.to_be_closed to_be_closed_lta,
	main.Utilisation_Percent

FROM (

	SELECT fed_code,
	--	dim_fed_hierarchy_history.hierarchylevel4hist,
		dim_date.fin_year, cast (dim_date.fin_month_no AS VARCHAR(3)) fin_month,
		-- Revenue
		SUM(fed_level_budget_value) Billable_target,
		SUM(bill_amount) Actual_Billed,
		ISNULL(SUM(bill_amount),0) - ISNULL(SUM(fed_level_budget_value),0) Diff_billed,
		IIF(SUM(fed_level_budget_value) IS NULL OR SUM(fed_level_budget_value) = 0, null, ISNULL(SUM(bill_amount),0) / ISNULL(SUM(fed_level_budget_value),0)) Diff_billed_percent,

		-- Charagable Hours
		SUM(fed_level_minute_value) chargable_hours_target,	
		SUM(chargeable_minutes_recorded/60) Actaul_chargable_hours,
		ISNULL(SUM(chargeable_minutes_recorded/60),0) - ISNULL(SUM(fed_level_minute_value),0) Diff_hours,
		IIF(SUM(fed_level_minute_value) IS NULL OR SUM(fed_level_minute_value) = 0, null, ISNULL(SUM(chargeable_minutes_recorded/60),0) / ISNULL(SUM(fed_level_minute_value),0)) Diff_hours_percent,

		-- Recovery Rates
		IIF(SUM(ISNULL(fed_level_tb_budget_value,0)) = 0, null, SUM(fed_level_budget_value) / SUM(fed_level_tb_budget_value)) Target_Recovery_Rate,
		IIF(SUM(ISNULL(billed_minutes_recorded,0)) = 0, null, SUM(bill_amount) / SUM(billed_minutes_recorded / 60)) Actual_Recovery_Rate,	
	
		(IIF(SUM(ISNULL(billed_minutes_recorded,0)) = 0, null, SUM(bill_amount) / SUM(billed_minutes_recorded / 60)))
		-
		(IIF(SUM(ISNULL(fed_level_tb_budget_value,0)) = 0, null, SUM(fed_level_budget_value) / SUM(fed_level_tb_budget_value))) Recovery_rate_diff,

		IIF (SUM(ISNULL(fed_level_budget_value,0)) = 0 OR SUM(ISNULL(fed_level_tb_budget_value,0)) = 0 , NULL,
			(IIF(SUM(ISNULL(billed_minutes_recorded,0)) = 0, null, SUM(bill_amount) / SUM(billed_minutes_recorded / 60)) )
			/
			(IIF(SUM(ISNULL(fed_level_tb_budget_value,0)) = 0, null, SUM(fed_level_budget_value) / SUM(fed_level_tb_budget_value)))) Recovery_rate_diff_percent
	
		,round(iif(sum(isnull(fact_agg_kpi_monthly_rollup.contracted_hours_in_month,0)) = 0, null, isnull(sum(fact_agg_kpi_monthly_rollup.chargeable_minutes_recorded/60),0) / isnull(sum(fact_agg_kpi_monthly_rollup.contracted_hours_in_month),0) * 100 ) , 1 ) Utilisation_Percent
	
		-- select dim_employee.leftdate
	FROM dbo.fact_agg_kpi_monthly_rollup 
	INNER JOIN dim_date ON fact_agg_kpi_monthly_rollup.dim_gl_date_key = dim_date.dim_date_key
	INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_kpi_monthly_rollup.dim_fed_hierarchy_history_key
	INNER JOIN dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key 
	WHERE  dim_date.fin_year = @fin_year 
	AND leaver = 0
	AND (dim_employee.leftdate IS NULL OR dim_employee.leftdate >= GETDATE())
	--AND fed_code = '6059'
	AND dbo.dim_date.calendar_date <= (DATEADD(m, DATEDIFF(m, 0, GETDATE()-1), 0))
	GROUP BY
	 GROUPING SETS (
	 (dim_date.fin_year, cast (dim_date.fin_month_no AS VARCHAR(3)),fed_code),
	 (dim_date.fin_year,fed_code)
	 )

) main 
LEFT OUTER JOIN WriteOffs WOF_Hourly ON ISNULL(main.fin_month,'YTD') = WOF_Hourly.fin_month AND WOF_Hourly.fixed_fee = 'Hourly' AND WOF_Hourly.fed_code = main.fed_code
LEFT OUTER JOIN WriteOffs WOF_Fixed ON ISNULL(main.fin_month,'YTD') = WOF_Fixed.fin_month AND WOF_Fixed.fixed_fee = 'Fixed Fee' AND WOF_Fixed.fed_code = main.fed_code
LEFT OUTER JOIN WIP ON WIP.fed_code = main.fed_code AND WIP.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN WIP_PY ON WIP_PY.fed_code = main.fed_code AND WIP_PY.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN NumberOfFiles ON NumberOfFiles.fed_code = main.fed_code AND NumberOfFiles.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN Client_balances ON Client_balances.fed_code = main.fed_code AND Client_balances.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN TotalBudget ON TotalBudget.fed_code = main.fed_code AND TotalBudget.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN FinalBill ON FinalBill.fed_code = main.fed_code AND FinalBill.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN FinalBill_PY ON FinalBill_PY.fed_code = main.fed_code AND FinalBill_PY.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN RepudiationRate ON RepudiationRate.fed_code = main.fed_code AND RepudiationRate.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN RepudiationRate_PY ON RepudiationRate_PY.fed_code = main.fed_code AND RepudiationRate_PY.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN Matterscapableofclosure ON Matterscapableofclosure.fed_code COLLATE Latin1_General_BIN = main.fed_code AND Matterscapableofclosure.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN Matterscapableofclosurelta ON Matterscapableofclosurelta.fed_code COLLATE Latin1_General_BIN = main.fed_code AND Matterscapableofclosurelta.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN Matters FixedMatters ON FixedMatters.fed_code = main.fed_code AND FixedMatters.fin_month = ISNULL(main.fin_month,'YTD') AND FixedMatters.fixed_fee = 'Fixed Fee'
LEFT OUTER JOIN Matters HourlyMatters ON HourlyMatters.fed_code = main.fed_code AND HourlyMatters.fin_month = ISNULL(main.fin_month,'YTD') AND HourlyMatters.fixed_fee = 'Hourly'
LEFT OUTER JOIN Dibs ON Dibs.fed_code = main.fed_code AND Dibs.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN Debt ON Debt.fed_code = main.fed_code AND Debt.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN Median_Fixed_Fee ON Median_Fixed_Fee.fed_code = main.fed_code AND Median_Fixed_Fee.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN Exceptions ON Exceptions.fed_code COLLATE Latin1_General_BIN = main.fed_code AND Exceptions.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN RR_PY ON RR_PY.fed_code = main.fed_code AND Median_Fixed_Fee.fin_month = ISNULL(main.fin_month,'YTD')
LEFT OUTER JOIN LTA_Exceptions ON LTA_Exceptions.fed_code = main.fed_code AND LTA_Exceptions.fin_month = ISNULL(main.fin_month,'YTD')
INNER JOIN dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = main.fed_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND dim_fed_hierarchy_history.activeud = 1
LEFT OUTER JOIN DebtTarget ON DebtTarget.team = dim_fed_hierarchy_history.hierarchylevel4hist AND DebtTarget.fin_month = ISNULL(main.fin_month,'YTD') 
WHERE ISNULL(main.fin_month,'YTD') IN ('YTD',CAST(@fin_month AS VARCHAR(2)))

ORDER BY 3, 2



/*

SELECT *
FROM dbo.dim_fed_hierarchy_history
WHERE fed_code = '4664'

SELECT *
FROM dbo.dim_fed_hierarchy_history
WHERE name = 'Jane Price'

SELECT DISTINCT CASE WHEN LOWER(fee_arrangement) IN ('fee_arrangement','annual retainer','fixed fee/fee quote/capped fee')
		THEN 'Fixed Fee' ELSE 'Hourly' END AS fee_arrangement
FROM dbo.dim_matter_header_current

*/

GO
