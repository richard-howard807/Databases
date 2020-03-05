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
EMP171.case_text [Training Session Description],
EMP167.case_value [Training Sessions Agreed],
fact_finance_summary.[fixed_fee_amount],
EMP169.case_date [Date of Training],
red_dw.dbo.fact_finance_summary.defence_costs_billed
FROM red_dw.dbo.fact_dimension_main fdm
LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr ON cashdr.client = fdm.client_code AND cashdr.matter = fdm.matter_number AND cashdr.current_flag = 'Y'

LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet EMP171 ON cashdr.case_id = EMP171.case_id AND EMP171.case_detail_code = 'EMP171' AND EMP171.current_flag = 'Y'
LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet EMP167 ON cashdr.case_id = EMP167.case_id AND EMP167.case_detail_code = 'EMP167' AND EMP167.current_flag = 'Y' AND EMP167.cd_parent = EMP171.seq_no
LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet EMP169 ON cashdr.case_id = EMP169.case_id AND EMP169.case_detail_code = 'EMP169' AND EMP169.current_flag = 'Y' AND EMP169.cd_parent = EMP171.seq_no

LEFT JOIN red_Dw.dbo.dim_client ON fdm.dim_client_key = dim_client.dim_client_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current  ON dim_matter_header_current.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fdm.master_fact_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE fdm.client_code IN ('HRR00171',
'00345800',
'HRR00163',
'HRR00059',
'00030645',
'HRR00172')
AND reporting_exclusions = 0 AND work_type_code = '1583'
END



GO
