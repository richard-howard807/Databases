SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[IAProductActivities]
AS
BEGIN 

SELECT AllData.dim_client_key,
       AllData.Activity,
       AllData.[Activity Type],
       AllData.[Date of Activity],
       AllData.CreatedBy,
       AllData.[Client Name],
       AllData.[Company Name],
       AllData.Segment,
       AllData.Sector,
       AllData.[Activity Key],
       AllData.[No. Act],
       AllData.Attendee,
       AllData.Product FROM 
(
SELECT IA_Activities_Data.dim_client_key,
       Activity,
       [Activity Type],
       [Date of Activity],
       CreatedBy,
       [Client Name],
       [Company Name],
       --[Client Category],
       Segment,
       Sector,
       [Activity Key],
       [No. Act],
       Attendee,
       Products.Product 
	 FROM dbo.IA_Activities_Data
INNER JOIN (
SELECT dim_client_key,Product FROM dbo.IA_Client_Data WHERE Product IS NOT NULL
)  AS Products
ON Products.dim_client_key = IA_Activities_Data.dim_client_key
WHERE Products.Product IS NOT NULL
UNION

SELECT dim_ia_activity_involvement.dim_client_key
	,activity_calendar_date AS [Activity]
	,activity_type_desc AS [Activity Type]
	,activity_calendar_date AS [Date of Activity]
	,red_dw.dbo.dim_employee.forename + ' ' + surname AS CreatedBy
	,dim_client.client_name AS [Client Name]
	,dim_ia_activity_involvement.company_name AS [Company Name]
    --,NULL AS [Client Category]
    ,segment AS Segment
    ,sector AS Sector
	, dim_ia_activity_involvement.dim_ia_activity_key [Activity Key]
	, 1 AS [No. Act]
	, dim_ia_activity_involvement.first_name+' '+dim_ia_activity_involvement.last_name AS [Attendee]
    ,product AS Product 
FROM red_dw.dbo.dim_ia_activity
 INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity.dim_ia_activity_key=dim_ia_activity_involvement.dim_ia_activity_key
INNER JOIN red_dw.dbo.dim_be_pursuits
 ON ia_client_key=ia_contact_id
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON dim_ia_activity.dim_created_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = dim_ia_activity_involvement.dim_client_key
 WHERE product IS NOT NULL
) AS AllData

END
GO
