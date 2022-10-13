SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[MarkerstudyQuarterlyShelfLife]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS

BEGIN

--DECLARE @Startdate AS DATE
--DECLARE @EndDate AS DATE

--SET @Startdate='2022-04-01'
--SET @EndDate='2022-06-30'

SELECT
RTRIM(master_client_code) +'-'+RTRIM(master_matter_number) AS [Case Number]
,matter_description AS [Case Description]

,surname +', '+knownas  AS [Weightmans Fee-Earner]
,hierarchylevel4hist AS [Team]
,dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Markerstudy Handler]
,insurerclient_reference AS [Markerstudy Ref]
,date_opened_case_management AS [Date Opened]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,DATEDIFF(DAY,date_opened_case_management,date_claim_concluded) AS [Elapsed Days]
,dim_detail_core_details.coop_client_branch

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER  JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE master_client_code IN ('C1001','W24438')
AND date_claim_concluded BETWEEN @StartDate AND @EndDate
AND coop_client_branch='Complex Claims Manchester'

END 
GO
