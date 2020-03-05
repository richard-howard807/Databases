SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2018/08/23
-- Description:	New report for Motor based on key date tasks, webby 304716
-- =============================================

CREATE PROCEDURE [dbo].[MotorUpcomingHearings]
(
	 @StartDate AS DATETIME
	 ,@EndDate AS DATETIME
	 ,@Team AS VARCHAR(100)
	 ,@MatterOwner AS VARCHAR(100)
	 --,@ClientGroupName AS VARCHAR(100)
	 ,@ClientCode AS VARCHAR(8)
)
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


; WITH KeyDateTasks AS 
(
SELECT dim_tasks.client_code
	, dim_tasks.matter_number
	, RTRIM(CAST(CONVERT(DATE, calendar_date,103) AS VARCHAR) +' '+ task_desccription) AS [Key Dates]
	
FROM red_dw.dbo.fact_tasks
LEFT OUTER JOIN red_dw.dbo.dim_tasks ON dim_tasks.dim_tasks_key = fact_tasks.dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_task_due_date ON dim_task_due_date.dim_task_due_date_key = fact_tasks.dim_task_due_date_key
WHERE red_dw.dbo.dim_tasks.task_code IN ('POLA0117','WPSA0168','TRAA0345','REGA0123','REGA0211','PIDA0140','NHSA0183','PSRA0120','PSRA0141','REGA0128','PIDA0120','LLSA0107','EMPA0134','FTRA9908','FTRA0132','FTRA0122','TRAA0348')
--AND task_amended_deleted_flag IS NULL
AND calendar_date>=@StartDate
AND calendar_date<=@EndDate
--AND dim_tasks.client_code='00030645' AND dim_tasks.matter_number='00010653' 

)

, KeyDateTasksXML AS 
(SELECT DISTINCT client_code
	, matter_number
	, STUFF((SELECT ', '+ [Key Dates]
from KeyDateTasks T1
where T1.client_code=T2.client_code AND T1.matter_number=T2.matter_number
FOR XML PATH('')),1,1,'') AS [KeyDates]
	 FROM KeyDateTasks T2)




SELECT dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, dim_client.client_group_code AS [Client Group Code]
	, dim_client.client_group_name AS [Client Group Name]
	, dim_matter_header_current.master_client_code+'/'+dim_matter_header_current.master_matter_number AS [3E Reference]
	, name AS [Case Handler]
	, hierarchylevel4hist AS [Team]
	, output_wip_fee_arrangement AS [Fee Regime]
	, fixed_fee_amount AS [Fixed Fee (inc Costs)]
	, matter_description AS [Matter Description]
	, court_name AS [Court Name]
	, dim_detail_core_details.track AS [Track]
	, KeyDateTasksXML.[KeyDates] AS [Key Dates]
	
	, counsel_1st_nature_of_work_pick_list AS [1st Nature of Work]
	, counsel_1st_date_paperwork_due AS [1st Due Date for Paperwork Instruction]
	, counsel_1st_internal_external_y_n_pick_list AS [1st Internal/External]
	, counsel_1st_internal_counsel_name AS [1st Internal Counsel]
	, counsel_1st_internal_counsel_fee AS [1st Internal Counsel's Fee]
	, counsel_1st_hearing_outcome AS [1st Hearing Outcome]
	, counsel_1st_hearing_date AS [1st Hearing Date]

	, counsel_2nd_nature_of_work_pick_list AS [2nd Nature of Work]
	, counsel_2nd_date_paperwork_due AS [2nd Due Date for Paperwork Instruction]
	, counsel_2nd_internal_external_y_n_pick_list AS [2nd Internal/External]
	, counsel_2nd_internal_counsel_name AS [2nd Internal Counsel]
	, counsel_2nd_internal_counsel_fee AS [2nd Internal Counsel's Fee]
	, counsel_2nd_hearing_outcome AS [2nd Hearing Outcome]
	, counsel_2nd_hearing_date AS [2nd Hearing Date]

	, counsel_3rd_nature_of_work_pick_list AS [3rd Nature of Work]
	, counsel_3rd_date_paperwork_due AS [3rd Due Date for Paperwork Instruction]
	, counsel_3rd_internal_external_y_n_pick_list AS [3rd Internal/External]
	, counsel_3rd_internal_counsel_name AS [3rd Internal Counsel]
	, counsel_3rd_internal_counsel_fee AS [3rd Internal Counsel's Fee]
	, counsel_3rd_hearing_outcome AS [3rd Hearing Outcome]
	, counsel_3rd_hearing_date AS [3rd Hearing Date]

	, counsel_4th_nature_of_work_pick_list AS [4th Nature of Work]
	, counsel_4th_date_paperwork_due AS [4th Due Date for Paperwork Instruction]
	, counsel_4th_internal_external_y_n_pick_list AS [4th Internal/External]
	, counsel_4th_internal_counsel_name AS [4th Internal Counsel]
	, counsel_4th_internal_counsel_fee AS [4th Internal Counsel's Fee]
	, counsel_4th_hearing_outcome AS [4th Hearing Outcome]
	, counsel_4th_hearing_date AS [4th Hearing Date]

	, counsel_5th_nature_of_work_pick_list AS [5th Nature of Work]
	, counsel_5th_date_paperwork_due AS [5th Due Date for Paperwork Instruction]
	, counsel_5th_internal_external_y_n_pick_list AS [5th Internal/External]
	, counsel_5th_internal_counsel_name AS [5th Internal Counsel]
	, counsel_5th_internal_counsel_fee AS [5th Internal Counsel's Fee]
	, counsel_5th_hearing_outcome AS [5th Hearing Outcome]
	, counsel_5th_hearing_date AS [5th Hearing Date]

	
FROM red_dw.dbo.fact_dimension_main
INNER JOIN KeyDateTasksXML ON KeyDateTasksXML.client_code=fact_dimension_main.client_code
AND KeyDateTasksXML.matter_number=fact_dimension_main.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.client_code = fact_dimension_main.client_code
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_court ON fact_detail_court.master_fact_key = fact_dimension_main.master_fact_key


WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel3hist='Motor'
AND hierarchylevel4hist IN (@Team)
AND name IN (@MatterOwner)
--AND dim_client.client_group_name IN (@ClientGroupName)
AND dim_client.client_code IN (@ClientCode)


END
GO
