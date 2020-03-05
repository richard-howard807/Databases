SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 18/07/2018
-- Description:	This bit of the report got overwritten before due to multiple people working on the same report
--				I will put in a store procedure so that it can be modified outside of the report
-- =============================================
-- ES - 03/01/2019 - Added service of claim form key date, 5892
-- =============================================
CREATE PROCEDURE [asw].[mi_renewals_tasks]
AS

WITH mintaskdate AS (
					SELECT client_code, matter_number, MIN(task_due_date) [taskduedate]
					FROM dbo.tasks_union tasks
					WHERE client_code IN ('00787558','00787559','00787560','00787561') 
					AND task_desc IN ('Expiry of section 26 notice due - today'
										,'Expiry of section 25 notice due - today'
										,'REM: Expiry of Section 26 Notice Due Today [CM]'
										,'REM: Expiry of Section 25 Notice Due Today [CM]'
										,'Exchange of witness statements - today'
										,'Expiry of stay - today'
										,'Trial window - today'
										,'Update to court following expiry of stay - today'
										,'Hearing - today'
										,'Exchange of expert reports due - today'
										,'Pre-trial checklist due - today'
										,'CMC due - today'
										,'Service of claim form - today'
										,'REM: Service of claim form due today - [CASE MAN]'
					)
					GROUP BY client_code, matter_number
					)

SELECT 
	a.client_code
	,a.matter_number
	,a.task_id
	,a.task_due_date [Task Due Date]
	,a.task_desc [Category]
	,CONVERT(VARCHAR(10),a.task_due_date,103)+' : '+
	
		CASE WHEN task_desc = 'Expiry of section 26 notice due - today' THEN 'Expiry of section 26 notice due'

										 WHEN task_desc ='Expiry of section 25 notice due - today' THEN 'Expiry of section 25 notice due'
										 WHEN task_desc ='REM: Expiry of Section 26 Notice Due Today [CM]' THEN 'Expiry of section 26 notice due'
										 WHEN task_desc ='REM: Expiry of Section 25 Notice Due Today [CM]'  THEN 'Expiry of section 25 notice due' 
										 WHEN task_desc ='Exchange of witness statements - today' THEN 'Exchange of witness statements'
										 WHEN task_desc ='Expiry of stay - today' THEN 'Expiry of stay'
										 WHEN task_desc ='Trial window - today' THEN 'Trial window'
										 WHEN task_desc ='Update to court following expiry of stay - today' THEN 'Update to court following expiry of stay'
										 WHEN task_desc ='Hearing - today' THEN 'Hearing'
										 WHEN task_desc ='Exchange of expert reports due - today' THEN 'Exchange of expert reports due'
										 WHEN task_desc ='Pre-trial checklist due - today' THEN 'Pre-trial checklist due'
										 WHEN task_desc ='CMC due - today' THEN 'CMC due'
										 WHEN task_desc ='Service of claim form - today' THEN 'Service of claim form'
										 WHEN task_desc ='REM: Service of claim form due today - [CASE MAN]' THEN 'Service of claim form'
			ELSE a.task_desc END AS [Next Key Date Action]
	, ROW_NUMBER() OVER(PARTITION BY a.client_code,a.matter_number ORDER BY a.task_id) AS [Row number]

FROM dbo.tasks_union a
INNER JOIN mintaskdate ON a.client_code=mintaskdate.client_code AND a.matter_number=mintaskdate.matter_number AND a.task_due_date=mintaskdate.taskduedate 
--INNER JOIN mintaskid ON a.client_code=mintaskid.client_code AND a.matter_number=mintaskid.matter_number AND a.task_id=mintaskid.taskid
WHERE a.client_code IN ('00787558','00787559','00787560','00787561')




GO
