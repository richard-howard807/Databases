SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[NHSRFramworkBillingReport]

AS 

BEGIN
SELECT dim_detail_health.[nhs_scheme] AS [Scheme]
,dim_claimant_thirdparty_involvement.claimant_name AS [Claimant]
,RTRIM(master_client_code)+'-'+ RTRIM(master_matter_number)  AS [Client/matter - MS]
,name AS [Matter owner]
,hierarchylevel4hist  AS [Team]
,insurerclient_reference AS [Insurer client reference]
,date_instructions_received AS [Date of instruction]
,dim_detail_health.[nhs_instruction_type] AS [Instruction type]
,CostBillType.cdDesc AS [Type of bill]
,NHSRDAMBAND.cdDesc AS [Damages Reserve Banding]
,NHSRINSTTYPE.cdDesc AS [Type of Instruction]
,CASE WHEN cboNHSRResDLOR='Y' THEN 'Yes' WHEN cboNHSRResDLOR='N' THEN 'No' END AS [Did NHSR draft Letter of Response?]
,curFee AS [Fee]
,TO10PLUS.cdDesc AS [How many experts were instructed?]
,CASE WHEN cboReqSupComms='Y' THEN 'Yes' WHEN cboReqSupComms='N' THEN 'No' END   AS [Did we request any supplementary comments that incurred fees?]
,curSuppFees AS [How many extra fees were incurred?]
,CASE WHEN cboExpertDetail='Y' THEN 'Yes' WHEN cboExpertDetail='N' THEN 'No' END   AS [Are all expert fees shown in the disbursement list above?]
,YESNONA1200.cdDesc AS [Expert more than £1200 - Permission to bill the extra from NHSR? ]
,CASE WHEN CAST(cboMedicRecs AS INT)>10 THEN '10+' ELSE CAST(CAST(cboMedicRecs AS INT) AS NVARCHAR(10)) END [How many sets of medical records did we obtain?]
,CASE WHEN CAST(cboGPTrustSets AS INT)>10 THEN '10+' ELSE CAST(CAST(cboGPTrustSets AS INT) AS NVARCHAR(10)) END  AS [How many sets did we obtain from the GP or trust?]
,CASE WHEN CAST(cboExtra85 AS INT)>10 THEN '10+' ELSE CAST(CAST(cboExtra85 AS INT) AS NVARCHAR(10)) END  AS [For how many sets can we charge £85 for sorting and paginating?]
,curExtraSortPag AS [Extra Charge for sorting and paginating]
,CASE WHEN CAST(cboClaimSolSets AS INT)>10 THEN '10+' ELSE CAST(CAST(cboClaimSolSets AS INT) AS NVARCHAR(10)) END   AS [How many sets did we obtain from the claimant’s solicitors or a third party?]
,CASE WHEN cboAllRecDet='Y' THEN 'Yes' WHEN cboAllRecDet='N' THEN 'No' END AS [Are all the invoices relating to medical records obtained from Claimant Sols or Third Party]
,CASE WHEN cboNHSRApprove='Y' THEN 'Yes' WHEN cboNHSRApprove='N' THEN 'No' END  AS [Have NHSR approved the above disbursements? ]
,curExtWorkFees AS [Detail here the amount of any other fees agreed]
,txtNotes AS [Bill Notes]
,red_dw.dbo.datetimelocal(dteInserted) AS [Activity date]
,usrFullName AS [Who ran the activity?]
,CASE WHEN cboTravelExpen='Y' THEN 'Yes' WHEN cboTravelExpen='N' THEN 'No' END  AS [Has the claimant incurred (reasonable) travel expenses? ]
,CASE WHEN cboAllExpFeeSho='Y' THEN 'Yes' WHEN cboAllExpFeeSho='N' THEN 'No' END  AS [Are all expert fees & other disbs shown in the disbursement list above?]
,NHSRTYPEBILL.cdDesc AS [What type of bill?]
,CASE WHEN cboBillExceed='Y' THEN 'Yes' WHEN cboBillExceed='N' THEN 'No' END  AS [Does WIP exceed £2500]
,CASE WHEN cboFeeSch5Prot='Y' THEN 'Yes' WHEN cboFeeSch5Prot='N' THEN 'No' END  AS [Are the fees as set out at para 4 (c) of the Schedule 5 protocol? ]
,YESNONANOEXPINS.cdDesc AS [Are all experts’ fees shown above including any fees relating to a summit meeting?]
,CASE WHEN cboNHSRAuthFee='Y' THEN 'Yes' WHEN cboNHSRAuthFee='N' THEN 'No' END  AS [Have NHSR authorised these experts and fees? ]
,CASE WHEN cboObtainMedRec='Y' THEN 'Yes' WHEN cboObtainMedRec='N' THEN 'No' END  AS [Did we obtain medical records]
,CASE WHEN cboFeesAbove='Y' THEN 'Yes' WHEN cboFeesAbove='N' THEN 'No' END  AS [Are all medical records showing above?]
,CASE WHEN cboCounInpProv='Y' THEN 'Yes' WHEN cboCounInpProv='N' THEN 'No' END  AS [Has counsel input been provided? ]
,YESNONA1250.cdDesc AS [If counsel input has been provided & fees exceed £1,250, has this been approved by NHSR?]

,INQDAYS.cdDesc AS [How many days was the inquest?]
,CASE WHEN cboChargeExtra='Y' THEN 'Yes' WHEN cboChargeExtra='N' THEN 'No' END  AS [Can we charge extra for intial report?]
,CASE WHEN cboEstCostContr='Y' THEN 'Yes' WHEN cboEstCostContr='N' THEN 'No' END  AS [Have the trust been provided with an estimate of costs over the NHSR contribution? ]
,txtTrustRef AS [What is the reference of the Trust matter? ]
,YESNONANOEXPINS1.cdDesc AS [Are all expert’ fees (in respect of the inquest only – not claim) shown above?]
,CASE WHEN CAST(cboMedicRecs AS INT)>10 THEN '10+' ELSE CAST(CAST(cboMedicRecs AS INT) AS NVARCHAR(10)) END  AS [How many sets of medical records have we obtained? ]
,CASE WHEN cboCounselInst='Y' THEN 'Yes' WHEN cboCounselInst='N' THEN 'No' END  AS [Was counsel instructed? ]
,CASE WHEN cboAllInvCouns='Y' THEN 'Yes' WHEN cboAllInvCouns='N' THEN 'No' END  AS [Are all the invoices relating to Counsel fees detailed in the disbursement list above?]
,CASE WHEN cboPermBillCoun='Y' THEN 'Yes' WHEN cboPermBillCoun='N' THEN 'No' END   AS [Have we had permission to bill counsel fees in addition to the fixed fee? (see protocol)]
,CostBillType.cdDesc AS [Type of bill?]
,YESNONANOEXPINS2.cdDesc AS [Are all experts’ fees (in respect of the claim only – not inquest) shown above? ]
,YESNONADISB.cdDesc AS [Are all the invoices detailed in the disbursement list above?]
,CASE WHEN cboFeeAuth='Y' THEN 'Yes' WHEN cboFeeAuth='N' THEN 'No' END  AS [Has any extra work and fee been authorised?  ]
,NHSRDAMBAND.cdDesc AS [Damages banding?]
,CAST([red_dw].[dbo].[datetimelocal](dteDQFiled) AS DATE)  AS [Date DQ was filed ]
,CASE WHEN cboMediationAt='Y' THEN 'Yes' WHEN cboMediationAt='N' THEN 'No' END  AS [Did we attend mediation?]
,curExtraMedia AS [What extra can be billed (max 8 hours) Mediation]
,curExtraPrep AS [What extra can be billed (max 8 hours) Preparation: ]
,CASE WHEN CAST(cboMedExpInst AS INT)>10 THEN '10+' ELSE CAST(CAST(cboMedExpInst AS INT) AS NVARCHAR(10)) END AS [How many medical experts were instructed?]
,CASE WHEN cboAllMedExpFee='Y' THEN 'Yes' WHEN cboAllMedExpFee='N' THEN 'No' END  AS [Are all medical experts fees shown above? ]
,CASE WHEN cboAllCounseFee='Y' THEN 'Yes' WHEN cboAllCounseFee='N' THEN 'No' END  AS [Are all counsel fees shown above? (to be included within capped fee)]
,CASE WHEN cboAllMedRecFee='Y' THEN 'Yes' WHEN cboAllMedRecFee='N' THEN 'No' END  AS [Are all fees for medical records shown above?]
,CASE WHEN cboCourtFeeInc='Y' THEN 'Yes' WHEN cboCourtFeeInc='N' THEN 'No' END  AS [Were court fees incurred?]
,CASE WHEN cboAllCourtFee='Y' THEN 'Yes' WHEN cboAllCourtFee='N' THEN 'No' END  AS [Are all court fees shown above?]
,YESNONAODISB.cdDesc AS [If there are any other disbursements, are they shown above?]
,CASE WHEN cboIncAnyDibs='Y' THEN 'Yes' WHEN cboIncAnyDibs='N' THEN 'No' END  AS [Have we incurred any disbs? ]
,CASE WHEN cboAllDibsShown='Y' THEN 'Yes' WHEN cboAllDibsShown='N' THEN 'No' END  AS [Are all disbs shown above?]
FROM MS_Prod.dbo.udNHSRBillProcessSL AS a WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=a.fileid
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN ms_prod.dbo.dbUser WITH(NOLOCK)
 ON usrID=usrIDInserted
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS CostBillType WITH(NOLOCK)
 ON a.cboBillType=CostBillType.cdCode AND CostBillType.cdType='NHSRBILLTYPE'
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number

LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS NHSRDAMBAND WITH(NOLOCK)
 ON cboDamBand=NHSRDAMBAND.cdCode AND NHSRDAMBAND.cdType='NHSRDAMBAND'

LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS NHSRINSTTYPE WITH(NOLOCK)
 ON cboFeeType=NHSRINSTTYPE.cdCode AND NHSRINSTTYPE.cdType='NHSRINSTTYPE'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS TO10PLUS WITH(NOLOCK)
 ON cboExpertNum=TO10PLUS.cdCode AND TO10PLUS.cdType='0TO10PLUS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS YESNONA1200 WITH(NOLOCK)
 ON cbo1200PlusPerm=YESNONA1200.cdCode AND YESNONA1200.cdType='YESNONA1200'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS YESNONANOEXPINS WITH(NOLOCK)
 ON a.cboNoSummitFee=YESNONANOEXPINS.cdCode AND YESNONANOEXPINS.cdType='YESNONANOEXPINS'
 LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS YESNONA1250 WITH(NOLOCK)
 ON a.cboNHSRAgreed=YESNONA1250.cdCode AND YESNONA1250.cdType='YESNONA1250'
  LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS INQDAYS WITH(NOLOCK)
 ON a.cboInqDays=INQDAYS.cdCode AND INQDAYS.cdType='INQDAYS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS YESNONANOEXPINS1 WITH(NOLOCK)
 ON a.cboMissExpFee=YESNONANOEXPINS1.cdCode AND YESNONANOEXPINS1.cdType='YESNONANOEXPINS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS YESNONANOEXPINS2 WITH(NOLOCK)
 ON a.cboAllExpShown=YESNONANOEXPINS2.cdCode AND YESNONANOEXPINS2.cdType='YESNONANOEXPINS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS YESNONAODISB WITH(NOLOCK)
 ON a.cboAnyOtherDisb=YESNONAODISB.cdCode AND YESNONAODISB.cdType='YESNONAODISB'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS YESNONADISB WITH(NOLOCK)
 ON a.cboAnyOtherDisb=YESNONADISB.cdCode AND YESNONADISB.cdType='YESNONADISB' 
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup  AS NHSRTYPEBILL WITH(NOLOCK)
 ON a.cboTypeOfBill=NHSRTYPEBILL.cdCode AND NHSRTYPEBILL.cdType='NHSRTYPEBILL' 

 
 
 
-- WHERE master_client_code='N1001'
END

 

 


GO
