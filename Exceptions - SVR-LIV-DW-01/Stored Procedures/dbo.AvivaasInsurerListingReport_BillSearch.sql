SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[AvivaasInsurerListingReport_BillSearch]
 @StartDate AS DATE,  @EndDate AS DATE
 
 AS

 --DECLARE @StartDate AS DATE = '2021-10-01'
 --, @EndDate AS DATE = '2021-12-31'

DROP TABLE IF EXISTS #t1
/*Filters*/
DROP TABLE IF EXISTS #filterList
SELECT DISTINCT 
	 ms_fileid = CAST(ms_fileid AS VARCHAR(20))
	 INTO #filterList
	 FROM red_dw.dbo.dim_matter_header_current
	 JOIN red_dw.dbo.fact_dimension_main
	 ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	 JOIN red_dw.dbo.dim_client
	 ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
	 LEFT JOIN red_dw.dbo.dim_client_involvement
	 ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	 LEFT JOIN red_dw.dbo.dim_detail_core_details
	 ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	 LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
	 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	 LEFT JOIN red_dw.dbo.dim_detail_outcome
	 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	WHERE 1 =1 
	
          AND (LOWER(dim_client.[client_name]) LIKE '%aviva%'
          OR (LOWER(dim_client.[client_name]) LIKE '%bibby%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client_involvement.[insuredclient_name]) LIKE '%bibby%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client.[client_name]) LIKE '%veolia%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client_involvement.[insuredclient_name]) LIKE '%veolia%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client.[client_name]) LIKE '%green%king%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client_involvement.[insuredclient_name]) LIKE '%green%king%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client.[client_name]) LIKE '%menzies%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client_involvement.[insuredclient_name]) LIKE '%menzies%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
		  /*Bring in matters under Client No 817628 (Smiths News) where ‘Does claimant have personal injury claim’ = Yes and Aviva is listed in the Associates section*/
          OR (
		  dim_matter_header_current.master_client_code = '817628' 
		  AND does_claimant_have_personal_injury_claim = 'Yes'
		  AND ms_fileid IN (SELECT DISTINCT fileID FROM MS_Prod.[config].[dbAssociates]LEFT JOIN MS_Prod.config.dbContact ON dbContact.contID = dbAssociates.contID WHERE assocHeading LIKE '%Aviva%' OR contName LIKE '%Aviva%' )
           ))
--Remove all matters closed before 1st Jan 2020
AND ISNULL(date_closed_case_management, GETDATE()) >= '2020-01-01'
--Remove any matters within Real Estate teams
AND hierarchylevel3hist <> 'Real Estate'
 AND dim_matter_header_current.[matter_number] NOT IN ( '00000000', 'ML')
 AND ISNULL(outcome_of_case, '') <> 'Exclude from reports'


--DECLARE 
--@ClientGroupName AS NVARCHAR(50) = NULL,
--@ClientCode AS NVARCHAR(50) = NULL,
--@MatterNumber AS NVARCHAR(50) = NULL,
--@WorkTypeDesc AS NVARCHAR(150) = 'Management                              ',
--@BillDateFrom AS INT = NULL,
--@BillDateTo AS INT = NULL, 
--@MatterDateFrom AS DATE = NULL, 
--@MatterDateTo AS DATE = NULL, 
--@FEDCode AS NVARCHAR(50) = 'Unknown', 
--@BillType AS NVARCHAR(50) = 'Bill',  
--@Division AS NVARCHAR(50) = 'Unknown',
--@Department AS NVARCHAR(50) = 'Unknown',
--@Team AS NVARCHAR(50) = 'Unknown',
--@FeeValue AS NUMERIC(13,2)	= 0.00, 
--@BillStatus AS NVARCHAR(50) = 'All'

SELECT  --TOP 10 
distinct
					           
							
								dim_client.client_group_name AS ClientGroupName,
								dim_matter_header_current.client_code AS ClientCode,
								dim_matter_header_current.matter_number AS[MatterNumber],
								dim_matter_header_current.client_name AS [ClientName],
								matter_description AS [MatterDesc],
								branch_code AS [BranchCode],
								work_type_name AS [WorkTypeDesc],
								fact_bill.bill_number AS [BillNumber],
						        CASE when fact_bill.amount_paid = fact_bill.bill_total then 0 else cast(datediff(day,cast( cast(fact_bill.dim_bill_date_key as varchar(10)) as date), getdate()) as numeric(10,2))  end 		AS [BillAgeDays],
								case when bill_record_type = 'b' then 'Bill' when bill_record_type = 'a' then 'Abatement' else bill_record_type end  [BillTypeDesc],
								dim_bill_date.bill_date AS [BillDateDate],
								date_opened_case_management [DateMatterOpenedDate],
								matter_partner_code [PartnerCode],
								dim_fed_hierarchy_history.fed_code [MatterFEDCode],
								dim_fed_hierarchy_history.name [MatterFEDName],
								dim_fed_hierarchy_history.hierarchylevel4hist [MatterTeam],
								dim_fed_hierarchy_history.hierarchylevel3hist [MatterPracticeArea],
								dim_fed_hierarchy_history.hierarchylevel2hist [MatterBusinessLine],
								fact_bill.bill_total AS [BillAmount],
								fact_bill.fees_total as FeeValue,
                                fact_bill.paid_disbursements as DisbursementsPaid,
                                fact_bill.unpaid_disbursements as DisbursementsUnpaid,
                                fact_bill.admin_charges_total as AdministrationCharges,
                                fact_bill.vat_amount as VATAmount,
                                fact_bill.amount_paid as AmountPaid,
								case when final_bill_flag = 1 then 'Final'when final_bill_flag = 0 then 'Interim'end as BillFinalOrInterimDesc,
								CASE WHEN last_pay_calendar_date = '1753-01-01 00:00:00.000' THEN NULL ELSE last_pay_calendar_date END [DateBillLastPaymentDate],
                                fact_dimension_main.master_fact_key [MasterFactKey]
								,final_bill_flag
                                ,ms_fileid = CAST(ms_fileid AS VARCHAR(20) )
                             ,ROW_NUMBER() OVER (PARTITION BY ms_fileid, fact_bill.bill_number ORDER BY CASE when bill_record_type = 'b' then 'Bill' when bill_record_type = 'a' then 'Abatement' else bill_record_type end  desc  ) RN
							 ,BillabatementIssue = CASE WHEN bill_record_type = 'a' AND fact_bill.bill_total <0 THEN 1 ELSE 0 END
							   INTO #t1 
		FROM red_dw.dbo.fact_dimension_main
		JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
		JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
		JOIN red_dw.dbo.fact_bill ON fact_bill.master_fact_key = fact_dimension_main.master_fact_key
		JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		JOIN red_dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
		JOIN red_dw.dbo.fact_bill_activity ON fact_bill_activity.master_fact_key = fact_bill.master_fact_key
		JOIN red_dw.dbo.dim_last_pay_date ON dim_last_pay_date.dim_last_pay_date_key = fact_bill.dim_last_pay_date_key

		WHERE 1= 1
		AND fact_bill.bill_number <> 'PURGE'
	
	     AND dim_bill_date.bill_date BETWEEN @StartDate AND @EndDate
		 
		 AND ms_fileid IN (SELECT ms_fileid FROM #filterList)	

		 --AND ISNULL(bill_record_type, '') <> 'a'
		--AND TRIM(fact_dimension_main.client_code) = 'W15347'
		ORDER BY 
dim_bill_date.bill_date

		SELECT DISTINCT ClientGroupName,
                        ClientCode,
                        MatterNumber,
                        ClientName,
                        MatterDesc,
                        BranchCode,
                        WorkTypeDesc,
                        BillNumber,
                        BillAgeDays,
                        BillTypeDesc,
                        BillDateDate,
                        DateMatterOpenedDate,
                        PartnerCode,
                        MatterFEDCode,
                        MatterFEDName,
                        MatterTeam,
                        MatterPracticeArea,
                        MatterBusinessLine,
                        BillAmount,
                        FeeValue,
                        DisbursementsPaid,
                        DisbursementsUnpaid,
                        AdministrationCharges,
                        VATAmount,
                        AmountPaid,
                        BillFinalOrInterimDesc,
                        DateBillLastPaymentDate,
                        MasterFactKey,
                        final_bill_flag,
                        ms_fileid
                      FROM #t1 WHERE RN = 1 OR BillabatementIssue =1
		ORDER BY BillDateDate

GO
