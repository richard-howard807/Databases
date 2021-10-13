SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







--SELECT * FROM dbo.IA_Client_Data


CREATE PROCEDURE [dbo].[IAClientData]
AS 

DROP TABLE IF EXISTS dbo.IA_Client_Data;

BEGIN

SELECT opportunitysn AS [Opportunity Number]
	,Company.dim_client_key AS dim_client_key
	,ISNULL(target_company,Company.client_name) AS [Client Name]
	,ISNULL(Lists.list_name,'Client (Excl Patron & Star)') AS [Client Category]
	,dim_be_opportunities.title AS [Opportunity Name]
	,type AS [Opportunity Type]
	,dim_be_opportunities.client_type AS [Revenue Type]
	,COALESCE(CASE WHEN practice_groups='OMB, Public Bodies' THEN 'OMB' 
									WHEN dim_be_opportunities.practice_groups='Public Bodies' THEN 'Public bodies'
	ELSE practice_groups END,Company.segment) AS [Segment]
	,REPLACE(REPLACE(COALESCE(
	CASE WHEN industries='Local & Central Government, OMB Manchester' THEN  'OMB Manchester' 
	
	ELSE industries END,Company.sector)
	,'Motor Composites & Monoline','Motor Composites and Monoline')
	,'Hotels & Leisure','Leisure & Hotels')
	
	AS [Sector]
	,ISNULL(Lead.knownas+' '+Lead.surname,Company.client_partner_name) AS [CRP]
	,dim_be_opportunities.open_date AS [Open Date]
	,DATEDIFF(DAY,dim_be_opportunities.open_date, GETDATE()) AS [Days Open]
	,CASE WHEN LastEngement.LastEngement='1753-01-01 00:00:00.000' THEN NULL ELSE LastEngement.LastEngement END AS [Last Contacted Date]
	,DATEDIFF(DAY,CASE WHEN LastEngement.LastEngement='1753-01-01 00:00:00.000' THEN NULL ELSE LastEngement.LastEngement END, GETDATE()) AS [Days Since Last Contacted]
	,NextEngement.NextEngement AS [Next Engagement Date]
	,est_close_date AS [Expected Close Date]
	,stage AS [Stage]
	,stagestate AS [Sales Stage]
	,origin AS [Opportunity Source]
	,NULL AS [Campaigns]
	,chance_of_success AS [Probability %]
	,estimated_value AS [Opportunity Value]
	,LeadClient.contact_name AS [Referrer Name]
	,intermediary_referrer AS [Referrer Company]
	,hierarchylevel2hist AS [Division]
	,Coordinator.contact_name AS [BD]
	,TargetRevenue AS [Target Revenue]
	,NULL AS [Last YR Annual]
	,NULL AS [MTD Actual]
	,ActualRevenue.Revenue AS [YTD Actual]
	,outcome AS [Outcome]
	,win_or_loss_reason AS [Outcome Reason]
	,state_outcome
	,close_date AS ActualClosedDate
	,product AS [Product]

INTO dbo.IA_Client_Data
--SELECT *
FROM red_dw.dbo.dim_be_opportunities
LEFT JOIN red_dw.dbo.fact_be_opportunities
 ON fact_be_opportunities.dim_be_opportunities_key = dim_be_opportunities.dim_be_opportunities_key
INNER JOIN red_dw.dbo.dim_client  AS Company
ON Company.dim_client_key = dim_be_opportunities.dim_company_client_key 
INNER JOIN red_dw.dbo.dim_client  AS LeadClient
ON dim_lead_client_key=LeadClient.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_client AS Coordinator
 ON dim_coordinator_client_key=Coordinator.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=Company.client_partner_code AND dss_current_flag='Y'
 LEFT OUTER JOIN red_dw.dbo.dim_employee AS [Lead]
 ON [Lead].dim_employee_key=dim_lead_emp_key

--LEFT OUTER JOIN ( SELECT DISTINCT companyid
--,MIN(activity_date) AS [NextEngement]
--FROM red_dw.dbo.dim_ia_activities
--INNER JOIN red_dw.dbo.dim_ia_activity_type
-- ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key 
-- WHERE dim_ia_activities.activity_date>GETDATE()+1
-- GROUP BY companyid) AS NextEngement
--  ON NextEngement.companyid = dim_be_opportunities.ia_client_id

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
ON NextEngement.ia_contact_id = dim_be_opportunities.ia_client_id

--LEFT OUTER JOIN 
--(
-- SELECT companyid
--,MAX(activity_calendar_date) AS LastEngement
-- FROM red_dw.dbo.dim_ia_activities
--INNER JOIN red_dw.dbo.dim_activity_date
-- ON activity_date_key=dim_activity_date_key
--INNER JOIN red_dw.dbo.dim_ia_activity_type
-- ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key 
--WHERE dim_ia_activities.activity_date<=GETDATE()
-- GROUP BY companyid
--) AS LastEngement
-- ON LastEngement.companyid = dim_be_opportunities.ia_client_id

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
 ON LastEngement.ia_contact_id = dim_be_opportunities.ia_client_id

LEFT OUTER JOIN (SELECT segment,sector,SUM(bill_amount) AS Revenue
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year= (SELECT bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,GETDATE(),103))
GROUP BY  segment,sector
) AS ActualRevenue
 ON ActualRevenue.sector = COALESCE(Company.sector,industries)
 AND  ActualRevenue.segment = COALESCE(Company.segment,practice_groups)

LEFT OUTER JOIN 
(
SELECT segmentname,sectorname,SUM(target_value) AS TargetRevenue FROM red_dw.dbo.fact_segment_target_upload
WHERE [year] =(SELECT bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,GETDATE(),103))
GROUP BY segmentname,sectorname
) AS Targets
 ON COALESCE(Company.sector,industries)=sectorname
 AND COALESCE(Company.segment,practice_groups)=Targets.segmentname
--WHERE Company.dim_client_key <>0
--AND Company.client_name IS NOT NULL

LEFT OUTER JOIN (SELECT dim_ia_contact_lists.dim_client_key
	, dim_ia_lists.list_name
	, dim_ia_contact_lists.ia_client_id
	,ROW_NUMBER() OVER (PARTITION BY ia_client_id ORDER BY list_name DESC) AS xOrder
	  FROM red_dw.dbo.dim_ia_lists
	  INNER JOIN red_dw.dbo.dim_ia_contact_lists ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
	  WHERE dim_ia_lists.list_name IN ('Clients (Active)','Clients (Lapsed)','Non client','Patron','Star')
	  AND dim_ia_contact_lists.dim_client_key<>0
	  AND list_type_desc='Status'
	  ) AS [Lists]
	  ON Lists.ia_client_id=dim_be_opportunities.ia_client_id AND xOrder=1

WHERE UPPER(dim_be_opportunities.title)  NOT LIKE '%TEST%' AND UPPER(dim_be_opportunities.title)  NOT LIKE '%ERROR%'
--AND dim_be_opportunities.target_company='Severn Trent Water'
--AND ISNULL(target_company,Company.client_name) LIKE '%Severn Trent Water%'

ORDER BY [Client Name]
END

--SELECT * FROM red_dw.dbo.dim_be_opportunities
--WHERE dim_be_opportunities.target_company='4th Dimension Innovation Ltd'

GO
