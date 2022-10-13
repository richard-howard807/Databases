SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2021-03-10
Description:		This is to drive part of the monthly HSD summary Report 
Current Version:	Initial Create
====================================================

====================================================

*/
	CREATE PROCEDURE [dbo].[HSD_Summary_Objectives]	--'[Dim Bill Date].[Hierarchy].[Bill Fin Period].&[2022-01 (May-2022)]','[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&[Motor]&[Legal Ops - Claims]&[Weightmans LLP]'
 
	( 
	@Month AS VARCHAR(max) ,
	@Department VARCHAR (max) )

	AS
	BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
Declare
	@FinMonthPrev AS INT = (SELECT fin_month FROM red_dw.dbo.dim_date
	WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(mm,-1,DATEADD(MONTH,-1,GETDATE())),103)) ,
	@FinMonth AS int=(SELECT fin_month FROM red_dw.dbo.dim_date
	WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(MONTH,-1,GETDATE()),103)) 
	 
	IF OBJECT_ID('tempdb..#WriteOff') IS NOT NULL DROP TABLE #WriteOff
	IF OBJECT_ID('tempdb..#TotalExceptions') IS NOT NULL DROP TABLE #TotalExceptions
	IF OBJECT_ID('tempdb..#MIexceptionsreducedfrom2to1') IS NOT NULL DROP TABLE #MIexceptionsreducedfrom2to1  
	IF OBJECT_ID('tempdb..#FraudIndicatorchecklist') IS NOT NULL DROP TABLE #FraudIndicatorchecklist
	IF OBJECT_ID('tempdb..#CMDebt180Days') IS NOT NULL DROP TABLE #CMDebt180Days

------------------------------------------------------------------------------------------------------------------
---Current Month Debt >180 days------------------------------------------------------------------------------------------
--DECLARE  @FinMonth AS int=(SELECT fin_month FROM red_dw.dbo.dim_date
--WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(MONTH,-1,GETDATE()),103)) ,
 --@Department AS VARCHAR(MAX)= '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&[Motor]&[Legal Ops - Claims]&[Weightmans LLP]'

SELECT 
master_fact_key
,financial_date
,SUM(outstanding_total_bill) AS [Month Debt Over 180 Days]
,dim_fed_hierarchy_history.hierarchylevel3hist

INTO #CMDebt180Days

FROM red_dw.dbo.fact_debt_monthly
LEFT OUTER JOIN red_dw.dbo.dim_days_banding ON dim_days_banding.dim_days_banding_key = fact_debt_monthly.dim_days_banding_key
INNER JOIN red_dw.dbo.dim_date ON dim_transaction_date_key=dim_date_key
AND fact_debt_monthly.debt_month=@FinMonth ---this is current Month Debt >180 days
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = FACT_DEBT_MONTHLY.dim_fed_matter_owner_key

WHERE  daysbanding='Greater than 180 Days'
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+dim_fed_hierarchy_history.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department

GROUP BY 
master_fact_key
,financial_date
,dim_fed_hierarchy_history.hierarchylevel3hist
 
HAVING SUM(outstanding_total_bill) >0
				--) AS [Debt] ON Debt.client_group_name = dim_client.client_group_name

------------Testing-----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- DECLARE 
-- @Month AS VARCHAR(max)='[Dim Bill Date].[Hierarchy].[Bill Fin Period].&[2021-09 (Jan-2021)] ',
--@Department AS VARCHAR(max) ='[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&[Motor]&[Legal Ops - Claims]&[Weightmans LLP]'

----------------------------------------------------------------------------------------------------------------------------------

 -----------------------------------------------------------------------------------------------------------------------------------
 --------Write offs--------------------------------------------------------------------------------------------------------------------
 SELECT
RTRIM(fact_write_off.master_client_code)+'/'+fact_write_off.[master_matter_number] AS [Weightmans Reference]
	 ,fact_write_off.[master_matter_number]
      ,fact_write_off.[master_client_code]
	  ,fin_year
	  ,dim_matter_header_current.dim_matter_header_curr_key
	      ,dim_fed_hierarchy_history.hierarchylevel3hist
		 ,SUM(CASE WHEN fin_period<=@Month THEN ISNULL(fact_write_off.bill_amt_wdn,0) ELSE 0 END )[ytd_value_Total]
		 ,SUM(CASE WHEN fin_period<=@Month AND  fact_write_off.write_off_type = 'WA' THEN ISNULL(fact_write_off.bill_amt_wdn,0) ELSE 0 END) [ytd_value_WIP_Adjustment]
  INTO #WriteOff   
   
FROM red_dw.dbo.fact_write_off
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
       ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_matter_owner_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  feeearner
       ON feeearner.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON fact_write_off.dim_matter_header_curr_key
       = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date on dim_date.dim_date_key=fact_write_off.dim_write_off_date_key

WHERE
dim_write_off_date_key>=20180501
AND'[Dim Bill Date].[Hierarchy].[Bill Fin Period].&['+fin_period+']' <=@Month
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
AND dim_date.current_fin_year = 'Current'
AND fact_write_off.write_off_type IN ('WA','NC','BA','P')	
AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+dim_fed_hierarchy_history.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department

GROUP BY
RTRIM(fact_write_off.master_client_code)+'/'+fact_write_off.[master_matter_number]
 ,fact_write_off.[master_matter_number]
      ,fact_write_off.[master_client_code]
	  ,fin_year
	  ,dim_matter_header_current.dim_matter_header_curr_key
	  ,dim_fed_hierarchy_history.hierarchylevel3hist

------------------------------------------------	MI exceptions reduced from 2 to 1 --------------- 



SELECT 
       hir.employeeid AS Employeed_ID,
       hir.hierarchylevel3hist AS Department,
       SUM(no_of_exceptions) no_of_exceptions  
INTO  #TotalExceptions
FROM Exceptions.dbo.MI_Management_firm_wide
		JOIN red_dw.dbo.dim_fed_hierarchy_history hir
        ON MI_Management_firm_wide.employeeid = hir.employeeid AND hir.dss_current_flag = 'Y'  AND hir.activeud = 1
		JOIN red_dw.dbo.dim_employee 
		ON dim_employee.dim_employee_key = hir.dim_employee_key  AND (leaverlastworkdate IS NULL OR leaverlastworkdate > GETDATE())
WHERE hir.hierarchylevel2hist  IN ( 'Legal Ops - Claims' )
AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+hir.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department
GROUP BY hir.hierarchylevel3hist, hir.employeeid


SELECT 
       Department,
       SUM(no_of_exceptions)  no_of_exceptions,
	   SUM(ISNULL(critria_cases,0)) critria_cases,
	   CAST(SUM(CAST(ISNULL(no_of_exceptions, 0) AS DECIMAL))  /  SUM(CAST(ISNULL(critria_cases,0) AS DECIMAL)) AS DECIMAL( 18, 2)) [Average Exceptions Per  Matter (Open\Closed)]
 INTO #MIexceptionsreducedfrom2to1
FROM #TotalExceptions
    LEFT JOIN (SELECT dim_fed_hierarchy_history.employeeid,
	    COUNT(dim_matter_header_current.ms_fileid) critria_cases
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.dim_detail_core_details
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
    LEFT JOIN red_dw.dbo.dim_detail_outcome
        ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE fact_dimension_main.client_code <> 'ml'
      AND 1 = 1
    and  referral_reason LIKE 'Dispute%' AND 
(
	date_claim_concluded IS NULL  OR 
	date_claim_concluded >= '2017-01-01'  
)  AND dim_matter_header_current.reporting_exclusions = 0    AND 
LOWER(ISNULL(outcome_of_case, '')) NOT in ('exclude from reports','returned to client')  AND 
(date_closed_case_management >= '2017-01-01' OR date_closed_case_management IS NULL
)   AND employeeid NOT IN ('D7FCD8D2-A936-472A-8CEB-1BCBECFF65B9','49452DCE-A032-42C2-B328-AFCFE1079561','A7C4010A-8F29-4058-A11E-220C5461036F') AND 
(dim_matter_header_current.ms_only = 1  ) AND hierarchylevel2hist = 'Legal Ops - Claims' AND work_type_code <> '0032'
GROUP BY dim_fed_hierarchy_history.employeeid ) #critria_cases
        ON #critria_cases.employeeid = #TotalExceptions.Employeed_ID
GROUP BY Department




------------------------------Fraud Indicator checklist @ 95%--------------------------------

 SELECT DISTINCT
		
		 dim_fed_hierarchy_history.hierarchylevel3hist AS Department,

		/*SUM(Fields!countscore.Value)/SUM(Fields!Number_of_Matters.Value) from Process/Fraud Indicator Results Summary*/
	CAST(CAST(SUM(CASE WHEN totalpointscalc IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY dim_fed_hierarchy_history.hierarchylevel3hist) AS DECIMAL(18,2)) 
		/ SUM(CASE WHEN 
	    dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
		AND LOWER(dim_detail_core_details.referral_reason) LIKE '%dispute%'
		AND dim_detail_core_details.suspicion_of_fraud ='No'
		AND dim_matter_worktype.work_type_group IN ('EL','PL All','Motor','Disease') 
		AND (DATEDIFF(DAY,date_opened_case_management, GETDATE())>=14 OR totalpointscalc IS NOT null)
		THEN 1 ELSE 0 END) OVER (PARTITION BY dim_fed_hierarchy_history.hierarchylevel3hist) AS DECIMAL(18,2))  AS [Fraud Checklist Complete %]
	INTO #FraudIndicatorchecklist
	FROM 
	red_dw.dbo.fact_dimension_main
	JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key  
	JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'  AND GETDATE() BETWEEN dss_start_date AND dss_end_date AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'AND leaver=0
	JOIN red_dw.dbo.dim_detail_outcome ON fact_dimension_main.dim_detail_outcome_key = dim_detail_outcome.dim_detail_outcome_key
	JOIN red_dw..dim_detail_core_details ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	JOIN red_dw.dbo.ds_sh_ms_udficcommon ON fileid = ms_fileid
	
	WHERE 1 = 1

		AND dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
		AND LOWER(referral_reason) LIKE '%dispute%'
	    AND suspicion_of_fraud ='No'
		AND work_type_group IN ('EL','PL All','Motor','Disease')
		AND (DATEDIFF(DAY,date_opened_case_management, GETDATE())>=14 OR totalpointscalc IS NOT null)
		AND LOWER(ISNULL(dim_detail_outcome.outcome_of_case,''))<>'exclude from reports'
		AND ISNULL(dim_matter_worktype.work_type_code,'')<>'1603'
		AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+dim_fed_hierarchy_history.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department
 









 ----------Main Code----------------------------------------------------------------------

SELECT 
RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference_]
--,RTRIM(dim_matter_header_current.master_client_code)+'/'+dim_matter_header_current.master_matter_number AS [Weightmans Reference]
,DaysConcludeLastBill.DaysLastBillToConclude
,DaystoDateClaimConcluded.DaysElapsedConcluded
,InitialReportSent.[Days to Send Initial Report]
,[Indemnity Spend]
,CY_Revenue
,hist.hierarchylevel3hist AS Department
,hist.hierarchylevel4hist  AS Team
,client_group_name
,client_name
,red_dw.dbo.fact_matter_summary_current.client_code
,red_dw.dbo.fact_finance_summary.wip AS CurrentWIP
, DaysConcludeLastBill.fin_period
,'[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+hist.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]' AS ParameterValue
,[ytd_value_Total]
,[ytd_value_WIP_Adjustment]
,[Average Exceptions Per  Matter (Open\Closed)]
,[Fraud Checklist Complete %]
, SUBSTRING(@Month, LEN(LEFT(@Month, CHARINDEX ('(', @Month))) + 1, LEN(@Month) - LEN(LEFT(@Month, 
    CHARINDEX ('(', @Month))) - LEN(RIGHT(@Month, LEN(@Month) - CHARINDEX (')', @Month))) - 1) AS [Month] 
 ,[Prior Month Debt Over 180 Days]
 ,[Month Debt Over 180 Days]
  
FROM
red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS hist ON hist.dim_fed_hierarchy_history_key=fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
left  JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
LEFT OUTER JOIN #WriteOff ON #WriteOff.dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN #MIexceptionsreducedfrom2to1 ON hist.hierarchylevel3hist  = #MIexceptionsreducedfrom2to1.Department
LEFT JOIN #FraudIndicatorchecklist ON hist.hierarchylevel3hist  = #MIexceptionsreducedfrom2to1.Department
LEFT JOIN #CMDebt180Days ON #CMDebt180Days.master_fact_key = fact_dimension_main.master_fact_key
---------------------------------------------------------------------------------------------------------------------------------------------
----1 get the days between Date Opened and Last Bill Date for the current FY
----------------------------------------------------------------------------------------------------------------------------------------------
	 LEFT OUTER JOIN (
		SELECT 
		RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		--,AVG(DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,fact_bill_matter.last_bill_date )) AS AverageDaysToConclude
		,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,fact_bill_matter.last_bill_date ) AS DaysLastBillToConclude
		--,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,date_claim_concluded ) AS DaysElapsedConcluded
		,dim_matter_header_current.date_closed_case_management
		,dim_detail_core_details.present_position
		,hierarchylevel3hist AS Department
		,hierarchylevel4hist  AS Team
		,dim_date.fin_period
		,dim_matter_header_current.date_opened_case_management
		,fact_bill_matter.last_bill_date
		,fact_dimension_main.dim_matter_header_curr_key
		, ISNULL(damages_paid,0) + ISNULL(claimants_costs_paid,0)	+ ISNULL(total_amount_billed,0) -ISNULL(vat_billed,0)   AS [Indemnity Spend]

		FROM 
		red_dw.dbo.fact_dimension_main
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.master_fact_key= fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = red_dw.dbo.dim_matter_header_current.fee_earner_code
					  AND red_dw.dbo.dim_fed_hierarchy_history.dss_current_flag = 'Y'
					  AND GETDATE() BETWEEN dss_start_date AND dss_end_date
		LEFT OUTER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key = fact_matter_summary_current.dim_last_bill_date_key

		WHERE 
		 hierarchylevel2hist='Legal Ops - Claims'
		 AND dim_matter_header_current.present_position in ('Final bill sent - unpaid', 'To be closed/minor balances to be clear') 
		 AND red_dw.dbo.dim_date.current_fin_year = 'Current'
		 AND dim_matter_header_current.reporting_exclusions=0
		 AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
		 --AND RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number = 'A3003/00011622'
) AS DaysConcludeLastBill ON DaysConcludeLastBill.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
----------------------------------------------------------------------------------------------------------------------------------------------
----2 get the days between Date Opened and Date Claim Concluded for the current FY (May-April)
----------------------------------------------------------------------------------------------------------------------------------------------
LEFT OUTER JOIN
		(SELECT 
		 RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,date_claim_concluded ) AS DaysElapsedConcluded
		,hierarchylevel3hist AS Department
		,hierarchylevel4hist  AS Team
		,datecliam_concluded.fin_period
		,fact_dimension_main.dim_matter_header_curr_key
		,date_claim_concluded
		


		FROM 
		red_dw.dbo.fact_dimension_main
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.master_fact_key= fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = red_dw.dbo.dim_matter_header_current.fee_earner_code
					  AND red_dw.dbo.dim_fed_hierarchy_history.dss_current_flag = 'Y'
					  AND GETDATE() BETWEEN dss_start_date AND dss_end_date
		LEFT OUTER JOIN red_dw.dbo.dim_date as datecliam_concluded ON  CAST(datecliam_concluded.calendar_date AS DATE) = CAST(dim_detail_outcome.date_claim_concluded AS DATE) 

		WHERE 
		 hierarchylevel2hist='Legal Ops - Claims'
		 AND datecliam_concluded.current_fin_year = 'Current'
		 AND dim_matter_header_current.reporting_exclusions=0

		) AS DaystoDateClaimConcluded  ON DaystoDateClaimConcluded.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key


---------------------------------------------------------------------------------------------------------------------------------------------------------
		-- 3 get the days between Date Opened and Date Initial Report Sent within the current FY
------------------------------------------------------------------------------------------------------------------------------------------------------------
 LEFT OUTER JOIN
		(SELECT 
			RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,date_initial_report_sent ) AS [Days to Send Initial Report] 
		,hierarchylevel3hist AS Department
		,hierarchylevel4hist  AS Team
		,date_InitialReportSent.fin_period
		,fact_dimension_main.dim_matter_header_curr_key
		,date_initial_report_sent


		FROM 
		red_dw.dbo.fact_dimension_main
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.master_fact_key= fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = red_dw.dbo.dim_matter_header_current.fee_earner_code
						AND red_dw.dbo.dim_fed_hierarchy_history.dss_current_flag = 'Y'
						AND GETDATE() BETWEEN dss_start_date AND dss_end_date
		LEFT OUTER JOIN red_dw.dbo.dim_date as date_InitialReportSent ON  CAST(date_InitialReportSent.calendar_date AS DATE)  = CAST(date_initial_report_sent AS DATE) 

		WHERE 
			hierarchylevel2hist='Legal Ops - Claims'
		AND date_InitialReportSent.current_fin_year = 'Current'
			AND dim_matter_header_current.reporting_exclusions=0
			AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
			AND red_dw.dbo.dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report <> 'Yes'
			AND red_dw.dbo.dim_detail_core_details.do_clients_require_an_initial_report <> 'No'
		) AS InitialReportSent  ON InitialReportSent.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key

------------------------------------------------------------------------------------------------------------------------------------------------------------------
	 --Revenue billed in the current FY
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
LEFT OUTER JOIN
(
		SELECT fact_bill_activity.client_code
		, fact_bill_activity.matter_number
		, SUM(fact_bill_activity.bill_amount) CY_Revenue
	
		FROM red_dw.dbo.fact_bill_activity
		INNER JOIN red_dw.dbo.dim_bill_date ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
		WHERE
		bill_current_fin_year = 'Current'
		AND  bill_amount <>0
		AND client_code = '00752920' --	this is for Armour only
		

		GROUP BY fact_bill_activity.client_code, fact_bill_activity.matter_number 	 ) AS CYRevenueBilled 
ON CYRevenueBilled.client_code = dim_matter_header_current.client_code AND CYRevenueBilled.matter_number = dim_matter_header_current.matter_number



----------------------------------------------------------------------------------------------------------------------
--------------------Prior Month Debt >180 days----------------------------------------------------------------------------------------------------
LEFT OUTER JOIN (
   
SELECT 
master_fact_key
,financial_date
,SUM(outstanding_total_bill) AS [Prior Month Debt Over 180 Days]
,dim_fed_hierarchy_history.hierarchylevel3hist

FROM red_dw.dbo.fact_debt_monthly
LEFT OUTER JOIN red_dw.dbo.dim_days_banding ON dim_days_banding.dim_days_banding_key = fact_debt_monthly.dim_days_banding_key
INNER JOIN red_dw.dbo.dim_date ON dim_transaction_date_key=dim_date_key
AND fact_debt_monthly.debt_month=@FinMonthPrev ---this is previous Month Debt >180 days
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = FACT_DEBT_MONTHLY.dim_fed_matter_owner_key

WHERE  daysbanding='Greater than 180 Days'
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+dim_fed_hierarchy_history.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department
--AND'[Dim Bill Date].[Hierarchy].[Bill Fin Period].&['+fin_period+']' =@Month
GROUP BY 
master_fact_key
,financial_date
,dim_fed_hierarchy_history.hierarchylevel3hist
 
HAVING SUM(outstanding_total_bill) >0
				) AS [Debt] ON Debt.master_fact_key = fact_dimension_main.master_fact_key



WHERE
hierarchylevel2hist='Legal Ops - Claims'
AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+hist.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department


	
END 

GO
