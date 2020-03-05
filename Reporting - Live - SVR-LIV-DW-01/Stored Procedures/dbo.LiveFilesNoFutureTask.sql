SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-01-27
-- Description:	Live files with no future task, 43794
-- =============================================
CREATE PROCEDURE [dbo].[LiveFilesNoFutureTask]

	@Division VARCHAR(MAX)
	,@Department VARCHAR(MAX)
	,@Team VARCHAR(MAX)
	,@MatterOwner VARCHAR(MAX)
	,@ClientCode VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT ListValue  INTO #Division FROM 	dbo.udt_TallySplit('|', @Division)
SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit('|', @Department)
SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team)
SELECT ListValue  INTO #MatterOwner FROM 	dbo.udt_TallySplit('|', @MatterOwner)
SELECT ListValue  INTO #ClientCode FROM 	dbo.udt_TallySplit('|', @ClientCode)


SELECT dim_matter_header_current.master_client_code AS [Client Code]
	, client_name AS [Client Name]
	, dim_matter_header_current.master_client_code+'-'+master_matter_number AS [3e Ref]
	, matter_owner_full_name AS [Matter Owner]
	, matter_description AS [Matter Description]
	, work_type_name AS [Work Type]
	, wip AS [WIP]
	, fact_finance_summary.disbursement_balance AS [Disbursements Balance]
	, dim_matter_header_current.date_opened_case_management AS [Date Opened]
	, last_time_transaction_date AS [Last Time Worked]
	, [DueDate] AS [Max Task Due Date]
	, hierarchylevel2hist AS [Division]
	, hierarchylevel3hist AS [Department]
	, hierarchylevel4hist AS [Team]

FROM red_dw.dbo.fact_dimension_main
LEFT JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key

INNER JOIN (SELECT master_fact_key, MAX(duedate.calendar_date) [DueDate]
FROM red_dw.dbo.fact_tasks
LEFT OUTER JOIN red_dw.dbo.dim_date duedate
ON duedate.dim_date_key=fact_tasks.dim_task_due_date_key
GROUP BY master_fact_key
HAVING MAX(duedate.calendar_date)<=GETDATE()) AS tasks 
ON tasks.master_fact_key = fact_dimension_main.master_fact_key

INNER JOIN #Division AS Division ON Division.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel2hist COLLATE DATABASE_DEFAULT
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #MatterOwner AS MatterOwner ON MatterOwner.ListValue COLLATE DATABASE_DEFAULT = matter_owner_full_name COLLATE DATABASE_DEFAULT
INNER JOIN #ClientCode AS ClientCode ON ClientCode.ListValue COLLATE DATABASE_DEFAULT = dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT

WHERE dim_matter_header_current.date_closed_case_management IS NULL 
AND reporting_exclusions=0
AND ms_only=1
AND hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
AND matter_owner_full_name <>'Prv Property View'

END
GO
