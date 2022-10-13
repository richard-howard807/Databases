SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2018-07-10
Description:		Royal Mail Real Estate Monthly Summary MI to drive the Tableau Dashboard
Current Version:	Initial Create
====================================================
====================================================

*/

CREATE PROCEDURE [Tableau].[RoyalMailRealEstateMonthlySummary]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
dim_matter_header_current.client_code AS [Client]
, dim_matter_header_current.matter_number AS [Matter]
, dim_matter_worktype.[work_type_name] AS [Work Type]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_detail_property.[fixed_feehourly_rate] AS [Fixed fee/Hourly rate]
, dim_detail_property.[team] AS [Team]
, dim_detail_property.[case_classification] AS [Case classification]
, dim_detail_property.[completion_date] AS [Completion Date]
, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (date_opened_practice_management,coalesce( dim_detail_property.[completion_date],dim_detail_property.date_elements_agreed)) AS [Days to Complete Cases]
, CASE WHEN dim_detail_property.[completion_date] IS NULL THEN '0' ELSE '1' END AS [Completed Cases]
, NULL AS [Legal Spend]
, NULL AS [Current Month Legal Spend]
, dim_matter_header_current.date_closed_case_management AS [Date Closed]
, NULL [Bill Date]
, NULL [Bill Date (month)]
, NULL [Bill Date (year)]
, DATEPART(MONTH, GETDATE())-1 [Previous Month]
, DATEPART(YEAR, GETDATE()) [Current Year]
, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-1  AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [New (Month)]
, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-1 AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [Completed (Month)]
, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [New (Year)]
, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [Completed (Year)]
, 'Matter Level' [Level]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw..dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key


WHERE (dim_matter_header_current.client_code IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022') 
OR (dim_detail_property.client_code='R1001' AND dim_instruction_type.instruction_type IN ('Real Estate Transactional Work (Volume)','Real Estate Litigation Work (Volume)', 'Real Estate Advisory Work (Volume)','Real Estate Transactional Work (BAU)','Real Estate Litigation Work (BAU)','Real Estate Advisory Work (BAU)')))
AND dim_matter_header_current.matter_number <> 'ML'
AND (CASE WHEN date_closed_case_management IS NOT NULL THEN 0 ELSE 1 END)=1
AND (LOWER(matter_description) NOT LIKE '%ignore%' OR LOWER(matter_description) NOT LIKE '%opened in error%' )
AND  ISNULL(dim_detail_property.status_rm,'') <> 'On hold'


UNION ALL 

/****Bills Level Data Below*/

SELECT dim_matter_header_current.client_code AS [Client Code]
, dim_matter_header_current.matter_number AS [Matter Number]
, dim_matter_worktype.[work_type_name] AS [Work Type]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_detail_property.[fixed_feehourly_rate] AS [Fixed fee/Hourly rate]
, dim_detail_property.[team] AS [Team]
, dim_detail_property.[case_classification] AS [Case classification]
, dim_detail_property.[completion_date] AS [Completion Date]
, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (date_opened_practice_management,coalesce( dim_detail_property.[completion_date],dim_detail_property.date_elements_agreed)) AS [Days to Complete Cases]
, CASE WHEN dim_detail_property.[completion_date] IS NULL THEN '0' ELSE '1' END AS [Completed Cases]
, [Legal Spend] AS [Legal Spend]
, [Current Month Legal Spend] AS [Current Month Legal Spend]
, dim_matter_header_current.date_closed_case_management AS [Date Closed]
, Bills.bill_date AS [Bill Date]
, DATEPART(MONTH,Bills.bill_date) AS [Bill Date (month)]
, DATEPART(YEAR,Bills.bill_date) AS [Bill Date (year)]
, DATEPART(MONTH, GETDATE())-1 [Previous Month]
, DATEPART(YEAR, GETDATE()) [Current Year]
, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-1  AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [New (Month)]
, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-1 AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [Completed (Month)]
, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [New (Year)]
, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [Completed (Year)]
, 'Bill Level' AS [Level]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw..dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN (SELECT 
				     client_code
				   , matter_number
				   , bill_date
				   , sum(bill_total) as Bill_Total
				   , sum(fees_total) as Fees_Total
				   , sum(CASE WHEN DATEPART(YEAR, bill_date) = DATEPART(YEAR, GETDATE()) AND (DATEPART(MONTH, bill_date) <> DATEPART(MONTH, GETDATE()) AND DATEPART(MONTH, bill_date) <> DATEPART(MONTH, GETDATE())-1) THEN fees_total ELSE '0' END) [Legal Spend]
				   , sum(CASE WHEN DATEPART(YEAR, bill_date) = DATEPART(YEAR, GETDATE()) AND (DATEPART(MONTH, bill_date) = DATEPART(MONTH, GETDATE()) -1) THEN fees_total ELSE '0' END) [Current Month Legal Spend]
				   , master_fact_key
				
				FROM red_dw..fact_bill_matter_detail AS billlevel
				WHERE 
				     client_code IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022','R1001')
				     AND CASE WHEN DATEPART(YEAR, bill_date) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, bill_date) <> DATEPART(MONTH, GETDATE()) THEN 1 ELSE 0 END = 1
				GROUP BY
				     client_code
				   , matter_number
				   , master_fact_key
				   , bill_date
				)  AS Bills ON fact_dimension_main.master_fact_key = Bills.master_fact_key 


WHERE (dim_matter_header_current.client_code IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022') 
OR (dim_detail_property.client_code='R1001' 
AND dim_instruction_type.instruction_type IN ('Real Estate Transactional Work (Volume)','Real Estate Litigation Work (Volume)', 'Real Estate Advisory Work (Volume)','Real Estate Transactional Work (BAU)','Real Estate Litigation Work (BAU)','Real Estate Advisory Work (BAU)')))
AND dim_matter_header_current.matter_number <> 'ML'
AND (CASE WHEN date_closed_case_management IS NOT NULL AND Bills.bill_date IS NULL THEN 0 ELSE 1 END)=1
AND (LOWER(matter_description) NOT LIKE '%ignore%' OR LOWER(matter_description) NOT LIKE '%opened in error%' )
AND  ISNULL(dim_detail_property.status_rm,'') <> 'On hold'

END
GO
