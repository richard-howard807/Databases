SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[coopInternalAudits]

AS

BEGIN
SELECT dim_matter_header_current.client_code AS client
,dim_matter_header_current.matter_number AS[matter number]
,master_client_code + '-'+master_matter_number AS [3E Reference]
,dim_matter_header_current.matter_description AS[Matter description]
,dim_matter_header_current.date_opened_case_management AS [Date file opened]
,last_bill_date AS [Date of last bill]
,[Present position]= dim_detail_core_details.[present_position]
,[Date damages concluded] =  dim_detail_outcome.[date_claim_concluded]
,[Date costs concluded] =  dim_detail_outcome.[date_costs_settled]
,[Date of Audit] = dim_detail_audit.[date_of_audit_coop]
,[Date of Client Partner Audit] = dim_detail_audit.[date_of_client_partner_audit]
,hierarchylevel4hist AS [Team]
,NULL AS [Comments]
,NULL AS [Date of next audit]	


FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_audit
 ON dim_detail_audit.client_code = dim_matter_header_current.client_code
 AND dim_detail_audit.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
  ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number

 
WHERE master_client_code='C1001'
AND dim_matter_header_current.date_closed_practice_management IS NULL
AND hierarchylevel4hist 
IN ('Motor Manchester','Large Loss Manchester and Leeds','Large Loss Manchester 2','Motor Mainstream')
END
GO
