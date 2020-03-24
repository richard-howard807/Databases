SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-03-04
-- Description:	Business source referral report, 45459
-- =============================================

CREATE PROCEDURE [dbo].[BusinessReferral] 

	@ClientGroupName varchar(MAX)
	, @ClientNumber varchar(MAX)
	, @Department varchar(MAX)

AS
BEGIN

	IF OBJECT_ID('tempdb..#ClientGroupName') IS NOT NULL   DROP TABLE #ClientGroupName
	IF OBJECT_ID('tempdb..#ClientNumber') IS NOT NULL   DROP TABLE #ClientNumber
	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department

	SELECT ListValue  INTO #ClientGroupName FROM 	dbo.udt_TallySplit(',', @ClientGroupName)
	SELECT ListValue  INTO #ClientNumber FROM 	dbo.udt_TallySplit(',', @ClientNumber)
	SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)

	SET NOCOUNT ON;

SELECT RTRIM(dim_client.client_code)+'-'+dim_matter_header_current.matter_number AS [Client/Matter Number]
	, matter_description AS [Matter Description]
	, date_opened_case_management AS [Date Opened]
	, date_closed_case_management AS [Date Closed]
	, matter_owner_full_name AS [Matter Owner]
	, hierarchylevel4hist AS [Team]
	, hierarchylevel3hist AS [Department]
	, dim_client.client_name AS [Client Name]
	, work_type_code AS [Work Type Code]
	, work_type_name AS [Work Type Name]
	, dim_client.business_source AS [Business Source]
	, matter_source_contact_name AS [Business Source Contact]
	, business_source_name AS [Business Source User]
	, client_source AS [Client Source]
	, client_source_contact AS [Client Source Contact]
	, client_source_user AS [Client Source User]
	, defence_costs_billed AS [Revenue]
	, disbursements_billed AS [Disbursements]
	, total_amount_billed AS [Total Amount Billed]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.client_code = fact_dimension_main.client_code
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

INNER JOIN #ClientGroupName AS ClientGroupName ON ClientGroupName.ListValue COLLATE database_default = dim_client.client_group_name COLLATE database_default
INNER JOIN #ClientNumber AS ClientNumber ON ClientNumber.ListValue COLLATE database_default = dim_client.client_code COLLATE DATABASE_DEFAULT
INNER JOIN #Department AS Department ON Department.ListValue COLLATE database_default = hierarchylevel3hist COLLATE database_default

WHERE 
(dim_client.business_source IS NOT NULL
OR client_source IS NOT NULL)
AND reporting_exclusions=0
 
 
END
GO
