SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----SELECT * FROM VisualFiles.CabotPaymentHistory
CREATE PROCEDURE [VisualFiles].[CabotMonthlyDataBuild]
AS
BEGIN

DECLARE @Year AS INT
DECLARE @Month AS INT

SET @Year=YEAR(GetDate())
SET @Month=MONTH(getdate())

PRINT @Year
PRINT @Month

DECLARE @StartDate AS Date
DECLARE @EndDate AS Date
SET @StartDate=(SELECT CONVERT(Date,(CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),103)),103))
SET  @EndDate=(SELECT CONVERT(Date,(CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,GETDATE()))),DATEADD(mm,1,GETDATE())),103)),103))

PRINT @StartDate
PRINT @EndDate


DELETE FROM VisualFiles.CabotPaymentHistory
WHERE YearNumber=@Year
AND MonthNumber=@Month


   INSERT INTO VisualFiles.CabotPaymentHistory
   (
   mt_int_code,
   MonthNumber,
   YearNumber,
   [30DayStart],
   [60DayStart],
   EndDate,
   ArtiionOpenFile,
   CaseDateOpened,
   PaymentArrangementAmount,
   [30Amount],
   [60Amount],
   [Rehab],
   CurrrentBalance 
   ,AccountRehabilitated
   ,NoPayment30Days
   ,NoPayment60Days
   ,DefaultedAccount
   ,NumberAccounts
   ,ReportingStartDate
   )
   SELECT  mt_int_code,
   MonthNumber,
   YearNumber,
   [30DayStart],
   [60DayStart],
   EndDate,
   ArtiionOpenFile,
   CaseDateOpened,
   PaymentArrangementAmount,
   [30Amount],
   [60Amount],
   [Rehab],
   CurrrentBalance 
   ,CASE WHEN CaseDateOpened > DATEADD(DAY,1,EndDate) THEN 0 ELSE(CASE WHEN Rehab IS NULL AND [30Amount] >0 THEN 1 ELSE 0 END) END  AS AccountRehabilitated
   ,CASE WHEN CaseDateOpened > DATEADD(DAY,1,EndDate) THEN 0 ELSE (CASE WHEN [30Amount] IS NULL THEN 1 ELSE 0 END ) END AS NoPayment30Days
   ,CASE WHEN CaseDateOpened > DATEADD(DAY,1,EndDate) THEN 0 ELSE (CASE WHEN [60Amount] IS NULL THEN 1 ELSE 0 END ) END AS NoPayment60Days
   ,CASE WHEN CaseDateOpened > DATEADD(DAY,1,EndDate) THEN 0 ELSE(CASE WHEN [30Amount] IS NULL  AND PaymentArrangementAmount >0 THEN 1 ELSE 0 END) END  AS DefaultedAccount
   ,1 AS NumberAccounts
   ,ReportingStartDate
 
   FROM 
   (
   SELECT  AllData.mt_int_code,
   MonthNumber,
   YearNumber,
   [30DayStart],
   [60DayStart],
   EndDate,
   ArtiionOpenFile,
   CaseDateOpened,
   VFile_Streamlined.dbo.ReturnPaymentAmount(AllData.mt_int_code,[30DayStart],EndDate) AS [30Amount],
   VFile_Streamlined.dbo.ReturnPaymentAmount(AllData.mt_int_code,[60DayStart],EndDate) AS [60Amount],
   VFile_Streamlined.dbo.ReturnPaymentAmount(AllData.mt_int_code,[60DayStart],[30DayStart]) AS [Rehab],
   VFile_Streamlined.[dbo].[ReturnCurrentBalance](AllData.mt_int_code,ReportingStartDate) AS CurrrentBalance,
   PaymentArrangementAmount ,
   ReportingStartDate
   FROM 
   (SELECT  mt_int_code,
   MonthNumber,
   YearNumber,
   DATEADD(DAY,-30,EndDate) AS [30DayStart],
   DATEADD(DAY,-60,EndDate) AS [60DayStart],
   EndDate,
   ArtiionOpenFile,
   CaseDateOpened,
   ReportingStartDate,
   PaymentArrangementAmount
   FROM (SELECT   mt_int_code, MonthNum AS MonthNumber ,
   DATEADD(DAY,-1,CONVERT(DATE,'01/' +(CASE WHEN LEN(MonthNum)<2 THEN '0' +  CAST(MonthNum AS VARCHAR(2))  ELSE   CAST(MonthNum AS VARCHAR(2)) END) + '/' + CAST(YearNum AS VARCHAR(10)),103)) AS EndDate,
   DATEADD(DAY,0,CONVERT(DATE,'01/' +(CASE WHEN LEN(MonthNum)<2 THEN '0' +  CAST(MonthNum AS VARCHAR(2))  ELSE   CAST(MonthNum AS VARCHAR(2)) END) + '/' + CAST(YearNum AS VARCHAR(10)),103)) AS ReportingStartDate,
                                            YearNum AS YearNumber ,
                                            (CASE WHEN CaseDateOpened < DatePeriod
                                                          AND ( CaseDateClosed IS NULL
                                                              OR CaseDateClosed > DatePeriod
                                                              ) THEN 1
                                                     ELSE 0
                                                END) AS ArtiionOpenFile 
									,CaseDateOpened
									,PaymentArrangementAmount
                                  FROM      ( SELECT   DISTINCT
                                                        DATENAME(MONTH, Date)
                                                        + ' '
                                                        + CAST(YEAR(Date) AS VARCHAR(50)) AS Period ,
                                                        MONTH(Date) AS MonthNum ,
                                                        YEAR(Date) AS YearNum ,
                                                        1 AS Link ,
                                                        DATEADD(DAY, -1,
                                                              ( DATEADD(MONTH,
                                                              1,
                                                              CONVERT(DATE, CAST(YEAR(Date) AS VARCHAR(50))
                                                              + '-'
                                                              + CASE
                                                              WHEN LEN(CAST(MONTH(Date) AS VARCHAR(50))) < 2
                                                              THEN '0'
                                                              + CAST(MONTH(Date) AS VARCHAR(50))
                                                              ELSE CAST(MONTH(Date) AS VARCHAR(50))
                                                              END + '-01', 102)) )) AS DatePeriod ,
                                                        CONVERT(DATE, CAST(YEAR(Date) AS VARCHAR(50))
                                                        + '-'
                                                        + CASE
                                                              WHEN LEN(CAST(MONTH(Date) AS VARCHAR(50))) < 2
                                                              THEN '0'
                                                              + CAST(MONTH(Date) AS VARCHAR(50))
                                                              ELSE CAST(MONTH(Date) AS VARCHAR(50))
                                                          END + '-01', 102) AS PeriodStart
                                              FROM      dbo.PeriodDates
                                              WHERE     Date BETWEEN @StartDate AND @EndDate
                                            ) AS AllDates
                                            LEFT OUTER JOIN ( SELECT
                                                              mt_int_code ,
                                                              DateOpened AS CaseDateOpened ,
                                                              CLO_ClosedDate AS CaseDateClosed ,
                                                              CurrentBalance,
                                                              PaymentArrangementAmount,
                                                              1 AS Link
                                                              FROM VFile_Streamlined.dbo.AccountInformation 
                                                              WHERE ClientName='Cabot'
                                                            ) AS CaseDates ON AllDates.Link = CaseDates.Link
                                                            
    ) AS Files
  ) AS AllData

WHERE  AllData.ArtiionOpenFile=1


GROUP BY AllData.mt_int_code,
   MonthNumber,
   YearNumber,
   [30DayStart],
   [60DayStart],
   EndDate,
   ArtiionOpenFile,
   CaseDateOpened,
   ReportingStartDate,
   PaymentArrangementAmount
   
   ) AS FilteredData
    
                                                           ORDER BY FilteredData.mt_int_code,MonthNumber
    


END
GO
