SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[STWRetainerHrsAnalysis] -- EXEC STWRetainerHrsAnalysis '2020-01-01','2020-06-29'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS

--DECLARE @StartDate AS DATE = '2022-11-01'
--,@EndDate AS DATE = '2022-11-30'

BEGIN
SELECT  master_client_code AS Client
,master_matter_number AS Matter
,date_opened_case_management AS [Date Opened]
,bill_number AS [Bill Number]
,jobtitle [Lawyer Grade]
,name AS FeeeEarner
,SUM(BillHrs) AS HrsBilled
,SUM(BillAmt) AS AmountBilled 
,SUM(WorkAmt) AS WorkAmount
,SUM(WorkHrs) AS WorkHrs
FROM  red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_bill
ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
        LEFT OUTER JOIN TE_3E_Prod.dbo.TimeBill
            ON TimeCard = fact_bill_billed_time_activity.transaction_sequence_number
               AND TimeBill.timebillindex = fact_bill_billed_time_activity.timebillindex
WHERE bill_date BETWEEN  @StartDate AND @EndDate

AND bill_number COLLATE DATABASE_DEFAULT  IN 
(
SELECT DISTINCT InvMaster.InvNumber FROM TE_3E_Prod.dbo.InvMaster
LEFT OUTER JOIN TE_3E_Prod.dbo.ProfMaster
ON ProfMaster.InvMaster = InvMaster.InvIndex
AND InvMaster.LeadMatter = ProfMaster.LeadMatter
WHERE InvMaster.InvDate BETWEEN  @StartDate AND @EndDate
AND
(
LOWER(COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText)) LIKE '%stw%escrow%74%water%'
 OR LOWER(COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText)) LIKE '%balance%sheet%fund%100%water%'
 OR LOWER(COALESCE(ProfMaster.InvNarrative_UnformattedText, InvMaster.Narrative_UnformattedText)) LIKE '%derwent%fund%86%water%'
--Narrative IN (
--'STW Escrow - 74% water'
--,'STW Escrow & 74% Water'
--,'Balance Sheet Fund & 100% Water'
--,'Balance Sheet Fund - 100% water'
--,'Derwent Fund - 86% water'
--,'Derwent Fund & 86% Water'
--) 
)
)
AND IsReversed=0
GROUP BY master_client_code,master_matter_number,date_opened_case_management,bill_number,name
,jobtitle

END

GO
