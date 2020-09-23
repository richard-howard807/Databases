SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[TrackingPursuits]
AS
BEGIN
SELECT  dim_be_pursuits.company_name AS [Company Name]
	, Lead.knownas+' '+Lead.surname AS [Lead Partner]
	, dim_ia_lists.list_name AS [Working List Title]
	, DATEDIFF(DAY,LastContact.[Last Contacted Date], GETDATE()) AS [Days Since Last Contacted]
	, LastContact.[Last Contacted Date]
	, activity_type_desc AS [Activity Description]
	,activity_date
	, summary
	--, LastContact.[Last Activity Type]
	--, LastContact.[Last Activity Summary]
	--,*
FROM red_dw.dbo.dim_ia_lists
INNER JOIN red_dw.dbo.dim_ia_contact_lists 
ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
LEFT OUTER JOIN red_dw.dbo.dim_be_pursuits
ON dim_be_pursuits.ia_client_key=dim_ia_contact_lists.ia_client_id 
LEFT OUTER JOIN red_dw.dbo.dim_employee AS [Lead]
 ON [Lead].dim_employee_key=dim_lead_emp_key
LEFT OUTER JOIN red_dw.dbo.dim_ia_activities 
ON dim_ia_activities.company_name = dim_be_pursuits.company_name
--INNER JOIN red_dw.dbo.dim_activity_date
-- ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key
LEFT OUTER JOIN (SELECT company_name
,MAX(activity_calendar_date) AS [Last Contacted Date]
--,activity_type_desc AS [Last Activity Type]
--,summary AS [Last Activity Summary]
 FROM red_dw.dbo.dim_ia_activities
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key 
 GROUP BY company_name
          --activity_type_desc,
          --summary
 HAVING MAX(activity_calendar_date)<GETDATE()) AS [LastContact] ON LastContact.company_name = dim_be_pursuits.company_name

WHERE dim_ia_lists.list_name LIKE 'BD - NBM - AM - OMB Pursuits and Opportunities%'--' - Midlands (companies)' 
--AND dim_be_pursuits.company_name='Investigo Limited'
END
GO
