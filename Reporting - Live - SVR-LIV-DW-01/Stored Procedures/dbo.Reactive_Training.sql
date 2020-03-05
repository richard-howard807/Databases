SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego	
-- Create date: 2018-04-10
-- Description:	requested by mandy to show the profit made by Reactive Training
-- =============================================
CREATE PROCEDURE [dbo].[Reactive_Training]

AS
BEGIN
SET NOCOUNT ON;
SELECT 
fdm.client_code,
fdm.matter_number,
dim_client.client_name,
training_session_description,
training_sessions_agreed,
fact_finance_summary.[fixed_fee_amount],
[date_of_training],
red_dw.dbo.fact_finance_summary.defence_costs_billed,
ms_fileid
FROM red_dw.dbo.fact_dimension_main fdm
LEFT JOIN red_dw.dbo.dim_parent_detail  ON dim_parent_detail.client_code = fdm.client_code AND dim_parent_detail.matter_number = fdm.matter_number
LEFT JOIN red_dw.dbo.dim_child_detail ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key 
LEFT JOIN red_dw.dbo.fact_child_detail ON fact_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
LEFT JOIN red_Dw.dbo.dim_client ON fdm.dim_client_key = dim_client.dim_client_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current  ON dim_matter_header_current.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fdm.master_fact_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE 
--fdm.client_code IN ('HRR00171',
--'00345800',
--'HRR00163',
--'HRR00059',
--'00030645',
--'HRR00172')
--AND 
reporting_exclusions = 0 
AND work_type_code = '1583' 

ORDER BY fdm.client_code,fdm.matter_number 
END



GO
