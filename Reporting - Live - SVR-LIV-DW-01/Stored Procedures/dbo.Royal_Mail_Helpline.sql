SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-03-08
-- Description:	#91119, stored procedure for RMG Employments Dashboard 
-- =============================================
CREATE PROCEDURE [dbo].[Royal_Mail_Helpline]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Chargeable_hours') IS NOT NULL DROP TABLE #Chargeable_hours;

			SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			   PVIOT.[2023],
			   PVIOT.[2022],
			   PVIOT.[2021]
			   INTO #Chargeable_hours
		FROM (
	
			SELECT dim_matter_header_current.client_code, dim_matter_header_current.matter_number, dim_bill_date.bill_fin_year bill_fin_year, SUM(fact_billable_time_activity.minutes_recorded/60) Billed_hours
			FROM red_dw.dbo.fact_billable_time_activity
			INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_billable_time_activity.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_bill_date ON fact_billable_time_activity.dim_orig_posting_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_fin_year IN (2021,2022,2023)
			GROUP BY client_code, matter_number, bill_fin_year
			) AS hours
		PIVOT	
			(
			SUM(Billed_hours)
			FOR bill_fin_year IN ([2021],[2022],[2023])
			) AS PVIOT

 SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [MatterSphere Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_worktype.work_type_name AS [Matter Type]
	, dim_matter_header_current.matter_owner_full_name AS [Matter Owner]
	, dim_matter_header_current.date_opened_case_management AS [Date Opened]
	, dim_detail_advice.[case_classification] AS [Case Classification]
	, dim_detail_advice.[name_of_caller] AS [Name of Caller]
	, dim_detail_advice.[job_title_of_caller_emp] AS [Job Title]
	, dim_detail_advice.[geography] AS [Region]
	, dim_detail_advice.[name_of_employee] AS [Name of Employee]
	, dim_detail_advice.[summary_of_advice] AS [Subject Matter]
	, dim_detail_advice.[status] AS [Status]
	, dim_detail_advice.[knowledge_gap] AS [Knowledge Gap]
	, SUM(fact_all_time_activity.minutes_recorded/60) AS [Chargeable Hours posted]
	, Chargeable_hours.[2021] [Chargeable Hours Posted 2020/2021]
	, Chargeable_hours.[2022] [Chargeable Hours Posted 2021/2022]
	, Chargeable_hours.[2023] [Chargeable Hours Posted 2022/2023]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.fact_all_time_activity
ON fact_all_time_activity.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN #Chargeable_hours Chargeable_hours  ON dim_matter_header_current.client_code=Chargeable_hours.client_code
AND dim_matter_header_current.matter_number=Chargeable_hours.matter_number 

WHERE dim_matter_header_current.reporting_exclusions=0
AND dim_matter_header_current.master_client_code='R1001'
AND dim_matter_worktype.work_type_name='Employment Advice Line'

GROUP BY dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number,
         dim_matter_header_current.matter_description,
         dim_matter_worktype.work_type_name,
         dim_matter_header_current.matter_owner_full_name,
         dim_matter_header_current.date_opened_case_management,
         dim_detail_advice.case_classification,
         dim_detail_advice.name_of_caller,
         dim_detail_advice.job_title_of_caller_emp,
         dim_detail_advice.geography,
         dim_detail_advice.name_of_employee,
         dim_detail_advice.summary_of_advice,
         dim_detail_advice.status,
         dim_detail_advice.knowledge_gap,
		 Chargeable_hours.[2021], 
		 Chargeable_hours.[2022],
		 Chargeable_hours.[2023]

END
GO
