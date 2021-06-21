SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SocialCareMatters]

AS 

BEGIN


SELECT master_client_code +'-'+master_matter_number AS [Matter References]
,matter_description AS [Matter Description]
,work_type_name AS [Matter type]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,name AS [Matter Owner]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,wip AS [WIP]
,disbursement_balance AS [Unbilled Disbursements]
,defence_costs_billed AS [Revenue Billed]
,ISNULL(unpaid_disbursements,0) + ISNULL(paid_disbursements,0) AS [Disbursements Billed]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel4hist='Regulatory Social Care & Governance'
ORDER BY [Date Opened] DESC

END
GO
