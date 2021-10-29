SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[IAProducts]

AS 

BEGIN 

SELECT Pursuits.[Pursuit Number]
       ,Pursuits.Company
       ,Pursuits.Description
       ,Pursuits.[Date Opened]
	   ,Segment
,Sector
,Pursuits.Type
,Pursuits.[Days Since Last Contacted]
,Pursuits.LastEngement
,Pursuits.NextEngement
,Pursuits.[Expected Closure Date]
,Pursuits.Product
,'Pursuits' [Pursuits/Opportunity]
,NULL AS [Value]
,Pursuits.Stage
,Pursuits.[Lead Partner]
,Pursuits.[Closed Date]
,NULL AS Outcome
FROM (
SELECT pursuitsn AS [Pursuit Number],
       company_name AS [Company],
	   dim_be_pursuits.title AS [Description],
	   open_date AS [Date Opened],
       priority_rank AS [Priority Rank],
       ISNULL(stage_state,'Unspecified') AS [Stage/State],
       ISNULL(state,'Unspecified') AS [State],
       ISNULL(stage,'Unspecified') AS [Stage],
       ISNULL(status,'Unspecified') AS [Status],
       ISNULL(type,'Unspecified') AS [Type],
       ISNULL(practicegrouplist,'Unspecified') AS Segment,
	   ISNULL(industry_list,'Unspecified') AS Sector,
       worktype_list AS [WorkType List],
	   est_close_date [Expected Closure Date],
       close_date AS [Closed Date],
	   close_reason AS [Closure Reason],
       create_date AS [Created Date],
       priority AS [Piority],
       modified_date AS [Date Last Updated],
       originationsource AS [Origination Source]
	   ,NextEngement.NextEngement
	   ,LastEngement.LastEngement
	   ,red_dw.dbo.dim_employee.knownas + ' ' + surname AS [Lead Partner]
	   ,DATEDIFF(DAY,CASE WHEN LastEngement.LastEngement='1753-01-01 00:00:00.000' THEN NULL ELSE LastEngement.LastEngement END, GETDATE()) AS [Days Since Last Contacted]
	   ,DATEDIFF(DAY,CASE WHEN open_date='1753-01-01 00:00:00.000' THEN NULL ELSE open_date END, GETDATE()) AS [Days Open]
	   ,product AS [Product]
	   FROM red_dw.dbo.dim_be_pursuits
	   	LEFT OUTER JOIN red_dw.dbo.dim_employee
	 ON dim_lead_emp_key=dim_employee_key
	   	   LEFT OUTER JOIN (SELECT DISTINCT ia_contact_id
,MIN(activity_date) AS [NextEngement]
FROM red_dw.dbo.dim_ia_activity
INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity.dim_ia_activity_key=dim_ia_activity_involvement.dim_ia_activity_key
--AND contact_type='Client'
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key 
 WHERE dim_ia_activity.activity_date>GETDATE()+1
 GROUP BY ia_contact_id
 ) AS NextEngement
ON NextEngement.ia_contact_id = dim_be_pursuits.ia_client_key
 LEFT OUTER JOIN 
(
 SELECT ia_contact_id
,MAX(activity_calendar_date) AS LastEngement
 FROM red_dw.dbo.dim_ia_activity
 INNER JOIN red_dw.dbo.dim_ia_activity_involvement
ON dim_ia_activity.dim_ia_activity_key=dim_ia_activity_involvement.dim_ia_activity_key
--AND contact_type='Client'
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activity.dim_activity_type_key 
WHERE dim_ia_activity.activity_date<=GETDATE()
 GROUP BY ia_contact_id
) AS LastEngement
 ON LastEngement.ia_contact_id = dim_be_pursuits.ia_client_key
	   WHERE pursuitsn <>'Unknown'
	  -- AND close_date IS NULL
	   AND product IS NOT NULL
	   AND ISNULL(product,'')<>'Unknown'
) AS Pursuits
UNION
SELECT [Opportunity Number]
,[Client Name] AS [Company]
,[Opportunity Name] AS [Description]
,[Open Date] AS [Date Opened]
,Segment
,Sector
,[Opportunity Type]
,[Days Since Last Contacted]
,[Last Contacted Date]
,[Next Engagement Date]
,[Expected Close Date]
,Product 
,'Opportunity' [Pursuits/Opportunity]
,[Opportunity Value] AS [Value]
,[Sales Stage] AS Stage
,[CRP]
,ActualClosedDate
,Outcome
FROM dbo.IA_Client_Data
WHERE product IS NOT NULL
AND ISNULL(Product,'')<>'Unknown'



END 
GO
