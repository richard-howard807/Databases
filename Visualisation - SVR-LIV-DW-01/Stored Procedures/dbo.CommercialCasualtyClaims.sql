SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CommercialCasualtyClaims]

AS 



BEGIN 


SELECT

RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [MatterSphere Client/Matter Number]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,red_dw.dbo.dim_matter_worktype.work_type_name AS [Matter Type]
,name AS [Case Manager]
,hierarchylevel4hist AS Team
,dim_client.client_name AS [Client Name]
,sector AS [Client Sector]
,insuredclient_name AS [Insured Client Name]
,dim_detail_outcome.[outcome_of_case] AS Outcome
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,dim_detail_outcome.[reason_for_settlement] AS [Reason for settlement]
,fact_finance_summary.[damages_paid] AS [Damages Paid]
,brief_details_of_claim
,dim_detail_core_details.[insured_sector] AS [Insured Client Sector]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
  ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number

WHERE hierarchylevel3hist='Casualty'

----------------------Exclusions--------------------------------------
AND sector NOT LIKE '%Education%'
AND sector NOT LIKE '%Emergency Services%'
AND sector NOT LIKE '%Health%'
AND sector NOT LIKE '%Local & Central Government%'
AND insured_sector NOT LIKE '%Ambulance%'
AND insured_sector NOT LIKE '%Education%'
AND insured_sector NOT LIKE '%Fire%'
AND insured_sector NOT LIKE '%Local & Central Government%'
AND insured_sector NOT LIKE '%Police%'
AND insured_sector NOT LIKE '%Healthcare%'
AND insured_sector NOT LIKE '%Social Housing%'
AND insured_sector NOT LIKE '%Societies/political/religious%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Council%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Borough%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%MBC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%LBC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%CC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%BC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%DC%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Police%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Constab%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Fire%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Health%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%NHS%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%School%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%University%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%College%'
AND red_dw.dbo.dim_matter_header_current.client_name NOT LIKE '%Housing%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Council%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Borough%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%MBC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%LBC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%CC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%BC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%DC%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Police%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Constab%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Fire%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Health%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%NHS%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%School%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%University%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%College%'
AND red_dw.dbo.dim_matter_header_current.matter_description NOT LIKE '%Housing%'
--AND( (CASE WHEN CONVERT(DATE,date_opened_case_management,103)  BETWEEN @StartDate AND @EndDate  THEN 1 ELSE 0 END)=1
--OR(CASE WHEN CONVERT(DATE,date_claim_concluded,103)  BETWEEN @StartDate AND @EndDate  THEN 1 ELSE 0 END)=1)

END 
GO
