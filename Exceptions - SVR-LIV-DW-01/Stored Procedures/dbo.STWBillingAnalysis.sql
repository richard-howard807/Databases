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

--DECLARE @StartDate AS DATE = '2022-11-01'
--,@EndDate AS DATE = '2022-11-30'


SELECT DISTINCT 
ClientMatter = fact_bill.client_code +'-'+fact_bill.matter_number,
client_name,
InvMaster.InvNumber
,InvMaster.InvDate
,InvMaster.OrgAmt AS [Bill Total]
,InvMaster.OrgFee AS [Revenue]
,InvMaster.OrgHCo + OrgSCo  AS [Disbursements]
,InvMaster.OrgTax AS [Vat]
,COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText)		AS Narrative_UnformattedText
,IsReversed
,fact_bill.dim_matter_header_curr_key
--SELECT ProfMaster.*
FROM TE_3E_Prod.dbo.InvMaster WITH(NOLOCK)
LEFT JOIN red_dw.dbo.dim_bill 
ON bill_number = InvNumber COLLATE DATABASE_DEFAULT
LEFT JOIN red_dw.dbo.fact_bill
ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
LEFT JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
LEFT OUTER JOIN TE_3E_Prod.dbo.ProfMaster
ON ProfMaster.InvMaster = InvMaster.InvIndex
AND InvMaster.LeadMatter = ProfMaster.LeadMatter

WHERE 1 = 1
AND CAST(InvMaster.InvDate AS Date) BETWEEN @StartDate AND @EndDate 
AND  (LOWER(COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText)) LIKE '%stw%escrow%74%water%'
 OR LOWER(COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText)) LIKE '%balance%sheet%fund%100%water%'
 OR LOWER(COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText)) LIKE '%derwent%fund%86%water%'
 ) --OR fact_bill.client_code = '00257248'
AND COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText) IS NOT NULL 

AND IsReversed=0
--AND InvMaster.InvNumber IN ('02123683', '02123453', '02124053')
ORDER BY InvDate,Narrative_UnformattedText






GO
