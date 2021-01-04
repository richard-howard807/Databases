SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [ClaimsMilestoneDashboard].[Revenue]
AS
BEGIN

SELECT 
dim_bill_date.bill_date AS [Date of bill]
,bill_amount AS [Revenue billed]
,RTRIM(fact_bill_activity.client_code) + '-' + RTRIM(fact_bill_activity.matter_number) AS [Client/Matter Number]
,bill_number AS [Bill Number]
,dim_fed_hierarchy_history.name AS [Fee earner]
,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel2hist AS Division
,levelidud AS [Grade]
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key

WHERE dim_bill_date.bill_date >='2019-05-01'
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'

END
GO
