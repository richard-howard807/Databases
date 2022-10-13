SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 /*
	Author:			Lucy Dickinson
	Date:			20180116
	Description:	Webby ticket 286328 for Jill Sheridan. A report on future activies.  Performance wasn't great using the union and 
					the dim_tasks table didn't quite work correctly which is why I have used the below code.  this will need rewriting once
					we have moved to mattersphere (hopefully all keydates will be available in the warehouse.
	Amendments:		15/05/2019 - ES - Amended task descriptions to look at MS descriptions
					17/07/2019 - ES - Removed FED union, only active MS tasks need to pull through, JS
					25/01/2020 - JB - #130720 added is_there_an_issue_on_liability columns. Added an order on damages reserve
 */
 
CREATE PROCEDURE [nhs].[Key_dates_future_mediation_trials]
 AS
 
-- SELECT 
-- matter.client_code
-- ,matter.matter_number
-- ,matter.master_client_code
-- ,matter.master_matter_number
-- ,matter.matter_description
-- ,matter.matter_owner_full_name
-- ,finance.damages_reserve
-- ,reference.insurerclient_reference
-- ,plan_date,activity_desc  collate database_default AS  activity_desc  
--  ,'FED' AS [Systems]
--  ,locationidud AS [Office]
--FROM red_dw.dbo.dim_matter_header_current matter
--INNER JOIN red_dw.dbo.fact_finance_summary finance ON finance.client_code = matter.client_code
--AND finance.matter_number = matter.matter_number 
--LEFT JOIN red_dw.dbo.dim_client_involvement reference ON reference.client_code = finance.client_code AND reference.matter_number = finance.matter_number
--INNER JOIN 
--(SELECT tasks.case_id
--	,tasks.plan_date 
--	,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tasks.activity_desc,'REM: ',''), ' - [CASE MAN]',''),' - [NP]',''),' {CASE MAN]',''), ' [CASE MAN]','') activity_desc
--	, ROW_NUMBER() OVER (PARTITION BY tasks.case_id ORDER BY tasks.plan_date ASC) AS RowNum
--	FROM axxia01.dbo.casact tasks 
--	INNER JOIN axxia01.dbo.cashdr cashdr ON cashdr.case_id = tasks.case_id
--	INNER JOIN axxia01.dbo.caclient caclient ON cashdr.client = caclient.cl_accode AND caclient.cl_clgrp = '00000003'
--WHERE	tasks.activity_code IN (
--'NHSA0189','NHS01043','TRAA0348','PIDA0125','GEN01001'
--)
--AND tasks.tran_done IS NULL
--AND tasks.p_a_marker = 'p'

--	) activities ON activities.case_id = matter.case_id AND activities.RowNum = 1
--LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fee_earner_code=fed_code collate database_default AND dss_current_flag='Y'
--LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
--WHERE matter.client_group_name = 'NHS Resolution'
-- AND matter.date_closed_case_management IS NULL 
 
--UNION

 SELECT DISTINCT 
 matter.client_code
 ,matter.matter_number
 ,matter.master_client_code
 ,matter.master_matter_number
 ,matter.matter_description
 ,matter.matter_owner_full_name
 ,finance.damages_reserve
 ,reference.insurerclient_reference
  ,plan_date,activity_desc  collate database_default AS  activity_desc  
 ,'MS' AS [Systems]
 ,locationidud AS [Office]
 , dim_detail_core_details.is_there_an_issue_on_liability		AS [Liability Admitted]
FROM red_dw.dbo.dim_matter_header_current matter
INNER JOIN red_dw.dbo.fact_finance_summary finance ON finance.client_code = matter.client_code
AND finance.matter_number = matter.matter_number 
LEFT JOIN red_dw.dbo.dim_client_involvement reference ON reference.client_code = finance.client_code AND reference.matter_number = finance.matter_number
INNER JOIN 
(
SELECT fileID
	,tskDue AS  plan_date 
	,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tskDesc,'REM: ',''), ' - [CASE MAN]',''),' - [NP]',''),' {CASE MAN]',''), ' [CASE MAN]','') activity_desc
	,tskComplete
	, ROW_NUMBER() OVER (PARTITION BY dbTasks.fileID ORDER BY dbTasks.tskDue ASC) AS RowNum
	FROM MS_Prod.dbo.dbTasks
	WHERE tskDesc  IN ('RTM - today','Trial date - today','Trial date - today','Mediation - today', 'Joint settlement meeting - today') --('Trial date - today','Mediation - today','RTM - today','REM: Trial due today - [CASE MAN]','REM: Mediation today - [CASE MAN]','REM: RTM due today [CASE MAN]')
	AND tskComplete=0
	AND tskType='KEYDATE'
	AND tskActive=1
) AS activities 
 ON matter.ms_fileid=fileID

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fee_earner_code=fed_code collate database_default AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
	ON dim_detail_core_details.client_code = matter.client_code
		AND dim_detail_core_details.matter_number = matter.matter_number
 WHERE matter.client_group_name = 'NHS Resolution'
 AND matter.date_closed_case_management IS NULL  
ORDER BY
	finance.damages_reserve DESC	

GO
