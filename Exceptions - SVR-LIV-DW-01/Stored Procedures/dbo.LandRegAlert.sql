SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LandRegAlert]
(
@EmailAddress NVARCHAR(200)
)
AS

BEGIN

IF @EmailAddress='All'

BEGIN

SELECT fact_disbursements_detail.client_code AS Client
,fact_disbursements_detail.matter_number AS Matter
,master_client_code + '-' + master_matter_number AS [3E Reference]
,matter_description
,matter_owner_full_name AS [Matter Manager]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,workdate AS [Work Date]
,total_unbilled_disbursements AS [Disbursement Type]
,costtype AS [Cost Type]
,costype_description AS [Cost Description]
,completion_date AS [Completion Date]
,workemail AS [EmailAddress]
,forename AS Forename
FROM red_dw.dbo.fact_disbursements_detail
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_disbursements_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_disbursement_date
 ON dim_disbursement_date.dim_disbursement_date_key = fact_disbursements_detail.dim_disbursement_date_key
LEFT OUTER JOIN red_dw.dbo.dim_employee
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.client_code = dim_matter_header_current.client_code
 AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
WHERE dim_bill_key=0
AND LOWER(costype_description) LIKE '%land registry%'
--AND workdate=CONVERT(DATE,GETDATE()-1)--'2021-01-25'
--AND hierarchylevel3hist='Real Estate'
END

ELSE 

BEGIN 
SELECT fact_disbursements_detail.client_code AS Client
,fact_disbursements_detail.matter_number AS Matter
,master_client_code + '-' + master_matter_number AS [3E Reference]
,matter_description
,matter_owner_full_name AS [Matter Manager]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,workdate AS [Work Date]
,total_unbilled_disbursements AS [Disbursement Type]
,costtype AS [Cost Type]
,costype_description AS [Cost Description]
,completion_date AS [Completion Date]
,workemail AS [EmailAddress]
,forename AS Forename
FROM red_dw.dbo.fact_disbursements_detail
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_disbursements_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_disbursement_date
 ON dim_disbursement_date.dim_disbursement_date_key = fact_disbursements_detail.dim_disbursement_date_key
LEFT OUTER JOIN red_dw.dbo.dim_employee
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.client_code = dim_matter_header_current.client_code
 AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
WHERE dim_bill_key=0
AND LOWER(costype_description) LIKE '%land registry%'
AND workdate=CONVERT(DATE,GETDATE()-1)--'2021-01-25'
AND hierarchylevel3hist='Real Estate'
AND workemail=@EmailAddress

END 

END
GO
