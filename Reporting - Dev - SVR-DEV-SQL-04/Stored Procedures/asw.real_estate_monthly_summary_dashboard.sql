SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/* History
Version	  Date		    By		Description
************************************************************************************************ 
1.1	    12-04-2017	JL	replaced "Days to Complete Cases" with new logic for week days only see ticket 221792
1.2     17-08-2017  JL  I have changed the 'days to complete' to look at Trans Agreed as per ticket 252331
1.3		10-05-2018	LD	Put query into a stored procedure with parameter, so this can be used in Average Case Summary report
						as well as the dashboard
1.4		10-05-2018 LD	Added matter description and property contact for the Average Case Summary report			 
*/

CREATE PROCEDURE [asw].[real_estate_monthly_summary_dashboard]
	-- Add the parameters for the stored procedure here
	@Year INT
	,@Month INT 
AS

		-- Test Data
		--DECLARE @Year INT = 2018
		--DECLARE @Month INT = 3



	   SELECT dim_matter_header_current.client_code AS [Client Code]
			, dim_matter_header_current.matter_number AS [Matter Number]
			, dim_detail_property.[case_type_asw_desc]  AS [Case Type - ASW]
			, dim_matter_worktype.[work_type_name] AS [Work Type]
			, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received]) AS [Date Documents Received]
			, dim_detail_property.[date_elements_agreed] AS [Date Transaction Agreed]
			, dim_detail_property.[exchange_date] AS [Exchange Date]
			, dim_detail_property.[completion_date] AS [Completion Date]
			--, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) AS [Days to Documents Received]

	/*1.1  -  removed as per Kate Fox and replaced with below logic for week days only 
	*********************************************************************************
		  , DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[date_elements_agreed]) AS [Days to Transaction Agreed] 
		  , DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[exchange_date]) AS [Days to Exchange]
		  , DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[completion_date]) AS [Days to Complete]
			*/
			
	,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=@Month AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year OR DATEPART(MONTH,dim_detail_property.[date_elements_agreed])=@Month AND DATEPART(YEAR,dim_detail_property.[date_elements_agreed])=@Year THEN DATEDIFF( DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] ) - 2*DATEDIFF( WEEK, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] )  + 
			CASE WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 7 THEN 1 ELSE 0 END + 
			CASE WHEN DATEPART ( WEEKDAY, dim_detail_property.[date_elements_agreed] ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Transaction Agreed]


	,CASE WHEN DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year THEN DATEDIFF( DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] ) - 2*DATEDIFF( WEEK, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] )  + 
			CASE WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 7 THEN 1 ELSE 0 END + 
			CASE WHEN DATEPART ( WEEKDAY, dim_detail_property.[exchange_date] ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Exchange]


	,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=@Month AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year THEN DATEDIFF( DAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), CAST(dim_detail_property.[completion_date] AS INT) ) - 2*DATEDIFF( WEEK, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), CAST (dim_detail_property.[completion_date] AS INT) )  + 
			CASE WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management)) = 7 THEN 1 ELSE 0 END + 
			CASE WHEN DATEPART ( WEEKDAY, CAST(dim_detail_property.[completion_date] AS INT) ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Complete]

	--,DateDiff(dd, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date]) - DateDiff(ww, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date])*2 as test
 
			, dim_fed_hierarchy_history.[name] AS [Fee Earner]
			, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
			, dim_department.[department_name] AS [Department]
			, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
			, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
			, CASE WHEN dim_matter_header_current.client_code ='00787558' THEN 'Superdrug'
						WHEN dim_matter_header_current.client_code ='00787559' THEN 'The Perfume Shop'
						WHEN dim_matter_header_current.client_code ='00787560' THEN 'Three Mobile'
						WHEN dim_matter_header_current.client_code ='00787561' THEN 'Savers Health and Beauty'
						END AS [Fascia]
			, CASE WHEN (COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received]) IS NOT NULL) 
						AND ((DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = 3 )
						--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-2)
						--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-3) 
						AND DATEPART(YEAR, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(YEAR, GETDATE())) 
						THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) ELSE NULL END [Days to Documents Received]
			--, CASE WHEN (dim_detail_property.[date_elements_agreed] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = 1 /* OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[date_elements_agreed]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed]) ELSE NULL END [Days to Transaction Agreed]
			--, CASE WHEN (dim_detail_property.[completion_date] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[completion_date]) = 2 /* OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date]) ELSE NULL END [Days to Complete]
			, 3 [Previous Month] --current month
			, DATEPART(YEAR, GETDATE()) [Current Year]
			, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = 3 /* OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE())THEN '1' ELSE '0' END [New (Month)]
			, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = 3 /*OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) THEN '1' ELSE '0' END [Completed (Month)]
			, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [New (Year)]
			, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [Completed (Year)]
			, NULL [Legal Spend]
			, NULL [Current Legal Spend]
			, NULL [Bill Date]
			, NULL [Bill Date (month)]
			, NULL [Bill Date (year)]
			, 'Matter Level' [Level]
			, NULL InvoiceDate
			,ISNULL(StatusChanged,0) AS StatusChanged
			,dim_matter_header_current.matter_description
			,dim_detail_property.property_contact

	FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 

	LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
	LEFT OUTER JOIN (SELECT dim_detail_previous_details.client_code
				  , dim_detail_previous_details.matter_number
				  , CASE WHEN RTRIM([status_rm]) <>   RTRIM([prev_status_rm]) THEN 1 ELSE 0 END  AS StatusChanged
              
	FROM red_dw.dbo.dim_detail_previous_details
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code = dim_detail_previous_details.client_code AND dim_matter_header_current.matter_number = dim_detail_previous_details.matter_number
	WHERE 
	dim_detail_previous_details.client_code IN ('00787558','00787559','00787560','00787561','R1001','P00010','P00011','P00012','P00020','P00021','P00022')
	AND 
	prev_status_rm IS NOT NULL) AS CompletionRule
	 ON dim_matter_header_current.client_code = CompletionRule.client_code
	AND  dim_matter_header_current.matter_number = CompletionRule.matter_number

	WHERE dim_matter_header_current.client_code IN ('00787558','00787559','00787560','00787561')
	AND dim_matter_header_current.matter_number <> 'ML'
	--AND dim_detail_property.[case_type_asw] IS NOT NULL 
	AND ISNULL(dim_detail_property.[status_rm],'') <> 'On Hold'
	AND RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number <> '00787558/00010157'  -- Ticket 208667

	UNION ALL 

	SELECT dim_matter_header_current.client_code AS [Client Code]
			, dim_matter_header_current.matter_number AS [Matter Number]
			, dim_detail_property.[case_type_asw_desc]  AS [Case Type - ASW]
			, dim_matter_worktype.[work_type_name] AS [Work Type]
			, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received]) AS [Date Documents Received]
			, dim_detail_property.[date_elements_agreed] AS [Date Transaction Agreed]
			, dim_detail_property.[exchange_date] AS [Exchange Date]
			, dim_detail_property.[completion_date] AS [Completion Date]
			--, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) AS [Days to Documents Received]

	/*1.1  -  removed as per Kate Fox and replaced with below logic for week days only
	************************************************************************************* 
			, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[date_elements_agreed]) AS [Days to Transaction Agreed]
			, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[exchange_date]) AS [Days to Exchange]
			, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[completion_date]) AS [Days to Complete]
	*/
	,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=@Month AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year OR DATEPART(MONTH,dim_detail_property.[date_elements_agreed])=@Month AND DATEPART(YEAR,dim_detail_property.[date_elements_agreed])=@Year THEN DATEDIFF( DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] ) - 2*DATEDIFF( WEEK, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] )  + 
			CASE WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 7 THEN 1 ELSE 0 END + 
			CASE WHEN DATEPART ( WEEKDAY, dim_detail_property.[date_elements_agreed] ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Transaction Agreed]


	,CASE WHEN DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year THEN DATEDIFF( DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] ) - 2*DATEDIFF( WEEK, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] )  + 
			CASE WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 7 THEN 1 ELSE 0 END + 
			CASE WHEN DATEPART ( WEEKDAY, dim_detail_property.[exchange_date] ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Exchange]


	,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=@Month AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year THEN DATEDIFF( DAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), CAST(dim_detail_property.[completion_date] AS INT) ) - 2*DATEDIFF( WEEK, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), CAST (dim_detail_property.[completion_date] AS INT) )  + 
			CASE WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management)) = 7 THEN 1 ELSE 0 END + 
			CASE WHEN DATEPART ( WEEKDAY, CAST(dim_detail_property.[completion_date] AS INT) ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Complete]


	--,DateDiff(dd, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date]) - DateDiff(ww, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date])*2 as test

			, dim_fed_hierarchy_history.[name] AS [Fee Earner]
			, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
			, dim_department.[department_name] AS [Department]
			, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
			, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
			, CASE WHEN dim_matter_header_current.client_code ='00787558' THEN 'Superdrug'
						WHEN dim_matter_header_current.client_code ='00787559' THEN 'The Perfume Shop'
						WHEN dim_matter_header_current.client_code ='00787560' THEN 'Three Mobile'
						WHEN dim_matter_header_current.client_code ='00787561' THEN 'Savers Health and Beauty'
						END AS [Fascia]
			, CASE WHEN (COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received]) IS NOT NULL) 
						AND ((DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = 3) 
						--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-2)
						--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-3) 
						AND DATEPART(YEAR, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(YEAR, GETDATE())) 
						THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) ELSE NULL END [Days to Documents Received]
			--, CASE WHEN (dim_detail_property.[date_elements_agreed] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = 1 /*OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[date_elements_agreed]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed]) ELSE NULL END [Days to Transaction Agreed]
			--, CASE WHEN (dim_detail_property.[completion_date] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[completion_date]) = 1 /*OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date]) ELSE NULL  END [Days to Complete]
			, 2 [Previous Month] -- current month
			, DATEPART(YEAR, GETDATE()) [Current Year]
			, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = 3) /* OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-3)*/ AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE()) THEN '1' ELSE '0' END AS [New (Month)]
			, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = 3) /*OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3)*/ AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) THEN '1' ELSE '0' END AS [Completed (Month)]
			, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END AS [New (Year)]
			, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END AS [Completed (Year)]
			, [Legal Spend] AS [Legal Spend]
			, [Current Legal Spend] AS [Current Legal Spend]
			, [InvDate] AS [Bill Date]
			, DATEPART(MONTH,[InvDate]) AS [Bill Date (month)]
			, DATEPART(YEAR,[InvDate]) AS [Bill Date (year)]
			, 'Bill Level' AS [Level]
			,  InvoiceDate
			,ISNULL(StatusChanged,0) AS StatusChanged
			,dim_matter_header_current.matter_description
			,dim_detail_property.property_contact


	FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
	LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key

	LEFT OUTER JOIN (SELECT Matters.Client
							, Matters.Matter
							, ARMaster.ARFee AS [ARFee]
							, ARMaster.InvDate AS [InvDate]
	, CASE WHEN ARMaster.InvDate BETWEEN '2018-01-01' AND '2018-03-31' THEN ARMaster.ARFee ELSE '0' END [Legal Spend] --YTD
							, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = DATEPART(YEAR, GETDATE()) AND (DATEPART(MONTH, ARMaster.InvDate) = 3 /*OR DATEPART(MONTH, ARMaster.InvDate) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, ARMaster.InvDate) = DATEPART(MONTH, GETDATE())-3*/) THEN ARMaster.ARFee ELSE '0' END [Current Legal Spend]
							, ARMaster.InvDate AS InvoiceDate
					FROM  TE_3E_Prod.dbo.InvMaster WITH (NOLOCK) 
					INNER JOIN  TE_3E_Prod.dbo.ARMaster WITH (NOLOCK)
					ON InvMaster.InvIndex=ARMaster.InvMaster 
					INNER JOIN  
					(
					SELECT  ISNULL(RTRIM(LEFT(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) - 1)) ,RTRIM(LEFT(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) - 1)) ) AS Client
							,ISNULL(SUBSTRING(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber)  + 1, LEN(Matter.LoadNumber)),SUBSTRING(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber)  + 1, LEN(Matter.AltNumber))) AS Matter
							,Matter.MattIndex
							,LoadNumber AS LoadNumber
							,RelMattIndex
					FROM TE_3E_Prod.dbo.Matter
					) AS Matters
					ON ARMaster.Matter=Matters.MattIndex 

					WHERE Matters.Client IN ('00787558','00787559','00787560','00787561')
					AND ARList='Bill'
					--AND (CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, ARMaster.InvDate) <> DATEPART(MONTH, GETDATE()) THEN 1 ELSE 0 END) = 1)
					) AS [Bills] ON [Bills].Client=dim_matter_header_current.client_code COLLATE DATABASE_DEFAULT AND [Bills].Matter = dim_matter_header_current.matter_number COLLATE DATABASE_DEFAULT

	LEFT OUTER JOIN (SELECT dim_detail_previous_details.client_code
				  , dim_detail_previous_details.matter_number
				  , CASE WHEN RTRIM([status_rm]) <>   RTRIM([prev_status_rm]) THEN 1 ELSE 0 END  AS StatusChanged
              
	FROM red_dw.dbo.dim_detail_previous_details
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code = dim_detail_previous_details.client_code AND dim_matter_header_current.matter_number = dim_detail_previous_details.matter_number
	WHERE 
	dim_detail_previous_details.client_code IN ('00787558','00787559','00787560','00787561','R1001','P00010','P00011','P00012','P00020','P00021','P00022')
	AND 
	prev_status_rm IS NOT NULL) AS CompletionRule
	 ON dim_matter_header_current.client_code = CompletionRule.client_code
	AND  dim_matter_header_current.matter_number = CompletionRule.matter_number

	WHERE dim_matter_header_current.client_code IN ('00787558','00787559','00787560','00787561')
	AND dim_matter_header_current.matter_number <> 'ML'
	--AND dim_detail_property.[case_type_asw] IS NOT NULL 
	AND ISNULL(dim_detail_property.[status_rm],'') <> 'On Hold'
	AND RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number <> '00787558/00010157' -- Ticket 208667











GO
