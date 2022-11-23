SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ClarionBillingReport]

AS 

BEGIN 
SELECT 
master_client_code + '-'+master_client_code AS [Weightmans Ref]
,name AS [Fee earner name]
,hierarchylevel4hist AS [Team]
,matter_description AS [Matter description]
,wip AS [WIP balance]
,disbursement_balance AS [Disbs balance]
,CASE WHEN disbursement_balance>0 OR wip>50 THEN 1 ELSE 2 END AS Sheet
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
WHERE master_client_code='756630'
AND date_closed_case_management IS NULL
AND hierarchylevel4hist IN ('Niche Costs','Property Litigation')
END 
GO
