SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Author : Max Taylor
Date: 2021/06/10
Report - Help to Buy - Exchange/Completion Tracker - Ticket #102296

*/
CREATE  PROCEDURE [dbo].[RealEstate_HelptoBuy_ExchangeCompletionTracker] 

AS 

BEGIN

--IF OBJECT_ID('tempdb..#FeeEarner') IS NOT NULL   DROP TABLE #FeeEarner
--SELECT ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit('|', @FeeEarner)

--IF OBJECT_ID('tempdb..#Client') IS NOT NULL   DROP TABLE #Client
--SELECT ListValue  INTO #Client FROM 	dbo.udt_TallySplit('|', @Client)

IF OBJECT_ID('tempdb..#Exchange') IS NOT NULL DROP TABLE #Exchange
IF OBJECT_ID('tempdb..#Completion') IS NOT NULL DROP TABLE #Completion

SELECT fileID,MAX(red_dw.dbo.datetimelocal(tskCompleted)) AS ExchangeDateCompleted
INTO #Exchange
FROM MS_Prod.dbo.dbTasks WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE tskFilter IN ('tsk_04_010_rem_cont_exch') 
AND master_client_code = 'W15353'
AND tskActive=1 AND tskComplete=1
GROUP BY fileID



SELECT fileID,MAX(red_dw.dbo.datetimelocal(tskCompleted)) AS CompletionDateCompleted
INTO #Completion
FROM MS_Prod.dbo.dbTasks WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE tskFilter IN ('tsk_05_010_est_comp_today') 
AND master_client_code = 'W15353'
AND tskActive=1 AND tskComplete=1
GROUP BY fileID

SELECT 


 [Client Number] = dim_matter_header_current.master_client_code 
,[Matter Number] = master_matter_number
,[Matter Description] = matter_description 
,[Matter Owner] = name 
,[Team] = hierarchylevel4hist 
,[Date Instructions Received] = date_instructions_received 
,[Date File Opened] = date_opened_case_management 
,[Date File Closed] = date_closed_case_management 
,[Exchange Date] = COALESCE(dim_detail_plot_details.exchange_date, udPlotSalesExchange.dteExchangeDate, ExchangeDateCompleted, dim_detail_property.[exchange_date], dim_detail_plot_details.[date_of_exchange], dim_detail_property.[residential_date_of_exchange])
,[Date Notice of Exchange Sent] = dim_detail_plot_details.date_exchange_documentation_sent
,[Completion Date] = COALESCE(dim_detail_plot_details.pscompletion_date, udPlotSalesExchange.dteCompDate, CompletionDateCompleted)
,[Date Notice of Completion Sent] = dim_detail_plot_details.date_completion_documentation_sent 
,[Completion Flag] = CASE WHEN dim_detail_plot_details.pscompletion_date IS NOT NULL THEN 'Completed' ELSE 'Ongoing' END 
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
JOIN red_dw.dbo.fact_dimension_main 
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_plot_details
ON dim_detail_plot_details.dim_detail_plot_detail_key = fact_dimension_main.dim_detail_plot_detail_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'


--INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue = CAST(fee_earner_code AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT
--INNER JOIN #Client AS Client ON Client.ListValue = CAST(dim_matter_header_current.master_client_code AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.client_code = dim_matter_header_current.client_code
 AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
			
/* Exchange Date*/
LEFT JOIN ms_prod.dbo.udPlotSalesExchange ON udPlotSalesExchange.fileID = ms_fileid

LEFT OUTER JOIN #Exchange  AS Excxhange
 ON ms_fileid=Excxhange.fileID
LEFT OUTER JOIN #Completion AS Completion
ON ms_fileid=Completion.fileID
 
WHERE dim_matter_header_current.master_client_code = 'W15353'
AND dim_detail_plot_details.[type_of_scheme] = 'Help to Buy'
AND (date_closed_case_management >= '2012-05-01' OR date_closed_case_management IS NULL)
AND reporting_exclusions = 0
AND TRIM(master_matter_number) <> '12096'

ORDER BY dim_matter_header_current.master_client_code, master_matter_number

END 

GO
