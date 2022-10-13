SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	LD: 20190228
	ES - 20190621 - Added fixed fee cases to create a report parameter based on fee arrangement, 24172
	ES - 20190702 - had to revert this back as the macro helen duffy uses wasn't working, fixed fee cases have been removed for now
	ES - 20190808 - created copy of BillingByScheme to filter to fixed fee cases
*/



CREATE PROCEDURE [nhs].[BillingBySchemeFixedFee] -- EXEC [nhs].[BillingBySchemeFixedFee] 'CNST','2018-10-31'
(
    @Scheme AS VARCHAR(MAX),
    @EndDate AS DATETIME
)
AS
BEGIN

    -- For Testing Purposes

    --DECLARE @Scheme AS VARCHAR(200) = 'CNST'
    --DECLARE @EndDate AS DATE = '20201031'


    IF OBJECT_ID('tempdb..#Details') IS NOT NULL
        DROP TABLE #Details;


    SELECT a.client_code AS client,
           a.matter_number AS matter,
           RTRIM(a.client_code) + '-' + a.matter_number [LoadNumber],
           matter_description AS case_public_desc1,
		   a.matter_owner_full_name AS matter_owner,
           insurerclient_reference AS ClientRef,
           [nhs_scheme] AS [Schema],
           a.client_code AS FeesClient,
           a.matter_number AS FeesMatter,
           dim_claimant_thirdparty_involvement.claimant_name AS Claimant,
           defendant_name AS Defendant,
           insurerclient_name AS cl_clname,
           [nhs_scheme] AS [Scheme],
           [output_wip_fee_arrangement] [FeeArrangement],
           [nhs_instruction_type] AS [InstructionType]

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
	AND [output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee'


    SELECT Matters.Client,
           Matters.Matter,
           CostCard.WorkRate AS ChargeRate,
           NULL AS tt_feecod,
           ClientRef,
           [Schema],
           FeesClient,
           FeesMatter,
           Claimant,
           Defendant,
           cl_clname,
           [Scheme],
           [FeeArrangement],
           [InstructionType],
           NULL AS MinutesWorked,
           NULL AS NetAmount,
           REPLACE(CostCard.Narrative_UnformattedText, 'Supplier: ', '') AS DisbNotes,
           ClientRef AS DisbClientRef,
           Matters.Client AS DisbClient,
           Matters.Matter AS DisbMatter,
           CostCard.WorkAmt AS DisbAmount,
           (CostCard.WorkAmt) * (tax.Rate / 100) AS DisbVAT,
           NULL DisbJoin,
           Timekeeper.DisplayName AS AccountsUser,
           [FeeArrangement] [DisbsFeeArrangement],
           NULL AS HourlyRate,
           Number AS FE,
           2 AS xOrder,
           Matters.AltNumber AS AltNumber,
		   Details.case_public_desc1,
		   Details.matter_owner,
		   CostCard.PostDate,
		   dim_disbursement_cost_type.cost_type_description

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
	--unbilled disbursements
			INNER JOIN (SELECT * FROM TE_3E_Prod.dbo.CostCard
							WHERE InvMaster IS NULL
							AND IsActive=1
							AND IsNB=0
							AND IsNoCharge=0) AS CostCard ON CostCard.Matter = Matters.MattIndex
        --INNER JOIN TE_3E_Prod.dbo.CostCard AS UnbilledWIP
        --    ON Matters.MattIndex = UnbilledWIP.Matter
        LEFT JOIN TE_3E_Prod.dbo.Timekeeper
            ON CostCard.Timekeeper = TkprIndex
        --INNER JOIN axxia01.dbo.camatgrp AS camatgrp 
        --ON Matters.Client=mg_client collate database_default  AND Matters.Matter=mg_matter collate database_default
        INNER JOIN #Details AS Details
            ON Matters.Client = Details.client COLLATE DATABASE_DEFAULT
               AND Matters.Matter = Details.matter COLLATE DATABASE_DEFAULT
        LEFT OUTER JOIN TE_3E_Prod.dbo.VchrDetail AS VchrDetail
            ON CostCard.CostIndex = VchrDetail.CostCard
		LEFT OUTER JOIN red_dw.dbo.dim_disbursement_cost_type
		ON cost_type_code=CostCard.CostType COLLATE DATABASE_DEFAULT
        LEFT OUTER JOIN
        (
            SELECT [TaxLkUp] [TaxCode],
                   [Rate]
            FROM [TE_3E_Prod].[dbo].[TaxDate]
            WHERE NxEndDate = '9999-12-31 00:00:00.000'
        ) tax
            ON CostCard.TaxCode = tax.[TaxCode]

			

    --LEFT OUTER JOIN (SELECT VchrTax.Voucher,SUM(VchrTax.CalcAmt) AS CalcAmt 
    --			    FROM  TE_3E_Prod.dbo.VchrTax AS VchrTax
    --			    WHERE  VchrTax.CalcAmt>0 AND VchrTax.IsActive=1
    --			    GROUP BY VchrTax.Voucher

    --			    ) AS VchrTax
    -- ON VchrDetail.Voucher=VchrTax.Voucher 

    WHERE CostCard.WIPRemoveDate IS NULL
          AND CONVERT(DATE, CostCard.WorkDate) <= @EndDate
          AND CostCard.IsActive = 1
          AND
          (
              Matters.LoadNumber LIKE '%-%'
              OR Matters.AltNumber LIKE '%-%'
          );




END;
GO
