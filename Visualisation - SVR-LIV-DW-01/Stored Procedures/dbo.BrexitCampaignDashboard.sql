SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 16/12/2018
-- Description:	Query for the Brexit Campaign Dashboard because the Vis tableau connection didn't seem to pick up all files
-- =============================================
CREATE PROCEDURE [dbo].[BrexitCampaignDashboard]
AS
BEGIN
	

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SELECT RTRIM(header.client_code) +'-' +header.matter_number [Weightmans Ref]
		,matter_description [Matter Description]
		,client.client_name [Client Name]
		,client.postcode [Clients Postcode]
		,matter_owner_full_name [Case Manager]
		,header.branch_name [Office]
		,fed.hierarchylevel3hist [Department]
		,fed.hierarchylevel4hist [Team]
		,worktype.work_type_name [Work Type]
		,worktype.work_type_group [Work Type Group]
		,header.date_opened_case_management [Date Opened]
		,header.date_closed_case_management [Date Closed]
		,ISNULL(fin_sum.defence_costs_billed,0) [Revenue]
		,fin_sum.wip [WIP]
		,fin_sum.disbursements_billed [Disbursements Billed]
		,ISNULL(fin_sum.vat_billed,0) [VAT Billed]
		,ISNULL(fin_sum.time_billed,0) [Time Billed]
		,header.fee_arrangement [Fee Arrangement]
		,area_Postcode.Latitude 
		,area_Postcode.Longitude

	

	FROM red_dw.dbo.fact_dimension_main main
	INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fed ON fed.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
	INNER JOIN red_dw.dbo.dim_matter_worktype worktype ON worktype.dim_matter_worktype_key = header.dim_matter_worktype_key
	INNER JOIN red_dw.dbo.dim_client client ON client.dim_client_key = main.dim_client_key
	INNER JOIN red_dw.dbo.fact_finance_summary fin_sum ON fin_sum.master_fact_key = main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.Doogal AS [area_Postcode] ON [area_Postcode].Postcode=client.postcode 


	WHERE UPPER(matter_description) LIKE '%BREXIT%';



END

GO
