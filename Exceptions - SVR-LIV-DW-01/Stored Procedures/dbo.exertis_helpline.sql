SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:           <Reece Doughty>
-- Create date: <1/12/2022>
-- Description:      <#179609 Exertis helpline for tableau>
-- =============================================
CREATE PROCEDURE [dbo].[exertis_helpline]

AS
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT

dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [Client/Matter Number],
dim_fed_hierarchy_history.display_name AS [Solicitors Initials]
,ISNULL(dim_detail_advice.issue, dim_detail_advice.emph_primary_issue) AS Issue
,dim_detail_advice.name_of_caller AS [Name of Caller]
,dim_matter_header_current.matter_description AS [Subject Matter]
,CASE 
WHEN dim_detail_advice.status = 'Closed'
THEN 'Yes'
ELSE 'No'
END AS [Query Concluded (Yes/No)]
,SUM(fata.minutes_recorded / 60) AS [Time Spent]
,dim_detail_advice.knowledge_gap AS [Knowledge Gap]
,MAX(dd.calendar_date) AS [Date of Call]

FROM red_dw.dbo.fact_all_time_activity AS fata
INNER JOIN red_dw.dbo.dim_date AS dd ON fata.dim_transaction_date_key = dd.dim_date_key
INNER JOIN red_dw.dbo.fact_dimension_main AS fdm ON fdm.master_fact_key = fata.master_fact_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = fdm.dim_detail_advice_key
INNER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fdm.dim_detail_outcome_key
INNER JOIN red_dw.dbo.dim_all_time_activity ON dim_all_time_activity.dim_all_time_activity_key = fata.dim_all_time_activity_key
INNER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

WHERE dim_matter_header_current.reporting_exclusions = 0
AND dim_matter_header_current.master_client_code = 'W25730'
AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
--AND fata.dim_transaction_date_key BETWEEN 20221101 AND 20221130
AND fata.minutes_recorded > 0
AND dim_matter_worktype.work_type_code = '1114'

GROUP BY dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number,
         ISNULL(dim_detail_advice.issue, dim_detail_advice.emph_primary_issue),
         CASE
         WHEN dim_detail_advice.status = 'Closed' THEN
         'Yes'
         ELSE
         'No'
         END,
         dim_fed_hierarchy_history.display_name,
         dim_detail_advice.name_of_caller,
         dim_matter_header_current.matter_description,
         dim_detail_advice.knowledge_gap
              ,dim_all_time_activity.transaction_type


END
GO
