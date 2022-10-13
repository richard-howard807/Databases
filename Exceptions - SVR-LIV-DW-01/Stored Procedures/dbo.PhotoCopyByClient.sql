SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PhotoCopyByClient]
(
@Client AS NVARCHAR(30)
)
AS
BEGIN
SELECT a.client_code AS [Client]
,a.costype_description AS [Type]
,SUM(CASE WHEN bill_number='PURGE' OR bill_reversed=1 THEN NULL ELSE a.total_disbursements  END) AS [Billed]
,SUM(CASE WHEN bill_number='PURGE' OR bill_reversed=1 THEN NULL ELSE a.total_disbursements  END)  +
 SUM(CASE WHEN bill_number='PURGE' OR bill_reversed=1 THEN NULL ELSE a.total_disbursements_vat  END) AS [BilledIncVAT]
,SUM(WrittenOff) AS [WriteOff]
,SUM(WriteOffQuantity) AS [WriteOffQuantity]
,SUM(a.total_unbilled_disbursements) AS Unbilled
,SUM(a.total_unbilled_disbursements)+SUM(a.total_unbilled_disbursements_vat) AS UnbilledIncVAT
FROM red_dw.dbo.fact_disbursements_detail AS a
LEFT OUTER JOIN  red_dw.dbo.dim_disbursement_cost_type AS b
 On a.dim_disbursement_cost_type_key=b.dim_disbursement_cost_type_key
LEFT OUTER JOIN red_dw.dbo.dim_bill 
 ON a.dim_bill_key=dim_bill.dim_bill_key
LEFT OUTER JOIN (
SELECT costindex,SUM(workamt) WrittenOff ,SUM(workqty) AS WriteOffQuantity FROM red_dw.dbo.ds_sh_3e_costcard
WHERE  costtype='CP'
GROUP BY costindex
) AS WrittenOff
 ON a.costindex=WrittenOff.costindex 
WHERE cost_type_code='CP'
AND a.client_code=@Client

GROUP BY a.client_code
,a.costype_description
END
GO
