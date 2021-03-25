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
	CREATE PROCEDURE [dbo].[HSD_Summary_Objectives]	--'[Dim Bill Date].[Hierarchy].[Bill Fin Period].&[2021-10 (Feb-2021)]','[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&[Motor]&[Legal Ops - Claims]&[Weightmans LLP]'
 
	( 
	@Month AS VARCHAR(max) ,
	@Department VARCHAR (max) )

	AS
	BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	 
	IF OBJECT_ID('tempdb..#WriteOff') IS NOT NULL DROP TABLE #WriteOff

------------Testing-----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
 --DECLARE 
-- @Month AS VARCHAR(max)='[Dim Bill Date].[Hierarchy].[Bill Fin Period].&[2021-10 (Feb-2021)] ',
 --@Department AS VARCHAR(max) ='[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&[Motor]&[Legal Ops - Claims]&[Weightmans LLP]'


 SELECT
	 fact_write_off.[master_matter_number]
      ,fact_write_off.[master_client_code]
      --,[write_off_month] 
	  --,write_off_date
	  ,fin_year
	  --,fin_month_no
	  --,fin_period
	  ,dim_matter_header_current.dim_matter_header_curr_key
	      ,dim_fed_hierarchy_history.hierarchylevel3hist
		 -- ,RTRIM(dim_fed_hierarchy_history.hierarchylevel4hist) hierarchylevel4hist
		 --  ,CASE WHEN fact_write_off.write_off_type = 'NC' THEN 'Chargeable Time Not Billed'
			--WHEN  fact_write_off.write_off_type = 'BA' THEN 'Billing Adjustment'
			--WHEN  fact_write_off.write_off_type = 'WA' THEN 'WIP Adjustment' 
			--WHEN fact_write_off.write_off_type = 'P' THEN 'Purged Time' END AS write_off_type
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
--AND dim_matter_header_current.master_client_code  = '10015' AND dim_matter_header_current.master_matter_number = '3'

GROUP BY
 fact_write_off.[master_matter_number]
      ,fact_write_off.[master_client_code]
	  ,fin_year
	  ,dim_matter_header_current.dim_matter_header_curr_key
	  ,dim_fed_hierarchy_history.hierarchylevel3hist

	
 --------------------------------------------------------------------------------------

SELECT 
RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
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


  
FROM
red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS hist ON hist.dim_fed_hierarchy_history_key=fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
INNER  JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
LEFT OUTER JOIN #WriteOff ON #WriteOff.dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key


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
		 --hierarchylevel2hist='Legal Ops - Claims'
		 datecliam_concluded.current_fin_year = 'Current'
		 AND dim_matter_header_current.reporting_exclusions=0
		-- AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
		 
		 --AND RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number = 'A3003/00011622'
		) AS DaystoDateClaimConcluded  ON DaystoDateClaimConcluded.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
		--and '[Dim Bill Date].[Hierarchy].[Bill Fin Period].&['+fin_period+']' =@Month
		--AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department

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

---------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------
--LEFT OUTER JOIN
 --(   
--DECLARE  @Month AS VARCHAR(max)='[Dim Bill Date].[Hierarchy].[Bill Fin Period].&[2021-10 (Feb-2021)] '

		

--)AS TimeWriteOff
--ON TimeWriteOff.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key

  				

WHERE
hierarchylevel2hist='Legal Ops - Claims'
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+hist.hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department


	
END 

		
GO
