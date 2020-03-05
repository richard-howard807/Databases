SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 21/08/2017
-- Description:	This is a list of Weightmans employee Leavers that have live/open matters in their name . This has been requested by Helen Fox see ticket 253877  
-- =============================================
CREATE PROCEDURE [dbo].[WeightmansEmployeeLeavers]

AS
BEGIN
	SELECT 
 hc.client_code
,hc.matter_number
,case when hh.leaver = 1 then 'Yes' end as Leavers
,hc.matter_owner_full_name
,e.leaverlastworkdate as [Leaver last Work Date]
,hc.matter_partner_full_name
,hc.matter_description
,hc.date_opened_case_management
,hc.date_closed_case_management
,cd.present_position
,do.date_claim_concluded
,do.date_costs_settled
,fs.wip
,fs.disbursement_balance
,hh.hierarchylevel2hist as Divison
,hh.hierarchylevel3hist as Department
,hh.hierarchylevel4hist as Team
,hh.fed_code
,hc.ms_only
FROM red_dw.dbo.fact_dimension_main as dm
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history as hh on hh.dim_fed_hierarchy_history_key=dm.dim_fed_hierarchy_history_key 
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current hc ON hc.dim_matter_header_curr_key=dm.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details AS cd ON cd.dim_detail_core_detail_key = dm.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome do ON do.dim_detail_outcome_key = dm.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary fs ON fs.master_fact_key = dm.master_fact_key
left join red_dw.dbo.dim_employee e on hh.employeeid = e.employeeid
where dss_current_flag = 'Y' and activeud = 1 and leaver = 1
AND hc.client_code NOT IN ('00030645','95000C','00453737')
AND hc.date_closed_case_management is null


END
GO
