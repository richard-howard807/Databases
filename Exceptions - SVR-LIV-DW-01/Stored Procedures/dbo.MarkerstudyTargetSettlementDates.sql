SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[MarkerstudyTargetSettlementDates]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 
BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate=(SELECT CONVERT (date,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0)))
--SET @EndDate=(SELECT CONVERT (date,DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)))

SELECT dim_detail_core_details.[clients_claims_handler_surname_forename] AS [MSG Handler]
,insurerclient_reference AS [MSG Ref]
,RTRIM(master_client_code)+'-'+master_matter_number  AS [Weightmans Ref]
,matter_description AS [Name Of Case]
,name AS [Fee Earner Name]
,hierarchylevel4hist AS [Team]
,date_opened_case_management AS [Date File Opened]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued?]
,dim_detail_core_details.[fixed_fee] AS [Fixed Fee?]
,dim_detail_core_details.[delegated] AS [Delegated Authority?]
,dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
,dim_detail_outcome.[date_claim_concluded] AS [Date Damages Concluded]
,dim_detail_core_details.[initial_target_settlement_date] AS [Initial Target Settlement Date]
,dim_detail_core_details.[coop_target_settlement_date] AS [Last Target Settlement Date]
,dim_detail_outcome.[repudiated]
,dim_matter_header_current.delegated
,CASE WHEN dim_matter_header_current.delegated='Y' THEN 'Delegated'
WHEN repudiated='repudiated' THEN 'repudiated'
ELSE 'TSD' END AS Sheet
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details 
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code IN ('C1001','W24438')
AND CONVERT(DATE,date_claim_concluded,103) BETWEEN @StartDate AND @EndDate

END
GO
