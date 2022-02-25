SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2019-06-10
-- Description:	STW Retainer Billing Report
-- =============================================
-- LD 20190703 Added in transaction date
--  ok 28/07/2020 added matter 00000626
-- ES 25/02/2022 #136034, added grade and charge rate

CREATE PROCEDURE [dbo].[STW_Retainer_Billing_Report]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT 
fact_dimension_main.client_code,
dim_matter_header_current.matter_number,
dim_matter_header_current.master_client_code,
master_matter_number,
matter_description,
matter_owner_full_name,
insurerclient_reference,
dim_all_time_narrative.*,
wipamt wipamt,
name,
-- LD Added the below
tr_date.calendar_date [transaction_date]
, dim_employee.levelidud AS [Fee Earner Grade]
, fact_all_time_activity.hourly_charge_rate AS [Charge Rate]

 FROM red_Dw.dbo.fact_dimension_main
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.fact_all_time_activity  ON fact_all_time_activity.master_fact_key = fact_dimension_main.master_fact_key AND dim_bill_key = 0 
LEFT JOIN red_Dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_Dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_Dw.dbo.dim_all_time_narrative ON dim_all_time_narrative.dim_all_time_narrative_key = fact_all_time_activity.dim_all_time_narrative_key  
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_date tr_date ON red_dw.dbo.fact_all_time_activity.dim_transaction_date_key = tr_date.dim_date_key
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.employeeid = dim_fed_hierarchy_history.employeeid

WHERE 
(dim_detail_claim.[stw_work_type] = 'Retainer' AND 
fact_dimension_main.client_code IN ('00257248','00513126')
AND wipamt > 0 AND isactive = 1 ) OR 
( wipamt > 0 AND isactive = 1 AND fact_dimension_main.client_code = '00257248' AND 
 fact_dimension_main.matter_number = '00000626') 


END
GO
