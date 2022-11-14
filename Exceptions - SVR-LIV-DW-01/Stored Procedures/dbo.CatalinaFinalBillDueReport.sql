SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CatalinaFinalBillDueReport]


AS

SELECT 

ClientMatter = dim_matter_header_current.master_client_code + '-' + master_matter_number,
created,
task_desccription
, dim_tasks.tskdue
,completed
,CASE WHEN completed IS NOT NULL THEN 1 ELSE 0 END AS CompletedFlag
, name AS [Fee Earner]
, final_bill_flag = CASE WHEN final_bill_flag = 1 THEN 'Yes' ELSE 'No' END
 FROM red_dw.dbo.dim_tasks
 JOIN red_dw.dbo.fact_dimension_main
 ON fact_dimension_main.client_code = dim_tasks.client_code AND fact_dimension_main.matter_number = dim_tasks.matter_number
 JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
 JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
 
 
 
 WHERE task_desccription IN ( 
 'Catalina 15 Day Bill Reminder - Due in 7 days'                                                      
 , 'Catalina 15 Day Bill Reminder - Due today'                                                          
, 'Catalina 15 Day Bill Reminder - Due tomorrow'
 )

 AND dim_matter_header_current.master_client_code <> '30645'

GO
