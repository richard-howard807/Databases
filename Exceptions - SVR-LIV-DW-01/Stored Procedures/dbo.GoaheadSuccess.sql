SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GoaheadSuccess]

(
@StartDate AS DATE
,@EndDate AS DATE
) 

AS 

BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE

--SET @StartDate=(SELECT DATEADD(q, DATEDIFF(q, 0, GETDATE()), 0))
--SET @EndDate=(SELECT DATEADD(d, -1, DATEADD(q, DATEDIFF(q, 0, GETDATE()) + 1, 0)))



SELECT 
master_client_code + '-' + master_matter_number AS [Weightmans Ref]
,matter_description AS [Matter Description]
,matter_owner_full_name AS [Weightmans Case Handler]
,client_reference AS [Client Ref]
,date_claim_concluded AS[Date Claim Concluded]
,outcome_of_case AS [Outcome of Claim]
,(ISNULL(fact_finance_summary.[damages_reserve],0)  + ISNULL(fact_detail_reserve_detail.[claimant_costs_reserve_current],0))
- ( ISNULL(fact_finance_summary.[damages_paid],0)  + ISNULL(fact_finance_summary.[claimants_costs_paid],0)) AS [Saving (Damages and TP Costs)]


FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
 
WHERE dim_matter_header_current.client_code='W15492'
AND date_claim_concluded BETWEEN @StartDate AND @EndDate
AND 
(
LOWER(outcome_of_case) LIKE '%discontinued%' OR
LOWER(outcome_of_case) LIKE '%won%' OR
LOWER(outcome_of_case) LIKE '%struck%' OR
LOWER(outcome_of_case) LIKE '%assessment%' 
)

END 
GO
