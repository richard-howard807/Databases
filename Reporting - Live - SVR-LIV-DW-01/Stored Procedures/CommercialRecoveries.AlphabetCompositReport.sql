SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [CommercialRecoveries].[AlphabetCompositReport]

AS 

BEGIN




SELECT ROW_NUMBER() OVER (PARTITION BY fact_bill_matter_detail.bill_number,dim_matter_header_current.client_code,dim_matter_header_current.matter_number ORDER BY fact_bill_matter_detail.bill_number) AS [Number ID]
,COALESCE(assocRef,txtCliRef) AS [F_INV_ACCREF]
,fact_bill_matter_detail.bill_number AS [F_INV_EXTERNAL_NUMBER]
,bill_total - vat AS [F_INV_NET_TOTAL]
,vat AS [F_INV_VAT_TOTAL]
,txtCliRef AS [F_INV_VEH_ID]
,narrative AS [NARRATIVE_1]
,txtVehicleReg AS [NARRATIVE_2]
,matter_description AS [Customer Name]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.fact_bill_matter_detail
 ON fact_bill_matter_detail.client_code = dim_matter_header_current.client_code
 AND fact_bill_matter_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN MS_Prod.dbo.udCRCore
 ON ms_fileid=udcrcore.fileID
LEFT OUTER JOIN red_dw.dbo.dim_bill_debt_narrative
 ON dim_bill_debt_narrative.dim_bill_debt_narrative_key = fact_bill_matter_detail.dim_bill_debt_narrative_key


LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant],assocRef FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant

 ON ms_fileid=Defendant.fileID
WHERE dim_matter_header_current.client_code  IN ('W20110','FW23557','890248') 
AND work_type_code='2038'
AND reversed=0
ORDER BY fact_bill_matter_detail.bill_number

END
GO
