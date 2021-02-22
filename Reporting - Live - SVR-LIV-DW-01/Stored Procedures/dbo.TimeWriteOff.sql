SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2019-02-20
-- Description:	Time write off report

-- 2020/05/26 RH -  Amended to take into account new fact_write_off design
-- 2021/02/17 RH -  Amended to include write ups and downs
-- =============================================

CREATE PROCEDURE [dbo].[TimeWriteOff]
(
@FedCode AS VARCHAR(MAX)
,@Month AS VARCHAR(100)
,@Level as VARCHAR(100)
,@Report AS NVARCHAR(100)
)
AS


BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--DECLARE @FEDCode VARCHAR(MAX) = '126556,126961,50405,51723,53046,54374,55704,57033,58362,59691,61474,114549,119905,121477,121774,26483,37777,26484,37778' 
	--DECLARE @Month VARCHAR(100)= '2021-09 (Jan-2021)'
	--DECLARE @Level VARCHAR(100)='Firm'


--SELECT ListValue COLLATE Latin1_General_BIN ListValue INTO #FedCodeList FROM dbo.udt_TallySplit(',', @FedCode)



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

INSERT into #FedCodeList 
exec sp_executesql @sql
	end
	
	
	IF  @level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT into #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END



--SELECT * FROM #FedCodeList

SELECT [dim_transaction_date_key]
	  ,dim_write_off_date_key
	  ,fin_period
      ,[dim_client_key]
      ,fact_write_off.[client_code]
      ,fact_write_off.[matter_number]
      ,fact_write_off.[master_client_code]
      ,fact_write_off.[master_matter_number]
	  ,matter_description
	  ,client_name
	  ,dim_fed_hierarchy_history.fed_code
      ,[matter_owner]
	  ,matter_owner_full_name
	  , feeearner.display_name Fee_Earner
      ,dim_fed_hierarchy_history.hierarchylevel2hist
      ,dim_fed_hierarchy_history.hierarchylevel3hist
      ,RTRIM(dim_fed_hierarchy_history.hierarchylevel4hist) hierarchylevel4hist
      ,CASE WHEN LOWER(fee_arrangement)= 'annual retainer' OR LOWER(fee_arrangement)= 'contingent' OR LOWER(fee_arrangement)= 'internal / no charge' OR LOWER(fee_arrangement)= 'secondment' OR LOWER(fee_arrangement)= 'tbc/other'  THEN 'Other'
			WHEN LOWER(fee_arrangement)='hourly rate' THEN 'Hourly Rate'
			WHEN LOWER(fee_arrangement)='fixed fee/fee quote/capped fee' THEN 'Fixed Fee/Fee Quote/Capped Fee'
			--WHEN fee_arrangement is null THEN 'Not Specified'
			ELSE 'Other' END  [fee_arrangement]
	  ,fee_arrangement AS [original_fee_arrangement]
      ,date_opened_case_management
      ,date_closed_case_management
	  ,CASE WHEN fact_write_off.write_off_type = 'NC' THEN 'Chargeable Time Not Billed'
			WHEN  fact_write_off.write_off_type = 'BA' THEN 'Billing Adjustment'
			WHEN  fact_write_off.write_off_type = 'WA' THEN 'WIP Adjustment' 
			WHEN fact_write_off.write_off_type = 'P' THEN 'Purged Time' END AS write_off_type
		, CASE WHEN fact_write_off.write_off_type = 'NC' THEN 3
			WHEN  fact_write_off.write_off_type = 'BA' THEN 2
			WHEN  fact_write_off.write_off_type = 'WA' THEN 1
			WHEN fact_write_off.write_off_type = 'P' THEN 4 END AS write_off_type_order

	-- ****************************************
	-- Section below can be removed when new report goes live 
	-- ****************************************
	  ,CASE WHEN fin_period=@Month AND fact_write_off.write_off_type IN ('NC','P') THEN fact_write_off.bill_amt_wdn ELSE 0 END [mtd_work_amt]
	  ,CASE WHEN fin_period=@Month AND fact_write_off.write_off_type IN ('NC','P') THEN fact_write_off.bill_hrs_wdn ELSE 0 END [mtd_work_hrs]
	  ,CASE WHEN fin_period<=@Month AND fact_write_off.write_off_type IN ('NC','P') THEN fact_write_off.bill_amt_wdn ELSE 0 END [ytd_work_amt]
	  ,CASE WHEN fin_period<=@Month AND fact_write_off.write_off_type IN ('NC','P') THEN fact_write_off.bill_hrs_wdn ELSE 0 END [ytd_work_hrs]
	  
	  ,CASE WHEN fin_period=@Month AND fact_write_off.write_off_type NOT IN ('NC','P') THEN [bill_amt_wdn] ELSE 0 END [mtd_bill_amt_wdn]
	  ,CASE WHEN fin_period=@Month AND fact_write_off.write_off_type NOT IN ('NC','P') THEN [bill_hrs_wdn] ELSE 0 END [mtd_bill_hrs_wdn]
	  ,CASE WHEN fin_period<=@Month AND fact_write_off.write_off_type NOT IN ('NC','P') THEN [bill_amt_wdn]  ELSE 0 END [ytd_bill_amt_wdn]
	  ,CASE WHEN fin_period<=@Month AND fact_write_off.write_off_type NOT IN ('NC','P') THEN [bill_hrs_wdn] ELSE 0 END [ytd_bill_hrs_wdn]
	

	  ,CASE WHEN fin_period=@Month THEN ISNULL(fact_write_off.bill_amt_wdn,0) ELSE 0 END [mtd_value]
	  ,CASE WHEN fin_period=@Month THEN ISNULL(fact_write_off.bill_hrs_wdn,0) ELSE 0  END [mtd_hrs]
	  ,CASE WHEN fin_period<=@Month THEN ISNULL(fact_write_off.bill_amt_wdn,0) ELSE 0 END [ytd_value]
	  ,CASE WHEN fin_period<=@Month THEN ISNULL(fact_write_off.bill_hrs_wdn,0) ELSE 0 END [ytd_hrs]
	-- ****************************************
	-- ****************************************

	  ,CASE WHEN fin_period=@Month THEN fact_write_off.bill_amt_wdn ELSE 0 END [mtd_amt_wdn]
	  ,CASE WHEN fin_period=@Month THEN fact_write_off.bill_hrs_wdn ELSE 0 END [mtd_hrs_wdn]
	  ,CASE WHEN fin_period<=@Month THEN fact_write_off.bill_amt_wdn ELSE 0 END [ytd_amt_wdn]
	  ,CASE WHEN fin_period<=@Month THEN fact_write_off.bill_hrs_wdn ELSE 0 END [ytd_hrs_wdn]

	  ,CASE WHEN fin_period=@Month THEN fact_write_off.bill_amt_wup ELSE 0 END [mtd_amt_wup]
	  ,CASE WHEN fin_period=@Month THEN fact_write_off.bill_hrs_wup ELSE 0 END [mtd_hrs_wup]
	  ,CASE WHEN fin_period<=@Month THEN fact_write_off.bill_amt_wup ELSE 0 END [ytd_amt_wup]
	  ,CASE WHEN fin_period<=@Month THEN fact_write_off.bill_hrs_wup ELSE 0 END [ytd_hrs_wup]

      ,[write_off_month] 
	  ,write_off_date
	  ,fin_year
	  ,fin_month_no
	  ,fact_write_off.dim_fed_matter_owner_key AS [dim_fed_hierarchy_history_key]
     
   
FROM red_dw.dbo.fact_write_off
--from red_dw.dbo.reddw_fact_write_off_190402 fact_write_off
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
       ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_matter_owner_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  feeearner
       ON feeearner.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON fact_write_off.dim_matter_header_curr_key
       = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date on dim_date.dim_date_key=fact_write_off.dim_write_off_date_key

--INNER JOIN 
--(select dim_fed_hierarchy_history_key from
--(case 
--when @Level = 'Firm' then (select dim_fed_hierarchy_history_key from red_dw.dbo.dim_fed_hierarchy_history)
--when @Level = 'Individual' then (select ListValue as dim_fed_hierarchy_history_key from #FedCodeList)
--end) gfd

--) AS FedCode 

--ON FedCode.ListValue = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key 

WHERE 
dim_write_off_date_key>=20180501
and fin_year=(select  fin_year from red_dw.dbo.dim_date
				WHERE fin_period = @Month
				AND fin_day_in_month = 1 )
--AND fact_write_off_monthly.client_code = 'W19106' AND fact_write_off_monthly.matter_number = '00000002'
--and [matter_owner]='4972'




 --AND ISNULL(exclude_from_exceptions_reports, '') <> 'Yes'
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





--and dim_fed_hierarchy_history.dim_fed_hierarchy_history_key in 
--(
--select (case when @Level = 'Firm' then dim_fed_hierarchy_history.dim_fed_hierarchy_history_key else NULL END) 
--from red_dw.dbo.dim_fed_hierarchy_history
--union
--select (case when @Level IN ('Individual', 'Area Managed') then ListValue else null end) from #FedCodeList WHERE #FedCodeList.ListValue <> 'Unknown'

--)

--AND fact_write_off_monthly.write_off_type <> 'N'
--AND fact_write_off.write_off_type IN ('W','D')
AND fact_write_off.write_off_type IN ('WA','NC','BA','P')
AND CASE WHEN @Report='Total' THEN 1 
		 WHEN @Report=  CASE WHEN LOWER(fee_arrangement)= 'annual retainer' OR LOWER(fee_arrangement)= 'contingent' OR LOWER(fee_arrangement)= 'internal / no charge' OR LOWER(fee_arrangement)= 'secondment' OR LOWER(fee_arrangement)= 'tbc/other'  THEN 'Other'
			WHEN LOWER(fee_arrangement)='hourly rate' THEN 'Hourly Rate'
			WHEN LOWER(fee_arrangement)='fixed fee/fee quote/capped fee' THEN 'Fixed Fee/Fee Quote/Capped Fee'
			ELSE 'Other' END   THEN 1
			ELSE 0 END =1



END




GO
