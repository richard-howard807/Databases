SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[EmergencyServicesSectorDashboard]

AS 

BEGIN
SELECT master_client_code + '-'+ master_matter_number AS [Reference]
,matter_description AS [Matter Description]
,name AS [Matter Manager]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,branch_name AS [Office]
, CASE WHEN red_dw.dbo.dim_matter_worktype.work_type_name IN 
(
'PL - Pol - False Imprisonment','PL - Pol - Negligence','PL - Pol - Human Rights','PL - Pol - CHIS'
,'Motor - Driver','PL - Other','EL - Stress','PL - Pol - Assault','PL - Pol - Mal Proc Arrest/Search Warran','Disease - Asbestos/Mesothelioma'
,'PL - Pol - Malicious Prosecution','EL - Bullying and Harassment/PHA Claims','PL - Pol - Civil Claim Under Equal s Act','EL - Slip/Trip/Fall on Same Level','PL - Pol - Trespass (Land and Goods)'
,'Motor - Motorcyclist','Insurance/Costs - Negotiation','Motor - Passenger','Motor - Vehicle Owner','EL - Assault - Member of the Public'
,'EL - Fall From Height','EL - Other Kind of Accident','Insurance/Costs - Strategic Advice','EL - PPE - Defective','PL - OL - Water Hazard - Property'
,'EL - Crush, Traps and Collisions','Disease - Industrial Deafness','EL - Manual Handling - Object','EL - Hazardous Substances - Respiratory'
,'EL - Defective Equipment','Disease - Asthma/Bronchitis/Emphysema','Motor - Cyclist','EL - PPE - Unsuitable','Disease - Outsource NIHL'
,'EL - Moving/Falling Object','EL - Assault - Colleague','EL - Assault - Service User') THEN 'Civil Claims'

 WHEN red_dw.dbo.dim_matter_worktype.work_type_name IN ('PL - Pol - Inquests','Inquest','PL - Pol - Public Enquiries') THEN 'Inquests'
 WHEN red_dw.dbo.dim_matter_worktype.work_type_name IN ('PL - Pol - Stalking Protection Order'
,'PL - Pol - DVPO/DVPN','PL - Pol - SHPO/RSO','PL - Pol - DVPO Breach','PL – Pol – Modern Slavery') THEN 'Violence against women and girls'


ELSE  red_dw.dbo.dim_matter_worktype.work_type_name END


AS [Matter Type]
,bill_amount AS [Revenue]
,dim_bill_date.bill_date AS [Bill Date]
,CASE WHEN ISNULL(dim_client.client_group_name,'')='' THEN dim_client.client_name ELSE dim_client.client_group_name END AS Client
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
INNER JOIN red_dw.dbo.fact_bill_activity
 ON fact_bill_activity.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
WHERE sector='Emergency Services'
AND bill_fin_year >='2019'

END 
GO
