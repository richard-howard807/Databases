SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*All time with chargeable and transaction type */

CREATE PROCEDURE [dbo].[TimeSearch_ChargeableHours]

(
@StartDate AS DATE,
@EndDate AS DATE
--@WrittenOff AS NVARCHAR(10)
)

AS

--DECLARE @StartDate AS DATE = GETDATE()-10,
--@EndDate AS DATE = GETDATE(), 
--@WrittenOff AS NVARCHAR(10) = 'Yes|No'

----SELECT ListValue  INTO #writtenoff FROM 	dbo.udt_TallySplit('|', @WrittenOff)

SELECT 

master_client_code + '-' + master_matter_number AS [Client Matter]
,client_name AS [Client Name]
,matter_description AS [Matter Description]
,TimeRecordedBy.name AS [Transaction Fee Earner]
,wipamt AS [WIP]
, SUM(CAST(fact_all_time_activity.minutes_recorded AS DECIMAL(10,2)))/60 [Chargeable Hours]
,TransDate.calendar_date AS [Transaction Date]
,PostDate.calendar_date  AS [Posting Date]
,[Written off?] = CASE WHEN dim_all_time_activity.transaction_type IN ('Written Off','Written Off Transaction') THEN 'Yes' ELSE 'No' END
,TransDate.fin_year
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
 JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
 JOIN red_dw.dbo.dim_fed_hierarchy_history AS TimeRecordedBy
 ON TimeRecordedBy.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
 LEFT JOIN red_dw.dbo.dim_date TransDate ON dim_transaction_date_key = TransDate.dim_date_key
 LEFT JOIN red_dw.dbo.dim_date PostDate ON dim_transaction_date_key = PostDate.dim_date_key
 LEFT JOIN red_dw.dbo.dim_all_time_activity  on dim_all_time_activity.dim_all_time_activity_key = fact_all_time_activity.dim_all_time_activity_key
 --JOIN #writtenoff ON CASE WHEN dim_all_time_activity.transaction_type IN ('Written Off','Written Off Transaction') THEN 'Yes' ELSE 'No' END = ListValue
 
 WHERE 1 = 1 --TransDate.fin_year = 2022
 AND fact_all_time_activity.chargeable_nonc_nonb = 'C' 
 AND fact_all_time_activity.reporting_exclusions = 0
 AND master_client_code + '-' + master_matter_number <> 'Unknown -Unknown '
 AND minutes_recorded >= 0
 AND TransDate.calendar_date BETWEEN @StartDate AND @EndDate
 --AND CASE WHEN dim_all_time_activity.transaction_type IN ('Written Off','Written Off Transaction') THEN 'Yes' ELSE 'No' END IN (@WrittenOff) 
 GROUP BY 
client_name
,master_client_code + '-' + master_matter_number 
,matter_description
,TimeRecordedBy.name
, wiphrs
,wipamt
,TransDate.calendar_date
,PostDate.calendar_date 
,CASE WHEN dim_all_time_activity.transaction_type IN ('Written Off','Written Off Transaction') THEN 'Yes' ELSE 'No' END
,TransDate.fin_year

ORDER BY TransDate.calendar_date


SELECT DISTINCT dim_all_time_activity.transaction_type  FROM red_dw.dbo.dim_all_time_activity

--SELECT * from #t1 WHERE TransactionDate <= '2021-11-30'
--SELECT * from #t1 WHERE TransactionDate > '2021-11-30'
GO
