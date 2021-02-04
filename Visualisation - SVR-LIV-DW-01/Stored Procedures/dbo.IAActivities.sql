SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[IAActivities]
AS 

DROP TABLE IF EXISTS dbo.IA_Activities_Data;

BEGIN
SELECT AllData.dim_client_key,
       AllData.Activity,
       AllData.[Activity Type],
       AllData.[Date of Activity],
       AllData.CreatedBy,
       AllData.[Client Name],
       AllData.[Company Name],
       AllData.[Client Category],
       AllData.Segment,
       AllData.Sector,
       AllData.[Days Since Last Contacted],
       AllData.[Next Engagement Date],
       AllData.CRP,
       AllData.ClientKey,
       AllData.leftdate,
	   AllData.[Activity Key],
	   AllData.[No. Act],
	   AllData.Attendee

 INTO dbo.IA_Activities_Data
 --SELECT COUNT(1)  FROM dbo.IA_Activities_Data
 FROM 
(SELECT client_involvement.dim_client_key AS dim_client_key
	,activity_calendar_date AS [Activity]
	,activity_type_desc AS [Activity Type]
	,activity_calendar_date AS [Date of Activity]
	,red_dw.dbo.dim_employee.forename + ' ' + surname AS CreatedBy
	,dim_client.client_name AS [Client Name]
	,dim_ia_activity_involvement.company_name AS [Company Name]
	--,dim_client.generator_status AS [Client Category]
	,ISNULL(Lists.list_name,'Client (Excl Patron & Star)') AS [Client Category]
	,dim_client.segment AS Segment
	,dim_client.sector AS Sector
	--,COALESCE(dbo.IA_Client_Data.[Client Name],dim_client.client_name) AS [Client Name]
	--,COALESCE(dbo.IA_Client_Data.[Client Category],dim_client.generator_status) AS [Client Category]
	--,COALESCE(IA_Client_Data.Segment,dim_client.segment) AS Segment
	--,COALESCE(IA_Client_Data.Sector,dim_client.sector) AS Sector
	--,[Days Open]
	--,[Opportunity Name]
	,DATEDIFF(DAY,CASE WHEN LastEngement.LastEngement='1753-01-01 00:00:00.000' THEN NULL ELSE LastEngement.LastEngement END, GETDATE())  AS [Days Since Last Contacted]
	,NextEngement.NextEngement AS [Next Engagement Date]
	--,[Expected Close Date]
	--,[Sales Stage]
	--,[Probability %]
	--,[Opportunity Value]
	,client_partner_name AS CRP
	,client_involvement.dim_client_key AS ClientKey
	--,ActualClosedDate
	,leftdate
	, dim_ia_activity_involvement.dim_ia_activity_key [Activity Key]
	, 1 AS [No. Act]
	, dim_ia_activity_involvement.first_name+' '+dim_ia_activity_involvement.last_name AS [Attendee]
	
 FROM red_dw.dbo.dim_ia_activity
 INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity.dim_ia_activity_key=dim_ia_activity_involvement.dim_ia_activity_key
AND contact_type='Employee'
 INNER JOIN red_dw.dbo.dim_ia_activity_involvement AS client_involvement
ON dim_ia_activity.dim_ia_activity_key=client_involvement.dim_ia_activity_key
AND client_involvement.contact_type='Client'
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON dim_ia_activity.dim_created_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = client_involvement.dim_client_key
 ---- Added in below so it 1 dataset for sector segmetn
--LEFT OUTER JOIN dbo.IA_Client_Data
 --ON IA_Client_Data.dim_client_key = dim_client.dim_client_key

LEFT OUTER JOIN (SELECT client_involvement.dim_client_key
,MAX(activity_calendar_date) AS NextEngement
 FROM red_dw.dbo.dim_ia_activity
  INNER JOIN red_dw.dbo.dim_ia_activity_involvement AS client_involvement
ON dim_ia_activity.dim_ia_activity_key=client_involvement.dim_ia_activity_key
AND client_involvement.contact_type='Client'
INNER JOIN red_dw.dbo.dim_activity_date
 ON dim_ia_activity.activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key 
 --Maybe have filter activity type
 GROUP BY client_involvement.dim_client_key
 HAVING MAX(activity_calendar_date)>=GETDATE()) AS NextEngement
  ON NextEngement.dim_client_key = dim_client.dim_client_key

LEFT OUTER JOIN 
(
 SELECT client_involvement.dim_client_key
,MAX(activity_calendar_date) AS LastEngement
 FROM red_dw.dbo.dim_ia_activity
  INNER JOIN red_dw.dbo.dim_ia_activity_involvement AS client_involvement
ON dim_ia_activity.dim_ia_activity_key=client_involvement.dim_ia_activity_key
AND client_involvement.contact_type='Client'
INNER JOIN red_dw.dbo.dim_activity_date
 ON dim_ia_activity.activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key 
 --Maybe have filter activity type
 GROUP BY client_involvement.dim_client_key
 HAVING MAX(activity_calendar_date)<GETDATE()
) AS LastEngement
 ON LastEngement.dim_client_key = dim_client.dim_client_key

 LEFT OUTER JOIN (SELECT dim_ia_contact_lists.dim_client_key
	, dim_ia_lists.list_name
	, dim_ia_contact_lists.ia_client_id
	  FROM red_dw.dbo.dim_ia_lists
	  INNER JOIN red_dw.dbo.dim_ia_contact_lists ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
	  WHERE dim_ia_lists.list_name IN ('Clients (Active)','Clients (Lapsed)','Non client','Patron','Star')
	  AND dim_ia_contact_lists.dim_client_key<>0
	  AND list_type_desc='Status'
	  ) AS [Lists]
	  ON Lists.ia_client_id=dim_ia_activity_involvement.ia_contact_id

 WHERE client_involvement.dim_client_key<>0
 AND leftdate IS NULL
 
UNION

SELECT client_involvement.dim_client_key AS dim_client_key
       ,activity_calendar_date AS [Activity]
       ,activity_type_desc AS [Activity Type]
       ,activity_calendar_date AS [Date of Activity]
       ,red_dw.dbo.dim_employee.forename + ' ' + surname AS CreatedBy
       ,dim_client.client_name AS [Client Name]
       ,dim_ia_activity_involvement.company_name AS [Company Name]
       ,ISNULL(Lists.list_name,'Non client') AS [Client Category]
       ,dim_client.segment AS Segment
       ,dim_client.sector AS Sector
       ,DATEDIFF(DAY,CASE WHEN LastEngement.LastEngement='1753-01-01 00:00:00.000' THEN NULL ELSE LastEngement.LastEngement END, GETDATE())  AS [Days Since Last Contacted]
       ,NextEngement.NextEngement AS [Next Engagement Date]
       ,client_partner_name AS CRP
       ,client_involvement.dim_client_key AS ClientKey
       ,leftdate
	   , dim_ia_activity_involvement.dim_ia_activity_key [Activity Key]
	, 1 AS [No. Act]
	, dim_ia_activity_involvement.first_name+' '+dim_ia_activity_involvement.last_name AS [Attendee]
FROM red_dw.dbo.dim_ia_activity
  INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity.dim_ia_activity_key=dim_ia_activity_involvement.dim_ia_activity_key
AND contact_type='Employee'
  INNER JOIN red_dw.dbo.dim_ia_activity_involvement AS client_involvement
ON dim_ia_activity.dim_ia_activity_key=client_involvement.dim_ia_activity_key
AND client_involvement.contact_type='Client'
INNER JOIN red_dw.dbo.dim_activity_date
ON dim_ia_activity.activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key
LEFT OUTER JOIN red_dw.dbo.dim_employee
ON dim_ia_activity.dim_created_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = client_involvement.dim_client_key
LEFT OUTER JOIN (SELECT dim_ia_contact_lists.dim_client_key
       , dim_ia_lists.list_name
       , dim_ia_contact_lists.ia_client_id
         FROM red_dw.dbo.dim_ia_lists
         INNER JOIN red_dw.dbo.dim_ia_contact_lists ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
         WHERE dim_ia_lists.list_name IN ('Clients (Active)','Clients (Lapsed)','Non client','Patron','Star')
         AND dim_ia_contact_lists.dim_client_key<>0
         AND list_type_desc='Status'
         ) AS [Lists]
         ON Lists.dim_client_key=dim_ia_activity_involvement.dim_client_key --Amended

LEFT OUTER JOIN (SELECT ia_contact_id
,MAX(activity_calendar_date) AS NextEngement
FROM red_dw.dbo.dim_ia_activity
  INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity.dim_ia_activity_key=dim_ia_activity_involvement.dim_ia_activity_key
INNER JOIN red_dw.dbo.dim_activity_date
ON dim_ia_activity.activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key 
 --Maybe have filter activity type
GROUP BY ia_contact_id
HAVING MAX(activity_calendar_date)>=GETDATE()) AS NextEngement
  ON  NextEngement.ia_contact_id = dim_ia_activity_involvement.ia_contact_id

LEFT OUTER JOIN 
(
SELECT ia_contact_id
,MAX(activity_calendar_date) AS LastEngement
FROM red_dw.dbo.dim_ia_activity
  INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity.dim_ia_activity_key=dim_ia_activity_involvement.dim_ia_activity_key
INNER JOIN red_dw.dbo.dim_activity_date
ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key 
 --Maybe have filter activity type
GROUP BY ia_contact_id
HAVING MAX(activity_calendar_date)<GETDATE()
) AS LastEngement
ON  LastEngement.ia_contact_id = dim_ia_activity_involvement.ia_contact_id

WHERE client_involvement.dim_client_key=0
AND leftdate IS NULL
) AS AllData


 END



GO
