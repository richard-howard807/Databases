SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2019-09-19
-- Description:	Weekly Holiday Pay ET & EC Summary Report, 31631
-- =============================================
CREATE PROCEDURE [royalmail].[WeeklyHolidayPayETEC]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   SELECT dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	--, instruction_type AS [Instruction Type]
	, cdDesc  AS [Instruction Type]
	, date_opened_case_management AS [Date Opened]
	, date_claim_concluded AS [Date Claim Concluded]
	, RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number AS [Matter No]
	, name AS [Fee Earner]
	, matter_description AS [Name]
	, emp_ep_number AS [Pay Number]
	, emp_claimants_place_of_work AS [Office]
	, location_of_hearing AS [Tribunal]
	, emp_date_of_final_hearing AS [Hearing Date]
	, have_we_dealt_with_ec AS [EC?]
	, ec_status AS [EC Current Position]
	, potential_compensation AS [Claim Value]
	, actual_compensation AS [Settlement Value]
	, emp_present_position AS [ET Current Position]

	
	, CASE WHEN cdDesc='Holiday Pay Employment Early Conciliations (Annual Retainer)' AND date_claim_concluded IS NULL THEN 1 ELSE 0 END AS [Live EC]
	, CASE WHEN cdDesc='Holiday Pay Employment Tribunal Claims (Annual Retainer)' AND date_claim_concluded IS NULL THEN 1 ELSE 0 END AS [Live ET]

	, CASE WHEN date_opened_case_management BETWEEN DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0) AND DATEADD(DAY,6,DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0)) AND cdDesc='Holiday Pay Employment Early Conciliations (Annual Retainer)' THEN 1 ELSE 0 END AS [EC Received Previous Week]
	, CASE WHEN date_opened_case_management BETWEEN DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0) AND DATEADD(DAY,6,DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0)) AND cdDesc='Holiday Pay Employment Tribunal Claims (Annual Retainer)' THEN 1 ELSE 0 END AS [ET Received Previous Week]

	, CASE WHEN date_claim_concluded BETWEEN DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0) AND DATEADD(DAY,6,DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0))  AND cdDesc='Holiday Pay Employment Early Conciliations (Annual Retainer)' THEN 1 ELSE 0 END AS [EC Settled Previous Week]
	, CASE WHEN date_claim_concluded BETWEEN DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0) AND DATEADD(DAY,6,DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0))  AND cdDesc='Holiday Pay Employment Tribunal Claims (Annual Retainer)' THEN 1 ELSE 0 END AS [ET Settled Previous Week]

	, CASE WHEN cdDesc='Holiday Pay Employment Early Conciliations (Annual Retainer)' OR cdDesc='Holiday Pay Employment Tribunal Claims (Annual Retainer)'
	AND date_claim_concluded IS NOT NULL THEN actual_compensation ELSE NULL END AS [EC&ET Settlement Amount (Concluded)]

	, CASE WHEN actual_compensation>0 AND (cdDesc='Holiday Pay Employment Early Conciliations (Annual Retainer)' OR cdDesc='Holiday Pay Employment Tribunal Claims (Annual Retainer)')
		THEN actual_compensation ELSE NULL END AS [EC&ET Settlement Amount (Paid)]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key

INNER JOIN (SELECT RTRIM(client_code) client_code
					, matter_number
					, cboInstrTypeRMG
					, cdDesc 
				FROM MS_Prod.dbo.udMICoreGeneral
				INNER JOIN MS_Prod.dbo.dbCodeLookup
				ON cboInstrTypeRMG=cdCode
				INNER JOIN red_dw.dbo.dim_matter_header_current
				ON fileID=ms_fileid
				WHERE cboInstrTypeRMG IS NOT NULL
				AND cdCode IN ('HOLPAYTRIB','HOLPAYEC')
				) AS instructionType ON instructionType.client_code = fact_dimension_main.client_code
				AND instructionType.matter_number = fact_dimension_main.matter_number

WHERE 
--(CAST(DATEADD(DAY,-1,GETDATE()) AS DATE)=opened_date.calendar_date
--OR CAST(DATEADD(DAY,-1,GETDATE()) AS DATE)=concluded_date.calendar_date)
reporting_exclusions=0
AND client_group_code='00000006'

END
GO
