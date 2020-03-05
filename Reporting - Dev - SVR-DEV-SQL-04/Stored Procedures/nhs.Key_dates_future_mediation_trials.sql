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
 
 */
 
CREATE PROCEDURE [nhs].[Key_dates_future_mediation_trials]
 AS
 
 SELECT 
 matter.client_code
 ,matter.matter_number
 ,matter.master_client_code
 ,matter.master_matter_number
 ,matter.matter_description
 ,matter.matter_owner_full_name
 ,finance.damages_reserve
 ,reference.insurerclient_reference
 ,activities.*
FROM red_dw.dbo.dim_matter_header_current matter
INNER JOIN red_dw.dbo.fact_finance_summary finance ON finance.client_code = matter.client_code
AND finance.matter_number = matter.matter_number 
LEFT JOIN red_dw.dbo.dim_client_involvement reference ON reference.client_code = finance.client_code AND reference.matter_number = finance.matter_number
INNER JOIN 
(SELECT tasks.case_id
	,tasks.plan_date 
	,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tasks.activity_desc,'REM: ',''), ' - [CASE MAN]',''),' - [NP]',''),' {CASE MAN]',''), ' [CASE MAN]','') activity_desc
	, ROW_NUMBER() OVER (PARTITION BY tasks.case_id ORDER BY tasks.plan_date ASC) AS RowNum
	FROM axxia01.dbo.casact tasks 
	INNER JOIN axxia01.dbo.cashdr cashdr ON cashdr.case_id = tasks.case_id
	INNER JOIN axxia01.dbo.caclient caclient ON cashdr.client = caclient.cl_accode AND caclient.cl_clgrp = '00000003'
WHERE	tasks.activity_code IN (
'NHSA0189','NHS01043','TRAA0348','PIDA0125'
)
AND tasks.tran_done IS NULL
AND tasks.p_a_marker = 'p'

	) activities ON activities.case_id = matter.case_id AND activities.RowNum = 1
 WHERE matter.client_group_name = 'NHS Resolution'
 AND matter.date_closed_case_management IS NULL 


GO
