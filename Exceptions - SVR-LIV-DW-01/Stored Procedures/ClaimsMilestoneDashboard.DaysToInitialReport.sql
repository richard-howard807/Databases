SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [ClaimsMilestoneDashboard].[DaysToInitialReport]
AS
BEGIN
SELECT date_opened_case_management AS [Date Opened]
,date_initial_report_sent AS [Date initial report sent]
,ll00_have_we_had_an_extension_for_the_initial_report AS [Extension Granted?]
,RTRIM(dim_matter_header_current.client_code) +'-' +RTRIM(dim_matter_header_current.matter_number) AS [Client/Matter Number]
,dim_fed_hierarchy_history.name AS [Fee earner]
,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel2hist AS Division
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_initial_report_sent>='2019-05-01'
END
GO
