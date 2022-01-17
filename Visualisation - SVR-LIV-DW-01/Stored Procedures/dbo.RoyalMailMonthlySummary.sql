SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2018-09-21
Description:		Royal Mail Monthly Summary to drive the Tableau Vis
Current Version:	Initial Create
====================================================
-- JB - 2020-09-08 - changed to look 2 months back to July for ticket #70140. Will revert to 1 month back once ticket closed off
-- JB - 2020-09-08 - reverted back to original query ready for next months dashboard update
-- JB - 2022-01-14 - added @fin_period/@previous_month/@current_year variables so proc doesn't need changing in January to deal with December
====================================================

*/
CREATE PROCEDURE [dbo].[RoyalMailMonthlySummary]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @fin_period AS VARCHAR(20) = (SELECT TOP 1
										last_month.last_month
									FROM (
										SELECT TOP 1
											dim_date.fin_period
											, LAG(dim_date.fin_period, 1) OVER	(ORDER BY dim_date.fin_period) AS last_month
										FROM red_dw.dbo.dim_date
										WHERE
											dim_date.calendar_date <= CAST(GETDATE() AS DATE)
										ORDER BY
											dim_date.fin_period DESC
										) AS last_month
									)
DECLARE @previous_month AS INT = (SELECT DISTINCT dim_date.cal_month_no FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @fin_period)
DECLARE @current_year AS INT = (SELECT DISTINCT dim_date.cal_year FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @fin_period)
DECLARE @current_month AS INT = (SELECT IIF(MONTH(GETDATE()) = 1, 0, MONTH(GETDATE()))) 

--SELECT @fin_period, @previous_month, @current_year, @current_month 

--uncomment for january and comment out below select as it deals with december

SELECT dim_matter_header_current.client_code AS [Client]
	        
			, dim_matter_header_current.matter_number AS [Matter]
			, RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
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
	
	
		--	, DATEPART(MONTH, GETDATE())-1 [Previous Month]
		--	, DATEPART(YEAR, GETDATE()) [Current Year]
		--	, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-1  AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [New (Month)]

		--, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-1 AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [Completed (Month)]
		--, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [New (Year)]
		--, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [Completed (Year)]
		, @previous_month [Previous Month]
		, @current_year [Current Year]
		, CASE WHEN dim_date_opened.fin_period = @fin_period THEN '1' ELSE '0' END [New (Month)]

		, CASE WHEN dim_date_completed.fin_period = @fin_period THEN '1' ELSE '0' END [Completed (Month)]
		, CASE WHEN dim_date_opened.cal_year = @current_year AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> @current_month THEN '1' ELSE '0' END [New (Year)]
		, CASE WHEN dim_date_completed.cal_year = @current_year AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> @current_month THEN '1' ELSE '0' END [Completed (Year)]
		, 'Matter Level' [Level]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw..dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
INNER JOIN red_dw.dbo.dim_date AS dim_date_opened
	ON dim_date_opened.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
LEFT OUTER JOIN red_dw.dbo.dim_date AS dim_date_completed
	ON dim_date_completed.calendar_date = CAST(dim_detail_property.completion_date AS DATE)
WHERE (dim_matter_header_current.client_code IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022') 
OR (dim_detail_property.client_code='R1001' AND dim_instruction_type.instruction_type IN ('Real Estate Transactional Work (Volume)','Real Estate Litigation Work (Volume)', 'Real Estate Advisory Work (Volume)','Real Estate Transactional Work (BAU)','Real Estate Litigation Work (BAU)','Real Estate Advisory Work (BAU)')))
AND dim_matter_header_current.matter_number <> 'ML'
--AND date_opened_case_management>='20170501'
AND (CASE WHEN date_closed_case_management IS NOT NULL THEN 0 ELSE 1 END)=1
AND (LOWER(matter_description) NOT LIKE '%ignore%' OR LOWER(matter_description) NOT LIKE '%opened in error%' )
AND  ISNULL(dim_detail_property.status_rm,'') <> 'On hold'


UNION ALL 

SELECT dim_matter_header_current.client_code AS [Client Code]
		, dim_matter_header_current.matter_number AS [Matter Number]
		, RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, dim_matter_worktype.[work_type_name] AS [Work Type]
		, dim_matter_header_current.date_opened_case_management AS [Date Opened]
		, dim_detail_property.[fixed_feehourly_rate] AS [Fixed fee/Hourly rate]
		, dim_detail_property.[team] AS [Team]
		, dim_detail_property.[case_classification] AS [Case classification]
		, dim_detail_property.[completion_date] AS [Completion Date]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (date_opened_practice_management,coalesce( dim_detail_property.[completion_date],dim_detail_property.date_elements_agreed)) AS [Days to Complete Cases]
		, CASE WHEN dim_detail_property.[completion_date] IS NULL THEN '0' ELSE '1' END AS [Completed Cases]
		, [Legal Spend] AS [Legal Spend]
		, [Current Legal Spend] AS [Current Month Legal Spend]
		, dim_matter_header_current.date_closed_case_management AS [Date Closed]
		, [InvDate] AS [Bill Date]
		, DATEPART(MONTH,[InvDate]) AS [Bill Date (month)]
		, DATEPART(YEAR,[InvDate]) AS [Bill Date (year)]
		--, DATEPART(MONTH, GETDATE())-1 [Previous Month]
		--, DATEPART(YEAR, GETDATE()) [Current Year]
		--, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = DATEPART(MONTH, GETDATE())-1  AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [New (Month)]

		--, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = DATEPART(MONTH, GETDATE())-1 AND DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE())) THEN '1' ELSE '0' END [Completed (Month)]
		--, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [New (Year)]
		--, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = DATEPART(YEAR, GETDATE()) AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> DATEPART(MONTH, GETDATE()) THEN '1' ELSE '0' END [Completed (Year)]
		, @previous_month [Previous Month]
		, @current_year [Current Year]
		, CASE WHEN dim_date_opened.fin_period = @fin_period THEN '1' ELSE '0' END [New (Month)]

		, CASE WHEN dim_date_completed.fin_period = @fin_period THEN '1' ELSE '0' END [Completed (Month)]
		, CASE WHEN dim_date_opened.cal_year = @current_year AND DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) <> @current_month THEN '1' ELSE '0' END  [New (Year)]
		, CASE WHEN dim_date_completed.cal_year = @current_year AND  DATEPART(MONTH, dim_detail_property.[completion_date]) <> @current_month  THEN '1' ELSE '0' END [Completed (Year)]
		
		, 'Bill Level' AS [Level]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw..dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
INNER JOIN red_dw.dbo.dim_date AS dim_date_opened
	ON dim_date_opened.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
LEFT OUTER JOIN red_dw.dbo.dim_date AS dim_date_completed
	ON dim_date_completed.calendar_date = CAST(dim_detail_property.completion_date AS DATE)
LEFT OUTER JOIN (SELECT Matters.Client
						, Matters.Matter
						, ARMaster.ARFee AS [ARFee]
						, ARMaster.InvDate AS [InvDate]
						--, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = DATEPART(YEAR, GETDATE()) AND (DATEPART(MONTH, ARMaster.InvDate) <> DATEPART(MONTH, GETDATE()) AND DATEPART(MONTH, ARMaster.InvDate) <> DATEPART(MONTH, GETDATE())-1) THEN ARMaster.ARFee ELSE '0' END [Legal Spend]
						--, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = DATEPART(YEAR, GETDATE()) AND (DATEPART(MONTH, ARMaster.InvDate) = DATEPART(MONTH, GETDATE())-1) THEN ARMaster.ARFee ELSE '0' END [Current Legal Spend]
						, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = @current_year AND (DATEPART(MONTH, ARMaster.InvDate)) <> @current_month AND DATEPART(MONTH, ARMaster.InvDate) <> @previous_month THEN ARMaster.ARFee ELSE '0' END [Legal Spend]
						, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = @current_year AND (DATEPART(MONTH, ARMaster.InvDate)) = @previous_month THEN ARMaster.ARFee ELSE '0' END [Current Legal Spend]
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

				WHERE Matters.Client IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022','R1001')
				AND ARList='Bill'
				--AND (CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, ARMaster.InvDate) <> DATEPART(MONTH, GETDATE()) THEN 1 ELSE 0 END) = 1)
				) AS [Bills] ON [Bills].Client=dim_matter_header_current.client_code COLLATE database_default AND [Bills].Matter = dim_matter_header_current.matter_number COLLATE database_default


WHERE (dim_matter_header_current.client_code IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022') 
OR (dim_detail_property.client_code='R1001' AND dim_instruction_type.instruction_type IN ('Real Estate Transactional Work (Volume)','Real Estate Litigation Work (Volume)', 'Real Estate Advisory Work (Volume)','Real Estate Transactional Work (BAU)','Real Estate Litigation Work (BAU)','Real Estate Advisory Work (BAU)')))

AND dim_matter_header_current.matter_number <> 'ML'
AND (CASE WHEN date_closed_case_management IS NOT NULL AND [InvDate] IS NULL THEN 0 ELSE 1 END)=1
AND (LOWER(matter_description) NOT LIKE '%ignore%' OR LOWER(matter_description) NOT LIKE '%opened in error%' )
AND  ISNULL(dim_detail_property.status_rm,'') <> 'On hold'



--deal with december
--SELECT dim_matter_header_current.client_code AS [Client]
	        
--			, dim_matter_header_current.matter_number AS [Matter]
--			, RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
--			, dim_matter_worktype.[work_type_name] AS [Work Type]
--			, dim_matter_header_current.date_opened_case_management AS [Date Opened]
--			, dim_detail_property.[fixed_feehourly_rate] AS [Fixed fee/Hourly rate]
--			, dim_detail_property.[team] AS [Team]
--			, dim_detail_property.[case_classification] AS [Case classification]
--			, dim_detail_property.[completion_date] AS [Completion Date]
--			, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (date_opened_practice_management,coalesce( dim_detail_property.[completion_date],dim_detail_property.date_elements_agreed)) AS [Days to Complete Cases]
--			, CASE WHEN dim_detail_property.[completion_date] IS NULL THEN '0' ELSE '1' END AS [Completed Cases]
--			, NULL AS [Legal Spend]
--			, NULL AS [Current Month Legal Spend]
--			, dim_matter_header_current.date_closed_case_management AS [Date Closed]
--			, NULL [Bill Date]
--			, NULL [Bill Date (month)]
--			, NULL [Bill Date (year)]
	
	
--			, 12 [Previous Month]
--			, 2020 [Current Year]
--			, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = 12  AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = 2020) THEN '1' ELSE '0' END [New (Month)]

--		, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = 12 AND DATEPART(YEAR, dim_detail_property.[completion_date]) = 2020) THEN '1' ELSE '0' END [Completed (Month)]
--		, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = 2020  THEN '1' ELSE '0' END [New (Year)]
--		, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = 2020 THEN '1' ELSE '0' END [Completed (Year)]
--		, 'Matter Level' [Level]


--FROM red_dw.dbo.fact_dimension_main
--LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
--LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
--LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
--LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
--LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
--LEFT OUTER JOIN red_dw..dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key


--WHERE (dim_matter_header_current.client_code IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022') 
--OR (dim_detail_property.client_code='R1001' AND dim_instruction_type.instruction_type IN ('Real Estate Transactional Work (Volume)','Real Estate Litigation Work (Volume)', 'Real Estate Advisory Work (Volume)','Real Estate Transactional Work (BAU)','Real Estate Litigation Work (BAU)','Real Estate Advisory Work (BAU)')))
--AND dim_matter_header_current.matter_number <> 'ML'
----AND date_opened_case_management>='20170501'
--AND (CASE WHEN date_closed_case_management IS NOT NULL THEN 0 ELSE 1 END)=1
--AND (LOWER(matter_description) NOT LIKE '%ignore%' OR LOWER(matter_description) NOT LIKE '%opened in error%' )
--AND  ISNULL(dim_detail_property.status_rm,'') <> 'On hold'


--UNION ALL 

--SELECT dim_matter_header_current.client_code AS [Client Code]
--		, dim_matter_header_current.matter_number AS [Matter Number]
--		, RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
--		, dim_matter_worktype.[work_type_name] AS [Work Type]
--		, dim_matter_header_current.date_opened_case_management AS [Date Opened]
--		, dim_detail_property.[fixed_feehourly_rate] AS [Fixed fee/Hourly rate]
--		, dim_detail_property.[team] AS [Team]
--		, dim_detail_property.[case_classification] AS [Case classification]
--		, dim_detail_property.[completion_date] AS [Completion Date]
--		, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (date_opened_practice_management,coalesce( dim_detail_property.[completion_date],dim_detail_property.date_elements_agreed)) AS [Days to Complete Cases]
--		, CASE WHEN dim_detail_property.[completion_date] IS NULL THEN '0' ELSE '1' END AS [Completed Cases]
--		, [Legal Spend] AS [Legal Spend]
--		, [Current Legal Spend] AS [Current Legal Spend]
--		, dim_matter_header_current.date_closed_case_management AS [Date Closed]
--		, [InvDate] AS [Bill Date]
--		, DATEPART(MONTH,[InvDate]) AS [Bill Date (month)]
--		, DATEPART(YEAR,[InvDate]) AS [Bill Date (year)]
--		, 12 [Previous Month]
--		, 2020 [Current Year]
--		, CASE WHEN (DATEPART(MONTH, dim_matter_header_current.date_opened_case_management) = 12  AND DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = 2020) THEN '1' ELSE '0' END [New (Month)]

--		, CASE WHEN (DATEPART(MONTH, dim_detail_property.[completion_date]) = 12 AND DATEPART(YEAR, dim_detail_property.[completion_date]) = 2020) THEN '1' ELSE '0' END [Completed (Month)]
--		, CASE WHEN DATEPART(YEAR, dim_matter_header_current.date_opened_case_management) = 2020  THEN '1' ELSE '0' END [New (Year)]
--		, CASE WHEN DATEPART(YEAR, dim_detail_property.[completion_date]) = 2020  THEN '1' ELSE '0' END [Completed (Year)]
--		, 'Bill Level' AS [Level]


--FROM red_dw.dbo.fact_dimension_main
--LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
--LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
--LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
--LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
--LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
--LEFT OUTER JOIN red_dw..dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key

--LEFT OUTER JOIN (SELECT Matters.Client
--						, Matters.Matter
--						, ARMaster.ARFee AS [ARFee]
--						, ARMaster.InvDate AS [InvDate]
--						, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = 2020  THEN ARMaster.ARFee ELSE '0' END [Legal Spend]
--						, CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = 2020 AND (DATEPART(MONTH, ARMaster.InvDate) = 12) THEN ARMaster.ARFee ELSE '0' END [Current Legal Spend]

--				FROM  TE_3E_Prod.dbo.InvMaster WITH (NOLOCK) 
--				INNER JOIN  TE_3E_Prod.dbo.ARMaster WITH (NOLOCK)
--				ON InvMaster.InvIndex=ARMaster.InvMaster 
--				INNER JOIN  
--				(
--				SELECT  ISNULL(RTRIM(LEFT(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) - 1)) ,RTRIM(LEFT(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) - 1)) ) AS Client
--						,ISNULL(SUBSTRING(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber)  + 1, LEN(Matter.LoadNumber)),SUBSTRING(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber)  + 1, LEN(Matter.AltNumber))) AS Matter
--						,Matter.MattIndex
--						,LoadNumber AS LoadNumber
--						,RelMattIndex
--				FROM TE_3E_Prod.dbo.Matter
--				) AS Matters
--				ON ARMaster.Matter=Matters.MattIndex 

--				WHERE Matters.Client IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022','R1001')
--				AND ARList='Bill'
--				--AND (CASE WHEN DATEPART(YEAR, ARMaster.InvDate) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, ARMaster.InvDate) <> DATEPART(MONTH, GETDATE()) THEN 1 ELSE 0 END) = 1)
--				) AS [Bills] ON [Bills].Client=dim_matter_header_current.client_code COLLATE database_default AND [Bills].Matter = dim_matter_header_current.matter_number COLLATE database_default


--WHERE (dim_matter_header_current.client_code IN ('P00010', 'P00011', 'P00012', 'P00020', 'P00021', 'P00022') 
--OR (dim_detail_property.client_code='R1001' AND dim_instruction_type.instruction_type IN ('Real Estate Transactional Work (Volume)','Real Estate Litigation Work (Volume)', 'Real Estate Advisory Work (Volume)','Real Estate Transactional Work (BAU)','Real Estate Litigation Work (BAU)','Real Estate Advisory Work (BAU)')))

--AND dim_matter_header_current.matter_number <> 'ML'
--AND (CASE WHEN date_closed_case_management IS NOT NULL AND [InvDate] IS NULL THEN 0 ELSE 1 END)=1
--AND (LOWER(matter_description) NOT LIKE '%ignore%' OR LOWER(matter_description) NOT LIKE '%opened in error%' )
--AND  ISNULL(dim_detail_property.status_rm,'') <> 'On hold'


END

GO
