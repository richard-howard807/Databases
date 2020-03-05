SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-26
Description:		Tasks Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[TasksDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

        

SELECT 

  RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, fact_dimension_main.client_code AS [Client Code]
		--, dim_matter_header_current.ms_client_code AS [MS Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_matter_header_current.[matter_description] AS [Matter Description]
		, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
		, dim_matter_header_current.date_opened_practice_management AS OpenedCaseDate_Finance
		, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
		, dim_tasks.task_code AS [Task Code]
		, dim_tasks.task_desccription AS [Task Description]
		, dim_task_date.calendar_date AS [Task Date]
		, dim_task_due_date.calendar_date AS [Task Due Date]
		, dim_tasks.task_status AS [Task Status]
		, CASE WHEN DATEDIFF(DAY,dim_task_date.calendar_date,GETDATE())<=14 THEN 1 ELSE 0 END AS [Task due within 14 days]
		, dim_detail_property.[brand] AS [Brand]
		, dim_detail_property.[address] AS [Address]
		, DATEDIFF(dd,dim_task_due_date.calendar_date,dim_task_date.calendar_date) as [Days to Complete Task]
		, CASE WHEN dim_task_due_date.calendar_date BETWEEN DATEADD(Month,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))  AND DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) THEN 1 ELSE 0 END AS [Task Due Date Rolling 12 Months]
	    , CASE WHEN dim_tasks.task_status='p' THEN 'Pending'
			 WHEN DATEDIFF(dd,dim_task_due_date.calendar_date,dim_task_date.calendar_date) > 10 then 'Action post > 10 days' 
			 when DATEDIFF(dd,dim_task_due_date.calendar_date,dim_task_date.calendar_date) <= 10 THEN 'Post actioned within 10 days'
			 else NULL end as [Action post > 10 days?]
		, CASE WHEN dim_client.client_code='00712551' AND dim_tasks.task_status ='a' AND dim_matter_header_current.[matter_description] NOT LIKE 'PV:%' AND (CASE WHEN DATEDIFF(DAY,dim_task_date.calendar_date,GETDATE())<=14 THEN 1 ELSE 0 END)=1 THEN 'Rexel Cases'
			WHEN dim_detail_property.[brand] IS NOT NULL AND dim_tasks.task_status ='a' THEN 'Pentland' 
			WHEN dim_tasks.task_code ='LIT0601' THEN 'Zurich Outsource SLA'  
			WHEN dim_tasks.task_code IN ('RECA0123','TRAA0449','TRAA0303','FTRA9912','TRAA0342','TRAA0315') THEN 'Fraud'
			ELSE NULL
			END AS [Dashboard Filter]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_tasks ON fact_tasks.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_tasks ON dim_tasks.dim_tasks_key = fact_tasks.dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_task_due_date ON dim_task_due_date.dim_task_due_date_key = fact_tasks.dim_task_due_date_key
LEFT OUTER JOIN red_dw.dbo.dim_task_date ON dim_task_date.dim_task_date_key = fact_tasks.dim_task_date_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key




WHERE 
ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.matter_number<>'ML'
AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)


AND dim_tasks.task_type_code<>0

--Dashboard task filters
AND (CASE WHEN dim_client.client_code='00712551' AND dim_tasks.task_status ='a' AND dim_matter_header_current.[matter_description] NOT LIKE 'PV:%' AND (CASE WHEN DATEDIFF(DAY,dim_task_date.calendar_date,GETDATE())<=14 THEN 1 ELSE 0 END)=1 THEN 'Rexel Cases'
			WHEN dim_detail_property.[brand] IS NOT NULL AND dim_tasks.task_status ='a' THEN 'Pentland' 
			WHEN dim_tasks.task_code ='LIT0601' THEN 'Zurich Outsource SLA' 
			WHEN dim_tasks.task_code IN ('RECA0123','TRAA0449','TRAA0303','FTRA9912','TRAA0342','TRAA0315') THEN 'Fraud'
			ELSE NULL END) IS NOT NULL

END

GO
