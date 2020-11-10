SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GentooMI]

AS 
BEGIN

SELECT dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,client_name AS [Client Name]
,matter_description AS [Description]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,branch_name AS [Office]
,work_type_name AS [Work Type]
,matter_owner_full_name AS [Fee Earner]


FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE dim_matter_header_current.client_code IN ('W23626','W19299')
AND reporting_exclusions=0


END
GO
