SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

















--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2020-10-01'
--SET @EndDate='2020-10-31'



CREATE PROCEDURE [Newcastle].[NPGSummary] -- EXEC [Newcastle].[NPGSummary] '2021-10 (Feb-2021)'
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
,red_dw.dbo.datetimelocal(dteCompletionD) AS dteCompletionD
,red_dw.dbo.datetimelocal(dbFile.Created) AS DateOpened
,red_dw.dbo.datetimelocal(fileClosed) AS [DateClosed]
,Finances.RevenueAll AS [TotalRevenue]
,Finances.Disbs AS [TotalDisbs]
,MatStat.cdDesc AS MatterStatus
,DATEDIFF(DAY,red_dw.dbo.datetimelocal(dbFile.Created),red_dw.dbo.datetimelocal(dteCompletionD)) AS ElapsedDaysToCompletion
,DATEDIFF(DAY,[red_dw].[dbo].[datetimelocal](dbFile.Created),[red_dw].[dbo].[datetimelocal](dteEngrDispatch)) AS [Days opened to Engrossment]
,CASE WHEN red_dw.dbo.datetimelocal(dteCompletionD) IS  NULL AND red_dw.dbo.datetimelocal(fileClosed) IS  NULL AND ISNULL(MatStat.cdDesc,'Live')='Live' THEN 1 ELSE 0 END AS LiveFiles
,CASE WHEN red_dw.dbo.datetimelocal(dbFile.Created) BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS NewInstructionsMonth
,CASE WHEN red_dw.dbo.datetimelocal(dbFile.Created) BETWEEN @YearStart AND @EndDate THEN 1 ELSE 0 END AS YTDNewInstructions
,CASE WHEN MatStat.cdDesc='On Hold'  AND dteCompletionD IS NULL THEN 1 ELSE 0 END AS [Abeyance]
,CASE WHEN red_dw.dbo.datetimelocal(dteCompletionD) BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS CompletedMonth
,CASE WHEN red_dw.dbo.datetimelocal(dteCompletionD) BETWEEN @YearStart AND @EndDate  THEN 1 ELSE 0 END AS YTDCompletions
,CASE WHEN red_dw.dbo.datetimelocal(dteCompletionD) IS  NULL AND red_dw.dbo.datetimelocal(fileClosed) IS  NULL AND 
DATEDIFF(MONTH,dbFile.Created,@EndDate) >60  AND dteCompletionD IS NULL AND ISNULL(MatStat.cdDesc,'Live')='Live' AND ISNULL(MatStat.cdDesc,'')<>'On Hold' THEN 1 ELSE 0 END  AS SlowMoving
,CASE WHEN red_dw.dbo.datetimelocal(dteCompletionD) BETWEEN @StartDate AND @EndDate  THEN Finances.RevenueAll ELSE NULL END AS [CostOfCase]
,CASE WHEN red_dw.dbo.datetimelocal(dteCompletionD) BETWEEN @StartDate AND @EndDate THEN DATEDIFF(DAY,red_dw.dbo.datetimelocal(dbFile.Created),red_dw.dbo.datetimelocal(dteCompletionD)) ELSE NULL END AS AvergeCompletedMonth
,Finances.RevenueYear  AS [ExpenditureYTD]
,Finances.RevenueMonth  AS [ExpenditureMonth]
,Finances.DisbsYear  AS [DisbursementsYTD]
,Finances.DisbsMonth  AS [DisbursementsMonth]
,WIPMonth AS [WIPMonth]
,WIPYTD AS [WIPYTD] --SELECT * FROM red_dw.dbo.fact_wip_monthly
,CASE WHEN CRSystemSourceID LIKE '164103%' OR CRSystemSourceID LIKE '165100%' THEN 'North East'
WHEN CRSystemSourceID LIKE '164107%' OR CRSystemSourceID LIKE '165102%' THEN 'Yorkshire'
WHEN clno IN ('W22559','WB164106','WB165103','WB170376') THEN 'Yorkshire'
WHEN clno IN ('WB164103','WB165100','W24159') THEN 'North East'END  AS [Area]
,@StartDate AS ReportDate
,work_type_name
,cboNPGFileType
,dteEngrDispatch
,cboInsTypeNPG
,usrFullName AS [Case Handler] 
,fileType.cdDesc AS [Case type]
,cboNPGFileType AS Team

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
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS Insttype
ON cboInsTypeNPG=Insttype.cdCode AND Insttype.cdType='INSTYPENPG'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS MatStat
ON cboMatterStat=MatStat.cdCode AND MatStat.cdType='STATUSNPG'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS FileType
ON filetype=FileType.cdCode AND FileType.cdType='FILETYPE'
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
WHERE client_code  IN ('W22559','WB164106','WB165103','WB170376','WB164103','WB165100','W24159')
AND bill_reversed=0
GROUP BY client_code,matter_number

)AS Finances
 ON  Finances.client_code = dim_matter_header_current.client_code
 AND Finances.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client,matter,SUM(wip_value) AS WIPMonth FROM red_dw.dbo.fact_wip_monthly
WHERE client IN ('W22559','WB164106','WB165103','WB170376','WB164103','WB165100','W24159')
AND wip_month=(SELECT fin_month FROM red_dw.dbo.dim_date WHERE CONVERT(DATE,calendar_date,103)=@StartDate)
GROUP BY client,matter) AS WIP
 ON dim_matter_header_current.client_code=WIP.client
 AND dim_matter_header_current.matter_number=WIP.matter
LEFT OUTER JOIN 
(
SELECT client_code,matter_number,SUM(time_charge_value) AS WIPYTD FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_transaction_date
 ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
WHERE client_code  IN ('W22559','WB164106','WB165103','WB170376','WB164103','WB165100','W24159')
AND dim_bill_key=0
AND isactive=1
GROUP BY client_code,matter_number
) AS WIPYTD
 ON WIPYTD.client_code = dim_matter_header_current.client_code
 AND  WIPYTD.matter_number = dim_matter_header_current.matter_number
WHERE clNo IN ('W22559','WB164106','WB165103','WB170376','WB164103','WB165100','W24159')
AND fileNo<>'0'
AND ISNULL(cboInsTypeNPG,'') NOT IN 
(
'INSTYPE001','INSTYPE002','INSTYPE003','INSTYPE004','INSTYPE005','INSTYPE006' 
)
AND dbFile.fileID<>5197870
END
GO
