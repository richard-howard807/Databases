SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MIBSuperCatSplit]
AS
BEGIN
SELECT dim_matter_header_current.client_code AS Client
,dim_matter_header_current.matter_number AS Matter
,matter_description AS [Matter Descrition]
,service_category AS [Service Category]
,name AS [Lead Handler]
,Recorded.[Total Hours Recorded]
,Recorded.[Total Amount Recorded]
,Recorded.[Lead Hours Recorded]
,Recorded.[Lead Amount Recorded]
,Recorded.[NonLead Hours Recorded]
,Recorded.[NonLead Amount Recorded]
,Billed.[Total Hours Billed]
,Billed.[Total Amount Billed]
,Billed.[Lead Hours Billed]
,Billed.[Lead Amount Billed]
,Billed.[NonLead Hours Billed]
,Billed.[NonLead Amount Billed]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN 
(
SELECT fact_all_time_activity.dim_matter_header_curr_key
,SUM(wiphrs) AS [Total Hours Recorded]
,SUM(wipamt) AS [Total Amount Recorded]
,SUM(CASE WHEN fee_earner_code=fed_code THEN wiphrs ELSE 0 END)  AS [Lead Hours Recorded]
,SUM(CASE WHEN fee_earner_code=fed_code THEN wipamt ELSE 0 END)  AS [Lead Amount Recorded]

,SUM(CASE WHEN fee_earner_code<>fed_code THEN wiphrs ELSE 0 END)  AS [NonLead Hours Recorded]
,SUM(CASE WHEN fee_earner_code<>fed_code THEN wipamt ELSE 0 END)  AS [NonLead Amount Recorded]
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
  ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
  WHERE service_category='Super cat'
 AND client_group_code='00000002'
 GROUP BY fact_all_time_activity.dim_matter_header_curr_key
) AS Recorded
 ON Recorded.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT fact_bill_billed_time_activity.dim_matter_header_curr_key
,SUM(minutes_recorded) AS [Total Hours Billed]
,SUM(time_charge_value) AS [Total Amount Billed]
,SUM(CASE WHEN fee_earner_code=fed_code THEN minutes_recorded ELSE 0 END) /60 AS [Lead Hours Billed]
,SUM(CASE WHEN fee_earner_code=fed_code THEN time_charge_value ELSE 0 END)  AS [Lead Amount Billed]

,SUM(CASE WHEN fee_earner_code<>fed_code THEN minutes_recorded ELSE 0 END) /60 AS [NonLead Hours Billed]
,SUM(CASE WHEN fee_earner_code<>fed_code THEN time_charge_value ELSE 0 END)  AS [NonLead Amount Billed]
FROM red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
  ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
  WHERE service_category='Super cat'
 AND client_group_code='00000002'
 GROUP BY fact_bill_billed_time_activity.dim_matter_header_curr_key
) AS Billed
 ON Billed.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 WHERE service_category='Super cat'
 AND client_group_code='00000002'
END
GO
