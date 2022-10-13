SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  /*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2021-04-30
Description:		#96970 'Supervision MI' 
Current Version:	Initial Create
====================================================
 */

CREATE PROCEDURE [dbo].[SupervisionMI]	--EXEC [dbo].[SupervisionMI] 'Legal Ops - Claims', 'Disease','Disease Liverpool 2','Closed','Giselle Drouillard'
											  
(
@Division AS VARCHAR(MAX),
@Department AS VARCHAR(MAX),
@Team AS VARCHAR(MAX),
--@Location AS VARCHAR(MAX),
@Status AS VARCHAR(MAX)	,
--@Client AS VARCHAR(max),
@FeeEarner AS VARCHAR(MAX)
) 
AS
BEGIN 


  ------TESTING-----
--  DECLARE
--@Client AS VARCHAR(max)='NHS Resolution',
--@Department AS VARCHAR(MAX)='Motor',
--@Team AS VARCHAR(MAX)='Motor Fraud',
--@Location AS VARCHAR(MAX)= 'Liverpool',
--@Status AS VARCHAR(MAX)='Open'

IF OBJECT_ID('tempdb..#Division') IS NOT NULL   DROP TABLE #Division
SELECT ListValue   INTO #Division FROM 	dbo.udt_TallySplit(',', @Division)

IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)

IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)

IF OBJECT_ID('tempdb..#Status') IS NOT NULL   DROP TABLE #Status
SELECT ListValue  INTO #Status FROM 	dbo.udt_TallySplit(',', @Status)

IF OBJECT_ID('tempdb..#FeeEarner') IS NOT NULL   DROP TABLE #FeeEarner
SELECT ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit(',', @FeeEarner)

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT dim_matter_header_current.master_client_code +'-'+master_matter_number AS [MattersphereRef]
,red_dw.dbo.dim_detail_claim.name_of_reviewer	 AS [Name of reviewer]
,red_dw.dbo.dim_detail_claim.name_of_future_reviewer	 AS [Next review to be completed by]
,red_dw.dbo.dim_detail_claim.date_most_recent_supervisor_review	 AS [Date of review]
,red_dw.dbo.dim_detail_claim.date_case_status_decision_made AS [Date case status decision made]
,red_dw.dbo.dim_detail_claim.date_of_next_review   AS [Date of next review]
,red_dw.dbo.dim_detail_claim.supervision_comments AS Comments
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,dim_matter_header_current.client_name
,CASE WHEN dim_detail_claim.date_of_next_review	>GETDATE() THEN 1 ELSE 0 END AS CountofNextReview
,client_group_name
,dim_fed_hierarchy_history.name AS [Matter Owner]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
--,red_dw.dbo.dim_employee.locationidud AS Location
,CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Open/Closed Case Status]



FROM 
red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
INNER JOIN #Division AS Division ON Division.ListValue  COLLATE DATABASE_DEFAULT = hierarchylevel2hist COLLATE DATABASE_DEFAULT
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN  #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = REPLACE(hierarchylevel4hist,',','')	  COLLATE DATABASE_DEFAULT
INNER JOIN #Status ON #Status.ListValue = CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END
INNER JOIN #FeeEarner ON #FeeEarner.ListValue COLLATE DATABASE_DEFAULT = dim_matter_header_current.matter_owner_full_name
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_involvement_full ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insurerclient_1_key
--INNER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key





WHERE 

red_dw.dbo.dim_matter_header_current.reporting_exclusions=0
AND dim_matter_header_current.matter_number <> 'ML'
--AND  client_group_name=@Client
--AND locationidud=@Location
AND hierarchylevel2hist = 'Legal Ops - Claims'
AND red_dw.dbo.dim_detail_claim.date_most_recent_supervisor_review IS NOT null
--AND hierarchylevel3hist = 'Healthcare'
AND LOWER(ISNULL(dim_detail_outcome.outcome_of_case,'')) <> 'exclude from reports'
--AND dim_matter_header_current.client_code = 'W15349'AND red_dw.dbo.dim_matter_header_current.matter_number = '00001520'
AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)
		   END
	--SELECT date_most_recent_supervisor_review,client_code,matter_number	 FROM red_dw.dbo.dim_detail_claim  WHERE red_dw.dbo.dim_detail_claim.name_of_reviewer IS NOT null
	
GO
