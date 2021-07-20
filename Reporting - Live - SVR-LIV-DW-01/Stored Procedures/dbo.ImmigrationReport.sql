SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-07-20
-- Description:	#107274, new report to track immigration work
-- =============================================
-- 
-- =============================================

CREATE PROCEDURE [dbo].[ImmigrationReport]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client and Matter Number]
		, dim_matter_header_current.matter_description AS [Matter Description]
		, dim_matter_header_current.matter_owner_full_name AS [Matter Owner]
		, matter_owner.hierarchylevel4hist AS [Team]
		, matter_owner.hierarchylevel3hist AS [Department]
		, dim_matter_header_current.date_opened_case_management AS [Date Opened]
		, dim_matter_header_current.date_closed_case_management AS [Date Closed]
		, dim_matter_worktype.work_type_name AS [Matter Type]
		, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement]
		, time_keeper.name AS [Time Keeper]
		, SUM(fact_all_time_activity.minutes_recorded)/60 AS [Hours Recorded]
		, dim_date.calendar_date AS [Transaction Date]
		, dim_all_time_narrative.narrative AS [Narrative]
FROM red_dw.dbo.fact_all_time_activity

LEFT OUTER JOIN red_dw.dbo.dim_all_time_narrative
ON dim_all_time_narrative.dim_all_time_narrative_key = fact_all_time_activity.dim_all_time_narrative_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS time_keeper
ON time_keeper.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date.dim_date_key=fact_all_time_activity.dim_transaction_date_key
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.master_fact_key = fact_all_time_activity.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS matter_owner
ON matter_owner.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome 
ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND (dim_all_time_narrative.narrative LIKE 'IMM%'
OR dim_matter_worktype.work_type_name LIKE '%Immigration%')
AND fact_all_time_activity.minutes_recorded>0
--AND fact_all_time_activity.client_code='00179281'
--AND fact_all_time_activity.matter_number='00000009'

GROUP BY dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number,
         dim_matter_header_current.matter_description,
         dim_matter_header_current.matter_owner_full_name,
         matter_owner.hierarchylevel4hist,
         matter_owner.hierarchylevel3hist,
         dim_matter_header_current.date_opened_case_management,
         dim_matter_header_current.date_closed_case_management,
         dim_matter_worktype.work_type_name,
         dim_detail_finance.output_wip_fee_arrangement,
         time_keeper.name,
         dim_date.calendar_date,
         dim_all_time_narrative.narrative
END
GO
