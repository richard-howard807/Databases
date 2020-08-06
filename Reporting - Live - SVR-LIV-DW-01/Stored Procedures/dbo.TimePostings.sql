SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-07-21
-- Description:	#65157 Stored procedure at time posting level for capacity planning dashboard
-- =============================================
CREATE PROCEDURE [dbo].[TimePostings]

AS
BEGIN
	
	SET NOCOUNT ON;

SELECT  master_client_code+'-'+master_matter_number AS [Client/Matter Number]
	,name AS [Fee Earner]
	,jobtitle AS [Grade]
	,hierarchylevel4hist AS [Team]
	,hierarchylevel3hist AS [Department]
	,client_name AS [Client Name]
	,time_activity_description AS [Time Activity]
	,transaction_type AS [Time Type]
	,calendar_date AS [Date of Time Posting]
	,SUM(minutes_recorded/60) AS [Hours Recorded]
	,fact_all_time_activity.hourly_charge_rate AS [Charge Rate]
	,dim_instruction_type.instruction_type [RMG Instuction Type]

FROM  red_dw.dbo.fact_all_time_activity WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK)
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date WITH (NOLOCK)
ON dim_date_key=dim_transaction_date_key
LEFT OUTER JOIN red_dw.dbo.dim_time_activity_type WITH (NOLOCK)
ON dim_time_activity_type.time_activity_code = fact_all_time_activity.time_activity_code
LEFT OUTER JOIN red_dw.dbo.dim_all_time_activity
ON dim_all_time_activity.dim_all_time_activity_key = fact_all_time_activity.dim_all_time_activity_key
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key


WHERE dim_matter_header_current.reporting_exclusions=0
AND calendar_date>='2019-05-01'
--AND master_client_code='43006'
--AND master_matter_number='104'

GROUP BY master_client_code + '-' + master_matter_number,
         name,
         jobtitle,
         hierarchylevel4hist,
         hierarchylevel3hist,
         client_name,
         time_activity_description,
         transaction_type,
         calendar_date,
         fact_all_time_activity.hourly_charge_rate, dim_instruction_type.instruction_type
END
GO
