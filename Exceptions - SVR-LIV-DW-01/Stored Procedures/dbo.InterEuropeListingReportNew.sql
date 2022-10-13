SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Jamie Bonner>
-- Create date: <2020-01-24>
-- Description:	<ticket #43507 new logic for InterEurope listing report>
-- Update as per Ticket 83725 -- removal of 351402.52
-- =============================================
-- ES 2021-06-01 #100867, amended status, claim category and damages paid logic
-- ES 2021-06-08 #101696, added quantified reserve fields
-- =============================================
CREATE PROCEDURE [dbo].[InterEuropeListingReportNew]
AS
BEGIN

    SET NOCOUNT ON;
    SELECT h_current.master_client_code + '.' + h_current.master_matter_number AS [Weightmans Reference],
           --	, LTRIM(RTRIM(client_involv.client_reference))	AS [Insurer Client Reference]
           COALESCE(
                       MSbillingAddress.[Insurer Reference],
                       client_involv.client_reference COLLATE DATABASE_DEFAULT,
                       client_involv.[insurerclient_reference] COLLATE DATABASE_DEFAULT
                   ) [Insurer Client Reference],
           --, LTRIM(RTRIM(client_involv.insuredclient_name))	AS [Insurer Client]
           foreigninsurer.name AS [Insurer Client],
           CAST(core_details.date_instructions_received AS DATE) AS [Date Instructions Received],
		   CONCAT(dim_date.cal_month_name,'-',dim_date.cal_year) AS [Month Instructions Received],
           CASE
               WHEN core_details.referral_reason = 'Costs dispute' THEN
                   'Costs Only'
               WHEN core_details.referral_reason = 'Infant approval' THEN
                   'Infant Approval'
               WHEN core_details.referral_reason = 'Nomination only' THEN
                   'Procedural Only'
               WHEN core_details.track = 'Small Claims' THEN
                   'Small Claims'
               WHEN core_details.track = 'Fast Track' THEN
                   'Fast Track'
			   WHEN core_details.track = 'Multi Track' AND fin_sum.damages_reserve > 5000000 THEN
                   'Multi Track > £5m'
               WHEN core_details.track = 'Multi Track' THEN
                   'Multi Track'
               ELSE
                   NULL
           END AS [Claim Category],
           CASE
               WHEN outcome.outcome_of_case = 'Exclude from reports' AND h_current.matter_owner_full_name<>'Steven Hassall' THEN
                   'Excluded'
               WHEN outcome.date_costs_settled IS NULL THEN
                   'Open'
               ELSE
                   'Closed'
           END AS [Status],
           CAST(core_details.incident_date AS DATE) AS [Date of Accident],
           COALESCE(third_party.claimantsols_name, third_party.claimantrep_name) AS [Claimant Solicitor],
           core_details.proceedings_issued AS [Proceedings Issued],
           --CASE
           --    WHEN outcome.date_claim_concluded IS NOT NULL THEN
           --        NULL
           --    ELSE
           --        fin_sum.damages_reserve_net
           --END AS 
		   fin_sum.damages_reserve
		   
		   [Damages Reserve],
           'TBC' AS [Quantified Damages claimed],
           --CASE
           --    WHEN outcome.date_claim_concluded IS NOT NULL THEN
           --        NULL
           --    ELSE
           --        fin_sum.tp_costs_reserve_net
           --END AS 
		   res_detail.claimant_costs_reserve_current
		   [TP Costs Reserve],
           'TBC' AS [Quantified Costs claimed],
           outcome.outcome_of_case AS [Outcome of Case],
           CASE
               WHEN outcome.date_claim_concluded IS NOT NULL THEN
                   NULL
               ELSE
                   elapsed_days.elapsed_days_live_files
           END AS [Live elapsed days],
           elapsed_days.elapsed_days_conclusion AS [Number of days to settlement],
           elapsed_days.elapsed_days_costs_to_settle AS [Damages to costs lifecycle],
           fin_sum.damages_paid AS [Damages Paid],
           'TBC' AS [Damages Saving against Reserve],
           --, fin_sum.total_tp_costs_paid_to_date																				
           fin_sum.total_tp_costs_paid AS [TP Costs Paid],
           'TBC' AS [Costs Saving against Claimed],
           CAST(h_current.date_closed_case_management AS DATE) AS [Date closed in MS],
           ISNULL(fin_sum.total_amount_billed, 0) AS [Total billed (inc disbs)],
           LTRIM(RTRIM(core_details.clients_claims_handler_surname_forename)) AS [InterEurope Handler Name],
           core_details.track AS [Track],
           core_details.referral_reason AS [Referral Reason],
           CAST(core_details.date_initial_report_sent AS DATE) AS [Date Initial Report Sent],
           CAST(core_details.date_subsequent_sla_report_sent AS DATE) AS [Date of Subsequent Report],
           CAST(core_details.date_the_closure_report_sent AS DATE) AS [Date Of Report Closure (internal)],
           fin_sum.damages_reserve AS [Damages Reserve  (not NET)],
           res_detail.quantified_damages_reserve AS [Quantified Damages Reserve (Not NET)],
           res_detail.claimant_costs_reserve_current AS [TP costs Reserve (Not NET)],
           res_detail.quantified_tp_costs_reserve AS [Quantified Costs Reserve (Not NET)],
           find_trial_date.trial_date AS [Trial date],
           core_details.present_position AS [Present Position],
           detail_fin.output_wip_fee_arrangement AS [Fee Arrangement],
           h_current.matter_owner_full_name AS [Weightmans Handler Name],
           h_current.matter_description AS [Matter Description],
           fin_sum.defence_costs_reserve AS [Defence Cost Reserve],
           CAST(outcome.date_claim_concluded AS DATE) AS [Date Claim Concluded],
           --required for dashboard
           outcome.[date_costs_settled] AS [Date Costs Settled],
           [dbo].[ReturnElapsedDaysExcludingBankHolidays](
                                                             core_details.date_instructions_received,
                                                             core_details.date_initial_report_sent
                                                         ) AS [Working Days to Initial Report Sent],
           outcome.[repudiation_outcome] AS [Repudiation - outcome],
           core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension for the Initail Report?]
    --select *
    FROM red_dw.dbo.dim_matter_header_current h_current
        INNER JOIN red_dw.dbo.fact_dimension_main fact_dim_main
            ON fact_dim_main.dim_matter_header_curr_key = h_current.dim_matter_header_curr_key
        INNER JOIN red_dw.dbo.dim_client_involvement client_involv
            ON client_involv.dim_client_involvement_key = fact_dim_main.dim_client_involvement_key
        INNER JOIN red_dw.dbo.dim_detail_core_details core_details
            ON core_details.dim_detail_core_detail_key = fact_dim_main.dim_detail_core_detail_key
        INNER JOIN red_dw.dbo.dim_detail_outcome outcome
            ON outcome.dim_detail_outcome_key = fact_dim_main.dim_detail_outcome_key
        INNER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement third_party
            ON third_party.dim_claimant_thirdpart_key = fact_dim_main.dim_claimant_thirdpart_key
        INNER JOIN red_dw.dbo.fact_finance_summary fin_sum
            ON fin_sum.master_fact_key = fact_dim_main.master_fact_key
        INNER JOIN red_dw.dbo.fact_detail_elapsed_days elapsed_days
            ON elapsed_days.master_fact_key = fact_dim_main.master_fact_key
        INNER JOIN red_dw.dbo.fact_detail_paid_detail paid_detail
            ON paid_detail.master_fact_key = fact_dim_main.master_fact_key
        INNER JOIN red_dw.dbo.dim_detail_finance detail_fin
            ON detail_fin.dim_detail_finance_key = fact_dim_main.dim_detail_finance_key
        INNER JOIN red_dw.dbo.fact_detail_reserve_detail res_detail
            ON res_detail.master_fact_key = fact_dim_main.master_fact_key
		INNER JOIN red_dw.dbo.dim_date
		ON dim_date.calendar_date=CAST(core_details.date_instructions_received AS DATE)
        LEFT OUTER JOIN
        (
            SELECT court.client_code,
                   court.matter_number,
                   tasks.task_code,
                   tasks.task_desccription,
                   COALESCE(CAST(court.date_of_trial AS DATE), CAST(due.calendar_date AS DATE)) AS trial_date
            FROM red_dw.dbo.dim_detail_court court
                INNER JOIN red_dw.dbo.dim_tasks tasks
                    ON tasks.client_code = court.client_code
                       AND tasks.matter_number = court.matter_number
                INNER JOIN red_dw.dbo.fact_tasks fact
                    ON fact.dim_tasks_key = tasks.dim_tasks_key
                INNER JOIN red_dw.dbo.dim_task_due_date due
                    ON due.dim_task_due_date_key = fact.dim_task_due_date_key
            WHERE tasks.client_code = '00351402'
                  AND tasks.task_desccription LIKE '%rial date - today%'
        ) find_trial_date
            ON find_trial_date.client_code = h_current.client_code
               AND find_trial_date.matter_number = h_current.matter_number
        LEFT JOIN
        (
            SELECT dbAssociates.fileID,
                   assocType,
                   contName AS [Insurer Name],
                   assocAddressee AS [Addressee],
                   CASE
                       WHEN assocdefaultaddID IS NOT NULL THEN
                           ISNULL(dbAddress1.addLine1, '') + ' ' + ISNULL(dbAddress1.addLine2, '') + ' '
                           + ISNULL(dbAddress1.addLine3, '') + ' ' + ISNULL(dbAddress1.addLine4, '') + ' '
                           + ISNULL(dbAddress1.addLine5, '') + ' ' + ISNULL(dbAddress1.addPostcode, '')
                       ELSE
                           ISNULL(dbAddress2.addLine1, '') + ' ' + ISNULL(dbAddress2.addLine2, '') + ' '
                           + ISNULL(dbAddress2.addLine3, '') + ' ' + ISNULL(dbAddress2.addLine4, '') + ' '
                           + ISNULL(dbAddress2.addLine5, '') + ' ' + ISNULL(dbAddress2.addPostcode, '')
                   END AS [Insurer Address],
                   dbAssociates.assocRef AS [Insurer Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress1 WITH (NOLOCK)
                    ON assocdefaultaddID = dbAddress1.addID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress2 WITH (NOLOCK)
                    ON contDefaultAddress = dbAddress2.addID
                LEFT OUTER JOIN MS_Prod.config.dbFile
                    ON dbFile.fileID = dbAssociates.fileID
                LEFT OUTER JOIN MS_Prod.config.dbClient
                    ON dbClient.clID = dbFile.clID
            WHERE assocType = 'CLIENT'
                  AND dbClient.clNo = '351402'
        )
        --WHERE assocType='INSURERCLIENT' ) 



        AS MSbillingAddress
            ON h_current.ms_fileid = MSbillingAddress.fileID
               AND MSbillingAddress.XOrder = 1
        LEFT OUTER JOIN
        (
            SELECT dim_matter_header_current.master_client_code,
                   dim_matter_header_current.master_matter_number,
                   dim_involvement_full.capacity_description,
                   dim_involvement_full.name
            FROM red_dw.dbo.fact_dimension_main
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
                LEFT OUTER JOIN red_dw.dbo.dim_involvement_full
                    ON dim_involvement_full.dim_involvement_full_bridge_key = fact_dimension_main.dim_involvement_full_bridge_key
            WHERE dim_matter_header_current.master_client_code = '351402'
                  AND dim_involvement_full.capacity_code = 'FORINS'
        ) AS foreigninsurer
            ON foreigninsurer.master_client_code = h_current.master_client_code
               AND foreigninsurer.master_matter_number = h_current.master_matter_number


    --  LEFT JOIN
    --    (
    --        SELECT dbAssociates.fileID,
    --               assocType,
    --               contName AS [Insurer Name],
    --               assocAddressee AS [Addressee],
    --               CASE
    --                   WHEN assocdefaultaddID IS NOT NULL THEN
    --                       ISNULL(dbAddress1.addLine1, '') + ' ' + ISNULL(dbAddress1.addLine2, '') + ' '
    --                       + ISNULL(dbAddress1.addLine3, '') + ' ' + ISNULL(dbAddress1.addLine4, '') + ' '
    --                       + ISNULL(dbAddress1.addLine5, '') + ' ' + ISNULL(dbAddress1.addPostcode, '')
    --                   ELSE
    --                       ISNULL(dbAddress2.addLine1, '') + ' ' + ISNULL(dbAddress2.addLine2, '') + ' '
    --                       + ISNULL(dbAddress2.addLine3, '') + ' ' + ISNULL(dbAddress2.addLine4, '') + ' '
    --                       + ISNULL(dbAddress2.addLine5, '') + ' ' + ISNULL(dbAddress2.addPostcode, '')
    --               END AS [Insurer Address],
    --               dbAssociates.assocRef AS [Insurer Reference],
    --               ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
    --        FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
    --            INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
    --                ON dbAssociates.contID = dbContact.contID
    --            LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress1 WITH (NOLOCK)
    --                ON assocdefaultaddID = dbAddress1.addID
    --            LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress2 WITH (NOLOCK)
    --                ON contDefaultAddress = dbAddress2.addID
    --LEFT OUTER JOIN MS_Prod.config.dbFile
    --	ON dbFile.fileID = dbAssociates.fileID
    --LEFT OUTER JOIN MS_Prod.config.dbClient
    --	ON dbClient.clID = dbFile.clID
    --        WHERE assocType = 'INSURERCLIENT'
    --AND dbClient.clNo = '351402'

    --    ) AS foreigninsurer ON foreigninsurer.fileID = MSbillingAddress.fileID
    --AND foreigninsurer.XOrder = 1 
    WHERE h_current.client_code = '00351402'
          AND h_current.matter_number <> 'ML'
          AND h_current.reporting_exclusions = 0
          AND CAST(core_details.date_instructions_received AS DATE) >= '2019-11-01'
          AND h_current.matter_owner_full_name <> 'Jake Whewell'
          /*Hardcoded as per Ticket 83725*/
          AND h_current.master_client_code + '.' + h_current.master_matter_number <> '351402.52'
          --AND core_details.matter_number IN ( '00000061', '00000092' );


END;
GO
