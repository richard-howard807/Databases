SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ClarionBordereau]
(
@StartDate AS DATE
,@EndDate AS DATE
)


AS 
BEGIN
SELECT master_client_code AS Client,
       master_matter_number AS Matter,
       matter_description AS [Description],
       commercial_costs_estimate AS FeeEstimate,
	   bill_date AS [Bill Date],
       fact_bill.bill_number AS [Bill Number],
       bill_total AS BillTotal,
       fees_total AS RevenueTotal,
       fact_bill.unpaid_disbursements + fact_bill.paid_disbursements AS DisbursementsTotal,
       vat_amount AS [VatTotal],
       matter_owner_full_name AS [Matter Owner],
       name AS [Fee Earner],
       adjustment_type AS [Adjustment Type],
       fee_arrangement AS [Fee Arragement],
       SUM(BillHrs) AS HrsBilled,
       SUM(BillAmt) AS AmountBilled,
       NULL AS DisbursementDetail,
       NULL AS DisbursementAmount

FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.fact_bill_billed_time_activity
 ON fact_bill_billed_time_activity.dim_bill_key = fact_bill.dim_bill_key
 AND fact_bill_billed_time_activity.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
        LEFT OUTER JOIN TE_3E_Prod.dbo.TimeBill WITH(NOLOCK)
            ON TimeCard = fact_bill_billed_time_activity.transaction_sequence_number
               AND TimeBill.timebillindex = fact_bill_billed_time_activity.timebillindex
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code='756630'
AND bill_date BETWEEN @StartDate AND @EndDate
AND fact_bill.bill_number <>'PURGE'
GROUP BY master_client_code, 
       master_matter_number, 
       matter_description, 
       commercial_costs_estimate,
	   bill_date, 
       fact_bill.bill_number, 
       bill_total, 
       fees_total, 
       fact_bill.unpaid_disbursements,
	   fact_bill.paid_disbursements,
       vat_amount,
       matter_owner_full_name,
       name,
       fee_arrangement,adjustment_type

UNION


SELECT master_client_code AS Client,
       master_matter_number AS Matter,
       matter_description AS [Description],
       commercial_costs_estimate AS FeeEstimate,
	   bill_date AS [Bill Date],
       fact_bill.bill_number AS [Bill Number],
       fact_bill.bill_total AS BillTotal,
       fees_total AS RevenueTotal,
       fact_bill.unpaid_disbursements + fact_bill.paid_disbursements AS DisbursementsTotal,
       fact_bill.vat_amount AS [VatTota],
       matter_owner_full_name AS [Matter Owner],
       matter_owner_full_name AS [Fee Earner],
       adjustment_type AS [Adjustment Type],
       fee_arrangement AS [Fee Arragement],
       NULL AS HrsBilled,
       NULL AS AmountBilled,
       narrative AS DisbursementDetail,
       bill_total_excl_vat AS DisbursementAmount

FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_bill_key = fact_bill_detail.dim_bill_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
LEFT OUTER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key=fact_bill_detail.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_detail.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.client_code = fact_bill_detail.client_code
AND dim_client_involvement.matter_number = fact_bill_detail.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.client_code = fact_bill_detail.client_code
AND dim_detail_core_details.matter_number = fact_bill_detail.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_narrative ON dim_bill_narrative.dim_bill_narrative_key = fact_bill_detail.dim_bill_narrative_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON  fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code='756630'
AND bill_date BETWEEN @StartDate AND @EndDate
AND  fact_bill_detail.charge_type='disbursements'
END
GO
