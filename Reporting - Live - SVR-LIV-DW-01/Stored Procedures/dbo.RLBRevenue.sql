SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE PROCEDURE [dbo].[RLBRevenue]
(
@FedCode AS VARCHAR(MAX)
,@Level AS VARCHAR(100)
,@Period AS NVARCHAR(MAX)
)
AS 

BEGIN
--DECLARE @Period AS NVARCHAR(500)
--SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,GETDATE(),103))
--PRINT @Period

DROP TABLE  IF EXISTS #FedCodeList
    	CREATE TABLE #FedCodeList  (
ListValue  NVARCHAR(MAX)
)
IF @level  <> 'Individual'
	BEGIN
	PRINT ('not Individual')
DECLARE @sql NVARCHAR(MAX)

SET @sql = '
use red_dw;
DECLARE @nDate AS DATE = GETDATE()

SELECT DISTINCT
dim_fed_hierarchy_history_key
FROM red_Dw.dbo.dim_fed_hierarchy_history 
WHERE dim_fed_hierarchy_history_key IN ('+@FedCode+')'

INSERT INTO #FedCodeList 
EXEC sp_executesql @sql
	END
	
	
	IF  @level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT INTO #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END

IF OBJECT_ID(N'tempdb..#RLBRevenue') IS NOT NULL
BEGIN
DROP TABLE #RLBRevenue
END

SELECT 
ttk AS [FE]
,tkfirst +' ' +tklast AS [Fe Name]
,tbilldt AS [Bill Date]
,SUM(tbilldol) AS Revenue
,SUM(tbillhrs) AS BilledHours
INTO #RLBRevenue
FROM [lon-elite1].son_db.dbo.timecard WITH(NOLOCK)
LEFT OUTER JOIN [lon-elite1].son_db.dbo.timekeep  WITH(NOLOCK)
 ON ttk=tkinit
WHERE tbilldt>='2022-06-01'

--WHERE tinvoice IN 
--(
--SELECT DISTINCT linvoice FROM [lon-elite1].son_db.dbo.ledger  WITH(NOLOCK)
--WHERE (((ledger.llcode)='FEES') AND ((ledger.lzero)<>'R'))
--AND ltradat>='2022-06-01'
--)
GROUP BY tkfirst + ' ' + tklast,
         ttk,
         tbilldt
--SELECT 
--MSupaty AS [FE]
--,tkfirst +' ' +tklast AS [Fe Name]
--,ltradat AS [Bill Date]
--, SUM(ledger.lamount) AS Revenue
--INTO #RLBRevenue
--FROM [lon-elite1].son_db.dbo.ledger
--INNER JOIN [lon-elite1].son_db.dbo.matter
-- ON lmatter=mmatter
--LEFT OUTER JOIN [lon-elite1].son_db.dbo.timekeep  WITH(NOLOCK)
-- ON MSupaty=timekeep.tkinit
--WHERE (((ledger.llcode)='FEES') AND ((ledger.lzero)<>'R'))
--AND ltradat>'2022-05-01'
--GROUP BY tkfirst + ' ' + tklast,
--         msupaty,
--         ltradat


DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

PRINT @FinMonth


SELECT #RLBRevenue.FE
,#RLBRevenue.[Fe Name]
,fed_code	
,ISNULL(display_name,#RLBRevenue.[Fe Name]) AS display_name
,employeeid
,ISNULL(hierarchylevel2hist,'Unknown') AS [Business Line]
,ISNULL(hierarchylevel3hist,'Unknown') AS [Practice Area]
,ISNULL(hierarchylevel4hist,'Unknown') AS [Team]
,SUM(CASE WHEN fin_month_no=@FinMonth THEN Revenue ELSE 0 END) AS CurrentMonth
,SUM(CASE WHEN fin_year=@FinYear AND fin_month_no<=@FinMonth THEN  Revenue ELSE 0 END) AS YTD
,SUM(CASE WHEN fin_month_no=@FinMonth THEN BilledHours ELSE 0 END) AS CurrentMonthHrs
,SUM(CASE WHEN fin_year=@FinYear AND fin_month_no<=@FinMonth THEN  BilledHours ELSE 0 END) AS YTDHrs
 FROM #RLBRevenue
 INNER JOIN red_dw.dbo.dim_date
 ON CONVERT(DATE,[Bill Date],103)=CONVERT(DATE,calendar_date,103)
 LEFT OUTER JOIN RLBStaff141022 
  ON #RLBRevenue.FE=RLBStaff141022.FE
 LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
  ON fed_code=FEDCode COLLATE DATABASE_DEFAULT AND dss_current_flag='Y' 
WHERE   ISNULL(dim_fed_hierarchy_history.dim_fed_hierarchy_history_key,0) IN
              (
                  SELECT (CASE
                              WHEN @Level = 'Firm' THEN
                                  dim_fed_hierarchy_history_key
                              ELSE
                                  0
                          END
                         )
                  FROM red_dw.dbo.dim_fed_hierarchy_history
                  UNION
                  SELECT  (CASE
                              WHEN @Level IN ( 'Individual' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
                  UNION
                  SELECT (CASE
                              WHEN @Level IN ( 'Area Managed' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
              )
	
			GROUP BY ISNULL(display_name, #RLBRevenue.[Fe Name]),
         ISNULL(hierarchylevel2hist, 'Unknown'),
         ISNULL(hierarchylevel3hist, 'Unknown'),
         ISNULL(hierarchylevel4hist, 'Unknown'),
         #RLBRevenue.FE,
         #RLBRevenue.[Fe Name],
         fed_code,
         employeeid

END 
GO
