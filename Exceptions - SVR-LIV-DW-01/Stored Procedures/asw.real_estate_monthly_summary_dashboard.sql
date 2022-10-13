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
1.5		22-08-2018 LD	Amended the calculations for days to exchange and days to completion
1.6		28-08-2018 LD	Amended the calculations for all of the Days to fields
						Also excluded later dates and days from showing in the report	
1.7     07/09/2018 LD  Amending as per D.Tabinor 

						So if I understand you correctly below, you've raised good point.  If the date of exchange falls in July, the table shows the previous "date to docs agreed" which, 
						if that date falls in June, still forms part of the July stats. 
						So we either : 
					-show any earlier dates that fall in a previous month but exclude them from the calculation (what we do now); or 
					-show any earlier dates that fall in a previous month but exclude them from the calculation (which would distort the average); or 
					-remove the earlier dates if they fall in a previous month and blanks out the cells 
				I think I'm leaning towards the latter. Otherwise a bad result for the "docs to agreed" stage will come back to haunt us in later months at exchange and completion 
				(unless they are all in the same month -- which is unlikely) as it will form part of those later stats. 


1.8 23/09/2018 Replaced date elements agreed with date lease agreed
1.9 13/05/2019 Exclude Miscellaneous and 'Renewal - LTA 1954 from the report #18837
*/
CREATE PROCEDURE [asw].[real_estate_monthly_summary_dashboard]
	-- Add the parameters for the stored procedure here
	@Year INT
	,@Month INT 
AS

		
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		-- Test Data
		--DECLARE @Year INT = 2019
		--DECLARE @Month INT = 4

		DECLARE @cal_year_start DATE = CAST(@Year AS VARCHAR(4)) + '0101'
		DECLARE @cal_year_end DATE 
		
		IF @Month = 12
		BEGIN
        
		SET @cal_year_end = CAST(@Year AS VARCHAR(4)) + '1231'
		END
		ELSE
		BEGIN
        SET @cal_year_end = DATEADD(DAY,-1,CAST(@Year AS VARCHAR(4)) + RIGHT('00'+CAST(@Month+1 AS VARCHAR(2)),2) + '01')
		END

		 



	   SELECT dim_matter_header_current.client_code AS [Client Code]
			, dim_matter_header_current.matter_number AS [Matter Number]
			, dim_detail_property.[case_type_asw_desc]  AS [Case Type - ASW]
			, dim_matter_worktype.[work_type_name] AS [Work Type]
			, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received]) AS [Date Documents Received]
			/* 1.6 Corrected the dates so that they only show if the are <= month run of the report*/
			, CASE WHEN (DATEPART(MONTH,dim_detail_property.[date_lease_agreed])<>@Month	OR DATEPART(YEAR,dim_detail_property.[date_lease_agreed])<>@Year) THEN NULL ELSE dim_detail_property.[date_lease_agreed] END AS [Date Transaction Agreed]
			, CASE WHEN (DATEPART(MONTH,dim_detail_property.[exchange_date])<>@Month			OR DATEPART(YEAR,dim_detail_property.[exchange_date])<>@Year) THEN NULL ELSE dim_detail_property.[exchange_date] END AS [Exchange Date]
			, CASE WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])<>@Month		OR DATEPART(YEAR,dim_detail_property.[completion_date])<>@Year) THEN NULL ELSE dim_detail_property.[completion_date] END AS [Completion Date]
			--, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) AS [Days to Documents Received]

			/*1.1  -  removed as per Kate Fox and replaced with below logic for week days only 
				*********************************************************************************
		  , DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[date_lease_agreed]) AS [Days to Transaction Agreed] 
		  , DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[exchange_date]) AS [Days to Exchange]
		  , DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_property.[completion_date]) AS [Days to Complete]
			*/
			/*
				1.6 amended below
				1st line excludeds the days value if the date concerned is greater than the @Month
				2nd line calculates the days if any of the dates fall in the correct @Month
				ELSE sets the days to NULL if they do not fall into any of the above (this is so that Average will work in the report)
			*/
		,CASE WHEN (DATEPART(MONTH,dim_detail_property.[date_lease_agreed])<>@Month	OR DATEPART(YEAR,dim_detail_property.[date_lease_agreed])<>@Year) THEN NULL

			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
				OR (DATEPART(MONTH,dim_detail_property.[date_lease_agreed])=@Month	AND DATEPART(YEAR,dim_detail_property.[date_lease_agreed])=@Year)
				OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (dim_matter_header_current.date_opened_case_management,dim_detail_property.[date_lease_agreed] )
			ELSE NULL END [Days to Transaction Agreed]
		
		,CASE WHEN (DATEPART(MONTH,dim_detail_property.[exchange_date])<>@Month			OR DATEPART(YEAR,dim_detail_property.[exchange_date])<>@Year) THEN NULL
			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
				OR (DATEPART(MONTH,dim_detail_property.[date_lease_agreed])=@Month	AND DATEPART(YEAR,dim_detail_property.[date_lease_agreed])=@Year)
				OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(dim_detail_property.[date_lease_agreed],dim_matter_header_current.date_opened_case_management),dim_detail_property.[exchange_date] )
			ELSE NULL END [Days to Exchange]
	
		,CASE	WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])<>@Month		OR DATEPART(YEAR,dim_detail_property.[completion_date])<>@Year) THEN NULL
			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
			OR (DATEPART(MONTH,dim_detail_property.[date_lease_agreed])=@Month	AND DATEPART(YEAR,dim_detail_property.[date_lease_agreed])=@Year)
			OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(dim_detail_property.[exchange_date],dim_detail_property.[date_lease_agreed],dim_matter_header_current.date_opened_case_management),dim_detail_property.[completion_date] )
			ELSE NULL END [Days to Complete]

	--,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=@Month AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year 
	--		OR DATEPART(MONTH,dim_detail_property.[date_elements_agreed])=@Month AND DATEPART(YEAR,dim_detail_property.[date_elements_agreed])=@Year THEN DATEDIFF( DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] ) - 2*DATEDIFF( WEEK, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] )  + 
	--		CASE WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 7 THEN 1 ELSE 0 END + 
	--		CASE WHEN DATEPART ( WEEKDAY, dim_detail_property.[date_elements_agreed] ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, dim_matter_header_current.date_opened_case_management ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Transaction Agreed]


	--,CASE WHEN DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year THEN DATEDIFF( DAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), dim_detail_property.[exchange_date] ) - 2*DATEDIFF( WEEK, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), dim_detail_property.[exchange_date] )  + 
	--		CASE WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management )) = 7 THEN 1 ELSE 0 END + 
	--		CASE WHEN DATEPART ( WEEKDAY, dim_detail_property.[exchange_date] ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management )) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Exchange]


	--,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=@Month AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year THEN DATEDIFF( DAY, COALESCE(dim_detail_property.[exchange_date],dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), CAST(dim_detail_property.[completion_date] AS INT) ) - 2*DATEDIFF( WEEK, COALESCE(dim_detail_property.[exchange_date],dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), CAST (dim_detail_property.[completion_date] AS INT) )  + 
	--		CASE WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[exchange_date],dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[exchange_date],dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management)) = 7 THEN 1 ELSE 0 END + 
	--		CASE WHEN DATEPART ( WEEKDAY, CAST(dim_detail_property.[completion_date] AS INT) ) = 7 THEN -1 WHEN DATEPART ( WEEKDAY, COALESCE(dim_detail_property.[exchange_date],dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 THEN 1 ELSE 0 END ELSE NULL END AS [Days to Complete]

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
			,  @Month [Previous Month]   --current month
			, DATEPART(YEAR, GETDATE()) [Current Year]
			, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = @Month /* OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE())THEN '1' ELSE '0' END [New (Month)]
			, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = @Month /*OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) THEN '1' ELSE '0' END [Completed (Month)]
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
	 -- excluded case_id 711935 (787558-10205) & case_id 710901 (787561-10085)  Ticket 221792
	AND ISNULL(dim_matter_header_current.case_id,0) NOT IN (711935,710901)
	AND ISNULL(dim_matter_header_current.ms_fileid,-1) NOT IN (4995876)  -- requested by Kate Fox

	--AND ( (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
	--				OR (DATEPART(MONTH,dim_detail_property.[date_elements_agreed])=@Month	AND DATEPART(YEAR,dim_detail_property.[date_elements_agreed])=@Year)
	--				OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
	--	)
			
	-- LD 20190513
	AND ISNULL(dim_detail_property.[case_type_asw_desc] ,'') NOT IN ('Renewal - LTA 1954', 'Miscellaneous'   )                                     
	
	ORDER BY dim_matter_header_current.client_code, dim_matter_header_current.matter_number
















GO
