SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[IAClientData]
AS 

DROP TABLE IF EXISTS dbo.IA_Client_Data;

BEGIN

SELECT opportunitysn AS [Opportunity Number]
	,Company.dim_client_key AS dim_client_key
	,ISNULL(target_company,Company.client_name) AS [Client Name]
	,Company.generator_status AS [Client Category]
	,dim_be_opportunities.title AS [Opportunity Name]
	,type AS [Opportunity Type]
	,dim_be_opportunities.client_type AS [Revenue Type]
	,COALESCE(Company.segment,CASE WHEN practice_groups='OMB, Public Bodies' THEN 'OMB' ELSE practice_groups END) AS [Segment]
	,REPLACE(REPLACE(COALESCE(Company.sector,
	CASE WHEN industries='Local & Central Government, OMB Manchester' THEN  'OMB Manchester' 
	
	ELSE industries END)
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

INTO dbo.IA_Client_Data

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
  ON NextEngement.dim_client_key = Company.dim_client_key
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
 ON LastEngement.dim_client_key = Company.dim_client_key
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
WHERE UPPER(dim_be_opportunities.title)  NOT LIKE '%TEST%' AND UPPER(dim_be_opportunities.title)  NOT LIKE '%ERROR%'
END

--SELECT * FROM red_dw.dbo.dim_be_opportunities
GO