SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[WorkingLists]

AS
BEGIN

DROP TABLE IF EXISTS dbo.IA_WorkingLists;

SELECT WorkingLists.[Company Name],
       WorkingLists.[Lead Partner],
       WorkingLists.[Activity Originator],
       WorkingLists.[Working List Title],
       WorkingLists.[Days Since Last Contacted],
       WorkingLists.[Last Contacted Date],
       WorkingLists.[Activity Description],
       WorkingLists.activity_date,
       WorkingLists.summary,
       WorkingLists.PossibleCompanies,
	  CASE WHEN [Working List Title] LIKE '%-%' THEN LEFT([Working List Title], charindex('-', [Working List Title]) - 2) ELSE NULL END AS Segment
INTO IA_WorkingLists
FROM 
(
SELECT DISTINCT company_name AS [Company Name]
	, client_partner_name AS [Lead Partner]
	, Employee2.knownas+' '+Employee2.surname AS [Activity Originator]
	, dim_ia_lists.list_name AS [Working List Title]
	, DATEDIFF(DAY,dim_ia_activity.activity_date, GETDATE()) AS [Days Since Last Contacted]
	, LastContact.[Last Contacted Date]
	, activity_type_desc AS [Activity Description]
	, activity_date
	,summary
	,Possible.PossibleCompanies

FROM  red_dw.dbo.dim_ia_lists
INNER JOIN red_dw.dbo.dim_ia_contact_lists 
ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = dim_ia_contact_lists.dim_client_key
INNER JOIN red_dw.dbo.dim_ia_activity_involvement
 ON dim_ia_activity_involvement.dim_client_key = dim_client.dim_client_key
AND dim_ia_activity_involvement.contact_type = 'Client' 
INNER JOIN red_dw.dbo.dim_ia_activity
ON dim_ia_activity.dim_ia_activity_key = dim_ia_activity_involvement.dim_ia_activity_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key
LEFT OUTER JOIN red_dw.dbo.dim_employee AS Employee2
 ON dim_created_employee_key=Employee2.dim_employee_key
LEFT OUTER JOIN 
(
SELECT dim_client_key
,MAX(activity_calendar_date) AS [Last Contacted Date]
 FROM red_dw.dbo.dim_ia_activity
 INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity_involvement.dim_ia_activity_key = dim_ia_activity.dim_ia_activity_key
AND dim_ia_activity_involvement.contact_type = 'Client' 
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key

 WHERE dim_ia_activity.activity_date<=GETDATE()
 GROUP BY dim_client_key
) AS LastContact
 ON  LastContact.dim_client_key = dim_ia_contact_lists.dim_client_key
 LEFT OUTER JOIN (SELECT dim_ia_lists.list_name AS IAList,COUNT(1) AS PossibleCompanies FROM  red_dw.dbo.dim_ia_lists
INNER JOIN red_dw.dbo.dim_ia_contact_lists 
ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key 
WHERE list_type_id='10011'
--OR list_name LIKE 'BD - NBM - AM - OMB Pursuits and Opportunities%' --ES added in as lists weren't updating, AM
GROUP BY list_name) AS Possible
 ON dim_ia_lists.list_name=Possible.IAList
WHERE list_type_id='10011'
--OR list_name LIKE 'BD - NBM - AM - OMB Pursuits and Opportunities%')
AND dim_ia_contact_lists.dim_client_key <>0

UNION -- Non clients

SELECT DISTINCT company_name AS [Company Name]
	, client_partner_name AS [Lead Partner]
	, Employee2.knownas+' '+Employee2.surname AS [Activity Originator]
	, dim_ia_lists.list_name AS [Working List Title]
	, DATEDIFF(DAY,dim_ia_activity.activity_date, GETDATE()) AS [Days Since Last Contacted]
	, LastContact.[Last Contacted Date]
	, activity_type_desc AS [Activity Description]
	, activity_date
	,summary
	,Possible.PossibleCompanies
FROM  red_dw.dbo.dim_ia_lists
INNER JOIN red_dw.dbo.dim_ia_contact_lists 
ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
INNER JOIN red_dw.dbo.dim_ia_activity_involvement
 ON ia_contact_id=ia_client_id
 INNER JOIN red_dw.dbo.dim_ia_activity
 ON dim_ia_activity.dim_ia_activity_key = dim_ia_activity_involvement.dim_ia_activity_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key
LEFT OUTER JOIN red_dw.dbo.dim_employee AS Employee2
 ON dim_created_employee_key=Employee2.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_client
  ON dim_client.dim_client_key = dim_company_key
  --ON dim_client.dim_client_key = dim_ia_contact_lists.dim_client_key

LEFT OUTER JOIN 
(
SELECT ia_contact_id
,MAX(activity_calendar_date) AS [Last Contacted Date]
 FROM red_dw.dbo.dim_ia_activity
 INNER JOIN red_dw.dbo.dim_ia_activity_involvement
 ON dim_ia_activity_involvement.dim_ia_activity_key = dim_ia_activity.dim_ia_activity_key
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key

 WHERE dim_ia_activity.activity_date<=GETDATE()
 GROUP BY ia_contact_id
) AS LastContact
 ON LastContact.ia_contact_id = dim_ia_activity_involvement.ia_contact_id
 LEFT OUTER JOIN (SELECT dim_ia_lists.list_name AS IAList,COUNT(1) AS PossibleCompanies FROM  red_dw.dbo.dim_ia_lists
INNER JOIN red_dw.dbo.dim_ia_contact_lists 
ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key 
WHERE list_type_id='10011'
--OR list_name LIKE 'BD - NBM - AM - OMB Pursuits and Opportunities%'
GROUP BY list_name) AS Possible
 ON dim_ia_lists.list_name=Possible.IAList
WHERE list_type_id='10011'
--OR list_name LIKE 'BD - NBM - AM - OMB Pursuits and Opportunities%')
AND dim_ia_contact_lists.dim_client_key=0
) AS WorkingLists

END 
GO
