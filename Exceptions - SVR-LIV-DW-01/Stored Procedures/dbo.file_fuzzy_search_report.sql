SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-11-30
-- Description:	#180759 - initial build
-- =============================================
CREATE PROCEDURE [dbo].[file_fuzzy_search_report]

(
@fuzzy_search AS VARCHAR(255)
)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--test parameter
--DECLARE @fuzzy_search AS NVARCHAR(255) = NULL


IF LEN(ISNULL(@fuzzy_search, '')) < 1
BEGIN PRINT 'initial load of report'
RETURN;
END


DECLARE @cleaned_fuzzy_search AS NVARCHAR(255) = LOWER(REPLACE(TRANSLATE(@fuzzy_search, ' /-().[]\?{}:', '#############'), '#', ''))

DROP TABLE IF EXISTS #associate_refs
DROP TABLE IF EXISTS #incident_dates
DROP TABLE IF EXISTS #registration
DROP TABLE IF EXISTS #description



--=================================================================================================================================================
-- Search through associate references
--=================================================================================================================================================
SELECT 
	search_pivot.client_code,
    search_pivot.matter_number,
    search_pivot.INSURERCLIENT,
    search_pivot.DEFENDANT,
    search_pivot.COURT,
    search_pivot.CLIENT,
    search_pivot.CLAIMANTSOLS,
    search_pivot.CLAIMANTINPERS,
    search_pivot.CLAIMANT
INTO #associate_refs
FROM (
	SELECT 
		dim_involvement_full.client_code
		, dim_involvement_full.matter_number
		, dim_involvement_full.capacity_code
		, dim_involvement_full.reference
	FROM red_dw.dbo.dim_involvement_full
	WHERE
		dim_involvement_full.is_active = 1 
		AND dim_involvement_full.capacity_code IN ('CLAIMANT', 'CLAIMANTINPERS', 'CLAIMANTSOLS', 'CLIENT', 'COURT', 'DEFENDANT', 'INSURERCLIENT')
		AND LOWER(REPLACE(TRANSLATE(dim_involvement_full.reference, ' /-().[]\?{}:', '#############'), '#', '')) LIKE '%' + @cleaned_fuzzy_search + '%'
		--AND dim_involvement_full.reference IS NOT NULL
	) AS search
PIVOT (
	MAX(reference)
	FOR capacity_code IN (CLAIMANT, CLAIMANTINPERS, CLAIMANTSOLS, CLIENT, COURT, DEFENDANT, INSURERCLIENT)
	) AS search_pivot




--=================================================================================================================================================
-- Search for incident dates
--=================================================================================================================================================
SELECT dim_detail_core_details.dim_matter_header_curr_key, dim_detail_core_details.incident_date
INTO #incident_dates
FROM red_dw.dbo.dim_detail_core_details
WHERE
	REPLACE(CAST(FORMAT(dim_detail_core_details.incident_date, 'd', 'en-gb') AS NVARCHAR(10)), '/', '') = @cleaned_fuzzy_search
	OR REPLACE(CAST(FORMAT(dim_detail_core_details.incident_date, 'dd/MM/yy') AS NVARCHAR(10)), '/', '') = @cleaned_fuzzy_search



--=================================================================================================================================================
-- Search for vehicle registration number
--=================================================================================================================================================
SELECT dim_detail_hire_details.dim_matter_header_curr_key, dim_detail_hire_details.chn_cho_vehicle_registration, dim_detail_hire_details.third_party_vehicle_registration
INTO #registration
FROM red_dw.dbo.dim_detail_hire_details
WHERE
	LOWER(REPLACE(TRANSLATE(dim_detail_hire_details.chn_cho_vehicle_registration, ' /-().[]\?{}:', '#############'), '#', '')) LIKE '%' + @cleaned_fuzzy_search + '%'
	OR LOWER(REPLACE(TRANSLATE(dim_detail_hire_details.third_party_vehicle_registration, ' /-().[]\?{}:', '#############'), '#', '')) LIKE '%' + @cleaned_fuzzy_search + '%'



--=================================================================================================================================================
-- Search matter description
--=================================================================================================================================================
SELECT dim_matter_header_current.dim_matter_header_curr_key, dim_matter_header_current.matter_description
INTO #description
FROM red_dw.dbo.dim_matter_header_current
WHERE
	LOWER(REPLACE(TRANSLATE(dim_matter_header_current.matter_description, ' /-().[]\?{}:', '#############'), '#', '')) LIKE '%' + @cleaned_fuzzy_search + '%'



--=================================================================================================================================================
-- Bring all together and show which fields the search returned results from
--=================================================================================================================================================
SELECT 
	dim_matter_header_current.master_client_code		AS [Client Code]
	, dim_matter_header_current.master_matter_number	AS [Matter Number]
	, dim_matter_header_current.matter_description		AS [Matter Description]
	, dim_fed_hierarchy_history.name					AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist		AS [Department]
	, dim_fed_hierarchy_history.hierarchylevel2hist		AS [Division]
	, #description.matter_description				AS [Matter Description Search Results]
	, #incident_dates.incident_date				AS [Incident Date Search Results]
	, #registration.chn_cho_vehicle_registration			AS [CHO Vehicle Reg Search Results]
	, #registration.third_party_vehicle_registration			AS [TP Vehicle Reg Search Results]
	, #associate_refs.CLAIMANT				AS [Claimant Associate Ref Search Results]
	, #associate_refs.CLAIMANTINPERS			AS [Claimant In Person Associate Ref Search Results]
	, #associate_refs.CLAIMANTSOLS	AS [Claimant Sols Associate Ref Search Results]               
	, #associate_refs.CLIENT             AS [Client Associate Ref Search Results]
	, #associate_refs.COURT           AS [Court Associate Ref Search Results]
	, #associate_refs.DEFENDANT           AS [Defendant Associate Ref Search Results]
	, #associate_refs.INSURERCLIENT        AS [Insurer Client Associate Ref Search Results]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN #associate_refs
		ON #associate_refs.client_code = dim_matter_header_current.client_code
			AND #associate_refs.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #incident_dates
		ON #incident_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #registration
		ON #registration.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #description
		ON #description.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code <> '30645'
	AND (#associate_refs.client_code IS NOT NULL
		OR #incident_dates.dim_matter_header_curr_key IS NOT NULL
		OR #registration.dim_matter_header_curr_key IS NOT NULL
		OR #description.dim_matter_header_curr_key IS NOT NULL
		)

END 
GO
