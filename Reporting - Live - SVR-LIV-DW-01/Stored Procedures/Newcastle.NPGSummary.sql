SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2020-10-01'
--SET @EndDate='2020-10-31'



CREATE PROCEDURE [Newcastle].[NPGSummary]
(
@Period AS VARCHAR(20)
)
AS

BEGIN 


DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE

SET @StartDate=(SELECT MIN(calendar_date) 
FROM red_dw.dbo.dim_date
WHERE fin_period=@Period)

SET @EndDate=(SELECT MAX(calendar_date) 
FROM red_dw.dbo.dim_date
WHERE fin_period=@Period)

DECLARE @YearStart AS DATE
SET @YearStart=CONVERT(DATE,CAST(CAST(YEAR(@StartDate) AS NVARCHAR(4))+'-01-01' AS DATE),103)

SELECT CRSystemSourceID,clNo,fileNo,fileDesc
,dteCompletionD
,dbFile.Created AS DateOpened
,fileClosed AS [DateClosed]
,Finances.RevenueAll AS [TotalRevenue]
,Finances.Disbs AS [TotalDisbs]
,MatStat.cdDesc AS MatterStatus
,DATEDIFF(DAY,dbFile.Created,dteCompletionD) AS ElapsedDaysToCompletion
,CASE WHEN dteCompletionD IS  NULL AND fileClosed IS  NULL THEN 1 ELSE 0 END AS LiveFiles
,CASE WHEN dbFile.Created BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS NewInstructionsMonth
,CASE WHEN dbFile.Created BETWEEN @YearStart AND @EndDate THEN 1 ELSE 0 END AS YTDNewInstructions
,CASE WHEN MatStat.cdDesc='On Hold' THEN 1 ELSE 0 END AS [Abeyance]
,CASE WHEN dteCompletionD BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS CompletedMonth
,CASE WHEN dteCompletionD BETWEEN @YearStart AND @EndDate  THEN 1 ELSE 0 END AS YTDCompletions
,CASE WHEN dteCompletionD IS  NULL AND fileClosed IS  NULL AND 
DATEDIFF(MONTH,dbFile.Created,@EndDate) >60 THEN 1 ELSE 0 END  AS SlowMoving
,CASE WHEN dteCompletionD BETWEEN @StartDate AND @EndDate  THEN Finances.RevenueAll ELSE NULL END AS [CostOfCase]
,CASE WHEN dteCompletionD BETWEEN @StartDate AND @EndDate THEN DATEDIFF(DAY,dbFile.Created,dteCompletionD) ELSE NULL END AS AvergeCompletedMonth
,Finances.RevenueYear  AS [ExpenditureYTD]
,Finances.RevenueMonth  AS [ExpenditureMonth]
,Finances.DisbsYear  AS [DisbursementsYTD]
,Finances.DisbsMonth  AS [DisbursementsMonth]
,WIPMonth AS [WIPMonth]
,NULL AS [WIPYTD] --SELECT * FROM red_dw.dbo.fact_wip_monthly
,CASE WHEN CRSystemSourceID LIKE '164103%' OR CRSystemSourceID LIKE '165100%' THEN 'North East'
WHEN CRSystemSourceID LIKE '164107%' OR CRSystemSourceID LIKE '165102%' THEN 'Yorkshire'
WHEN clno='W22559' THEN 'Yorkshire'
WHEN clno IN ('WB164103','WB165100','W24159') THEN 'North East'END  AS [Area]
,@StartDate AS ReportDate
FROM MS_Prod.dbo.udExtFile
INNER JOIN MS_Prod.config.dbFile
 ON dbFile.fileID = udExtFile.fileID
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON ms_fileid=dbFile.fileID
INNER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN MS_Prod.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udPlotSalesExchange
 ON udPlotSalesExchange.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS Insttype
ON cboInsTypeNPG=Insttype.cdCode AND Insttype.cdType='INSTYPENPG'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS MatStat
ON cboMatterStat=MatStat.cdCode AND MatStat.cdType='STATUSNPG'
LEFT OUTER JOIN 
(
SELECT client_code,matter_number
,SUM(fees_total) AS RevenueAll
,SUM(paid_disbursements) + SUM(unpaid_disbursements) AS Disbs
,SUM(CASE WHEN bill_date BETWEEN @StartDate AND @EndDate THEN fees_total ELSE NULL END) AS RevenueMonth
,SUM(CASE WHEN bill_date BETWEEN @StartDate AND @EndDate THEN paid_disbursements ELSE NULL END)
+ SUM(CASE WHEN bill_date BETWEEN @StartDate AND @EndDate THEN unpaid_disbursements ELSE NULL END) AS DisbsMonth
,SUM(CASE WHEN bill_date BETWEEN @YearStart AND @EndDate THEN fees_total ELSE NULL END) AS RevenueYear
,SUM(CASE WHEN bill_date BETWEEN @YearStart AND @EndDate THEN paid_disbursements ELSE NULL END)
+ SUM(CASE WHEN bill_date BETWEEN @YearStart AND @EndDate THEN unpaid_disbursements ELSE NULL END) AS DisbsYear
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
WHERE client_code  IN ('W22559','WB164103','WB165100','W24159')
AND bill_reversed=0
GROUP BY client_code,matter_number

)AS Finances
 ON  Finances.client_code = dim_matter_header_current.client_code
 AND Finances.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client,matter,SUM(wip_value) AS WIPMonth FROM red_dw.dbo.fact_wip_monthly
WHERE client IN ('W22559','WB164103','WB165100','W24159')
AND wip_month=(SELECT fin_month FROM red_dw.dbo.dim_date WHERE CONVERT(DATE,calendar_date,103)=@StartDate)
GROUP BY client,matter) AS WIP
 ON dim_matter_header_current.client_code=WIP.client
 AND dim_matter_header_current.matter_number=WIP.matter
WHERE clNo IN ('W22559','WB164103','WB165100','W24159')
AND fileNo<>'0'

END
GO
