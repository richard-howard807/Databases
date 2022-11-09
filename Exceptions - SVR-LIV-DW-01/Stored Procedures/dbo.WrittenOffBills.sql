SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[WrittenOffBills] -- EXEC  [dbo].[WrittenOffBills] 'KXH','Firm','2022-01-01','2022-10-25','Kevin Hansen','Kevin Hansen '
(
@FedCode AS VARCHAR(MAX)
,@Level AS VARCHAR(100)
,@StartDate AS DATE 
,@EndDate AS DATE
,@MatterOwner AS VARCHAR(MAX)
,@ClientPartner AS VARCHAR(MAX)
)
AS 

BEGIN
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2022-05-01'
--SET @EndDate='2022-10-17'


IF OBJECT_ID('tempdb..#MatterOwner') IS NOT NULL   DROP TABLE #MatterOwner
SELECT ListValue  INTO #MatterOwner FROM Reporting.dbo.[udt_TallySplit]('|', @MatterOwner)

IF OBJECT_ID('tempdb..#ClientPartner') IS NOT NULL   DROP TABLE #ClientPartner
SELECT ListValue  INTO #ClientPartner FROM Reporting.dbo.[udt_TallySplit]('|', @ClientPartner)

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



SELECT bill_number
,write_off_total 
,revenue_total
,ISNULL(hard_disb_total,0) + ISNULL(soft_disb_total,0) AS write_off_disbursements
,vat_total AS [write_off_vat]
,boa_total AS [write_off_boa_total]
,other_total AS [write_off_other]
,matter_owner_full_name AS [Matter Owner]
,client_partner_name AS [Client Partner]
,hierarchylevel2hist AS [Division]
,segment AS [Segment]
,sector AS Sector
,dim_matter_header_current.master_client_code AS Client
,dim_matter_header_current.master_matter_number AS Matter
,dim_client.client_name AS [Client Name]
,write_off_calendar_date 
--,DefaultPayor AS Payor
FROM red_dw.dbo.fact_bill_write_off
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_write_off.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_write_off_date
 ON dim_write_off_date.dim_write_off_date_key = fact_bill_write_off.dim_write_off_date_key
INNER JOIN #MatterOwner
 ON matter_owner_full_name=#MatterOwner.ListValue COLLATE DATABASE_DEFAULT

INNER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
INNER JOIN #ClientPartner
 ON dim_client.client_partner_name=#ClientPartner.ListValue COLLATE DATABASE_DEFAULT
--LEFT OUTER JOIN (SELECT InvNumber,STRING_AGG(CAST(DisplayName AS NVARCHAR(MAX)),',') AS DefaultPayor FROM TE_3E_Prod.dbo.InvMaster 
--INNER JOIN TE_3E_Prod.dbo.Payor
-- ON DefPayor=PayorIndex
--GROUP BY InvNumber
--)  AS Payor
-- ON bill_number=Payor.InvNumber COLLATE DATABASE_DEFAULT
WHERE CONVERT(DATE,write_off_calendar_date,103) BETWEEN @StartDate AND @EndDate
  AND dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
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
			END 
GO
