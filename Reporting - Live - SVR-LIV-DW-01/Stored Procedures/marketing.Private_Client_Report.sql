SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 19-05-2020
-- Description:	Private Client see ticket 57295
-- =============================================
CREATE PROCEDURE [marketing].[Private_Client_Report]

AS
BEGIN
	SELECT 
  RTRIM(red_dw.dbo.dim_matter_header_current.client_code)+'/'+red_dw.dbo.dim_matter_header_current.matter_number AS [Weightmans Reference]
  ,red_dw.dbo.dim_matter_header_current.matter_description
  ,RTRIM(red_dw.dbo.dim_involvement_full.forename)+ ' '+red_dw.dbo.dim_involvement_full.name AS [Client Name]
  ,red_dw.dbo.dim_client.client_type
  ,red_dw.dbo.dim_matter_header_current.date_opened_case_management
  ,red_dw.dbo.dim_matter_header_current.matter_owner_full_name
  ,red_dw.dbo.dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
  ,red_dw.dbo.dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department]
  ,red_dw.dbo.dim_matter_worktype.work_type_name
  ,red_dw.dbo.dim_matter_header_current.opt_out_of_auto_client_email AS [Do you want to opt out of automated private client email?]
  ,red_dw.dbo.dim_matter_header_current.reason_for_email_opt_out AS [Reason for opt out]
  ,red_dw.dbo.dim_matter_header_current.opt_out_reason_desc [Reason for opt out Y/N]
  ,red_dw.dbo.dim_involvement_full.default_email AS Email

  
 
  --,red_dw.dbo.dim_matter_header_current.DateofEmail -- on in yet


	

FROM red_dw.dbo.dim_involvement_full
INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code = dim_involvement_full.client_code AND dim_matter_header_current.matter_number = dim_involvement_full.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
AND GETDATE() BETWEEN dss_start_date AND dss_end_date
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
   

WHERE dim_involvement_full.capacity_code  = 'CLIENT'
AND is_active = 1
--AND red_dw.dbo.dim_involvement_full.client_code = '154981H'
AND red_dw.dbo.dim_client.client_type = 'Individual'
AND red_dw.dbo.dim_matter_header_current.opt_out_of_auto_client_email IS NOT NULL

	SET NOCOUNT ON;

END


GO
