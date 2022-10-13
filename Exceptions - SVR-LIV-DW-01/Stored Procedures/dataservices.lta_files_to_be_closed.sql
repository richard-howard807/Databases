SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* =============================================
-- Author:		Orlagh Kelly 
-- Create date: 04-12-2018
-- Description:	 report to drive the LTA Live files to be closed -- old sp_name = [dbo].[LiveLTAFilesToBeClosed]
-- =============================================
LD 20190904  Amended the logic so that it follows the below as requested by Helen Fox
	1. LTA Division
	2. Files are not closed 
	3. only show files opened more than 4 months ago
	4. only show files that have been worked on more than 6 months ago (using date of time recording)
	5. Only show files with WIP less than or equal to £50
	6. remove any Property view or Plot sales matter
	Status Logic
	Red - "To be closed" has £0 against unbilled disbs, client account balance and unpaid bill balance
	Amber  - " Client Balance" is £0 for unpaid bill balance but has a value in Client account
	Blue  - "Bill Balance" - is £0 for client balance but has a value in unpaid bill balance 
	Green - "Client and Bill Balance" - this is where client account balance and unpaid bill balance are both greater than £0.

	ES	2019-11-01	37619, added archive details
	ES  2020-01-16  43630, amended logic - remove any file where matter description contains "billing"
								 - remove any file where the Case Manager Name contains "Property View"
*/
CREATE PROCEDURE [dataservices].[lta_files_to_be_closed]


--(
--    @FedCode AS VARCHAR(MAX),
--    --@Month AS VARCHAR(100)
--    @Level AS VARCHAR(100)
--)
AS

BEGIN 

SET NOCOUNT ON 





--	DROP TABLE  IF EXISTS #FedCodeList
--    	CREATE TABLE #FedCodeList  (
--ListValue  NVARCHAR(MAX)
--)
--IF @level  <> 'Individual'
--	BEGIN
--	PRINT ('not Individual')
--DECLARE @sql NVARCHAR(MAX)

--SET @sql = '
--use red_dw;
--DECLARE @nDate AS DATE = GETDATE()

--SELECT DISTINCT
--dim_fed_hierarchy_history_key
--FROM red_Dw.dbo.dim_fed_hierarchy_history 
--WHERE dim_fed_hierarchy_history_key IN ('+@FedCode+')'

--INSERT into #FedCodeList 
--exec sp_executesql @sql
--	end
	
	
--	IF  @level  = 'Individual'
--    BEGIN
--	PRINT ('Individual')
--    INSERT into #FedCodeList 
--	SELECT ListValue
--   -- INTO #FedCodeList
--    FROM dbo.udt_TallySplit(',', @FedCode)
	
--	END

 
    SELECT RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number AS [Weightmans Reference],
           RTRIM(dim_matter_header_current.master_client_code) + '-' + dim_matter_header_current.master_matter_number AS [Mattershere Weightmans Reference],
		   fact_finance_summary.disbursement_balance,
           CASE WHEN ISNULL(fact_finance_summary.disbursement_balance,0) + ISNULL( fact_matter_summary_current.[client_account_balance_of_matter],0) + ISNULL( fact_finance_summary.unpaid_bill_balance,0) = 0 THEN 'To be closed'
			    WHEN ISNULL(fact_finance_summary.unpaid_bill_balance,0)  = 0 AND ISNULL( fact_matter_summary_current.[client_account_balance_of_matter],0) <> 0 THEN 'Client Balance'
				WHEN ISNULL(fact_matter_summary_current.[client_account_balance_of_matter],0) = 0 AND ISNULL(fact_finance_summary.unpaid_bill_balance,0) <> 0 THEN 'Bill Balance'
				WHEN ISNULL(fact_matter_summary_current.[client_account_balance_of_matter],0) > 0 AND ISNULL(fact_finance_summary.unpaid_bill_balance,0)>0 THEN 'Client and Bill Balance'
				ELSE 'Live'
			END [Status ],
		   matter_description AS [Matter Description ],
           dim_fed_hierarchy_history.name [Case Manger Name],
           dim_fed_hierarchy_history.[worksforname] [Team  Managers Name],
           branch [Office],
		   dim_fed_hierarchy_history.fed_code,
           dim_fed_hierarchy_history.hierarchylevel4hist [Team],
           dim_fed_hierarchy_history.hierarchylevel3hist [Department],
           dim_fed_hierarchy_history.hierarchylevel2hist [Division],
           dim_matter_worktype.work_type_name AS [Work Type ],
           dim_client.client_name [Client Name],
           red_dw.dbo.dim_matter_header_current.date_opened_case_management [Open Date ],
           red_dw.dbo.dim_matter_header_current.date_closed_case_management [Closed Date ],
           total_amount_bill_non_comp [Total Bill Amount - Composite (Inc. VAT )],
           defence_costs_billed [Revenue Costs Billed ],
           disbursements_billed [Disbursements Billed ],
           vat_billed [VAT Billed],
           wip [WIP],
           total_unbilled_disbursements_vat AS [Unbilled Disbursements],
           fact_finance_summary.client_account_balance_of_matter [Client Account Balance of Matter],
           fact_matter_summary_current.unpaid_bill_balance [Unpaid Bill Balance ],
           last_bill_date [Last Bill Date],
           last_time_transaction_date [Date of Last time Posting  ]
		  -- fact_bill_matter.last_bill_date [Last Bill Date Composite]
		  	,archive_details.[latest_archive_date] as [Latest Archive Date]
			,archive_details.[latest_archive_status] AS [Latest Archive Status]
			,archive_details.[latest_archive_type] AS [Latest Archive Type]

    FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        INNER JOIN red_dw.dbo.dim_client
            ON dim_client.client_code = fact_dimension_main.client_code
        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
            ON fact_dimension_main.client_code = dim_detail_client.client_code
               AND dim_detail_client.matter_number = fact_dimension_main.matter_number
        INNER JOIN red_dw.dbo.dim_matter_header_current
            ON dim_matter_header_current.client_code = fact_dimension_main.client_code
               AND dim_matter_header_current.matter_number = fact_dimension_main.matter_number
        INNER JOIN red_dw.dbo.fact_detail_client
            ON fact_dimension_main.master_fact_key = fact_detail_client.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
            ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
        LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
            ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
        INNER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
               AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
               AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details
            ON dim_detail_previous_details.client_code = fact_dimension_main.client_code
               AND dim_detail_previous_details.matter_number = fact_dimension_main.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
            ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
            ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
            ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
            ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_incident
            ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance
            ON dim_detail_compliance.dim_detail_compliance_key = fact_dimension_main.dim_detail_compliance_key
				/* Archive Details */
	LEFT OUTER JOIN (

	 SELECT  
		udDeedWill.fileID
		,udDeedWill.dwArchivedDate [latest_archive_date]
		,archstatus.cdDesc [latest_archive_status] 
		,archtype.cdDesc [latest_archive_type]


	FROM MS_Prod.dbo.udDeedWill udDeedWill
	INNER JOIN MS_Prod.config.dbFile dbFile ON dbFile.fileID = udDeedWill.fileID
	INNER JOIN MS_Prod.config.dbClient dbClient ON dbClient.clID = dbFile.clID
	INNER JOIN (SELECT fileID,MAX(dwID) [dwID] FROM MS_Prod.dbo.udDeedWill GROUP BY fileID) d ON udDeedWill.dwID = d.dwID 
	LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup archstatus ON cdType='ARCHSTATUS' AND archstatus.cdCode = udDeedWill.Status
	LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup archtype ON archtype.cdType='ARCHTYPE' AND archtype.cdCode = udDeedWill.Status

	) archive_details ON archive_details.fileID = dim_matter_header_current.ms_fileid


    WHERE 
	
	 dim_matter_header_current.matter_number <> 'ML'
    AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - LTA'
          AND dim_client.client_code NOT IN ( '00030645', '95000C', '00453737' )
          AND dim_matter_header_current.reporting_exclusions = 0
          AND dim_matter_header_current.date_closed_case_management IS NULL
		  AND dim_matter_header_current.date_opened_case_management <= DATEADD(MONTH,-4,GETDATE())
		  AND ISNULL(fact_matter_summary_current.last_time_transaction_date,'19000101') <= DATEADD(MONTH,-6,GETDATE())
		  AND wip <= 50
		  AND work_type_name  NOT IN ('Plot Sales','Property View')
		  AND NOT LOWER(matter_description)  LIKE '%billing%'
		  AND NOT LOWER(name) LIKE '%property view%'

	--	   AND dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
 --             (
 --                 SELECT (CASE
 --                             WHEN @Level = 'Firm' THEN
 --                                 dim_fed_hierarchy_history_key
 --                             ELSE
 --                                 0
 --                         END
 --                        )
 --                 FROM red_dw.dbo.dim_fed_hierarchy_history
 --                 UNION
 --                 SELECT  (CASE
 --                             WHEN @Level IN ( 'Individual' ) THEN
 --                                 ListValue
 --                             ELSE
 --                                 0
 --                         END
 --                        )
 --                 FROM #FedCodeList
 --                 UNION
 --                 SELECT (CASE
 --                             WHEN @Level IN ( 'Area Managed' ) THEN
 --                                 ListValue
 --                             ELSE
 --                                 0
 --                         END
 --                        )
 --                 FROM #FedCodeList
 --             )
	--ORDER BY hierarchylevel3hist, fact_dimension_main.master_client_code 


	END 
  







GO
