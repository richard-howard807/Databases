SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[IAActivities]
AS 

DROP TABLE IF EXISTS dbo.IA_Activities_Data;

BEGIN

SELECT dim_ia_activities.dim_client_key AS dim_client_key
	,activity_calendar_date AS [Activity]
	,activity_type_desc AS [Activity Type]
	,activity_calendar_date AS [Date of Activity]
	,red_dw.dbo.dim_employee.forename + ' ' + surname AS CreatedBy
	,dim_client.client_name AS [Client Name]
	,company_name AS [Company Name]
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
	,dim_ia_activities.dim_client_key AS ClientKey
	--,ActualClosedDate
	,leftdate

	
 INTO dbo.IA_Activities_Data
--SELECT * 
 FROM red_dw.dbo.dim_ia_activities
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON dim_created_employee_key=dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = dim_ia_activities.dim_client_key
 ---- Added in below so it 1 dataset for sector segmetn
--LEFT OUTER JOIN dbo.IA_Client_Data
 --ON IA_Client_Data.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN (SELECT dim_client_key
,MAX(activity_calendar_date) AS NextEngement
 FROM red_dw.dbo.dim_ia_activities
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key 
 --Maybe have filter activity type
 GROUP BY dim_client_key
 HAVING MAX(activity_calendar_date)>=GETDATE()) AS NextEngement
  ON NextEngement.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN 
(
 SELECT dim_client_key
,MAX(activity_calendar_date) AS LastEngement
 FROM red_dw.dbo.dim_ia_activities
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key 
 --Maybe have filter activity type
 GROUP BY dim_client_key
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
	  ON Lists.ia_client_id=dim_ia_activities.ia_client_key

 WHERE dim_ia_activities.dim_client_key<>0
 AND leftdate IS NULL

 END



GO
