SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  	CREATE PROCEDURE [dbo].[HSD_Summary_Objectives]
 
 AS
 BEGIN
  DECLARE @Month AS VARCHAR(max)='[Dim Bill Date].[Hierarchy].[Bill Fin Period].&[2021-10 (Feb-2021)] '
  --@Department AS VARCHAR(max) ='[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&[Motor]&[Legal Ops - Claims]&[Weightmans LLP]'

SELECT 
RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
,DaysConcludeLastBill.DaysLastBillToConclude
,DaystoDateClaimConcluded.DaysElapsedConcluded
,InitialReportSent.[Days to Send Initial Report]
,hist.hierarchylevel3hist AS Department
,hist.hierarchylevel4hist  AS Team

  
FROM
red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS hist ON hist.dim_fed_hierarchy_history_key=fact_dimension_main.dim_fed_hierarchy_history_key
INNER  JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
---------------------------------------------------------------------------------------------------------------------------------------------
----get the days between Date Opened and Last Bill Date for the current FY
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
		LEFT OUTER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key = fact_matter_summary_current.dim_last_bill_date_key

		WHERE 
		 hierarchylevel2hist='Legal Ops - Claims'
		 AND dim_matter_header_current.present_position in ('Final bill sent - unpaid', 'To be closed/minor balances to be clear') 
		 AND red_dw.dbo.dim_date.current_fin_ytd = 'Current'
		 AND dim_matter_header_current.reporting_exclusions=0
		 AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
		 --AND RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number = 'A3003/00011622'
) AS DaysConcludeLastBill ON DaysConcludeLastBill.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
----------------------------------------------------------------------------------------------------------------------------------------------
----get the days between Date Opened and Date Claim Concluded for the current FY (May-April)
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
		AND datecliam_concluded.current_fin_ytd = 'Current'
		 AND dim_matter_header_current.reporting_exclusions=0
		 AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
		 --AND RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number = 'A3003/00011622'
		) AS DaystoDateClaimConcluded  ON DaystoDateClaimConcluded.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
		--and '[Dim Bill Date].[Hierarchy].[Bill Fin Period].&['+fin_period+']' =@Month
		--AND '[Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+hierarchylevel3hist+']&[Legal Ops - Claims]&[Weightmans LLP]'=@Department

---------------------------------------------------------------------------------------------------------------------------------------------------------
		--get the days between Date Opened and Date Initial Report Sent within the current FY
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
		AND date_InitialReportSent.current_fin_ytd = 'Current'
			AND dim_matter_header_current.reporting_exclusions=0
			AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
			AND red_dw.dbo.dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report <> 'Yes'
			AND red_dw.dbo.dim_detail_core_details.do_clients_require_an_initial_report <> 'No'
		) AS InitialReportSent  ON InitialReportSent.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
WHERE
hierarchylevel2hist='Legal Ops - Claims'
AND hist.hierarchylevel3hist = 'Motor'
--AND red_dw.dbo.dim_date.current_fin_ytd = 'Current'
--AND RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number = 'A3003/00011622'
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)


	
END 


GO
