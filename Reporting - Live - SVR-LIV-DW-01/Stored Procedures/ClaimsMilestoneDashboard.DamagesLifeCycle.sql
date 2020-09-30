SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [ClaimsMilestoneDashboard].[DamagesLifeCycle]
AS
BEGIN
SELECT date_opened_case_management AS [Date Opened]
,date_claim_concluded AS [Date Claim Concluded]
,RTRIM(dim_matter_header_current.client_code) +'-' +RTRIM(dim_matter_header_current.matter_number) AS [Client/Matter Number]
,dim_fed_hierarchy_history.name AS [Fee earner]
,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel2hist AS Division
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_claim_concluded>='2019-05-01'
END
GO
