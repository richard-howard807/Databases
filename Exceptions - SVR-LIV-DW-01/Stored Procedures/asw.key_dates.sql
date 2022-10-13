SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 10/11/2017
-- Description:	Get List of Keydates using the view tasks_union
-- =============================================
CREATE PROCEDURE [asw].[key_dates]
	
AS


SELECT  
a.client_code
,a.matter_number
,a.task_id
,a.task_due_date
,a.task_due_date [task_date]
,a.task_desc [Category]
,client.client_name
,CASE	WHEN a.task_desc IN ('REM: Exchange of expert reports due today [CM]','Exchange of expert reports due - today') THEN 1
WHEN a.task_desc IN ('REM: Trial Window starts due today [CM]','Trial window - today') THEN 2
WHEN a.task_desc IN ('Trial date - today') THEN 3 ELSE 4 

END RowOrder
FROM dbo.tasks_union a
INNER JOIN red_dw.dbo.dim_client client ON client.client_code = a.client_code COLLATE Latin1_General_CI_AS
WHERE a.client_code IN ('00787558','00787559','00787560','00787561')  
AND [task_desc] IN ('REM: Exchange of expert reports due today [CM]'
,'REM: Trial Window starts due today [CM]'
,'REM: Trial due today - [CASE MAN]'
,'Trial window - today'
,'Exchange of expert reports due - today'
,'Trial due today', 
'Trial date - today'
)






--SELECT  DISTINCT a.task_desc
----,CASE	WHEN a.task_desc IN ('REM: Exchange of expert reports due today [CM]','Exchange of expert reports due - today') THEN 1
----WHEN a.task_desc IN ('REM: Trial Window starts due today [CM]','Trial window - today') THEN 2
----ELSE 3 END RowOrder
--FROM dbo.tasks_union a
--INNER JOIN red_dw.dbo.dim_client client ON client.client_code = a.client_code COLLATE Latin1_General_CI_AS
GO
