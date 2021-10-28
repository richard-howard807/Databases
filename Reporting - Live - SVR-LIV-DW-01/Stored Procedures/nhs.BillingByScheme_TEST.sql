SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	LD: 20190228
	ES - 20190621 - Added fixed fee cases to create a report parameter based on fee arrangement, 24172
	ES - 20190702 - had to revert this back as the macro helen duffy uses wasn't working, fixed fee cases have been removed for now
	JB - 20210615 - #102528 added in Solicitors PQE years and office location
*/



CREATE PROCEDURE [nhs].[BillingByScheme_TEST] -- EXEC nhs.BillingByScheme_TEST 'Inquest Funding','2021-10-31'
(
    @Scheme AS VARCHAR(MAX),
    @EndDate AS DATETIME
)
AS
BEGIN

    -- For Testing Purposes

    --DECLARE @Scheme AS VARCHAR(200) = 'CNST'
    --DECLARE @EndDate AS DATE = '20211021'


    IF OBJECT_ID('tempdb..#Details') IS NOT NULL
        DROP TABLE #Details;

--select * from #Details
    SELECT a.client_code AS client,
           a.matter_number AS matter,
           RTRIM(a.client_code) + '-' + a.matter_number [LoadNumber],
           matter_description AS case_public_desc1,
           insurerclient_reference AS ClientRef,
           [nhs_scheme] AS [Schema],
           a.client_code AS FeesClient,
           a.matter_number AS FeesMatter,
           dim_claimant_thirdparty_involvement.claimant_name AS Claimant,
           defendant_name AS Defendant,
           insurerclient_name AS cl_clname,
           [nhs_scheme] AS [Scheme],
           [output_wip_fee_arrangement] [FeeArrangement],
           [nhs_instruction_type] AS [InstructionType],
           CASE
               WHEN
               (
                   [output_wip_fee_arrangement] = 'Hourly rate'
                   OR LOWER([nhs_scheme]) = 'inquest funding'
                   OR
                   (
                       [nhs_scheme] = 'CNST'
                       AND [output_wip_fee_arrangement] <> 'Hourly rate'
                       AND [nhs_instruction_type] = 'Inquest - associated claim'
                   )
               ) THEN
                   'Hourly Rate'
               --WHEN [output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee' THEN
               --    'Fixed Fee'
               ELSE
                   NULL
           END AS [Fee Arrangement Filter]
    INTO #Details
    FROM red_dw.dbo.dim_matter_header_current AS a
        INNER JOIN red_dw.dbo.fact_dimension_main
            ON a.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        INNER JOIN red_dw.dbo.dim_detail_health
            ON fact_dimension_main.dim_detail_health_key = dim_detail_health.dim_detail_health_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
            ON fact_dimension_main.dim_detail_finance_key = dim_detail_finance.dim_detail_finance_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
            ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
        LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
            ON fact_dimension_main.dim_defendant_involvem_key = dim_defendant_involvement.dim_defendant_involvem_key
    WHERE LOWER(CASE WHEN [nhs_scheme] IN ('ELSGP (MPS)','ELSGP (MDDUS)') THEN 'ELSGP' ELSE [nhs_scheme] END) = LOWER(@Scheme)
          AND
          (
              (
                  [output_wip_fee_arrangement] = 'Hourly rate'
                  OR LOWER([nhs_scheme]) = 'inquest funding'
                  OR
                  (
                      [nhs_scheme] = 'CNST'
                      AND [output_wip_fee_arrangement] <> 'Hourly rate'
                      AND [nhs_instruction_type] = 'Inquest - associated claim'
                  )
              )
              --OR [output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee'
          )
		 -- AND [output_wip_fee_arrangement] = 'Hourly rate' -- Added by MT 
		  
		  ;

    SELECT Matters.Client,
           Matters.Matter,
           UnbilledWIP.WorkRate AS ChargeRate,
           Number + ' ' + Timekeeper.DisplayName AS tt_feecod,
           ClientRef,
           [Schema],
           FeesClient,
           FeesMatter,
           Claimant,
           Defendant,
           cl_clname,
           [Scheme],
           [FeeArrangement],
           [Fee Arrangement Filter],
           [InstructionType],
           SUM(WIPHrs) AS MinutesWorked, -- SUM(WorkHrs)
           SUM(WIPAmt) AS NetAmount,     -- SUM(WorkAmt)
           NULL AS DisbNotes,
           NULL AS DisbClientRef,
           NULL AS DisbClient,
           NULL AS DisbMatter,
           NULL AS DisbAmount,
           NULL AS DisbVAT,
           NULL DisbJoin,
           NULL AS AccountsUser,
           NULL [DisbsFeeArrangement],
           CASE
               WHEN UnbilledWIP.[WorkRate] > 0 THEN
           (SUM(UnbilledWIP.WorkRate) / COUNT(UnbilledWIP.WorkRate))
               ELSE
                   0
           END AS HourlyRate,
           Number AS FE,
           1 AS xOrder,
           Matters.AltNumber AS AltNumber,
		   DATEDIFF(YEAR, pqe_date.admissiondateud, UnbilledWIP.WorkDate)- 
				CASE 
					WHEN (MONTH(pqe_date.admissiondateud) > MONTH(UnbilledWIP.WorkDate)) OR (MONTH(pqe_date.admissiondateud) = MONTH(UnbilledWIP.WorkDate) AND DAY(pqe_date.admissiondateud) > DAY(UnbilledWIP.WorkDate)) THEN 
						1 
					ELSE 
						0 
				END				AS years_pqe,
		   pqe_date.locationidud AS office
		   --NULL AS [UnbilledDisbs]
    FROM
    (
        SELECT ISNULL(
                         RTRIM(LEFT(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) - 1)),
                         RTRIM(LEFT(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) - 1))
                     ) AS Client,
               ISNULL(
                         SUBSTRING(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) + 1, LEN(Matter.LoadNumber)),
                         SUBSTRING(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) + 1, LEN(Matter.AltNumber))
                     ) AS Matter,
               Matter.MattIndex,
               LoadNumber AS LoadNumber,
               AltNumber AS AltNumber
        FROM TE_3E_Prod.dbo.Matter
    ) AS Matters
        INNER JOIN TE_3E_Prod.dbo.Timecard AS UnbilledWIP WITH(NOLOCK)
            ON Matters.MattIndex = UnbilledWIP.Matter
        LEFT JOIN TE_3E_Prod.dbo.Timekeeper WITH(NOLOCK)
            ON UnbilledWIP.Timekeeper = TkprIndex
        --INNER JOIN axxia01.dbo.camatgrp AS camatgrp 
        -- ON Matters.Client=mg_client collate database_default  AND Matters.Matter=mg_matter collate database_default
        INNER JOIN #Details AS Details
            ON Matters.Client = Details.client COLLATE DATABASE_DEFAULT
               AND Matters.Matter = Details.matter COLLATE DATABASE_DEFAULT
		LEFT OUTER JOIN (
							SELECT 
								dim_fed_hierarchy_current.name
								, dim_fed_hierarchy_current.fed_code
								, dim_employee.admissiondateud
								, dim_employee.locationidud
							FROM red_dw.dbo.dim_fed_hierarchy_current
								INNER JOIN red_dw.dbo.dim_employee
									ON dim_employee.employeeid = dim_fed_hierarchy_current.employeeid
						) AS pqe_date
			ON pqe_date.fed_code COLLATE DATABASE_DEFAULT = Timekeeper.Number
    WHERE WIPRemoveDate IS NULL
          AND
          (
              Matters.LoadNumber LIKE '%-%'
              OR Matters.AltNumber LIKE '%-%'
          )
          AND CONVERT(DATE, WorkDate) <= @EndDate
          AND UnbilledWIP.IsActive = 1
		  AND ISNULL(TimeType,'') NOT IN ('CB10','CB11','CB12')
		  AND Details.FeeArrangement <> 'Fixed Fee/Fee Quote/Capped Fee'
    GROUP BY Matters.Client,
             Matters.Matter,
             UnbilledWIP.WorkRate,
             Number + ' ' + Timekeeper.DisplayName,
             ClientRef,
             [Schema],
             FeesClient,
             FeesMatter,
             Claimant,
             Defendant,
             cl_clname,
             [Scheme],
             [FeeArrangement],
             [Fee Arrangement Filter],
             Number,
             Matters.AltNumber,
             [InstructionType],
			 DATEDIFF(YEAR, pqe_date.admissiondateud, UnbilledWIP.WorkDate)- 
				CASE 
					WHEN (MONTH(pqe_date.admissiondateud) > MONTH(UnbilledWIP.WorkDate)) OR (MONTH(pqe_date.admissiondateud) = MONTH(UnbilledWIP.WorkDate) AND DAY(pqe_date.admissiondateud) > DAY(UnbilledWIP.WorkDate)) THEN 
						1 
					ELSE 
						0 
				END,
			 pqe_date.locationidud

    UNION
    SELECT Matters.Client,
           Matters.Matter,
           UnbilledWIP.WorkRate AS ChargeRate,
           NULL AS mg_feearn,
           ClientRef,
           [Schema],
           FeesClient,
           FeesMatter,
           Claimant,
           Defendant,
           cl_clname,
           [Scheme],
           [FeeArrangement],
           [Fee Arrangement Filter],
           [InstructionType],
           NULL AS MinutesWorked,
           NULL AS NetAmount,
           REPLACE(UnbilledWIP.Narrative_UnformattedText, 'Supplier: ', '') AS DisbNotes,
           ClientRef AS DisbClientRef,
           Matters.Client AS DisbClient,
           Matters.Matter AS DisbMatter,
           COALESCE(VchrDetail.Amount, UnbilledWIP.WorkAmt) AS DisbAmount,
           --,ISNULL(VchrTax.CalcAmt,0) AS DisbVAT
           COALESCE(VchrDetail.Amount, UnbilledWIP.WorkAmt) * (tax.Rate / 100) AS DisbVAT,
           NULL DisbJoin,
           Timekeeper.DisplayName AS AccountsUser,
           [FeeArrangement] [DisbsFeeArrangement],
           NULL AS HourlyRate,
           Number AS FE,
           2 AS xOrder,
           Matters.AltNumber AS AltNumber,
		   NULL AS years_pqe,
		   NULL AS office
		  --CostCard.WorkAmt AS [UnbilledDisbs]
    FROM
    (
        SELECT ISNULL(
                         RTRIM(LEFT(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) - 1)),
                         RTRIM(LEFT(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) - 1))
                     ) AS Client,
               ISNULL(
                         SUBSTRING(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) + 1, LEN(Matter.LoadNumber)),
                         SUBSTRING(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) + 1, LEN(Matter.AltNumber))
                     ) AS Matter,
               Matter.MattIndex,
               LoadNumber AS LoadNumber,
               AltNumber AS AltNumber
        FROM TE_3E_Prod.dbo.Matter
    ) AS Matters
        INNER JOIN TE_3E_Prod.dbo.CostCard AS UnbilledWIP WITH(NOLOCK)
            ON Matters.MattIndex = UnbilledWIP.Matter
        LEFT JOIN TE_3E_Prod.dbo.Timekeeper WITH(NOLOCK)
            ON UnbilledWIP.Timekeeper = TkprIndex
        --INNER JOIN axxia01.dbo.camatgrp AS camatgrp 
        --ON Matters.Client=mg_client collate database_default  AND Matters.Matter=mg_matter collate database_default
        INNER JOIN #Details AS Details
            ON Matters.Client = Details.client COLLATE DATABASE_DEFAULT
               AND Matters.Matter = Details.matter COLLATE DATABASE_DEFAULT
        LEFT OUTER JOIN TE_3E_Prod.dbo.VchrDetail AS VchrDetail
            ON UnbilledWIP.CostIndex = VchrDetail.CostCard
        LEFT OUTER JOIN
        (
            SELECT [TaxLkUp] [TaxCode],
                   [Rate]
            FROM [TE_3E_Prod].[dbo].[TaxDate] WITH(NOLOCK)
            WHERE NxEndDate = '9999-12-31 00:00:00.000'
        ) tax
            ON UnbilledWIP.TaxCode = tax.[TaxCode]

			--unbilled disbursements
			--LEFT OUTER JOIN (SELECT * FROM TE_3E_Prod.dbo.CostCard
			--				WHERE InvMaster IS NULL
			--				AND IsActive=1
			--				AND IsNB=0
			--				AND IsNoCharge=0) AS CostCard ON CostCard.Matter = Matters.MattIndex

    --LEFT OUTER JOIN (SELECT VchrTax.Voucher,SUM(VchrTax.CalcAmt) AS CalcAmt 
    --			    FROM  TE_3E_Prod.dbo.VchrTax AS VchrTax
    --			    WHERE  VchrTax.CalcAmt>0 AND VchrTax.IsActive=1
    --			    GROUP BY VchrTax.Voucher

    --			    ) AS VchrTax
    -- ON VchrDetail.Voucher=VchrTax.Voucher 

    WHERE UnbilledWIP.WIPRemoveDate IS NULL
          AND CONVERT(DATE, UnbilledWIP.WorkDate) <= @EndDate
          AND UnbilledWIP.IsActive = 1
          AND
          (
              Matters.LoadNumber LIKE '%-%'
              OR Matters.AltNumber LIKE '%-%'
          )
		  
		  
		  AND Details.FeeArrangement <> 'Fixed Fee/Fee Quote/Capped Fee'
		  
		  ;




END;
GO
