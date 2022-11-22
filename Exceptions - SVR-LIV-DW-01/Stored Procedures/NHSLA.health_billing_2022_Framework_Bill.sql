SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:      Julie Loughlin
-- Create date: 18/11/2022
-- Description: to get 2022 Framework Bill report #178545 to feed into the Staged Final Bill Report in the NHSR client folder
-- =============================================
--Version 1
-- ============================================
CREATE PROCEDURE [NHSLA].[health_billing_2022_Framework_Bill]	 --EXEC [NHSLA].[health_billing_2022_Framework_Bill] '20221101','20221120','Healthcare London','6724'

(
@DateFrom AS DATE,
@DateTo AS DATE,
@Team AS NVARCHAR(MAX),
@FedCode AS NVARCHAR(MAX)
)
AS
BEGIN
DROP TABLE IF EXISTS #Team
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
DROP TABLE IF EXISTS #FedCode
SELECT ListValue  INTO #FedCode FROM Reporting.dbo.[udt_TallySplit]('|', @FedCode)



     -- SET NOCOUNT ON added to prevent extra result sets from
     -- interfering with SELECT statements.
     SET NOCOUNT ON;


SELECT 
dim_matter_header_current.client_code AS client
,dim_matter_header_current.matter_number AS matter
,Child.[Type of Bill]
,red_dw.dbo.dim_detail_health.nhs_instruction_type
,matter_owner_full_name
,dim_fed_hierarchy_history.hierarchylevel4hist
,red_dw.dbo.fact_detail_client.number_of_defendants	  AS [No. Defendants]
,Child.[NHSR Ref]
,date_instructions_received AS [Date Of Instruction]
,Child.[Bill Type]
,CASE WHEN Child.[Type of Bill] IN( '(Clin) Liability Investigations'
,'(Clin) Instruction of Quantum Experts'
,'(Clin) Schedule 5 (EN)'
,'(Clin) Inquest'
,'(Clin) Inquest Associated Claim'
,'Other Capped/Fixed Fees')
THEN	'Fixed Fee' 
WHEN Child.[Type of Bill] IN ('(Clin) Dispute - Capped Fee','(Non-Clin) Dispute - Capped Fee') 
THEN 'Capped'
ELSE 'Hourly'
END AS 	[Fixed, capped or hourly rate]
,Child.[If fixed or capped - £]
,Child.[Extra Charge for sorting and paginating]
,Child.[Fees incurred for supplementary comments]
,Child.[Any other fees agreed]
,Child.[Extra charge for Mediation]
,Child.[Extra charge for Preparation]
,Child.[Date DQ was filed]
,Child.[Permission to bill Counsel in addition to FF? (Inquest only)]
,Child.[Scheme]
,Child.[Trust Name]
,tskCompleted



FROM red_dw.dbo.fact_dimension_main
INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health ON  dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
INNER JOIN #FedCode fedcodes ON fedcodes.ListValue COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT
INNER JOIN #Team team ON team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN MS_Prod.dbo.dbTasks ON dbtasks.fileID=ms_fileid


LEFT OUTER JOIN (
 ------------CHILD facts/Dim
SELECT 
fc.[nhsr_fee] AS  [If fixed or capped - £]
,fc.[nhsr_extra_charge_for_sorting_and_paginating] AS [Extra Charge for sorting and paginating]
,fc.[nhsr_how_many_extra_fees_were_incurred]  AS [Fees incurred for supplementary comments]
,fc.[nhsr_any_other_fees_agreed]  AS [Any other fees agreed]
,fc.[nhsr_how_much_extra_can_be_billed_mediation] AS [Extra charge for Mediation]
,fc.[nhsr_how_much_extra_can_be_billed_preparation]	AS [Extra charge for Preparation]
,fc.nhsr_share_multi_def
,dc.[nhsr_what_type_of_bill_do_you_require]	 AS [Type of Bill]
,dc.[nhsr_what_type_of_bill] AS [Bill Type]
,dc.[nhsr_permission_to_bill_counsel_fees_on_top_of_ff]	 AS [Permission to bill Counsel in addition to FF? (Inquest only)]
,dc.[nhsr_date_dq_filed]  AS [Date DQ was filed]
,dc.[nhsr_nhsr_ref_multi_def] AS [NHSR Ref]
,dc.[nhsr_defendant_trust_multi_def]  AS [Trust Name]
,dc.nhsr_scheme_multi_def AS [Scheme]
,fc.client_code
,fc.matter_number


FROM red_dw.dbo.fact_child_detail  AS fc
LEFT OUTER JOIN red_dw.dbo.dim_child_detail AS dc ON dc.dim_parent_key = fc.dim_parent_key
WHERE 
--fc.client_code = '00030645' AND fc.matter_number = '00004731'
 [nhsr_what_type_of_bill_do_you_require] <>'Cost Bill') AS Child
ON Child.client_code = fact_dimension_main.client_code AND Child.matter_number = fact_dimension_main.matter_number

WHERE 
fact_dimension_main.client_code = '00030645' AND fact_dimension_main.matter_number = '00004731'
-- tskType='MILESTONE'
--AND (LOWER(tskDesc) LIKE '%nhsr stage 1/final bill request%' OR dbTasks.tskDesc = 'NHSR GPI Final Bill Request')
--AND CONVERT(DATE,tskCompleted,103) BETWEEN @DateFrom AND @DateTo  
----AND CAST(tskCompleted AS DATE)  BETWEEN @DateFrom AND @DateTo
--AND tskComplete=1
--AND dim_matter_header_current.client_code NOT IN ('00030645','95000C','00453737') 
--AND dbTasks.tskActive=1
END 
GO
