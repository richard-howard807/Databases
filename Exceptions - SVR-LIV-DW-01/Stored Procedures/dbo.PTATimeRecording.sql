SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:           Emily Smith
-- Create date: 2018-01-19
-- Description:      Standard PTA Time Recording report, requested by Sinead Whitfield, webby 283023
-- =============================================

CREATE PROCEDURE [dbo].[PTATimeRecording]

       @StartDate date 
       , @EndDate date
AS
BEGIN

       SET NOCOUNT ON;


	   SELECT 
              fact_all_time_activity.client_code AS [Client Code],
              fact_all_time_activity.matter_number AS [Matter Number],
              fed_code_fee_earner AS [Reference],
              matter_description AS [Matter Description],
              dim_matter_header_current.date_opened_case_management AS [Date Opened],
              dim_matter_header_current.date_closed_case_management AS [Closed Date],
              dim_fed_hierarchy_history.name AS [Matter Manager],
              phase.description AS [Phase Description],
              phase.phaselist AS [Phase List],
              phase.code AS [Phase Code],
              ds_sh_3e_task.description AS [Task Description],
              ds_sh_3e_task.tasklist AS [Task List],
              ds_sh_3e_task.code AS [Task Code],
              activity.description AS [Activity Description],
              activity.activitylist AS [Activity List],
              activity.code AS [Activity Code],
              workhrs AS [Work Hours],
              CONVERT(DATE, transaction_calendar_date, 103) AS [Work Date],
              CONVERT(DATE, dim_posting_date.posting_date, 103) AS [Posting Date],
              CONVERT(DATE, dim_gl_date.gl_calendar_date, 103) AS [GL Date],
              CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open'ELSE 'Closed' END AS [Satus]

FROM red_dw..fact_all_time_activity
INNER JOIN red_dw..dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
inner JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key and dim_fed_hierarchy_history.hierarchylevel4hist = 'Litigation London' 
INNER JOIN red_dw..ds_sh_3e_timecard ON fact_all_time_activity.transaction_sequence_number = ds_sh_3e_timecard.timeindex
LEFT JOIN red_Dw.dbo.ds_sh_3e_task ds_sh_3e_task ON ds_sh_3e_task.taskid = ds_sh_3e_timecard.task
inner JOIN red_Dw.dbo.ds_sh_3e_phase phase ON phase.phaseid = ds_sh_3e_timecard.phase
LEFT JOIN red_Dw.dbo.ds_sh_3e_activity activity ON activity.activityid = ds_sh_3e_timecard.activity
INNER JOIN red_dw..dim_transaction_date ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
LEFT OUTER JOIN red_dw..dim_posting_date ON fact_all_time_activity.dim_posting_date_key=dim_posting_date.dim_posting_date_key
LEFT OUTER JOIN red_dw..dim_gl_date ON fact_all_time_activity.dim_gl_date_key=dim_gl_date.dim_gl_date_key
WHERE dim_matter_header_current.client_code <> 'A2002'
AND phase.phaselist='PTA-STD'
AND transaction_calendar_date BETWEEN @StartDate AND @EndDate
AND ds_sh_3e_timecard.isactive=1

END

--SELECT TOP 1 * FROM red_dw..fact_all_time_activity
GO
