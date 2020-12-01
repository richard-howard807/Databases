SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 30/11/2020
-- Description:	#80264
-- =============================================
CREATE PROCEDURE [dbo].[GasComplianceDashboard]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT 
dim_matter_header_current.master_client_code AS [Client Code]
,master_matter_number AS [Matter Number]
,matter_description AS Descripion
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,dim_fed_hierarchy_history.[name] AS [Case Manager]
,gascomp_lba_date_upload AS [LBA Date Upload]
,gascomp_lba_expiry_date AS [LBA Expiry Date]
,gascomp_injunction_application_date AS [Injunction Application Date]
,gascomp_injunction_type AS [Injunction Type]
,gascomp_date_order_served AS [Date Order Served]
,gascomp_hearing_date AS [Hearing Date]
,gascomp_injunction_service_date AS [Injunction Service Date]
,gascomp_comments AS Comments
,total_amount_bill_non_comp AS [Total Billed]
,defence_costs_billed AS Revenue
,disbursements_billed AS Disbursements
,vat_billed AS VAT
, CASE
               WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
                   NULL
               ELSE
                   fact_matter_summary_current.last_bill_date
           END AS [Last Bill Date]

FROM
red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
               AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
               AND GETDATE()
               BETWEEN dss_start_date AND dss_end_date

LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
            ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

WHERE 
dim_matter_header_current.master_client_code = 'W15603'
AND  dim_matter_worktype.[work_type_name] = 'Injunction'

END
GO
