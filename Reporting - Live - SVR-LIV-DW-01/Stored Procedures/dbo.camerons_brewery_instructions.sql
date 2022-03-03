SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-03-16
-- Description: #91950 New report request for Camerons Brewery. 
				Shows number of instructions received, split by Current Status
-- Update: #91950 change of columns needed by client
-- JB ticket #136881 - changed revenue/disb figures to look at 3E due to WB matters revenue not being in warehouse pre merger 
-- =============================================
*/

CREATE PROCEDURE [dbo].[camerons_brewery_instructions] --EXEC [dbo].[camerons_brewery_instructions] '2021-05-01','2021-05-31'
(
	@start_date AS DATE
	, @end_date AS DATE
)
AS

BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

----Testing
--DECLARE @start_date	AS DATE = CONVERT(DATE,DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0),103)
--		, @end_date AS DATE = CONVERT(DATE,DATEADD(DAY, -(DAY(GETDATE())), GETDATE()),103) 

DROP TABLE IF EXISTS #cb_bills

SELECT 
	bill_data.dim_matter_header_curr_key
	, SUM(bill_data.revenue)	AS revenue
	, SUM(bill_data.disbs)		AS disbs
	, SUM(bill_data.monthly_fees) AS monthly_fees
	, SUM(bill_data.monthly_disbs)		AS monthly_disbs
INTO #cb_bills
FROM (
		SELECT 
			dim_matter_header_current.dim_matter_header_curr_key
			, ARDetail.InvDate	
			, SUM(ARFee)		AS revenue
			, SUM(ARDetail.ARHCo) + SUM(ARDetail.ARSCo)		AS disbs
			, IIF(ARDetail.InvDate BETWEEN @start_date AND @end_date, SUM(ARDetail.ARFee), 0) AS monthly_fees
			, IIF(ARDetail.InvDate BETWEEN @start_date AND @end_date, SUM(ARDetail.ARHCo) + SUM(ARDetail.ARSCo), 0) AS monthly_disbs
		FROM TE_3E_Prod.dbo.ARDetail
			INNER JOIN TE_3E_Prod.dbo.InvMaster
				ON InvIndex=InvMaster
			INNER JOIN TE_3E_Prod.dbo.Matter
				ON InvMaster.LeadMatter = Matter.MattIndex
			INNER JOIN MS_Prod.config.dbFile
				ON Matter.MattIndex = dbFile.fileExtLinkID
			INNER JOIN red_dw.dbo.dim_matter_header_current	
				ON dim_matter_header_current.ms_fileid = dbFile.fileID
		WHERE 1 = 1 
			AND dim_matter_header_current.master_client_code IN ('W22555', 'W24107')
			AND ARList IN ('Bill','BillRev')
		GROUP BY
			dim_matter_header_current.dim_matter_header_curr_key
			, ARDetail.InvDate
	) AS bill_data
GROUP BY
	bill_data.dim_matter_header_curr_key



SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number			AS [MatterSphere Client/Matter Number]
	, dim_matter_header_current.matter_owner_full_name			AS [Case Handler]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, dim_file_notes.external_file_notes					AS [Present Position]
	, CASE
		WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN 
			fact_finance_summary.fixed_fee_amount
		ELSE
			fact_finance_summary.revenue_estimate_net_of_vat
	  END					AS [Agreed Fee]
	, ISNULL(#cb_bills.revenue, 0)			AS [Fees billed to Date]
	, ISNULL(#cb_bills.disbs, 0)			AS [Disbursements Billed to Date]
	, ISNULL(#cb_bills.monthly_fees, 0)			AS [Monthly Fees]
	, ISNULL(#cb_bills.monthly_disbs,0) AS [Monthly Disbs]
	, CASE
		WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN 
			ISNULL(fact_finance_summary.fixed_fee_amount, 0) - ISNULL(#cb_bills.revenue, 0)
		ELSE
			ISNULL(fact_finance_summary.revenue_estimate_net_of_vat, 0) - ISNULL(#cb_bills.revenue, 0)
	  END													AS [Fees to be Billed]
	, ISNULL(fact_finance_summary.disbursement_balance, 0)		AS [Unbilled Disbursements]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)		AS [Date Closed]
	, CASE

		WHEN dim_matter_header_current.date_closed_practice_management IS NULL THEN
			'Open'
		ELSE
			'Closed'
	  END				AS [OpenClosed]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_file_notes
		ON dim_file_notes.dim_file_notes_key = fact_dimension_main.dim_file_notes_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN #cb_bills
		ON #cb_bills.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code IN ('W22555', 'W24107')
	--AND dim_matter_header_current.master_matter_number = '211'
	AND dim_matter_header_current.reporting_exclusions = 0
ORDER BY
	OpenClosed DESC

END	



GO
