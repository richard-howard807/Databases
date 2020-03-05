SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[BillingByBillingGroup] -- EXEC dbo.BillingByBillingGroup 'C','2018-01-31'
(
@NMI1056 AS VARCHAR(MAX)
,@EndDate AS DATETIME
)
AS
BEGIN
IF OBJECT_ID('tempdb..#Details') IS NOT NULL
    DROP TABLE #Details
   

SELECT a.client_code AS client ,
        a.matter_number AS matter ,
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
[nhs_instruction_type] AS [InstructionType]

INTO #Details
FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main
 ON a.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
INNER  JOIN red_dw.dbo.dim_detail_client
 ON fact_dimension_main.dim_detail_client_key=dim_detail_client.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON fact_dimension_main.dim_detail_health_key=dim_detail_health.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
 ON fact_dimension_main.dim_detail_finance_key=dim_detail_finance.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement 
 ON fact_dimension_main.dim_client_involvement_key=dim_client_involvement.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON fact_dimension_main.dim_claimant_thirdpart_key=dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
 ON fact_dimension_main.dim_defendant_involvem_key=dim_defendant_involvement.dim_defendant_involvem_key

 
 
WHERE billing_group = RTRIM(@NMI1056)

SELECT Matters.Client,Matters.Matter,WorkRate AS ChargeRate
,Number + ' ' + Timekeeper.DisplayName AS tt_feecod
,ClientRef
,[Schema]
,FeesClient
,FeesMatter
,Claimant
,Defendant
,cl_clname
,[Scheme]
,[FeeArrangement]
,[InstructionType]
,SUM(WIPHrs) AS MinutesWorked -- SUM(WorkHrs) Requested to be changed by Jenny Byfield 26.09.17
,SUM(WIPAmt) AS NetAmount -- SUM(WorkAmt) Requested to be changed by Jenny Byfield 26.09.17
,NULL AS DisbNotes
,NULL AS DisbClientRef
,NULL AS DisbClient
,NULL AS DisbMatter
,NULL AS DisbAmount
,NULL AS DisbVAT
,NULL	DisbJoin
,NULL AS AccountsUser
,NULL[DisbsFeeArrangement]
,   CASE WHEN [WorkRate] > 0
         THEN (SUM(WorkRate) / COUNT(WorkRate))
         ELSE 0
    END AS HourlyRate
,Number AS FE
,1 AS xOrder
,Matters.AltNumber AS AltNumber
FROM 
(
SELECT  ISNULL(RTRIM(LEFT(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) - 1)) ,RTRIM(LEFT(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) - 1)) ) AS Client
,ISNULL(SUBSTRING(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber)  + 1, LEN(Matter.LoadNumber)),SUBSTRING(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber)  + 1, LEN(Matter.AltNumber)))
AS Matter
,Matter.MattIndex
,LoadNumber AS LoadNumber
,AltNumber AS AltNumber
FROM TE_3E_Prod.dbo.Matter  
) AS Matters
INNER JOIN TE_3E_Prod.dbo.Timecard AS UnbilledWIP
 ON Matters.MattIndex=UnbilledWIP.Matter
LEFT JOIN TE_3E_Prod.dbo.Timekeeper
 ON UnbilledWIP.Timekeeper=TkprIndex
--INNER JOIN axxia01.dbo.camatgrp AS camatgrp 
-- ON Matters.Client=mg_client COLLATE DATABASE_DEFAULT  AND Matters.Matter=mg_matter COLLATE DATABASE_DEFAULT
INNER JOIN #Details AS Details 
ON Matters.Client=Details.client COLLATE DATABASE_DEFAULT AND Matters.Matter=Details.matter COLLATE DATABASE_DEFAULT

WHERE  WIPRemoveDate IS NULL
AND CONVERT(DATE,WorkDate) <=@EndDate



AND UnbilledWIP.IsActive=1
GROUP BY Matters.Client,Matters.Matter,WorkRate 
,Number + ' ' + Timekeeper.DisplayName
,ClientRef,[Schema],FeesClient,FeesMatter
,Claimant,Defendant,cl_clname,[Scheme]
,[FeeArrangement],Number,Matters.AltNumber
,[InstructionType]

UNION
SELECT Matters.Client,Matters.Matter,WorkRate AS ChargeRate
,NULL AS mg_feearn
,ClientRef,[Schema],FeesClient,FeesMatter,Claimant
,Defendant,cl_clname,[Scheme],[FeeArrangement]
,[InstructionType]
,NULL AS MinutesWorked
,NULL AS NetAmount
,REPLACE(UnbilledWIP.Narrative,'Supplier: ','') AS DisbNotes
,ClientRef AS DisbClientRef
,Matters.Client AS DisbClient
,Matters.Matter AS DisbMatter
,COALESCE(VchrDetail.Amount,WorkAmt) AS DisbAmount
,ISNULL(VchrTax.CalcAmt,0) AS DisbVAT
,NULL	DisbJoin
,Timekeeper.DisplayName AS AccountsUser
,[FeeArrangement] [DisbsFeeArrangement]
,NULL AS HourlyRate
,Number AS FE
,2 AS xOrder
,Matters.AltNumber AS AltNumber
FROM 
(
SELECT  ISNULL(RTRIM(LEFT(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) - 1)) ,RTRIM(LEFT(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) - 1)) ) AS Client
,ISNULL(SUBSTRING(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber)  + 1, LEN(Matter.LoadNumber)),SUBSTRING(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber)  + 1, LEN(Matter.AltNumber)))
AS Matter
,Matter.MattIndex
,LoadNumber AS LoadNumber
,AltNumber AS AltNumber
FROM TE_3E_Prod.dbo.Matter  
) AS Matters
INNER JOIN TE_3E_Prod.dbo.CostCard AS UnbilledWIP  
 ON Matters.MattIndex=UnbilledWIP.Matter
LEFT JOIN TE_3E_Prod.dbo.Timekeeper 
 ON UnbilledWIP.Timekeeper=TkprIndex
--INNER JOIN axxia01.dbo.camatgrp AS camatgrp 
-- ON Matters.Client=mg_client COLLATE DATABASE_DEFAULT  AND Matters.Matter=mg_matter COLLATE DATABASE_DEFAULT
INNER JOIN #Details AS Details 
 ON Matters.Client=Details.client COLLATE DATABASE_DEFAULT AND Matters.Matter=Details.matter COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN TE_3E_Prod.dbo.VchrDetail AS VchrDetail
 ON UnbilledWIP.CostIndex=VchrDetail.CostCard
LEFT OUTER JOIN (SELECT VchrTax.Voucher,SUM(VchrTax.CalcAmt) AS CalcAmt 
			    FROM  TE_3E_Prod.dbo.VchrTax AS VchrTax
			    WHERE  VchrTax.CalcAmt>0 AND VchrTax.IsActive=1
			    GROUP BY VchrTax.Voucher
			    
			    ) AS VchrTax
 ON VchrDetail.Voucher=VchrTax.Voucher 
 
WHERE  WIPRemoveDate IS NULL
AND CONVERT(DATE,WorkDate) <=@EndDate
AND UnbilledWIP.IsActive=1




-- SELECT Details.case_id ,
--        client ,
--        matter ,
--		RTRIM(client) + '-' + matter [LoadNumber],
--        case_public_desc1,
--        ROW_NUMBER() OVER (PARTITION BY client, matter ORDER BY Details.case_id) AS DetailsRank,
--RTRIM(Reporting.dbo.ufn_Coalesce_CapacityDetails_reference(Details.case_id, 'TRA00002')) AS ClientRef,
--RTRIM(NHS039.detail) AS [Schema],
--[Details].[client] AS FeesClient,
--[Details].[matter] AS FeesMatter,
--RTRIM(Reporting.dbo.ufn_Coalesce_CapacityDetails (Details.case_id, '~ZCLAIM')) AS Claimant,
--Reporting.dbo.ufn_Coalesce_CapacityDetails (Details.case_id, '~ZDEFEND') AS Defendant,
--Reporting.dbo.ufn_Coalesce_CapacityDetails (Details.case_id, 'TRA00002') AS cl_clname,
--NHS039.detail [Scheme],
--NMI983.detail [FeeArrangement],
--NHS216.case_text AS [InstructionType]
--INTO #Details
--FROM axxia01.dbo.Details AS Details WITH (NOLOCK)

   



--LEFT OUTER JOIN ( SELECT    case_id, RTRIM(case_text) as detail
--                  FROM      axxia01.dbo.casdet WITH (NOLOCK)
--                  WHERE     case_detail_code = 'NHS039'
--                ) AS NHS039 ON Details.case_id = NHS039.case_id  --Scheme
--LEFT OUTER JOIN ( SELECT    case_id, RTRIM(case_text) as detail
--                  FROM      axxia01.dbo.casdet WITH (NOLOCK)
--                  WHERE     case_detail_code = 'NMI983'
--                ) AS NMI983 ON Details.case_id = NMI983.case_id  --Scheme
                
--LEFT OUTER JOIN ( SELECT    case_id, RTRIM(case_text) as case_text
--                  FROM      axxia01.dbo.casdet WITH (NOLOCK)
--                  WHERE     case_detail_code = 'NHS216'
--                ) AS NHS216 ON Details.case_id = NHS216.case_id  --Instruction Type


--WHERE NHS039.detail = @Scheme
--AND ( NMI983.detail='Hourly rate' OR NHS039.detail='Inquest Funding')
--ORDER BY Details.case_id
END

GO
