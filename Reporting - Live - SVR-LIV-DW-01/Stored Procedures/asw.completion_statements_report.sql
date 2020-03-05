SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 20/03/2018
-- Description:	New report requested by Anastasia Sinclair.  Webby 299916
-- =============================================
CREATE PROCEDURE [asw].[completion_statements_report]
AS

	
	
	SELECT
           
            dim_matter_header_current.client_code,
            dim_matter_header_current.matter_number,
            matter_description,
			name [case_handler],
            dim_detail_property.property_contact,

			-- LD The below are blank columns but have kept them in incase they begin to capture these in future
			-- as it will easy to replace the blanks without having to redeploy the report.
			'' [note_of_issues],
			'' [recover_all_monies],
			'' [time_units_taken],
			'' [completion_delayed],
			'' [additional_notes]


          

	FROM red_dw.dbo.dim_matter_header_current 
	INNER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.client_code = dim_matter_header_current.client_code AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
	INNER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.client_code = dim_matter_header_current.client_code AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
	INNER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT JOIN red_dw.dbo.fact_detail_property ON fact_detail_property.client_code = dim_matter_header_current.client_code AND fact_detail_property.matter_number = dim_matter_header_current.matter_number
	LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code AND dss_current_flag = 'Y'
	WHERE dim_matter_header_current.client_code IN  ('00787558', '00787559', '00787560', '00787561') 
	AND transaction_1 = 'Acquisition'
	AND dim_detail_property.case_type_asw IN ('Renewal','Acquisition')
	AND  dim_detail_property.status = 'Ongoing'
	AND date_opened_case_management >= '2017-05-01'



GO
