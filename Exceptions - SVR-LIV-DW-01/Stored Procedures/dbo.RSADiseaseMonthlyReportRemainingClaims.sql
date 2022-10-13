SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Max Taylor
-- Create date: 2021-03-22
-- Description:	91117 - New Report for RSA Disease Monthly Report - Remaining Claims
 
-- =============================================
CREATE PROCEDURE [dbo].[RSADiseaseMonthlyReportRemainingClaims] 

AS

DROP TABLE IF EXISTS #main

SELECT DISTINCT

 [FED Client/Matter No] = CASE WHEN ISNUMERIC(dim_matter_header_current.client_code) = 1 THEN  CAST(CAST(dim_matter_header_current.client_code AS INT) AS NVARCHAR(20)) ELSE dim_matter_header_current.client_code END +'/' + CASE WHEN ISNUMERIC(dim_matter_header_current.matter_number) = 1 THEN CAST(CAST(dim_matter_header_current.matter_number AS INT) AS NVARCHAR(20)) ELSE dim_matter_header_current.matter_number END
,[Solicitor Reference] = fact_dimension_main.master_client_code +'/'+ master_matter_number
,[Matter Description] = matter_description
,[Total Current Reserve] = ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END
,[Damages Reserve] = fact_finance_summary.[damages_reserve_net]
,[Claimant Costs Reserve] = fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net]
,[RSA Solicitor Costs Reserve] = CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END

,[Defence Costs] = ISNULL(fact_finance_summary.[defence_costs_reserve], 0) 
/*
 TTS Reserve Calculation 
If "Total Reserve" is £5,000 or less, multiply by 1.12
If "Total Reserve" is £5,000.01 - £10,000, multiply by 1.18
If "Total Reserve" is £10,000.01 - £25,000, multiply by 1.24
If "Total Reserve" is over £25,000, multiply by 1.3     */

,[TTS Reserve] = 
--If "Total Reserve" is £5,000 or less, multiply by 1.12
CASE WHEN (ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) <=5000.00 THEN 
(ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) *1.12
--If "Total Reserve" is £5,000.01 - £10,000, multiply by 1.18
     WHEN (ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) BETWEEN 5000.01 AND 10000.00 THEN 
(ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) +CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) *1.18
--If "Total Reserve" is £10,000.01 - £25,000, multiply by 1.24
     WHEN (ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) BETWEEN 10000.01 AND 25000 THEN 
(ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) *1.24
--If "Total Reserve" is over £25,000, multiply by 1.3  
WHEN (ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) > 25000.00 THEN 
(ISNULL(fact_finance_summary.[damages_reserve_net], 0) + ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net], 0) + CASE WHEN  ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)     < 0 THEN 0
                                  ELSE ISNULL(fact_finance_summary.[defence_costs_reserve], 0) - (ISNULL(total_amount_billed, 0) -310)   END) *1.3
ELSE NULL END 

,[RSA Solicitors Costs Spend] = total_amount_billed - 310
,[RSA Solicitors Costs Spend (RSA Share)] = total_amount_billed - 310

/* If "WIP" and "Unpaid bill balance" are both £0, can we show the last bill paid date from 3E?*/
,[Date File Closed] = CASE WHEN ISNULL(wip, 0) + ISNULL(unpaid_bill_balance, 0) = 0 THEN MAX(last_pay_calendar_date) OVER (PARTITION BY fact_bill.master_fact_key) END 
 
,[Total Spend] = ISNULL(fact_finance_summary.[damages_paid], 0)  + ISNULL(fact_finance_summary.[claimants_costs_paid], 0) + ISNULL(total_amount_billed, 0)
,[WIP] =  fact_finance_summary.wip
,[Unpaid bill balance] =  fact_finance_summary.unpaid_bill_balance



,fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] AS [Gross (Global) Damages Agreed]
,fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] AS [Total Damages Paid by All Parties]
,fact_finance_summary.[damages_paid] AS [Total Damages Paid by RSA]
,fact_finance_summary.[claimants_total_costs_paid_by_all_parties] AS [Total Claimants Costs Agreed Global ]
,fact_finance_summary.[claimants_costs_paid] AS [Claimant Solicitors Total Paid]
,fact_detail_paid_detail.[tp_total_costs_claimed_all_parties] AS [Total Claimed Costs Bill]
,curNetPCAgainst AS [Net Profit Costs Claimed (Global)]
,curNetPCPaid AS [Net Profit Costs Settled (Global)]
,dim_detail_outcome.[date_claim_concluded] AS [Damages Settlement Date]
,dim_detail_outcome.[date_claimants_costs_received] AS [Date Costs Received]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]

INTO #main
FROM red_dw.dbo.fact_dimension_main

JOIN red_dw.dbo.dim_matter_header_current 
	ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key

JOIN red_dw.dbo.fact_finance_summary 
	ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

JOIN red_dw.dbo.fact_detail_reserve_detail 
	ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key

JOIN red_dw.dbo.fact_bill 
	ON fact_bill.master_fact_key = fact_dimension_main.master_fact_key

JOIN red_dw.dbo.dim_last_pay_date 
	ON dim_last_pay_date.dim_last_pay_date_key = fact_bill.dim_last_pay_date_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
 ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN ms_prod.dbo.udMIOutcomeCosts
 ON ms_fileid=fileID
	WHERE fact_dimension_main.master_client_code +'-' + master_matter_number IN 
(
'W15558-1417'
,'W15558-1662'
,'W15558-316'
,'W15558-620'
,'W15558-799'
,'W15558-1064'
,'W15558-1201'
,'W15558-1307'
,'W15558-1437'
,'W15558-1527'
)

/* Final select */
	SELECT *
		   FROM #main 
	WHERE [Date File Closed] IS NULL 
	ORDER BY [Solicitor Reference]


GO
