SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-03-23
-- Description:	Reference Search report, 53312
-- =============================================
CREATE PROCEDURE [dbo].[ReferenceSearch]
	
	@ClientCode VARCHAR(MAX),
	@MatterNumber VARCHAR(MAX),
	@MatterDesc VARCHAR(MAX),
	@ClientRef VARCHAR(MAX)
AS
BEGIN

	--DECLARE @ClientCode VARCHAR(MAX) = 'W15492'
	--DECLARE @MatterNumber VARCHAR(MAX) ='00001863'
	--DECLARE @MatterDesc VARCHAR(MAX) = 'Triangle'
	--DECLARE @ClientRef VARCHAR(MAX) ='19'

	SET NOCOUNT ON;
 
SELECT RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number AS [Weightmans Reference]
	, dim_matter_header_current.master_client_code+'-'+master_matter_number AS [Mattersphere Weightmans Reference]
	, matter_description AS [Matter Description]
	, matter_owner_full_name AS [Case Manager]
	, client_group_name AS [Client Group Name]
	, insurerclient_reference AS [Insurer Client Reference]
	, insuredclient_reference AS [Insured Client Reference]
	, client_reference AS [Client Reference]
	
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key

WHERE reporting_exclusions=0
AND date_closed_case_management IS NULL
AND (RTRIM(dim_matter_header_current.client_code) = @ClientCode
	OR dim_matter_header_current.master_client_code = @ClientCode
	OR @ClientCode IS NULL)
AND (fact_dimension_main.matter_number = @MatterNumber
	OR master_matter_number = @MatterNumber
	OR @MatterNumber IS NULL)
AND (LOWER(matter_description) LIKE '%'+@MatterDesc+'%'
	OR matter_description LIKE '%'+@MatterDesc+'%'
	OR @MatterDesc IS NULL)
AND (insurerclient_reference LIKE '%'+@ClientRef+'%' 
	OR insuredclient_reference LIKE '%'+@ClientRef+'%' 
	OR client_reference LIKE '%'+@ClientRef+'%'
	OR @ClientRef IS NULL)

END
GO
