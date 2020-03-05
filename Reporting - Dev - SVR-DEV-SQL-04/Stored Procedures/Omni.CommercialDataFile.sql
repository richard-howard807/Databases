SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Commercial Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[CommercialDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
		RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_client.client_name AS [Client Name]
		, dim_detail_core_details.[date_initial_estimate_retainer] AS [Date Initial Estimate Retainer]
		, dim_detail_core_details.[date_of_current_estimate_to_complete_retainer] AS [Date of Current Estimate to Complete Retainer]
		, dim_detail_client.whitbread_brand AS [Whitbread Brand]
		, dim_detail_client.whitbread_previous_advice_given AS [Whitbread Previous Advice Given]
		, dim_detail_client.whitbread_region AS [Whitbread Region]
		, dim_detail_client.whitbread_subregion AS [Whitbread Subregion]
		, dim_detail_client.whitbread_rom AS [ROM]
		, dim_detail_client.whitbread_rdm AS [RDM]
		, dim_detail_client.whitbread_managed_business_rom AS [Whitbread Managed Business ROM]
		, dim_detail_client.[whitbread_employee_business_line] AS [Whitbread Employee Business Line_orig]
		, dim_detail_advice.issue AS Issue
		, dim_detail_advice.[issue_hr] AS [Issue HR]
		, dim_detail_advice.[secondary_issue_hr] AS [Secondary Issue HR]
		, dim_detail_outcome.[outcome_hr] AS [Outcome HR]
		, dim_detail_advice.[status_hr] AS [Status HR]
		, fact_detail_paid_detail.[value_of_instruction] AS [Value of Instruction]
		, dim_detail_client.pizza_express_strategy AS [Pizza Express Strategy]
		, dim_detail_client.[pizza_express_region] AS [Pizza Express Region]
		, CASE WHEN DATEDIFF(YEAR,dim_matter_header_current.date_opened_case_management,GETDATE())<=2 THEN 'Instructed within last 2 years' ELSE NULL END AS [Pizza Express New Instructions]
		, dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill [Date of Final Bill (com)]
		, CASE WHEN Month(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))>=3 THEN  CAST(YEAR(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management)) as varchar(4)) + '/' + CAST(YEAR(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))+1  as varchar(4))
			   WHEN Month(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))<3  THEN CAST(YEAR(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))-1 as varchar(4)) +'/' + CAST(Year(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management)) as varchar(4)) END AS [Financial Year Concluded (com)]
		, CASE WHEN Month(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))<3  THEN 'QTR 4'
			   WHEN Month(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))<6  THEN 'QTR 1'
			   WHEN Month(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))<9  THEN 'QTR 2'
			   WHEN Month(Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management))<12  THEN 'QTR 3'
			   ELSE 'QTR 4' END AS [Financial Quarter Concluded (com)]
		, CASE WHEN Coalesce(dim_detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill, dim_matter_header_current.date_closed_case_management) IS NULL  AND dim_matter_header_current.date_closed_case_management IS NULL THEN 'Outstanding' else 'Concluded' END AS [Concluded Claim Status (com)]
		, dim_detail_core_details.jaguar_nature_of_claim AS [Claim Type]
		, CASE WHEN (CASE WHEN dim_detail_client.whitbread_brand IN ('Premier Inn - CoLo','Premier Inn - RPI','Premier Inn - Solus')
                      THEN 'Premier Inn' ELSE dim_detail_client.whitbread_brand END)='Beefeater' THEN 'BE'
		   WHEN (CASE WHEN dim_detail_client.whitbread_brand IN ('Premier Inn - CoLo','Premier Inn - RPI','Premier Inn - Solus')
					  THEN 'Premier Inn' ELSE dim_detail_client.whitbread_brand END) like 'Brewers%'  THEN 'BF'
		   WHEN (CASE WHEN dim_detail_client.whitbread_brand IN ('Premier Inn - CoLo','Premier Inn - RPI','Premier Inn - Solus')
					  THEN 'Premier Inn' ELSE dim_detail_client.whitbread_brand END) = 'Costa'  THEN 'CC'
		   WHEN (CASE WHEN dim_detail_client.whitbread_brand IN ('Premier Inn - CoLo','Premier Inn - RPI','Premier Inn - Solus')
					  THEN 'Premier Inn' ELSE dim_detail_client.whitbread_brand END) = 'Premier Inn'  THEN 'PI'
		   WHEN (CASE WHEN dim_detail_client.whitbread_brand IN ('Premier Inn - CoLo','Premier Inn - RPI','Premier Inn - Solus')
					  THEN 'Premier Inn' ELSE dim_detail_client.whitbread_brand END) ='Support Centre'  THEN 'SC'
		   WHEN (CASE WHEN dim_detail_client.whitbread_brand IN ('Premier Inn - CoLo','Premier Inn - RPI','Premier Inn - Solus')
					  THEN 'Premier Inn' ELSE dim_detail_client.whitbread_brand END) ='Table Table' THEN 'TT'
		   WHEN (CASE WHEN dim_detail_client.whitbread_brand IN ('Premier Inn - CoLo','Premier Inn - RPI','Premier Inn - Solus')
					  THEN 'Premier Inn' ELSE dim_detail_client.whitbread_brand END) ='Taybarns'  THEN 'TY' END AS [Whitbread Brand Group Name]
		,CAST(REPLACE(PizzaExpressPeriod,'Period','') AS INT) AS [Pizza Express Period]
        ,YearPeriod [Pizza Express Year Period]
		--, CASE	when datepart(mm,dim_matter_header_current.date_opened_case_management) < 7 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE()) THEN 1	  -- current may to dec
		--        when datepart(mm,dim_matter_header_current.date_opened_case_management) > 6 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-1 THEN 1   -- current jan to apr
		--		when datepart(mm,dim_matter_header_current.date_opened_case_management) < 7 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-1 THEN 2	  -- historic -1
		--        when datepart(mm,dim_matter_header_current.date_opened_case_management) > 6 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-2 THEN 2  -- historic -1
		--		when datepart(mm,dim_matter_header_current.date_opened_case_management) < 7 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-2 THEN 3	  --  historic -2
		--        when datepart(mm,dim_matter_header_current.date_opened_case_management) > 6 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-3 THEN 3  -- historic -2
		--  ELSE 4
		--  end [Period Type - Pizza Express]
		--, CASE	WHEN YearPeriod='2015-16' THEN 1	 	
		--		WHEN YearPeriod='2014-15' THEN 2
		--		WHEN YearPeriod='2013-14' THEN 3	  
		--		ELSE 4
		--  END [Period Type - Pizza Express] 
		  , CASE WHEN DATEPART(yyyy,dim_matter_header_current.date_opened_case_management) = DATEPART(yyyy,GETDATE()) THEN 1	 	
				WHEN DATEPART(yyyy,dim_matter_header_current.date_opened_case_management) = DATEPART(yyyy,GETDATE())-1 THEN 2
				WHEN DATEPART(yyyy,dim_matter_header_current.date_opened_case_management) = DATEPART(yyyy,GETDATE())-2 THEN 3	  
				ELSE 4
		  END [Period Type - Pizza Express] 
		  , dim_detail_advice.[outcome_combined] AS [Outcome - Pizza Express]
		  , Coalesce(dim_detail_client.[whitbread_employee_business_line],dim_detail_client.whitbread_brand) as [Whitbread Employee Business Line]

		FROM red_dw.dbo.fact_dimension_main
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key=fact_dimension_main.dim_detail_outcome_key
		LEFT OUTER JOIN Omni.PizzExpressReportingPeriods AS PEReportingPeriods ON dim_matter_header_current.date_opened_case_management=PEReportingPeriods.Dates

		WHERE 
		ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
		AND dim_matter_header_current.reporting_exclusions=0
		AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)


END
GO
