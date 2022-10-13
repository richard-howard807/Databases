SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
--Author:			Max Taylor
--Created Date:		2022-07-08
--Description:		Guinness Finance Dashboard (Ticket 156613)
--Current Version:	Initial Create
====================================================

====================================================

*/
CREATE PROCEDURE [dbo].[GuinnessFinanceDashboard] 

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_practice_management AS [Date Closed]
,name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,department_name AS [Department]
,work_type_name AS [Work Type]
,dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
,dim_detail_core_details.[date_instructions_received] AS [Date Instructions Received]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements]
,vat_billed AS [VAT]
,wip AS [WIP]
,CASE WHEN dim_detail_critical_mi.[litigated]='Yes' OR dim_detail_core_details.[proceedings_issued]='Yes' THEN 'Litigated' ELSE 'Pre-Litigated' END AS [Litigated/Proceedings Issued]
--Billed
,ISNULL(Bills.[Total Billed 1 April 2018 - 31 March 2019],0) AS [Total Billed 1 April 2018 - 31 March 2019]
,ISNULL(Bills.[Total Billed 1 April 2019 - 31 March 2020],0) AS [Total Billed 1 April 2019 - 31 March 2020]
,ISNULL(Bills.[Total Billed 1 April 2020 - 31 March 2021],0) AS [Total Billed 1 April 2020 - 31 March 2021]
,ISNULL(Bills.[Total Billed 1 April 2021 - 31 March 2022],0) AS [Total Billed 1 April 2021 - 31 March 2022]
,ISNULL(Bills.[Total Billed 1 April 2022 - 31 March 2023],0) AS [Total Billed 1 April 2022 - 31 March 2023]
,ISNULL(Bills.[Total Billed 1 April 2023 - 31 March 2024],0) AS [Total Billed 1 April 2023 - 31 March 2024]
,ISNULL(Bills.[Total Billed 1 April 2024 - 31 March 2025],0) AS [Total Billed 1 April 2024 - 31 March 2025]
,ISNULL(Bills.[Total Billed 1 April 2025 - 31 March 2026],0) AS [Total Billed 1 April 2025 - 31 March 2026]
,ISNULL(Bills.[Total Billed 1 April 2026 - 31 March 2027],0) AS [Total Billed 1 April 2026 - 31 March 2027]
--Revenue
,ISNULL([Revenue 1 April 2018 - 31 March 2019],0) AS [Revenue 1 April 2018 - 31 March 2019]
,ISNULL([Revenue 1 April 2019 - 31 March 2020],0) AS [Revenue 1 April 2019 - 31 March 2020]
,ISNULL([Revenue 1 April 2020 - 31 March 2021],0) AS [Revenue 1 April 2020 - 31 March 2021]
,ISNULL([Revenue 1 April 2021 - 31 March 2022],0) AS [Revenue 1 April 2021 - 31 March 2022]
,ISNULL([Revenue 1 April 2022 - 31 March 2023],0) AS [Revenue 1 April 2022 - 31 March 2023]
,ISNULL([Revenue 1 April 2023 - 31 March 2024],0) AS [Revenue 1 April 2023 - 31 March 2024]
,ISNULL([Revenue 1 April 2024 - 31 March 2025],0) AS [Revenue 1 April 2024 - 31 March 2025]
,ISNULL([Revenue 1 April 2025 - 31 March 2026],0) AS [Revenue 1 April 2025 - 31 March 2026]
,ISNULL([Revenue 1 April 2026 - 31 March 2027],0) AS [Revenue 1 April 2026 - 31 March 2027]
--Disbursements
,ISNULL(Bills.[Disbursements Billed 1 April 2018 - 31 March 2019],0) AS [Disbursements Billed 1 April 2018 - 31 March 2019]
,ISNULL(Bills.[Disbursements Billed 1 April 2019 - 31 March 2020],0) AS [Disbursements Billed 1 April 2019 - 31 March 2020]
,ISNULL(Bills.[Disbursements Billed 1 April 2020 - 31 March 2021],0) AS [Disbursements Billed 1 April 2020 - 31 March 2021]
,ISNULL(Bills.[Disbursements Billed 1 April 2021 - 31 March 2022],0) AS [Disbursements Billed 1 April 2021 - 31 March 2022]
,ISNULL(Bills.[Disbursements Billed 1 April 2022 - 31 March 2023],0) AS [Disbursements Billed 1 April 2022 - 31 March 2023]
,ISNULL(Bills.[Disbursements Billed 1 April 2023 - 31 March 2024],0) AS [Disbursements Billed 1 April 2023 - 31 March 2024]
,ISNULL(Bills.[Disbursements Billed 1 April 2024 - 31 March 2025],0) AS [Disbursements Billed 1 April 2024 - 31 March 2025]
,ISNULL(Bills.[Disbursements Billed 1 April 2025 - 31 March 2026],0) AS [Disbursements Billed 1 April 2025 - 31 March 2026]
,ISNULL(Bills.[Disbursements Billed 1 April 2026 - 31 March 2027],0) AS [Disbursements Billed 1 April 2026 - 31 March 2027]

--VAT
,ISNULL(Bills.[VAT Billed 1 April 2018 - 31 March 2019],0) AS [VAT Billed 1 April 2018 - 31 March 2019]
,ISNULL(Bills.[VAT Billed 1 April 2019 - 31 March 2020],0) AS [VAT Billed 1 April 2019 - 31 March 2020]
,ISNULL(Bills.[VAT Billed 1 April 2020 - 31 March 2021],0) AS [VAT Billed 1 April 2020 - 31 March 2021]
,ISNULL(Bills.[VAT Billed 1 April 2021 - 31 March 2022],0) AS [VAT Billed 1 April 2021 - 31 March 2022]
,ISNULL(Bills.[VAT Billed 1 April 2022 - 31 March 2023],0) AS [VAT Billed 1 April 2022 - 31 March 2023]
,ISNULL(Bills.[VAT Billed 1 April 2023 - 31 March 2024],0) AS [VAT Billed 1 April 2023 - 31 March 2024]
,ISNULL(Bills.[VAT Billed 1 April 2024 - 31 March 2025],0) AS [VAT Billed 1 April 2024 - 31 March 2025]
,ISNULL(Bills.[VAT Billed 1 April 2025 - 31 March 2026],0) AS [VAT Billed 1 April 2025 - 31 March 2026]
,ISNULL(Bills.[VAT Billed 1 April 2026 - 31 March 2027],0) AS [VAT Billed 1 April 2026 - 31 March 2027]


FROM 
red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
INNER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key=fact_dimension_main.dim_detail_critical_mi_key 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code
AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
		SELECT dim_matter_header_current.client_code
		,dim_matter_header_current.matter_number
		--Billed
		,SUM(CASE WHEN bill_date BETWEEN '2018-04-01' AND '2019-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2018 - 31 March 2019]
		,SUM(CASE WHEN bill_date BETWEEN '2019-04-01' AND '2020-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2019 - 31 March 2020]
		,SUM(CASE WHEN bill_date BETWEEN '2020-04-01' AND '2021-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2020 - 31 March 2021]
		,SUM(CASE WHEN bill_date BETWEEN '2021-04-01' AND '2022-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2021 - 31 March 2022]
		,SUM(CASE WHEN bill_date BETWEEN '2022-04-01' AND '2023-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2022 - 31 March 2023]
		,SUM(CASE WHEN bill_date BETWEEN '2023-04-01' AND '2024-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2023 - 31 March 2024]
		,SUM(CASE WHEN bill_date BETWEEN '2024-04-01' AND '2025-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2024 - 31 March 2025]
		,SUM(CASE WHEN bill_date BETWEEN '2025-04-01' AND '2026-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2025 - 31 March 2026]
		,SUM(CASE WHEN bill_date BETWEEN '2026-04-01' AND '2027-03-31' THEN bill_total ELSE NULL END) AS [Total Billed 1 April 2026 - 31 March 2027]
		--Revenue
		,SUM(fees_total)  TotalRevenue
		,SUM(CASE WHEN bill_date BETWEEN '2018-04-01' AND '2019-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2018 - 31 March 2019]
		,SUM(CASE WHEN bill_date BETWEEN '2019-04-01' AND '2020-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2019 - 31 March 2020]
		,SUM(CASE WHEN bill_date BETWEEN '2020-04-01' AND '2021-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2020 - 31 March 2021]
		,SUM(CASE WHEN bill_date BETWEEN '2021-04-01' AND '2022-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2021 - 31 March 2022]
		,SUM(CASE WHEN bill_date BETWEEN '2022-04-01' AND '2023-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2022 - 31 March 2023]
		,SUM(CASE WHEN bill_date BETWEEN '2023-04-01' AND '2024-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2023 - 31 March 2024]
		,SUM(CASE WHEN bill_date BETWEEN '2024-04-01' AND '2025-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2024 - 31 March 2025]
		,SUM(CASE WHEN bill_date BETWEEN '2025-04-01' AND '2026-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2025 - 31 March 2026]
		,SUM(CASE WHEN bill_date BETWEEN '2026-04-01' AND '2027-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2026 - 31 March 2027]
		
		
		
		
		--Disbursements
		,SUM(CASE WHEN bill_date BETWEEN '2018-04-01' AND '2019-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2018 - 31 March 2019]
		,SUM(CASE WHEN bill_date BETWEEN '2019-04-01' AND '2020-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2019 - 31 March 2020]
		,SUM(CASE WHEN bill_date BETWEEN '2020-04-01' AND '2021-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2020 - 31 March 2021]
		,SUM(CASE WHEN bill_date BETWEEN '2021-04-01' AND '2022-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2021 - 31 March 2022]
		,SUM(CASE WHEN bill_date BETWEEN '2022-04-01' AND '2023-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2022 - 31 March 2023]
		,SUM(CASE WHEN bill_date BETWEEN '2023-04-01' AND '2024-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2023 - 31 March 2024]
		,SUM(CASE WHEN bill_date BETWEEN '2024-04-01' AND '2025-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2024 - 31 March 2025]
		,SUM(CASE WHEN bill_date BETWEEN '2025-04-01' AND '2026-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2025 - 31 March 2026]
		,SUM(CASE WHEN bill_date BETWEEN '2026-04-01' AND '2027-03-31' THEN ISNULL(hard_costs,0) + ISNULL(soft_costs,0) ELSE NULL END) AS [Disbursements Billed 1 April 2026 - 31 March 2027]

		
		
		
		--VAT
		,SUM(CASE WHEN bill_date BETWEEN '2018-04-01' AND '2019-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2018 - 31 March 2019]
		,SUM(CASE WHEN bill_date BETWEEN '2019-04-01' AND '2020-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2019 - 31 March 2020]
		,SUM(CASE WHEN bill_date BETWEEN '2020-04-01' AND '2021-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2020 - 31 March 2021]
		,SUM(CASE WHEN bill_date BETWEEN '2021-04-01' AND '2022-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2021 - 31 March 2022]
		,SUM(CASE WHEN bill_date BETWEEN '2022-04-01' AND '2023-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2022 - 31 March 2023]
		,SUM(CASE WHEN bill_date BETWEEN '2023-04-01' AND '2024-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2023 - 31 March 2024]
		,SUM(CASE WHEN bill_date BETWEEN '2024-04-01' AND '2025-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2024 - 31 March 2025]
		,SUM(CASE WHEN bill_date BETWEEN '2025-04-01' AND '2026-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2025 - 31 March 2026]
		,SUM(CASE WHEN bill_date BETWEEN '2026-04-01' AND '2027-03-31' THEN vat ELSE NULL END) AS [VAT Billed 1 April 2026 - 31 March 2027]


		FROM red_dw.dbo.fact_bill_matter_detail_summary
		INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code = fact_bill_matter_detail_summary.client_code
		 AND dim_matter_header_current.matter_number = fact_bill_matter_detail_summary.matter_number
		WHERE fact_bill_matter_detail_summary.client_code='00163012'
		GROUP BY dim_matter_header_current.client_code
		,dim_matter_header_current.matter_number
	) AS Bills
ON Bills.client_code = dim_matter_header_current.client_code
AND Bills.matter_number = dim_matter_header_current.matter_number
WHERE 
dim_matter_header_current.client_code='00163012'
AND (date_closed_practice_management IS NULL OR date_closed_practice_management>'2017-04-01')

ORDER BY 
dim_matter_header_current.client_code 
,dim_matter_header_current.matter_number




END


		
		
GO
