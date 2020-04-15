SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [zurich].[ZurichLiveMatterForEmail]
(
@Email AS NVARCHAR(500)
)
AS 
BEGIN

IF @Email='All'

BEGIN

SELECT client_code AS [Client]
,matter_number AS [Matter]
,matter_description AS MatterDescription
,name AS [Matter Owner]
,date_opened_case_management AS [Date Opened]
,work_type_name AS [Worktype]
,workemail AS [EmailAddress]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE master_client_code='Z1001'
AND date_closed_case_management IS NULL
AND matter_number <> 'ML'
AND reporting_exclusions = 0

END

ELSE 

BEGIN
SELECT client_code AS [Client]
,matter_number AS [Matter]
,matter_description AS MatterDescription
,name AS [Matter Owner]
,date_opened_case_management AS [Date Opened]
,work_type_name AS [Worktype]
,workemail AS [EmailAddress]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE master_client_code='Z1001'
AND date_closed_case_management IS NULL
AND workemail= @Email
AND matter_number <> 'ML'
AND reporting_exclusions = 0

END

END
GO
