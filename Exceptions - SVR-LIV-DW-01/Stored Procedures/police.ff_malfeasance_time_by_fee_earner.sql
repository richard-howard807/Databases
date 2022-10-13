SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 20171013
-- Description:	Fixed Fee Malfeasance Cases Chargeable Time by Fee Earner
-- Ticket:  264584
-- 20171017 ES added outstanding WIP, webby 267577
-- =============================================
CREATE PROCEDURE [police].[ff_malfeasance_time_by_fee_earner]
AS
BEGIN
	
	SET NOCOUNT ON;

	
	SELECT 

	matter_header.client_code [client_number]
	,matter_header.matter_number [matter_number]
	,matter_description
	,matter_owner_full_name [matter_handler]
	,hierarchylevel4 [team]
	,matter_header.date_opened_case_management
	,matter_header.date_closed_case_management
	,worktype.work_type_name
	,matter_header.fee_arrangement
	,matter_header.fixed_fee_amount
	,matter_header.present_position
	,finance_summary.chargeable_minutes_recorded/60 [chargeable_hours]
	,post_date.calendar_date [Date of last time posting]
	,minutes_recorded.fee_earner
	,minutes_recorded.minutes_recorded
	,finance_summary.chargeable_minutes_recorded
	,(matter_header.fixed_fee_amount * minutes_recorded.minutes_recorded) / finance_summary.chargeable_minutes_recorded [share]
	, matter_summary.wip_balance

	FROM red_dw.dbo.dim_matter_header_current matter_header
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_current fed_hierarchy on matter_header.fee_earner_code = fed_hierarchy.fed_code and fed_hierarchy.dss_current_flag = 'Y'
	INNER JOIN red_dw.dbo.dim_client client on matter_header.client_code = client.client_code
	INNER JOIN red_dw.dbo.dim_matter_worktype worktype on matter_header.dim_matter_worktype_key = worktype.dim_matter_worktype_key
	INNER JOIN red_dw.dbo.fact_finance_summary finance_summary on finance_summary.client_code = matter_header.client_code and finance_summary.matter_number = matter_header.matter_number
	INNER JOIN red_dw.dbo.fact_matter_summary_current matter_summary ON matter_summary.client_code = matter_header.client_code AND matter_summary.matter_number = matter_header.matter_number
	INNER JOIN red_dw.dbo.dim_last_posting_date post_date ON post_date.dim_last_posting_date_key = matter_summary.dim_last_transaction_date_key
	INNER JOIN (SELECT client_code
					,matter_number
					,fed_hierarchy.name [fee_earner]
					,SUM(minutes_recorded) [minutes_recorded]
				FROM red_dw.[dbo].[fact_all_time_activity]
				INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fed_hierarchy ON fact_all_time_activity.dim_fed_hierarchy_history_key = fed_hierarchy.dim_fed_hierarchy_history_key --and fed_hierarchy.dss_current_flag = 'Y'
				WHERE client_code = 'W15512' 
				AND chargeable_nonc_nonb = 'C'
				GROUP BY client_code
					,matter_number
					,fed_hierarchy.name) minutes_recorded
					ON minutes_recorded.client_code = matter_header.client_code AND minutes_recorded.matter_number = matter_header.matter_number

	WHERE client.client_code = 'W15512'
	AND worktype.work_type_code IN ('1301','1302','1303','1304','1305','1307','1560','1128')
	AND matter_header.date_opened_case_management >= '20160601'
	AND matter_header.reporting_exclusions=0 

	ORDER BY matter_header.client_code, matter_header.matter_number


    
END
GO
