SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  -- =============================================
-- Author:		Julie Loughlin
-- Create date: 27.04.21
-- Description:	New report for Request #90641
-- =============================================

CREATE PROCEDURE [dbo].[MotorAXACSNotableCasesReport]--EXEC [dbo].[MotorAXACSNotableCasesReport] 'AXA XL','Motor','Motor Fraud','Emma Turner'

(
@Client AS NVARCHAR(MAX)
,@Department  AS NVARCHAR(MAX)
,@DateFrom AS DATE
,@DateTo AS DATE
--,@Team AS NVARCHAR(MAX)
--,@FeeEarner AS NVARCHAR(MAX)
) 
AS
BEGIN 

--DECLARE
--@Client AS VARCHAR(max)='AXA XL',
--@Department AS VARCHAR(MAX)='Motor'
--@Team AS VARCHAR(MAX)='Motor Fraud'

IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit('|', @Department)

--IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
--SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team)

--IF OBJECT_ID('tempdb..#FeeEarner') IS NOT NULL   DROP TABLE #FeeEarner
--SELECT ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit('|', @FeeEarner)


SELECT dim_matter_header_current.master_client_code +'-'+master_matter_number AS [MattersphereRef]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,dim_fed_hierarchy_history.name AS [Matter Owner]
,dim_matter_header_current.client_name
,dim_detail_core_details.clients_claims_handler_surname_forename
,dim_detail_claim.[dst_claimant_solicitor_firm]
,red_dw.dbo.dim_detail_outcome.date_claim_concluded	 AS [Date of Settlement / Outcome ]
,COALESCE(red_dw.dbo.dim_detail_core_details.date_instructions_received,date_opened_case_management) AS [Date Instructions Recevied]
,fact_detail_reserve_detail.savings_against_reserve AS [Amount Saved] 
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,date_claim_concluded AS [Date Claim Concluded]
,dim_detail_core_details.present_position AS [Present Position]
,[Client Ref] = ISNULL(dim_client_involvement.insurerclient_reference,dim_involvement_full.reference)
,outcome_of_case AS Outcome
--,narrative

FROM 
red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_involvement_full ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insurerclient_1_key
--LEFT OUTER JOIN red_dw.dbo.fact_all_time_activity ON fact_all_time_activity.master_fact_key = fact_dimension_main.master_fact_key
--LEFT OUTER JOIN red_dw.dbo.dim_all_time_narrative ON fact_all_time_activity.dim_all_time_narrative_key = dim_all_time_narrative.dim_all_time_narrative_key



WHERE 
--master_client_code IN ('A3003','T3003','W15564','A1001')
red_dw.dbo.dim_matter_header_current.reporting_exclusions=0
AND (date_closed_case_management IS NULL OR date_closed_case_management>='2018-01-01')
--AND (CASE WHEN master_client_code='W15564' THEN 'Sabre' 
--WHEN master_client_code='A1001' THEN 'AXA XL'
--WHEN master_client_code='T3003' THEN 'Tesco'
--WHEN master_client_code='A3003'  AND dim_detail_claim.[name_of_instructing_insurer]='Tesco Underwriting (TU)' THEN 'Tesco'
--WHEN master_client_code='A3003' THEN 'Ageas' END)=@Client
--AND hierarchylevel3hist=@Client
AND dim_matter_header_current.client_name =@Client
AND ISNULL(red_dw.dbo.dim_detail_outcome.outcome_of_case,'') IN ('Won at Trial','Struck out','Won','Discontinued','won at trial')
AND (dim_detail_outcome.date_claim_concluded >= @DateFrom AND dim_detail_outcome.date_claim_concluded <= @DateTo) 

END 


GO
