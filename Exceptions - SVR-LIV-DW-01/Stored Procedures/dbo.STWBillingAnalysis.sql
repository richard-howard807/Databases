SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[STWBillingAnalysis] --EXEC [STWBillingAnalysis] '2022-01-01', '2022-03-28'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS

--DECLARE @StartDate AS DATE = '2022-02-01'
--,@EndDate AS DATE = '2022-03-03'


SELECT DISTINCT 
ClientMatter = fact_bill.client_code +'-'+fact_bill.matter_number,
client_name,
InvNumber,InvDate,OrgAmt AS [Bill Total]
,OrgFee AS [Revenue]
,OrgHCo + OrgSCo  AS [Disbursements]
,OrgTax AS [Vat]
,Narrative_UnformattedText
,IsReversed
,fact_bill.dim_matter_header_curr_key

FROM TE_3E_Prod.dbo.InvMaster WITH(NOLOCK)
LEFT JOIN red_dw.dbo.dim_bill 
ON bill_number = InvNumber COLLATE DATABASE_DEFAULT
LEFT JOIN red_dw.dbo.fact_bill
ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
LEFT JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key

WHERE 1 = 1
AND CAST(InvDate AS Date) BETWEEN @StartDate AND @EndDate 
AND  (LOWER(Narrative) LIKE '%stw%escrow%74%water%'
 OR LOWER(Narrative) LIKE '%balance%sheet%fund%100%water%'
 OR LOWER(Narrative) LIKE '%derwent%fund%86%water%'
 ) --OR fact_bill.client_code = '00257248'
AND Narrative IS NOT NULL 

AND IsReversed=0

ORDER BY InvDate,Narrative_UnformattedText


GO
