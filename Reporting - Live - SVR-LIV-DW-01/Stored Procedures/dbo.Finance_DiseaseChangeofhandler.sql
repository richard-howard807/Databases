SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Finance_DiseaseChangeofhandler]

AS

DROP TABLE IF EXISTS #t1

SELECT DISTINCT 

dim_matter_header_current.master_client_code
,dim_matter_header_current.master_matter_number
,[Date Opened] =dim_matter_header_current.date_opened_case_management
,client_group_name
,client_name
,[Original Matter Owner] = dim_fed_hierarchy_history.name
,[Current Matter Owner] = hist.name
,WIPNonCosts

,[Owner Change Date] = hist.dss_start_date


--,ISNULL(dim_fed_hierarchy_history.cost_handler,0) [OriginalCostsHandler]
--,hist.cost_handler [CurrentisCostsHandler]
,CostHandlerChange =  CASE WHEN ISNULL(dim_fed_hierarchy_history.cost_handler,0) <> hist.cost_handler THEN 'Yes' ELSE 'No' END 
,FilterList = CASE WHEN hist.name IN ('Deborah Matheson','Lewis Fearon','Victoria James','Stephanie McBride','Sarah Evans') THEN 'FilterList' ELSE 'N/A' END
INTO #t1
FROM red_dw.dbo.fact_matter_summary
join red_dw.dbo.fact_dimension_main on fact_dimension_main.master_fact_key = fact_matter_summary.master_fact_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key_original_matter_owner_dopm 
JOIN  red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_fed_hierarchy_history hist
ON hist.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN (SELECT client_code AS WipClient,matter_number AS WipMatter,SUM(time_charge_value) AS WIPNonCosts
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
WHERE client_code IN ( 'W15373','W15349')
AND fed_code NOT IN ('3662','1713','3401','4456','3113','4878','4941','4846','2033','1924','4493','4204')
AND dim_bill_key=0
GROUP BY client_code,matter_number) AS WIPNonCosts
 ON dim_matter_header_current.client_code=WIPNonCosts.WipClient
 AND dim_matter_header_current.matter_number=WIPNonCosts.WipMatter


WHERE 1 = 1 

AND dim_matter_header_current.client_code IN ( 'W15373','W15349')


SELECT * FROM #t1
WHERE FilterList = 'FilterList'
AND CostHandlerChange = 'Yes'
GO
