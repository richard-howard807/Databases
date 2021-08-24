SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Max Taylor
-- Create date: 29/01/2021
-- Description:	New report for Midland Heart see ticket 86458
-- =============================================
CREATE PROCEDURE [dbo].[Midland_Heart_Social_Housing_Weekly_Report]
AS
BEGIN

	SET NOCOUNT ON;
SELECT 
	RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
	,dim_matter_header_current.[matter_description] AS [Matter Description]
	, dim_matter_worktype.[work_type_name] AS [Work Type]
	, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
	, clientcontact_name AS [Instructing Officer]
	, dim_fed_hierarchy_history.[name] AS [Case Manager]
	, dim_fed_hierarchy_history.jobtitle
	, [Instruction Type - Buyback/ Re-sale] = COALESCE( cboMHInsType.cdDesc, instruction_type COLLATE DATABASE_DEFAULT)
    , [Property Address] = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(matter_description,'Final Staircasing', ''), 'Sale of', ''), 'Leasehold Pack', ''), 'Leasehold Form', ''), 'Sale &', ''), '-', ''), 'Lease Extension', ''), ':', ''), '()', ''), '–' , ''     ), 'Partial Staircasing', ''), 'Leasehold Extension', ''), 'Leashold Pack', ''), 'Right to Acquire', '') , 'Sale of freehold', '') , 'Grant of Headlease', ''), 'Surrender of', ''), 'Resale', '') , 'SALE OF', ''), 'Leasehold Enquiries', ''), 'FINAL STAIRCASING', ''), 'LEASE EXTENSION', '' ) , 'Freehold', ''), 'LEASEHOLD EXTENSION', ''), 'PARTIAL STAIRCASING', ''), 'LSE ', ''), 'sale of', ''), 'Final staircasing', '')  )     --dim_detail_property.[property_address]
    , [Purchasers Name/ Leaseholders Name] = 	dim_detail_property.[pspurchaser_1_full_name]
    , [Third Party Solicitor Name] 	= dim_detail_property.[midland_heart_third_party_solicitor_name]
    , [Current Position/Sales Progression Notes] = 		dim_detail_property.[midland_heart_current_position]
    , [Obstacles to Progress. What's holding this matter up?] =	dim_detail_property.[midland_heart_obstacles_to_progress]
    , [Date Initial papers Issued to Solicior]	= 	dim_detail_property.[midland_heart_date_initial_papers_issued_to_solicitors]
    , [Date Engrossments sent to MHL] = 	dim_detail_property.[midland_heart_date_engrossments_sent_to_mhl]
    , [Exchange Date] 	= 	dim_detail_property.[exchange_date]
    , [Completion Date] = 		dim_detail_property.[completion_date]
    , [Sales Officer Comments] =  		dim_detail_property.[midland_heart_sale_officer_comments]
    , [PO Number] 	=	dim_detail_property.[midland_heart_po_number]
	, [MH Instruction Type] = cboMHInsType.cdDesc

	,[TabFilter] = 
	CASE WHEN cboMHInsType.cdDesc IN ('Final Staircasing','Partial Staircasing', 'RTA', 'Lease Extension') THEN 'Tab1'
	ELSE 'Tab2' END
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
               AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
               AND GETDATE()
               BETWEEN dss_start_date AND dss_end_date
LEFT JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key

LEFT JOIN ms_prod.dbo.udRealEstateSH ON fileID = ms_fileid
LEFT JOIN 

(
SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboMHInsType' AND txtMSTable = 'udRealEstateSH') cboMHInsType 
ON cboMHInsType.cdCode = udRealEstateSH.cboMHInsType



WHERE 

dim_matter_header_current.matter_number <> 'ML'
AND dim_matter_header_current.reporting_exclusions=0
AND fact_dimension_main.client_code = 'W23552'
AND TRIM(dim_matter_worktype.[work_type_name]) = 'Social Housing - Property'



END

GO
