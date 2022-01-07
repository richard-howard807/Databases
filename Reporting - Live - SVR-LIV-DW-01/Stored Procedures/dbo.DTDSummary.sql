SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-01-06
-- Description:	#122977 New DTD report (Digital, Technology and Data), summary report
-- =============================================
CREATE PROCEDURE [dbo].[DTDSummary]
	
AS
BEGIN
	
	SET NOCOUNT ON;


SELECT *

FROM 
(
SELECT dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
,dim_bill_date.bill_fin_period AS [Period]
,SUM(fact_bill_activity.bill_amount) AS [Measure]
,'Revenue' AS Level
 
FROM red_dw.dbo.fact_bill_activity
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.dim_bill_date_key = fact_bill_activity.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.master_fact_key = fact_bill_activity.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND (dim_detail_core_details.insured_sector='Digital/New Media'
OR dim_client.sub_sector='Digital/media'
OR dim_detail_core_details.is_this_part_of_a_campaign='Digital, Technology and Data (DTD)')
AND dim_bill_date.bill_date>='2020-05-01'

GROUP BY dim_bill_date.bill_fin_period, dim_fed_hierarchy_history.hierarchylevel4hist, dim_fed_hierarchy_history.hierarchylevel3hist, dim_fed_hierarchy_history.hierarchylevel2hist

UNION

SELECT dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
, dim_date.fin_period AS [Period]
,COUNT(dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number) AS [Measure]
,'Matter Count' AS Level
 
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_date
ON CAST(dim_matter_header_current.date_opened_case_management AS date)=CAST(dim_date.calendar_date AS date)
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND (dim_detail_core_details.insured_sector='Digital/New Media'
OR dim_client.sub_sector='Digital/media'
OR dim_detail_core_details.is_this_part_of_a_campaign='Digital, Technology and Data (DTD)')
AND dim_date.calendar_date>='2020-05-01'

GROUP BY dim_date.fin_period, dim_fed_hierarchy_history.hierarchylevel4hist, dim_fed_hierarchy_history.hierarchylevel3hist, dim_fed_hierarchy_history.hierarchylevel2hist

) AS summary

PIVOT (AVG([Measure]) FOR [Level] IN ([Matter Count], [Revenue])) AS PivotTable

WHERE PivotTable.Division IN ('Legal Ops - Claims', 'Legal Ops - LTA')

ORDER BY PivotTable.Division, PivotTable.Department, PivotTable.Team, PivotTable.Period

;

END
GO
