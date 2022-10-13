SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-07-21
-- Description:	#65157 Stored procedure at time posting level for capacity planning dashboard
-- =============================================
-- ES 2020-09-14   #71322 amended logic to be the same as the daily hours by department report
-- =============================================
CREATE PROCEDURE [dbo].[TimePostings]

AS
BEGIN
	
	SET NOCOUNT ON;

SELECT DISTINCT master_client_code+'-'+master_matter_number AS [Client/Matter Number]
	,name AS [Fee Earner]
	,jobtitle AS [Grade]
	,hierarchylevel4hist AS [Team]
	,hierarchylevel3hist AS [Department]
	,client_name AS [Client Name]
	,dim_time_activity_type.time_activity_description AS [Time Activity]
	,transaction_type AS [Time Type]
	,calendar_date AS [Date of Time Posting]
	,ISNULL(SUM(fact_billable_time_activity.minutes_recorded), 0) / 60 AS [Hours Recorded]
	,fact_billable_time_activity.hourly_charge_rate AS [Charge Rate]
	,dim_instruction_type.instruction_type [Instruction Type]

FROM red_dw.dbo.fact_billable_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = red_dw.dbo.fact_billable_time_activity.dim_fed_hierarchy_history_key
AND dim_fed_hierarchy_history.hierarchylevel2hist IN ( 'Legal Ops - Claims', 'Legal Ops - LTA' )
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_billable_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date WITH (NOLOCK)
ON dim_date_key=fact_billable_time_activity.dim_orig_posting_date_key
LEFT OUTER JOIN red_dw.dbo.dim_time_activity_type WITH (NOLOCK)
ON dim_time_activity_type.time_activity_code = fact_billable_time_activity.time_activity_code
AND dim_time_activity_type.dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_billable_time_activity
ON dim_billable_time_activity.dim_chargeable_time_activity_key=fact_billable_time_activity.dim_billable_time_activity_key
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK)
ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key


WHERE 
--dim_matter_header_current.reporting_exclusions=0
--AND 
calendar_date>='2019-05-01'
--AND master_client_code='43006'
--AND master_matter_number='104'
--AND calendar_date='2020-09-08'
--AND hierarchylevel2hist IN ( 'Legal Ops - Claims', 'Legal Ops - LTA' )
--AND dim_fed_hierarchy_history.hierarchylevel3hist='Motor'

GROUP BY master_client_code + '-' + master_matter_number,
         dim_fed_hierarchy_history.name,
         dim_fed_hierarchy_history.jobtitle,
         dim_fed_hierarchy_history.hierarchylevel4hist,
         dim_fed_hierarchy_history.hierarchylevel3hist,
         dim_matter_header_current.client_name,
         dim_time_activity_type.time_activity_description,
         dim_billable_time_activity.transaction_type,
         dim_date.calendar_date,
         fact_billable_time_activity.hourly_charge_rate,
         dim_instruction_type.instruction_type
END
GO
