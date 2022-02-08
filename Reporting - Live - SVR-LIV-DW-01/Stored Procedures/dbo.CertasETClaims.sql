SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CertasETClaims]

AS 

BEGIN 
SELECT
master_client_code +'.'+master_matter_number[MS Client/Matter Ref]
,matter_description AS [Matter Description]
,name AS [Case Manager]
,work_type_name AS [Matter Type]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_detail_core_details.present_position AS [Present Position]
,fact_detail_reserve_detail.[potential_compensation] AS [Potential Compensation]
,wip AS [WIP]
,Chargeable.AllTimeChargeableHrs AS [Chargeable Hours Recorded]
,last_time_transaction_date AS [Date of Last Time Posting]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, SUM(minutes_recorded)/60 AS AllTimeChargeableHrs
FROM red_dw.dbo.fact_billable_time_activity WITH(NOLOCK)
GROUP BY dim_matter_header_curr_key) AS Chargeable
 ON Chargeable.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.client_code = dim_matter_header_current.client_code
AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code='808656'
AND dim_matter_header_current.date_closed_case_management IS NULL
AND work_type_group='EPI'
AND work_type_name NOT IN 
(
'Boardroom Training'
,'Commercial drafting (advice)'
,'Compli Online Training'
,'Early Conciliation'
,'Employment Advice Line'
,'General Advice : Employment'
,'HR Rely'
,'Investigation'
,'Management'
,'Mediation'
,'Reactive Training'
,'Risk Management Services'
,'Training'
,'Settlement Agreements'
)

ORDER BY dim_matter_header_current.date_opened_case_management ASC
END 
GO
