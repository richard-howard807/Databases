SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [Newcastle].[WIPAnalysis]

AS 

BEGIN 


SELECT master_client_code AS [Client]
,dim_client.client_name AS [Client Name]
,segment AS [Segment]
,master_matter_number AS [Matter]
,matter_owner_full_name
,matter_owner_full_name AS matter_partner_code
,client_partner_code
,matter_description AS[Matter Description]
,name AS FeeEarner
,hierarchylevel4hist AS [Team]
,locationidud AS [Office]
,defence_costs_billed AS [Revenue]
,GETDATE() AS CurrentDate
,DATEADD(MONTH,1,GETDATE()) AS NextMonth
,DATEADD(MONTH,2,GETDATE()) AS ThirdMonth
,SUM(actual_time_recorded_value) AS WIPAmount
,SUM(minutes_recorded) AS WipTime
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_employee WITH(NOLOCK)
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
WHERE  dim_bill_key=0
AND isactive=1
AND locationidud='Newcastle'
AND master_client_code<>'30645'
GROUP BY master_client_code
,dim_client.client_name
,matter_owner_full_name
,matter_partner_code
,client_partner_code
,segment 
,master_matter_number
,matter_description 
,name 
,hierarchylevel4hist 
,locationidud
,defence_costs_billed
END
GO
