SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 15-10-20202
-- Description:	#69840 this is for a financial dashboard 
-- =============================================
-- ES 22-10-2020 added date bill paid requested by A-M
-- =============================================

CREATE PROCEDURE [dbo].[FixedFeeFinanceDashboard]  

AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
RTRIM(fact_bill.client_code)+'/'+fact_bill.matter_number AS [Weightmans Reference]
,name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,hierarchylevel3hist AS [Department]
,bill_sequence
,fact_bill.client_code
,fact_bill.matter_number
,fact_bill.bill_number
,hc.client_group_name
,hc.client_name
,hc.date_opened_case_management
,hc.date_closed_case_management
,dim_date.calendar_date as [Bill Date]
,work_type_name
,output_wip_fee_arrangement

,CASE
    WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
        NULL
    ELSE
        fact_matter_summary_current.last_bill_date
END AS [Last Bill Date]
,SUM(fact_bill.fees_total) [Revenue Billed]
,fact_matter_summary_current.wip_balance
,CASE WHEN PaidDate.calendar_date='1753-01-01' THEN NULL ELSE PaidDate.calendar_date end AS [Date Bill Paid]

FROM red_dw.dbo.fact_bill
LEFT JOIN red_Dw.dbo.dim_client 
ON dim_client.dim_client_key = fact_bill.dim_client_key
LEFT JOIN red_Dw.dbo.dim_date 
ON dim_bill_date_key = dim_date_key
LEFT JOIN red_dw.dbo.dim_matter_header_current AS hc 
ON fact_bill.dim_matter_header_curr_key = hc.dim_matter_header_curr_key
--LEFT JOIN red_dw.dbo.fact_dimension_main ON 
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = hc.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main ON  hc.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.fed_code = hc.fee_earner_code
AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
AND GETDATE() BETWEEN dss_start_date AND dss_end_date
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.dim_matter_header_curr_key = hc.dim_matter_header_curr_key

LEFT OUTER JOIN red_dw.dbo.dim_date AS [PaidDate]
ON paidDate.dim_date_key=fact_bill.dim_last_pay_date_key


WHERE 
bill_number <> 'PURGE'
AND hc.date_opened_case_management >='20171231'
AND output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee'

GROUP BY 
RTRIM(fact_bill.client_code)+'/'+fact_bill.matter_number
,name 
,hierarchylevel4hist 
,hierarchylevel3hist 
,bill_sequence
,fact_bill.client_code
,fact_bill.matter_number
,fact_bill.bill_number

,hc.client_group_name
,hc.client_name
,hc.date_opened_case_management
,hc.date_closed_case_management
,dim_date.calendar_date
,work_type_name
,output_wip_fee_arrangement
,fact_detail_paid_detail.output_wip_contingent_wip
,CASE
    WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
        NULL
    ELSE
        fact_matter_summary_current.last_bill_date
END
,last_bill_date
,fact_matter_summary_current.wip_balance
,CASE WHEN PaidDate.calendar_date='1753-01-01' THEN NULL ELSE PaidDate.calendar_date end

	


END
GO
