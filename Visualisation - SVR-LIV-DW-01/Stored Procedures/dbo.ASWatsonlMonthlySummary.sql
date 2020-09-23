SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2018-09-21
Description:		AS Watson Monthly Summary to drive the Tableau Vis
Current Version:	Initial Create
====================================================
====================================================

*/
CREATE PROCEDURE [dbo].[ASWatsonlMonthlySummary]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* History
Version	  Date		    By		Description
************************************************************************************************ 
1.1	      12-04-2017	JL		replaced "Days to Complete Cases" with new logic for week days only see ticket 221792
1.2       17-08-2017    JL      I have changed the 'days to complete' to look at Trans Agreed as per ticket 252331
1.3		  07-09-2018    LD		Amended Days to completion/ Days to Exchange and Days to transaction agreed as per D.Tabinor 334463
1.4		  01-10-2018	JL	    Replaced date_elements_agreed with date_lease_agreed as per Dave T
1.5		  04-10-2018    LD		Replaced the dbo.getWeekdays function with [dbo].[ReturnElapsedDaysExcludingBankHolidays]


*/
  DECLARE @Month INT = 07 --CHANGE THIS TO RELAVENT MONTH REPORTING AND CHANGE THE INV DATE (IN BELOW CODE) TO INCLUDE THE MONTH REPORTING
  DECLARE @Year INT = 2020
   
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
   
     SELECT dim_matter_header_current.client_code AS [Client Code]
		, dim_matter_header_current.matter_number AS [Matter Number]
		, ISNULL(dim_detail_property.[case_type_asw_desc],'Miscellaneous')  AS [Case Type - ASW]
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
/*		
,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=7 AND DATEPART(year,dim_detail_property.[completion_date])=2018 OR DATEPART(MONTH,dim_detail_property.[date_elements_agreed])=7 AND DATEPART(year,dim_detail_property.[date_elements_agreed])=2018 THEN DATEDIFF( day, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] ) - 2*datediff( week, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] )  + 
		case when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 7 then 1 else 0 end + 
		case when datepart ( weekday, dim_detail_property.[date_elements_agreed] ) = 7 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then 1 else 0 END ELSE NULL END AS [Days to Transaction Agreed]


,CASE WHEN DATEPART(MONTH,dim_detail_property.[exchange_date])=7 AND DATEPART(year,dim_detail_property.[exchange_date])=2018 THEN DATEDIFF( day, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] ) - 2*datediff( week, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] )  + 
		case when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 7 then 1 else 0 end + 
		case when datepart ( weekday, dim_detail_property.[exchange_date] ) = 7 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then 1 else 0 end ELSE NULL END AS [Days to Exchange]


,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=7 AND DATEPART(year,dim_detail_property.[completion_date])=2018 THEN DATEDIFF( day, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), cast(dim_detail_property.[completion_date] as int) ) - 2*datediff( week, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), cast (dim_detail_property.[completion_date] as int) )  + 
		case when datepart ( weekday, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 then -1 when datepart ( weekday, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management)) = 7 then 1 else 0 end + 
		case when datepart ( weekday, cast(dim_detail_property.[completion_date] as int) ) = 7 then -1 when datepart ( weekday, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 then 1 else 0 end ELSE NULL END AS [Days to Complete]

*/
--,DateDiff(dd, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date]) - DateDiff(ww, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date])*2 as test

	/**********************************************************************************************
				1.3 amended below
				1st line excludeds the days value doesn't fall in the correct @Month / @Year
				2nd line calculates the days if any of the dates fall in the correct @Month
				ELSE sets the days to NULL if they do not fall into any of the above (this is so that Average will work in the report)
			*/
			,CASE WHEN (DATEPART(MONTH,dim_detail_property.date_lease_agreed)<>@Month	OR DATEPART(YEAR,dim_detail_property.date_lease_agreed)<>@Year) THEN NULL

			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
				OR (DATEPART(MONTH,dim_detail_property.date_lease_agreed)=@Month	AND DATEPART(YEAR,dim_detail_property.date_lease_agreed)=@Year)
				OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (dim_matter_header_current.date_opened_case_management,dim_detail_property.date_lease_agreed )
			ELSE NULL END [Days to Transaction Agreed] /*1.4 jl*/
		
		,CASE WHEN (DATEPART(MONTH,dim_detail_property.[exchange_date])<>@Month			OR DATEPART(YEAR,dim_detail_property.[exchange_date])<>@Year) THEN NULL
			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
				OR (DATEPART(MONTH,dim_detail_property.date_lease_agreed)=@Month	AND DATEPART(YEAR,dim_detail_property.date_lease_agreed)=@Year)
				OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(dim_detail_property.date_lease_agreed,dim_matter_header_current.date_opened_case_management),dim_detail_property.[exchange_date] )
			ELSE NULL END [Days to Exchange] /*1.4 jl*/
	
		,CASE	WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])<>@Month		OR DATEPART(YEAR,dim_detail_property.[completion_date])<>@Year) THEN NULL
			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
			OR (DATEPART(MONTH,dim_detail_property.date_lease_agreed)=@Month	AND DATEPART(YEAR,dim_detail_property.date_lease_agreed)=@Year)
			OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(dim_detail_property.[exchange_date],dim_detail_property.date_lease_agreed,dim_matter_header_current.date_opened_case_management),dim_detail_property.[completion_date] )
			ELSE NULL END [Days to Complete] /*1.4 jl*/

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
					AND ((DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = @Month )
					--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-2)
					--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-3) 
					AND DATEPART(YEAR, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = @Year) 
					THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) ELSE NULL END [Days to Documents Received]
		--, CASE WHEN (dim_detail_property.[date_elements_agreed] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = 1 /* OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[date_elements_agreed]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed]) ELSE NULL END [Days to Transaction Agreed]
		--, CASE WHEN (dim_detail_property.[completion_date] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[completion_date]) = 2 /* OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date]) ELSE NULL END [Days to Complete]
		, @Month [Previous Month] --current month
		, @Year [Current Year]
		, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = @Month /* OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = @Year THEN '1' ELSE '0' END [New (Month)]
		, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = @Month /*OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[completion_date]) = @Year THEN '1' ELSE '0' END [Completed (Month)]
		, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = @Year AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [New (Year)]
		, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = @Year AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [Completed (Year)]
		, NULL [Legal Spend]
		, NULL [Current Legal Spend]
		, NULL [Bill Date]
		, NULL [Bill Date (month)]
		, NULL [Bill Date (year)]
		, 'Matter Level' [Level]
		, NULL InvoiceDate
		,ISNULL(StatusChanged,0) AS StatusChanged

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
and RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number <> '00787558/00010157'  -- Ticket 208667
AND ISNULL(dim_matter_header_current.ms_fileid,-1) NOT IN (4995876)  -- requested by Kate Fox

UNION ALL 

SELECT dim_matter_header_current.client_code AS [Client Code]
		, dim_matter_header_current.matter_number AS [Matter Number]
		, ISNULL(dim_detail_property.[case_type_asw_desc],'Miscellaneous')  AS [Case Type - ASW]
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
/* ,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=7 AND DATEPART(year,dim_detail_property.[completion_date])=2018 OR DATEPART(MONTH,dim_detail_property.[date_elements_agreed])=7 AND DATEPART(year,dim_detail_property.[date_elements_agreed])=2018 THEN DATEDIFF( day, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] ) - 2*datediff( week, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed] )  + 
		case when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 7 then 1 else 0 end + 
		case when datepart ( weekday, dim_detail_property.[date_elements_agreed] ) = 7 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then 1 else 0 END ELSE NULL END AS [Days to Transaction Agreed]


,CASE WHEN DATEPART(MONTH,dim_detail_property.[exchange_date])=7 AND DATEPART(year,dim_detail_property.[exchange_date])=2018 THEN DATEDIFF( day, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] ) - 2*datediff( week, dim_matter_header_current.date_opened_case_management, dim_detail_property.[exchange_date] )  + 
		case when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 7 then 1 else 0 end + 
		case when datepart ( weekday, dim_detail_property.[exchange_date] ) = 7 then -1 when datepart ( weekday, dim_matter_header_current.date_opened_case_management ) = 1 then 1 else 0 end ELSE NULL END AS [Days to Exchange]


,CASE WHEN DATEPART(MONTH,dim_detail_property.[completion_date])=7 AND DATEPART(year,dim_detail_property.[completion_date])=2018 THEN DATEDIFF( day, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), cast(dim_detail_property.[completion_date] as int) ) - 2*datediff( week, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management), cast (dim_detail_property.[completion_date] as int) )  + 
		case when datepart ( weekday, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 then -1 when datepart ( weekday, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management)) = 7 then 1 else 0 end + 
		case when datepart ( weekday, cast(dim_detail_property.[completion_date] as int) ) = 7 then -1 when datepart ( weekday, COALESCE(dim_detail_property.[date_elements_agreed],dim_matter_header_current.date_opened_case_management) ) = 1 then 1 else 0 end ELSE NULL END AS [Days to Complete]
*/

	/*
				1.3 amended below
				1st line excludeds the days value doesn't fall in the correct @Month / @Year
				2nd line calculates the days if any of the dates fall in the correct @Month
				ELSE sets the days to NULL if they do not fall into any of the above (this is so that Average will work in the report)
			*/
			,CASE WHEN (DATEPART(MONTH,dim_detail_property.date_lease_agreed)<>@Month	OR DATEPART(YEAR,dim_detail_property.date_lease_agreed)<>@Year) THEN NULL

			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
				OR (DATEPART(MONTH,dim_detail_property.date_lease_agreed)=@Month	AND DATEPART(YEAR,dim_detail_property.date_lease_agreed)=@Year)
				OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (dim_matter_header_current.date_opened_case_management,dim_detail_property.date_lease_agreed )
			ELSE NULL END [Days to Transaction Agreed] /*1.4 jl*/
		
		,CASE WHEN (DATEPART(MONTH,dim_detail_property.[exchange_date])<>@Month			OR DATEPART(YEAR,dim_detail_property.[exchange_date])<>@Year) THEN NULL
			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
				OR (DATEPART(MONTH,dim_detail_property.date_lease_agreed)=@Month	AND DATEPART(YEAR,dim_detail_property.date_lease_agreed)=@Year)
				OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(dim_detail_property.date_lease_agreed,dim_matter_header_current.date_opened_case_management),dim_detail_property.[exchange_date] )
			ELSE NULL END [Days to Exchange] /*1.4 jl*/
	
		,CASE	WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])<>@Month		OR DATEPART(YEAR,dim_detail_property.[completion_date])<>@Year) THEN NULL
			WHEN (DATEPART(MONTH,dim_detail_property.[completion_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[completion_date])=@Year) 
			OR (DATEPART(MONTH,dim_detail_property.date_lease_agreed)=@Month	AND DATEPART(YEAR,dim_detail_property.date_lease_agreed)=@Year)
			OR (DATEPART(MONTH,dim_detail_property.[exchange_date])=@Month			AND DATEPART(YEAR,dim_detail_property.[exchange_date])=@Year)
			THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(dim_detail_property.[exchange_date],dim_detail_property.date_lease_agreed,dim_matter_header_current.date_opened_case_management),dim_detail_property.[completion_date] )
			ELSE NULL END [Days to Complete] /*1.4 jl*/

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
					AND ((DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = @Month) 
					--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-2)
					--OR DATEPART(MONTH, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = DATEPART(MONTH, GETDATE())-3) 
					AND DATEPART(YEAR, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) = @Year) 
					THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, COALESCE(dim_detail_property.[date_documents_received_assignor_solicitors], dim_detail_property.[date_landlord_solicitor_documents_received], dim_detail_property.[date_required_documents_received], dim_detail_property.[date_seller_solicitor_documents_received])) ELSE NULL END [Days to Documents Received]
		--, CASE WHEN (dim_detail_property.[date_elements_agreed] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = 1 /*OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[date_elements_agreed]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[date_elements_agreed]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[date_elements_agreed]) ELSE NULL END [Days to Transaction Agreed]
		--, CASE WHEN (dim_detail_property.[completion_date] IS NOT NULL) AND ((DATEPART(MONTH, dim_detail_property.[completion_date]) = 1 /*OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3*/) AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_property.[completion_date]) ELSE NULL  END [Days to Complete]
		, @Month [Previous Month] -- current month
		, @Year [Current Year]
		, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = @Month) /* OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-3)*/ AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = @Year THEN '1' ELSE '0' END AS [New (Month)]
		, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = @Month) /*OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-3)*/ AND DATEPART(YEAR, dim_detail_property.[completion_date]) = @Year THEN '1' ELSE '0' END AS [Completed (Month)]
		, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = @Year AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END AS [New (Year)]
		, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = @Year AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END AS [Completed (Year)]
		, [Legal Spend] AS [Legal Spend]
		, [Current Legal Spend] AS [Current Legal Spend]
		, [InvDate] AS [Bill Date]
		, DATEPART(MONTH,[InvDate]) AS [Bill Date (month)]
		, DATEPART(YEAR,[InvDate]) AS [Bill Date (year)]
		, 'Bill Level' AS [Level]
		,  InvoiceDate
		,ISNULL(StatusChanged,0) AS StatusChanged


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
, CASE WHEN ARMaster.InvDate BETWEEN '2020-01-01' AND '2020-07-31' THEN ARMaster.ARFee ELSE '0' END [Legal Spend] --YTD */ *******CHANGE THIS DATE*******/*
						, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = @Year AND (DATEPART(MONTH, ARMaster.InvDate) = @Month /*OR DATEPART(MONTH, ARMaster.InvDate) = DATEPART(MONTH, GETDATE())-2 OR DATEPART(MONTH, ARMaster.InvDate) = DATEPART(MONTH, GETDATE())-3*/) THEN ARMaster.ARFee ELSE '0' END [Current Legal Spend]
						, ARMaster.InvDate as InvoiceDate
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
				AND ARList in ('Bill','BillRev')
				--AND (CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, ARMaster.InvDate) <> DATEPART(MONTH, GETDATE()) THEN 1 ELSE 0 END) = 1)
				) AS [Bills] ON [Bills].Client=dim_matter_header_current.client_code COLLATE database_default AND [Bills].Matter = dim_matter_header_current.matter_number COLLATE database_default

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
and RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number <> '00787558/00010157' -- Ticket 208667
AND ISNULL(dim_matter_header_current.ms_fileid,-1) NOT IN (4995876)  -- requested by Kate Fox


END


GO
