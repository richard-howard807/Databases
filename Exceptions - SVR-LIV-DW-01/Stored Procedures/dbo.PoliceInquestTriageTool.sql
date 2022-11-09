SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[PoliceInquestTriageTool]

AS 

BEGIN 

SELECT RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [Mattersphere Client/Matter Code]
,matter_description AS [Matter Description]
,red_dw.dbo.dim_matter_header_current.date_opened_case_management AS [Date Opened]
,matter_owner_full_name AS [Case Manager]
,work_type_name AS [Matter Type]
,client_name AS [Client Name]
,txtNamFamRep AS [Name of Family’s representative (Counsel/Firm)]
,txtLearnPo AS [Learning points]
,dteOfReview AS [Date of Review ]
,curYearPQE AS [Years call/PQE of own advocate]
,curNoOfWit AS [Number of own witnesses]
,curFamRepPay AS [Family’s representatives’ fees (inc. VAT) paid]
,curFamRepFee AS [Family’s representatives’ fees (inc. VAT) claimed]
,curFamRepDis AS [Family’s representatives’ disbursements (inc. VAT) claimed]
,curFamDisPay AS [Family’s representatives’ disbursements (inc. VAT) paid]
,CASE WHEN cboStaffRep='Y' THEN 'Yes' WHEN cboStaffRep='N' THEN 'No' WHEN cboStaffRep='DK' THEN 'Don''t know' ELSE cboStaffRep END AS [Has a member of staff specifically requested support or representation at the hearing?]
,CASE WHEN cboPSD='Y' THEN 'Yes' WHEN cboPSD='N' THEN 'No' WHEN cboPSD='DK' THEN 'Don''t know' ELSE cboPSD END  AS [Is the PSD report critical (or, if incomplete, expected to be critical) of any aspect of Police actions?]
,CASE WHEN cboPatholog='Y' THEN 'Yes' WHEN cboPatholog='N' THEN 'No' WHEN cboPatholog='DK' THEN 'Don''t know' ELSE cboPatholog END  AS [Do we accept the Pathologist’s cause of death?]
,CASE WHEN cboLenofInq='Y' THEN 'Yes' WHEN cboLenofInq='N' THEN 'No' ELSE cboLenofInq END  AS [Length of Inquest?]
,CASE WHEN cboIOPC='Y' THEN 'Yes' WHEN cboIOPC='N' THEN 'No' WHEN cboIOPC='DK' THEN 'Don''t know'  ELSE cboIOPC END  AS [Is there an ongoing IOPC investigation?]
,CASE WHEN cboFormCom='Y' THEN 'Yes' WHEN cboFormCom='N' THEN 'No' WHEN cboFormCom='DK' THEN 'Don''t know' ELSE cboFormCom END AS [Has there been a formal complaint made or an Incident reported in connection with the death?]
,CASE WHEN cboFam='Y' THEN 'Yes' WHEN cboFam='N' THEN 'No' WHEN cboFam='DK' THEN 'Don''t know' ELSE cboFam END  AS [Does the family (or any other IP) have legal representation?]
,CASE WHEN cboEvPot='Y' THEN 'Yes' WHEN cboEvPot='N' THEN 'No' WHEN cboEvPot='DK' THEN 'Don''t know' ELSE cboEvPot END  AS [Is there evidence of a potential failure to comply with a relevant Police Policy, Procedure or Guideline? ]
,CASE WHEN cboDeathVun='Y' THEN 'Yes' WHEN cboDeathVun='N' THEN 'No' WHEN cboDeathVun='DK' THEN 'Don''t know' ELSE cboDeathVun END  AS [Was this a death of a child or vulnerable adult?]
,CASE WHEN cboCoroner='Y' THEN 'Yes' WHEN cboCoroner='N' THEN 'No' WHEN cboCoroner='DK' THEN 'Don''t know' ELSE cboCoroner END  AS [Has the Coroner instructed an expert]
,CASE WHEN cboConPol='Y' THEN 'Yes' WHEN cboConPol='N' THEN 'No' WHEN cboConPol='DK' THEN 'Don''t know' ELSE cboConPol END  AS [Does the deceased have a vulnerable person profile or suicide prevention plan?]
,CASE WHEN cboConInt='Y' THEN 'Yes' WHEN cboConInt='N' THEN 'No' WHEN cboConInt='DK' THEN 'Don''t know' ELSE cboConInt END  AS [Is there any concern about conflicts of interest or any dispute between police staff? ]
,CASE WHEN cboCompl='Y' THEN 'Yes' WHEN cboCompl='N' THEN 'No' WHEN cboCompl='DK' THEN 'Don''t know' ELSE cboCompl END  AS [Was the deceased in contact with the police within 21 days prior to death?]
,CASE WHEN cboCaseStrik='Y' THEN 'Yes' WHEN cboCaseStrik='N' THEN 'No' WHEN cboCaseStrik='DK' THEN 'Don''t know' ELSE cboCaseStrik END  AS [Is this case inherently striking or unusual in any way?]
,CASE WHEN cboCaseRec='Y' THEN 'Yes' WHEN cboCaseRec='N' THEN 'No' WHEN cboCaseRec='DK' THEN 'Don''t know' ELSE cboCaseRec END  AS [Does this case involve recurrent issues or people of recurrent concern?]
,CASE WHEN cboCaseIn='Y' THEN 'Yes' WHEN cboCaseIn='N' THEN 'No' WHEN cboCaseIn='DK' THEN 'Don''t know' ELSE cboCaseIn END  AS [Does the case involve or is it connected to a celebrity or high profile individual/business?]
,CASE WHEN cboCaseAtt='Y' THEN 'Yes' WHEN cboCaseAtt='N' THEN 'No' WHEN cboCaseAtt='DK' THEN 'Don''t know' ELSE cboCaseAtt END  AS [Has this case attracted media attention already, or is extensive media coverage of the hearing expected?]
,CASE WHEN cboArticle2='Y' THEN 'Yes' WHEN cboArticle2='N' THEN 'No' WHEN cboArticle2='DK' THEN 'Don''t know' ELSE cboArticle2 END  AS [Is this potentially  an Article 2 case and/or likely to involve a jury?]
,CASE WHEN cboPotHigh='Y' THEN 'Yes' WHEN cboPotHigh='N' THEN 'No' WHEN cboPotHigh='DK' THEN 'Don''t know' ELSE cboPotHigh END  AS [Is there potential for high value civil claim (exposure over £100k including costs)?]
,CASE WHEN cboDoesCase='Y' THEN 'Yes' WHEN cboDoesCase='N' THEN 'No' WHEN cboDoesCase='DK' THEN 'Don''t know' ELSE cboDoesCase END  AS [Does the case involve issues about communications with other agencies or organisations?]
,CASE WHEN cboDeadImp='Y' THEN 'Yes' WHEN cboDeadImp='N' THEN 'No' WHEN cboDeadImp='DK' THEN 'Don''t know' ELSE cboDeadImp END  AS [Have all deadlines imposed by the Court been met?]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements]
,vat_billed AS [VAT]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled disbursements]
,last_bill_date AS [Date of last bill]
,last_time_transaction_date AS [Date of last time posting]
 FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN MS_Prod.dbo.udMIInquests
 ON ms_fileid=udMIInquests.fileID
LEFT OUTER JOIN MS_Prod.dbo.udMICoreNHS
 ON ms_fileid=udMICoreNHS.fileID
 
WHERE work_type_name='PL - Pol - Inquests'
AND dim_matter_header_current.date_closed_case_management IS NULL
AND reporting_exclusions=0

END 
GO
