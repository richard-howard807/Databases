SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<orlagh kelly>
-- Create date: <03-08-2018,>
-- Description:	<non chargeable hours >
-- =============================================
create PROCEDURE[dbo].[ChargeHoursMonthCHAR] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


with CTE as 
(
SELECT Distinct master_fact_key, activity_description,activity_code, minutes_recorded, fact_all_time_activity.dim_bill_key, dim_client_key, fact_all_time_activity.dim_fed_hierarchy_history_key [Fee Earner HIERKEY],
dim_transaction_date_key, fact_all_time_activity.chargeable_nonc_nonb [NON/CHAR]
FROM red_dw.dbo.fact_all_time_activity
LEFT JOIN red_dw.dbo.dim_all_time_activity ON dim_all_time_activity.dim_all_time_activity_key = fact_all_time_activity.dim_all_time_activity_key
LEFT JOIN (
SELECT DISTINCT activity_code,activity_description FROM red_dw.dbo.dim_time_type)
time_type ON dim_all_time_activity.time_activity_code = activity_code 

where dim_transaction_date_key >= 20180101)


Select CTE.activity_code
, CTE.activity_description
, CTE.minutes_recorded 
, dim_fed_hierarchy_history.hierarchylevel4hist [Team]
, dim_fed_hierarchy_history.hierarchylevel3hist [Department]
, dim_fed_hierarchy_history.hierarchylevel2hist [Division]
,dim_matter_header_current.fee_earner_code
,dim_fed_hierarchy_history.name [matter owner ]
,fact_dimension_main.client_code
, fact_dimension_main.matter_number
,PETA.name [Time FeeEARNER]
,[NON/CHAR]
, dim_transaction_date_key

From CTE
left join red_dw.dbo.fact_dimension_main on fact_dimension_main.master_fact_key = CTE.master_fact_key
left Join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key 
left join red_dw.dbo.dim_matter_header_current on dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
left join red_dw.dbo.dim_fed_hierarchy_history as PETA on PETA.dim_fed_hierarchy_history_key = [Fee Earner HIERKEY]
where [NON/CHAR] = 'C'

order by client_code, matter_number


END
GO
