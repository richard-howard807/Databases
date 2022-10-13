SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [ClaimsMilestoneDashboard].[WriteOffs]
AS
BEGIN
SELECT calendar_date AS [Date of write-off]
,SUM(fact_write_off.write_off_amt) AS [Amount of write-off]
,dim_matter_header_current.client_code + '-' + dim_matter_header_current.matter_number AS [Client/Matter Number]
,dim_fed_hierarchy_history.name AS [Fee earner]
,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel2hist AS Division
FROM red_dw.dbo.fact_write_off
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
       ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_matter_owner_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  feeearner
       ON feeearner.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON fact_write_off.dim_matter_header_curr_key
       = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
WHERE calendar_date >='2019-05-01'
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
AND fact_write_off.write_off_type IN ('WA','NC','BA','P')
AND dim_write_off_date_key>=20180501

GROUP BY calendar_date 
,dim_matter_header_current.client_code + '-' + dim_matter_header_current.matter_number 
,dim_fed_hierarchy_history.name 
,dim_fed_hierarchy_history.hierarchylevel4hist 
,dim_fed_hierarchy_history.hierarchylevel3hist 
,dim_fed_hierarchy_history.hierarchylevel2hist
END 
GO
