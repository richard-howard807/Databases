SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Author: Max Taylor
Date: 2022-06-17
Report: NHSR Trust Report Exceptions #152914


*/

CREATE PROCEDURE [dbo].[NHSRTrustReportExceptions]	--EXEC [dbo].[NHSRTrustReportExceptions] '1009'
--(@FeeEarner AS NVARCHAR(MAX)  )

AS 

DECLARE @nDate AS DATETIME = (SELECT MIN(dim_date.calendar_date) FROM red_dw..dim_date WHERE dim_date.fin_year = (SELECT fin_year - 3 FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = CAST(GETDATE() AS DATE)))
DECLARE @last_year AS DATE = DATEADD(MONTH, -11, GETDATE()+1)-DAY(GETDATE())

--IF OBJECT_ID('tempdb..#FeeEarner') IS NOT NULL   DROP TABLE #FeeEarner
--SELECT ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit('|', @FeeEarner)


SELECT DISTINCT 
[MatterSphere Ref] = dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number ,
[Matter Description] = dim_matter_header_current.matter_description,
[Case Manager] = name,
[Date Opened] = date_opened_case_management,
[Defendant Trust] = dim_detail_claim.[defendant_trust],
[Present Position] = dim_detail_core_details.[present_position],
[Exceptions] = REPLACE([Exceptions], '&amp;','&'),
fact_dimension_main.master_fact_key	 ,
nhs_instruction_type
,CASE WHEN nhs_instruction_type LIKE '%Group Action%' THEN 'Exclude' 
WHEN nhs_instruction_type LIKE '%group action%'	THEN 'Exclude' 
ELSE 'Do not exclude' END AS filter



FROM red_dw.dbo.dim_matter_header_current
JOIN red_dw.dbo.fact_dimension_main
	ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_fed_hierarchy_history 
	ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_instruction_type
	ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
JOIN Exceptions.dbo.vwExceptions
	ON fact_dimension_main.master_fact_key = vwExceptions.master_fact_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
--INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT
	  WHERE 1 = 1 
	  
	   AND dim_matter_header_current.master_client_code = 'N1001'
	   AND datasetid = 247
	   --AND name  IN( @CaseManager )
	   

	   /*Reporting Exclusions*/
	   AND dim_matter_header_current.ms_only = 1
	   AND reporting_exclusions = 0
	   AND ISNULL(RTRIM(LOWER(dim_detail_outcome.outcome_of_case)), '') <> 'exclude from reports'
      
	  /*Main Filter*/
	  AND (
	  dim_detail_core_details.[present_position] = 'Claim and costs outstanding'
	 
	 
	 OR 
	     CASE WHEN nhs_instruction_type IN ('EL/PL - PADs','Expert Report - Limited','Expert Report + LoR - Limited','Full Investigation - Limited'
		,'GPI - Advice','Inquest - associated claim','ISS 250','ISS 250 Advisory','ISS Plus','ISS Plus Advisory'
		,'Letter of Response - Limited','Lot 3 work','OSINT - Sch 1 FF','OSINT - Sch 2 - FF','OSINT & Claims Validation'
		,'OSINT & Fraud (returned to NHS Protocol)','OSINT (advice)','Schedule 1','Schedule 2','Schedule 3'
		,'Schedule 4','Schedule 4 (ENS)','Schedule 5 (ENS)') THEN 1 ELSE 0 END  = 1 
		AND dim_detail_health.zurichnhs_date_final_bill_sent_to_client >=@last_year 
		OR (dim_detail_outcome.date_claim_concluded >= @last_year )	  
		
		)



 
GO
