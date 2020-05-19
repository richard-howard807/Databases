SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[live_associates_Email] (@Division NVARCHAR(MAX), @Department NVARCHAR(MAX), @Team NVARCHAR(MAX), @CaseManager NVARCHAR(MAX))

AS 
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2020-05-15
Description:		Live Associates v2 for Case Team and Andy Griffiths to add in email type and further capapity's
Current Version:	Initial Create
====================================================
====================================================

*/
DROP TABLE  IF EXISTS #associates

DROP TABLE IF EXISTS #Division
 CREATE TABLE #Division  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

DROP TABLE IF EXISTS #Department
CREATE TABLE #Department  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

DROP TABLE IF EXISTS #Team
CREATE TABLE #Team  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

DROP TABLE IF EXISTS #CaseManager
CREATE TABLE #CaseManager  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

INSERT INTO #Division
SELECT ListValue
-- INTO #FedCodeList
FROM dbo.udt_TallySplit('|', @Division)

INSERT INTO #Department 
SELECT ListValue 
-- INTO #FedCodeList
FROM dbo.udt_TallySplit('|', @Department)

INSERT INTO #Team 
SELECT ListValue 
-- INTO #FedCodeList
FROM dbo.udt_TallySplit('|', @Team)

INSERT INTO #CaseManager 
SELECT ListValue
-- INTO #FedCodeList
FROM dbo.udt_TallySplit('|', @CaseManager)

-- Associates
SELECT dim_matter_header_curr_key, dim_client.dim_client_key,  IIF(LOWER(capacity_code) LIKE '%court%', 'COURT', capacity_code) capacity_code,
		ISNULL(IIF(LOWER(capacity_code) LIKE '%court%', 'Court', capacity_description), capacity_code) capacity_description, COALESCE(assocemail, emails.contemail, dim_client.email) email,
		address_line_1, address_line_2, address_line_3, reference, dim_involvement_full.name, emails.contcode AS EmailType
	INTO #associates
-- select *
FROM red_dw.dbo.dim_involvement_full
INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code = dim_involvement_full.client_code AND dim_matter_header_current.matter_number = dim_involvement_full.matter_number
LEFT outer JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
INNER JOIN red_dw.dbo.ds_sh_ms_dbassociates ON dim_involvement_full.sequence_number = ds_sh_ms_dbassociates.associd AND ds_sh_ms_dbassociates.contid = dim_client.contactid
LEFT OUTER JOIN (SELECT emails.contid, emails.contcode, emails.contemail, ROW_NUMBER() OVER	(PARTITION BY emails.contid ORDER BY emails.contdefaultorder) rnk
					-- select *
					FROM red_dw.dbo.ds_sh_ms_dbcontactemails emails
					WHERE emails.contactive = 1) as emails ON emails.contid = dim_client.contactid AND emails.rnk = 1
where (dim_involvement_full.capacity_code IN ('COURT','CLAIMANTSOLS','COMPRECUNITDWP','EXPERT','EXPERTNONMED','OTHER','CODEF','CLAIMANTREP','CORONERCOURT','OTHERSIDESOLS','DEFSOLICITOR','DEFENDANTSOLS','CORONER','DIS','CROWNCRT','P20DEFENDANTSOL',' RESPSOL','PURCHASERSOLS','CONVSOL','  COINSURERSOLS','CLAIMINSSOL') 
		OR
		LOWER(dim_involvement_full.capacity_code) LIKE '%court%') 
AND ds_sh_ms_dbassociates.assocactive = 1


-- Main Data
SELECT distinct RTRIM(dim_detail_core_details.client_code) client_code, LTRIM(dim_matter_header_current.matter_number) matter_number, matter_description, dim_matter_header_current.ms_fileid, fact_dimension_main.dim_matter_header_curr_key,
				dim_fed_hierarchy_history.name matter_owner_name,	

                dim_fed_hierarchy_history.hierarchylevel4 [matter_owner_team],
                dim_fed_hierarchy_history.hierarchylevel3 [matter_owner_practice_area],
                dim_fed_hierarchy_history.hierarchylevel2 [matter_owner_business_line],
                dim_matter_header_current.date_opened_case_management [matter_opened_case_management_calendar_date],
                dim_matter_header_current.date_closed_case_management [matter_closed_case_management_calendar_date],
				dim_detail_core_details.present_position,
				dim_detail_core_details.proceedings_issued,
				dim_matter_worktype.work_type_name,
				fact_matter_summary_current.last_time_transaction_date,

				associates.name,
                associates.capacity_code,
                associates.capacity_description,
                associates.email,
                associates.address_line_1,
                associates.address_line_2,
                associates.address_line_3,
                associates.reference,
				associates.EmailType,
				CASE WHEN capacity_code = 'COURT' THEN 1
					 WHEN capacity_code = 'CLAIMANTSOLS' THEN 2					 
					 WHEN capacity_code = 'CLAIMANTREP' THEN 3
					 WHEN capacity_code = 'CODEF' THEN 4 
					 WHEN associates.capacity_code = 'COMPRECUNITDWP' then 5 
					 WHEN associates.capacity_code = 'OTHER' then 6 
					 ELSE 15 END AS column_order

FROM red_dw.dbo.fact_dimension_main
INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT outer JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code AND dim_detail_outcome.matter_number = fact_dimension_main.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_current dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.client_code = dim_matter_header_current.client_code AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key

LEFT OUTER JOIN #associates associates ON associates.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key

INNER JOIN #Division ON #Division.ListValue = dim_fed_hierarchy_history.hierarchylevel2
INNER JOIN #Department ON #Department.ListValue = dim_fed_hierarchy_history.hierarchylevel3
INNER JOIN #Team ON #Team.ListValue = dim_fed_hierarchy_history.hierarchylevel4
--INNER JOIN #CaseManager ON #CaseManager.ListValue = dim_fed_hierarchy_history.name  

WHERE reporting_exclusions = 0
AND ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.date_closed_case_management IS NULL
AND (last_time_transaction_date > '20191031'
	OR
    work_type_name = 'Debt Recovery')
AND (dim_detail_core_details.present_position IS NULL
	OR 
	dim_detail_core_details.present_position IN ('Claim and costs outstanding','Claim concluded but costs outstanding','Claim and costs concluded but recovery outstanding')
	)
	--and dim_matter_header_current.client_code = 'N1001' AND dim_matter_header_current.matter_number = '00018068'

ORDER BY 1, 2
		
		
GO
