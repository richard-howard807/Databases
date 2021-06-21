SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[RealEstateKPIReports] -- EXEC RealEstateKPIReports '6034'
(
@FeeEarner AS NVARCHAR(MAX)
,@Client AS NVARCHAR(MAX)
)

AS 

BEGIN

IF OBJECT_ID('tempdb..#FeeEarner') IS NOT NULL   DROP TABLE #FeeEarner
SELECT ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit('|', @FeeEarner)

IF OBJECT_ID('tempdb..#Client') IS NOT NULL   DROP TABLE #Client
SELECT ListValue  INTO #Client FROM 	dbo.udt_TallySplit('|', @Client)

IF OBJECT_ID('tempdb..#Exchange') IS NOT NULL DROP TABLE #Exchange
IF OBJECT_ID('tempdb..#Completion') IS NOT NULL DROP TABLE #Completion




SELECT fileID,MAX(red_dw.dbo.datetimelocal(tskCompleted)) AS ExchangeDateCompleted
INTO #Exchange
FROM MS_Prod.dbo.dbTasks WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE tskFilter IN ('tsk_04_010_rem_cont_exch') 
AND master_client_code IN ('190593P', '153838M','848629','W15353')
AND tskActive=1 AND tskComplete=1
GROUP BY fileID



SELECT fileID,MAX(red_dw.dbo.datetimelocal(tskCompleted)) AS CompletionDateCompleted
INTO #Completion
FROM MS_Prod.dbo.dbTasks WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE tskFilter IN ('tsk_05_010_est_comp_today') 
AND master_client_code IN ('190593P', '153838M','848629','W15353')
AND tskActive=1 AND tskComplete=1
GROUP BY fileID

SELECT client_name AS [Client Name]
,dim_matter_header_current.master_client_code AS [Client Number]
,master_matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,name AS [Matter Owner]
,hierarchylevel4hist AS [Team]
,date_instructions_received AS [Date Instructions Received]
,date_opened_case_management AS [Date File Opened]
,date_closed_case_management AS [Date File Closed]
,FileOpeningAchieved AS [Date File Opening Process Completed]
,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,FileOpeningAchieved,103)) AS [Elapsed Days to File Opening Process]
,NULL AS [Date Exchange Process Completed]
,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,COALESCE(dim_detail_plot_details.exchange_date, udPlotSalesExchange.dteExchangeDate, ExchangeDateCompleted, dim_detail_property.[exchange_date], dim_detail_plot_details.[date_of_exchange], dim_detail_property.[residential_date_of_exchange]),103)) AS [Elapsed Days to Exchange]
,NULL AS [Date Completion Process Completed]
,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,COALESCE(dim_detail_plot_details.pscompletion_date, udPlotSalesExchange.dteCompDate),103))  AS [Elapsed Days to Completion]
,work_type_name
,[Exchange Date] = COALESCE(dim_detail_plot_details.exchange_date, udPlotSalesExchange.dteExchangeDate, ExchangeDateCompleted, dim_detail_property.[exchange_date], dim_detail_plot_details.[date_of_exchange], dim_detail_property.[residential_date_of_exchange])

,[Completion Date] = COALESCE(dim_detail_plot_details.pscompletion_date, udPlotSalesExchange.dteCompDate, CompletionDateCompleted)
,[Completion Flag] = CASE WHEN dim_detail_plot_details.pscompletion_date IS NOT NULL THEN 'Completed' ELSE 'Ongoing' END 


,[Fixed Fee] = fact_finance_summary.[fixed_fee_amount]
,[Hours Recorded] = TimeRecorded.HoursRecorded
,[Value of Hours Recorded] = TimeRecorded.RecordedValue
,[Revenue] = revenue.Revenue
,[Revnue - fact_bill_activity_bill_amount] = revenue.Revenue
,[Profit/ Loss] =  CASE WHEN revenue.Revenue IS NOT NULL THEN ISNULL(revenue.Revenue, 0) - ISNULL(TimeRecorded.RecordedValue, 0) 
  ELSE fact_finance_summary.[fixed_fee_amount] - ISNULL(TimeRecorded.RecordedValue, 0)
  END

FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
JOIN red_dw.dbo.fact_dimension_main 
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_plot_details
ON dim_detail_plot_details.dim_detail_plot_detail_key = fact_dimension_main.dim_detail_plot_detail_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'


INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue = CAST(fee_earner_code AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT
INNER JOIN #Client AS Client ON Client.ListValue = CAST(dim_matter_header_current.master_client_code AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT


LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.client_code = dim_matter_header_current.client_code
 AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT fileID,red_dw.dbo.datetimelocal(MSStage1Achieved) AS FileOpeningAchieved 
FROM ms_prod.dbo.dbMSData_OMS2K  WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE MSStage1Achieved IS NOT NULL
AND master_client_code IN ('190593P', '153838M','848629','W15353')) AS MilestonePlans
 ON ms_fileid=MilestonePlans.fileID
LEFT OUTER JOIN #Exchange  AS Excxhange
 ON ms_fileid=Excxhange.fileID
LEFT OUTER JOIN #Completion AS Completion
ON ms_fileid=Completion.fileID
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
 LEFT OUTER JOIN
        (
            SELECT fact_chargeable_time_activity.master_fact_key,
                   SUM(minutes_recorded) AS [MinutesRecorded],
                   SUM(fact_chargeable_time_activity.minutes_recorded) / 60 AS [HoursRecorded],
				   SUM(fact_chargeable_time_activity.actual_time_recorded_value) AS RecordedValue
            FROM red_dw.dbo.fact_chargeable_time_activity
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
            WHERE minutes_recorded <> 0
                  AND
                  (
                      dim_matter_header_current.date_closed_case_management >= '20120101'
                      OR dim_matter_header_current.date_closed_case_management IS NULL
                  )
            GROUP BY 
                     fact_chargeable_time_activity.master_fact_key
        ) AS TimeRecorded
            ON TimeRecorded.master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key


LEFT JOIN (SELECT master_fact_key,   SUM(fact_bill_activity.bill_amount) Revenue
			FROM red_dw.dbo.fact_bill_activity
			WHERE fact_bill_activity.bill_amount IS NOT NULL 
			
			GROUP BY master_fact_key
			) AS revenue ON revenue.master_fact_key = fact_dimension_main.master_fact_key
/* Exchange Date*/
LEFT JOIN ms_prod.dbo.udPlotSalesExchange ON udPlotSalesExchange.fileID = ms_fileid
 
WHERE dim_matter_header_current.master_client_code IN ('190593P', '153838M','848629','W15353')
--AND (completion_date>='2021-01-01' OR completion_date IS NULL)
--AND (date_closed_case_management>='2021-01-01' OR date_closed_case_management IS NULL)
AND work_type_name='Plot Sales'
AND date_opened_case_management >= '2015-05-01'
AND reporting_exclusions = 0
AND dim_matter_header_current.master_client_code + '-' + master_matter_number <> '190593P-7716'


END 

--2.	Change the report inclusion logic. 
--Remove previous criteria and just bring in everything opened on or after 1st May 2021

GO
