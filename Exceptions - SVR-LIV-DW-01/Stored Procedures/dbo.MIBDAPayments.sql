SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MIBDAPayments] --EXEC [dbo].[MIBDAPayments] '2019-02-11','2019-02-11'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT 
Client collate database_default AS Client
,Matter collate database_default AS Matter
,[MS Client] collate database_default AS [MS Client]
,[MS Matter] collate database_default AS [MS Matter]
,mg_feearn collate database_default AS mg_feearn
,[name] AS [FeeEarnerName]
,[Payment Date]
,[Claim Number] collate database_default AS [Claim Number]
,[Claimant Sequence Number] collate database_default AS [Claimant Sequence Number]
,[Claimant Initials]  collate database_default AS [Claimant Initials]
,[Claimant Surname] collate database_default AS [Claimant Surname]
,[Payee Name] collate database_default AS [Payee Name]
,[Payment Descripiton] collate database_default AS [Payment Descripiton]
,[Payment Code] collate database_default AS [Payment Code]
,ISNULL([Personal Injury],0) AS [Personal Injury]
,ISNULL([Property Damage],0) AS [Property Damage]
,[Total]
,[Adjustment Y/N]
,[Original Payment Date]
,[Approved] collate database_default AS [Approved]
,[Date Approved]
,CASE WHEN [Payment Date] IS NULL OR 
[Claim Number] IS NULL OR
[Claimant Sequence Number] IS NULL OR
[Claimant Initials] IS NULL OR  
[Claimant Surname] IS NULL OR
[Payee Name] IS NULL OR 
[Payment Descripiton] IS NULL OR
(ISNULL([Personal Injury],0)+ ISNULL([Property Damage],0) <>[Total]) OR 
[Date Approved] <>  [Payment Date] 
 THEN 'Exception' 
WHEN [Adjustment Y/N]='Y' AND [Original Payment Date] IS NULL THEN 'Exception' 
ELSE 'Report' END AS Exception 
,ISNULL(CASE WHEN ([Payment Date] IS NULL) THEN 'No Payment Date Added'+ '.'END, '') + ','
+ISNULL(CASE WHEN ([Claim Number] IS NULL) THEN 'Missing Claim Number'+ '.'END, '') + ','
+ISNULL(CASE WHEN ([Claimant Sequence Number] IS NULL) THEN 'Missing Sequence Number'+ '.'END, '') + ','
+ISNULL(CASE WHEN ([Claimant Initials] IS NULL) THEN 'Missing Initials'+ '.'END, '') + ','
+ISNULL(CASE WHEN ([Claimant Surname] IS NULL) THEN 'Missing Surname'+ '.'END, '') + ','
+ISNULL(CASE WHEN ([Payee Name] IS NULL) THEN 'Missing Payee'+ '.'END, '') + ','
+ISNULL(CASE WHEN ([Payment Descripiton] IS NULL) THEN 'Missing Payment description'+ '.'END, '') + ','
+ISNULL(CASE WHEN ((ISNULL([Personal Injury],0)+ ISNULL([Property Damage],0) <>[Total])) THEN 'Total Does not match'+ '.'END, '')
+ISNULL(CASE WHEN [Date Approved] <>  [Payment Date]  THEN 'Date Approved and Payment Date do not match'+ '.'END, '')
AS ExceptionDescription 
FROM 
(
SELECT case_id,
Client,Matter
,[MS Client]
,[MS Matter]
,mg_feearn
,[name]
,PaymentDate AS [Payment Date]
,MIBREF AS [Claim Number]
,NMI706 AS [Claimant Sequence Number]
,MIB037 AS [Claimant Initials] 
,MIB036 AS [Claimant Surname]
,PayeeName AS [Payee Name]
,REPLACE(PaymentDescription,'(cancelled)','') AS [Payment Descripiton]
,CASE WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Adjuster fees' THEN 'PAJ'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Claimant legal fees' THEN 'PLG'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Court fees' THEN 'CCP'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Engineer fees' THEN 'PEG'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Enquiry fees' THEN  'PEN'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Medical expert' THEN 'PMO'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='MIB legal fees final' THEN 'PML'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='MIB legal fees interim' THEN 'PMI'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Non medical expert fees'	 THEN 'PXP'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Police fees'	THEN 'PFE'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Claimants payment'	THEN 'PCP'
	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='DWP Payment'	THEN 'PCU'
	                                                   
	  END [Payment Code]
,CASE WHEN PaymentDescription like '%(cancelled)%' THEN [Amount personal injury]*-1 ELSE [Amount personal injury] END  AS [Personal Injury]
,CASE WHEN PaymentDescription like '%(cancelled)%' THEN [Amount property damage]*-1 ELSE [Amount property damage] END AS [Property Damage]
,CASE WHEN PaymentDescription like '%(cancelled)%' THEN [Total amount]*-1 ELSE [Total amount] END  AS [Total]
,Adjustment AS [Adjustment Y/N]
,CASE WHEN Adjustment='Y' THEN OriginalPaymentDate  ELSE NULL END AS [Original Payment Date]
,[Approved]
,[Date Approved]

FROM 
(
SELECT 
dim_matter_header_current.client_code AS client
,dim_matter_header_current.matter_number AS matter
,clno AS [MS Client]
,fileno AS [MS Matter]
,name + ' (' + RTRIM(fed_code)  + ')' AS mg_feearn
,udDAPayment.fileID AS case_id
,(CASE WHEN udDAPayment.cboDAPayment='ADJFEES' THEN 'Adjuster fees'
WHEN udDAPayment.cboDAPayment='MEDICALEXPERT' THEN 'Medical expert'
WHEN udDAPayment.cboDAPayment='COURTFEES' THEN 'Court fees'
WHEN udDAPayment.cboDAPayment='NONMEDEXPFEE' THEN 'Non medical expert fees'
WHEN udDAPayment.cboDAPayment='CLALEGALFEECANX' THEN 'Claimant legal fees (cancelled)'
WHEN udDAPayment.cboDAPayment='CLAPAYMENTCANX' THEN 'Claimants payment (cancelled)'
WHEN udDAPayment.cboDAPayment='ENGRFEESCANX' THEN 'Engineer fees (cancelled)'
WHEN udDAPayment.cboDAPayment='ENQUIRYFEES' THEN 'Enquiry fees'
WHEN udDAPayment.cboDAPayment='ADJFEESCANX' THEN 'Adjuster fees (cancelled)'
WHEN udDAPayment.cboDAPayment='ENGRFEES' THEN 'Engineer fees'
WHEN udDAPayment.cboDAPayment='COURTFEESCANX' THEN 'Court fees (cancelled)'
WHEN udDAPayment.cboDAPayment='POLICEFEES' THEN 'Police fees'
WHEN udDAPayment.cboDAPayment='POLICEFEESCANX' THEN 'Police fees (cancelled)'
WHEN udDAPayment.cboDAPayment='MEDICALEXPCANX' THEN 'Medical expert (cancelled)'
WHEN udDAPayment.cboDAPayment='NONMEDEXPFCANX' THEN 'Non medical expert fees (cancelled)'
WHEN udDAPayment.cboDAPayment='DWPPAYMENTCANX' THEN 'DWP Payment (cancelled)'
WHEN udDAPayment.cboDAPayment='CLAPAYMENT' THEN 'Claimants payment'
WHEN udDAPayment.cboDAPayment='DWPPAYMENT' THEN 'DWP Payment'
WHEN udDAPayment.cboDAPayment='ENQUIRYFEESCANX' THEN 'Enquiry fees (cancelled)'
WHEN udDAPayment.cboDAPayment='CLALEGALFEES' THEN 'Claimant legal fees'
END) AS PaymentType 
,red_dw.[dbo].[datetimelocal](dteDAPayment) AS PaymentDate
,txtPayeeName AS PayeeName
,(CASE WHEN udDAPayment.cboDAPayment='ADJFEES' THEN 'Adjuster fees'
WHEN udDAPayment.cboDAPayment='MEDICALEXPERT' THEN 'Medical expert'
WHEN udDAPayment.cboDAPayment='COURTFEES' THEN 'Court fees'
WHEN udDAPayment.cboDAPayment='NONMEDEXPFEE' THEN 'Non medical expert fees'
WHEN udDAPayment.cboDAPayment='CLALEGALFEECANX' THEN 'Claimant legal fees (cancelled)'
WHEN udDAPayment.cboDAPayment='CLAPAYMENTCANX' THEN 'Claimants payment (cancelled)'
WHEN udDAPayment.cboDAPayment='ENGRFEESCANX' THEN 'Engineer fees (cancelled)'
WHEN udDAPayment.cboDAPayment='ENQUIRYFEES' THEN 'Enquiry fees'
WHEN udDAPayment.cboDAPayment='ADJFEESCANX' THEN 'Adjuster fees (cancelled)'
WHEN udDAPayment.cboDAPayment='ENGRFEES' THEN 'Engineer fees'
WHEN udDAPayment.cboDAPayment='COURTFEESCANX' THEN 'Court fees (cancelled)'
WHEN udDAPayment.cboDAPayment='POLICEFEES' THEN 'Police fees'
WHEN udDAPayment.cboDAPayment='POLICEFEESCANX' THEN 'Police fees (cancelled)'
WHEN udDAPayment.cboDAPayment='MEDICALEXPCANX' THEN 'Medical expert (cancelled)'
WHEN udDAPayment.cboDAPayment='NONMEDEXPFCANX' THEN 'Non medical expert fees (cancelled)'
WHEN udDAPayment.cboDAPayment='DWPPAYMENTCANX' THEN 'DWP Payment (cancelled)'
WHEN udDAPayment.cboDAPayment='CLAPAYMENT' THEN 'Claimants payment'
WHEN udDAPayment.cboDAPayment='DWPPAYMENT' THEN 'DWP Payment'
WHEN udDAPayment.cboDAPayment='ENQUIRYFEESCANX' THEN 'Enquiry fees (cancelled)'
WHEN udDAPayment.cboDAPayment='CLALEGALFEES' THEN 'Claimant legal fees'
END) AS PaymentDescription
,curAmtPI AS [Amount personal injury]
,curAmtPropDmg AS [Amount property damage]
,red_dw.[dbo].[datetimelocal] (dteOrigPayment) AS OriginalPaymentDate
,cboApproved AS [Approved]
,red_dw.[dbo].[datetimelocal] (dteApproved) AS [Date Approved]
,cboStatus AS [Status]
,txtClaimNoMIB AS MIBREF
,cboSeqNumber AS NMI706
,txtClaimSurname AS MIB036
,txtClaimInit AS MIB037
,curDAPayment AS [Total amount]
,CASE WHEN udDAPayment.cboDAPayment IN 
(
'CLALEGALFEECANX','CLAPAYMENTCANX','ENGRFEESCANX','ADJFEESCANX','COURTFEESCANX','POLICEFEESCANX'
,'MEDICALEXPCANX','NONMEDEXPFCANX','DWPPAYMENTCANX','ENQUIRYFEESCANX' 
)THEN 'Y' ELSE 'N' END AS Adjustment 
,[name]

FROM MS_Prod.dbo.udDAPayment AS udDAPayment WITH(NOLOCK)
INNER JOIN MS_Prod.config.dbFile ON udDAPayment.fileID=dbFile.fileID
INNER JOIN MS_Prod.config.dbClient ON dbFile.clID=dbClient.clID
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) 
 ON udDAPayment.fileID=dim_matter_header_current.ms_fileid
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code=fee_earner_code collate database_default
AND dss_current_flag='Y'
LEFT OUTER JOIN MS_Prod.dbo.udMIClientMIB ON ms_fileid=udMIClientMIB.fileID
WHERE cboApproved IN ('Yes','Y')
AND CONVERT(DATE,red_dw.[dbo].[datetimelocal] (dteApproved),103) BETWEEN @StartDate AND @EndDate

) AS AllData
) AllPayments 
WHERE [Adjustment Y/N]='N'

--UNION

--SELECT 
--Client collate database_default
--,Matter collate database_default
--,[MS Client]
--,[MS Matter]
--,mg_feearn
--,NULL AS [FeeEarnerName]
--,[Payment Date]
--,[Claim Number]
--,[Claimant Sequence Number]
--,[Claimant Initials] 
--,[Claimant Surname]
--,[Payee Name]
--,[Payment Descripiton]
--,[Payment Code]
--,ISNULL([Personal Injury],0) AS [Personal Injury]
--,ISNULL([Property Damage],0) AS [Property Damage]
--,[Total]
--,[Adjustment Y/N]
--,[Original Payment Date]
--,[Approved]
--,[Date Approved]
--,CASE WHEN [Payment Date] IS NULL OR 
--[Claim Number] IS NULL OR
--[Claimant Sequence Number] IS NULL OR
--[Claimant Initials] IS NULL OR  
--[Claimant Surname] IS NULL OR
--[Payee Name] IS NULL OR 
--[Payment Descripiton] IS NULL OR
--(ISNULL([Personal Injury],0)+ ISNULL([Property Damage],0) <>[Total]) OR 
--[Date Approved] <>  [Payment Date] 
-- THEN 'Exception' 
--WHEN [Adjustment Y/N]='Y' AND [Original Payment Date] IS NULL THEN 'Exception' 
--ELSE 'Report' END AS Exception 
--,ISNULL(CASE WHEN ([Payment Date] IS NULL) THEN 'No Payment Date Added'+ '.'END, '') + ','
--+ISNULL(CASE WHEN ([Claim Number] IS NULL) THEN 'Missing Claim Number'+ '.'END, '') + ','
--+ISNULL(CASE WHEN ([Claimant Sequence Number] IS NULL) THEN 'Missing Sequence Number'+ '.'END, '') + ','
--+ISNULL(CASE WHEN ([Claimant Initials] IS NULL) THEN 'Missing Initials'+ '.'END, '') + ','
--+ISNULL(CASE WHEN ([Claimant Surname] IS NULL) THEN 'Missing Surname'+ '.'END, '') + ','
--+ISNULL(CASE WHEN ([Payee Name] IS NULL) THEN 'Missing Payee'+ '.'END, '') + ','
--+ISNULL(CASE WHEN ([Payment Descripiton] IS NULL) THEN 'Missing Payment description'+ '.'END, '') + ','
--+ISNULL(CASE WHEN ((ISNULL([Personal Injury],0)+ ISNULL([Property Damage],0) <>[Total])) THEN 'Total Does not match'+ '.'END, '')
--+ISNULL(CASE WHEN [Date Approved] <>  [Payment Date]  THEN 'Date Approved and Payment Date do not match'+ '.'END, '')
--AS ExceptionDescription 
--FROM 
--(
--SELECT
--Client,Matter
--,[MS Client]
--,[MS Matter]
--,mg_feearn
--,PaymentDate AS [Payment Date]
--,MIBREF AS [Claim Number]
--,NMI706 AS [Claimant Sequence Number]
--,MIB037 AS [Claimant Initials] 
--,MIB036 AS [Claimant Surname]
--,PayeeName AS [Payee Name]
--,REPLACE(PaymentDescription,'(cancelled)','') AS [Payment Descripiton]
--,CASE WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Adjuster fees' THEN 'PAJ'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Claimant legal fees' THEN 'PLG'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Court fees' THEN 'CCP'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Engineer fees' THEN 'PEG'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Enquiry fees' THEN  'PEN'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Medical expert' THEN 'PMO'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='MIB legal fees final' THEN 'PML'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='MIB legal fees interim' THEN 'PMI'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Non medical expert fees'	 THEN 'PXP'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Police fees'	THEN 'PFE'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='Claimants payment'	THEN 'PCP'
--	  WHEN CAST(REPLACE(PaymentDescription,'(cancelled)','') AS VARCHAR(max))='DWP Payment'	THEN 'PCU'
	                                                   
--	  END [Payment Code]
--,CASE WHEN PaymentDescription like '%(cancelled)%' THEN [Amount personal injury]*-1 ELSE [Amount personal injury] END  AS [Personal Injury]
--,CASE WHEN PaymentDescription like '%(cancelled)%' THEN [Amount property damage]*-1 ELSE [Amount property damage] END AS [Property Damage]
--,CASE WHEN PaymentDescription like '%(cancelled)%' THEN [Total amount]*-1 ELSE [Total amount] END  AS [Total]
--,Adjustment AS [Adjustment Y/N]
--,CASE WHEN Adjustment='Y' THEN OriginalPaymentDate  ELSE NULL END AS [Original Payment Date]
--,[Approved]
--,[Date Approved]

--FROM 
--(

--SELECT 
--client
--,matter
--,[MS Client]
--,[MS Matter]
--,name + ' (' + RTRIM(mg_feearn)  + ')' AS mg_feearn
--,PaymentParent.case_id
--,PaymentType 
--,PaymentDate AS PaymentDate
--,MIB040 AS PayeeName
--,PaymentType AS PaymentDescription
--,MIB042 AS [Amount personal injury]
--,MIB043 AS [Amount property damage]
--,MIB046 AS OriginalPaymentDate
--,MIB045 AS [Approved]
--,DateApproved AS [Date Approved]
--,MIB047 AS [Status]
--,MIBREF
--,NMI706
--,MIB036
--,MIB037
--,[Total amount]
--,CASE WHEN PaymentType like '%(cancelled)%' THEN 'Y' ELSE 'N' END AS Adjustment
--FROM axxia01.dbo.cashdr as cashdr
--INNER JOIN axxia01.dbo.camatgrp as camatgrp
--ON client=mg_client AND matter=mg_matter
--INNER JOIN 
--(
--SELECT case_id,seq_no,case_date AS PaymentDate,case_text AS PaymentType,case_value AS [Total amount]
--FROM axxia01.dbo.casdet
--WHERE case_detail_code='MIB038' 
--) AS PaymentParent
--ON cashdr.case_id=PaymentParent.case_id
--LEFT OUTER JOIN (SELECT case_id,case_text AS MIBREF FROM axxia01.dbo.casdet WHERE case_detail_code='MIBREF') AS MIBREF
-- ON PaymentParent.case_id=MIBREF.case_id
--LEFT OUTER JOIN (SELECT case_id,case_text AS NMI706 FROM axxia01.dbo.casdet WHERE case_detail_code='NMI706') AS NMI706
-- ON PaymentParent.case_id=NMI706.case_id 
--LEFT OUTER JOIN (SELECT case_id,case_text AS MIB037 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB037') AS MIB037
-- ON PaymentParent.case_id=MIB037.case_id 
--LEFT OUTER JOIN (SELECT case_id,case_text AS MIB036 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB036') AS MIB036
-- ON PaymentParent.case_id=MIB036.case_id 
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_date AS MIB039 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB039') AS MIB039
--ON PaymentParent.case_id=MIB039.case_id AND PaymentParent.seq_no=MIB039.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_text AS MIB040 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB040') AS MIB040
--ON PaymentParent.case_id=MIB040.case_id AND PaymentParent.seq_no=MIB040.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_text AS MIB041 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB041') AS MIB041
--ON PaymentParent.case_id=MIB041.case_id AND PaymentParent.seq_no=MIB041.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_value AS MIB042 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB042') AS MIB042
--ON PaymentParent.case_id=MIB042.case_id AND PaymentParent.seq_no=MIB042.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_value AS MIB043 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB043') AS MIB043
--ON PaymentParent.case_id=MIB043.case_id AND PaymentParent.seq_no=MIB043.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_date AS MIB044 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB044') AS MIB044
--ON PaymentParent.case_id=MIB044.case_id AND PaymentParent.seq_no=MIB044.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_text AS MIB045,case_date AS DateApproved FROM axxia01.dbo.casdet WHERE case_detail_code='MIB045') AS MIB045
--ON PaymentParent.case_id=MIB045.case_id AND PaymentParent.seq_no=MIB045.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_date AS MIB046 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB046') AS MIB046
--ON PaymentParent.case_id=MIB046.case_id AND PaymentParent.seq_no=MIB046.cd_parent
--LEFT OUTER JOIN (SELECT case_id,cd_parent,case_text AS MIB047 FROM axxia01.dbo.casdet WHERE case_detail_code='MIB047') AS MIB047
--ON PaymentParent.case_id=MIB047.case_id AND PaymentParent.seq_no=MIB047.cd_parent--
--LEFT OUTER JOIN MS_Prod.dbo.MatterSpheretoFedNumbers AS MS WITH (NOLOCK)
-- ON cashdr.client=[Fed Client] collate database_default AND cashdr.matter=[Fed Matter] collate database_default
--LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON mg_feearn=fed_code collate database_default AND dss_current_flag='Y'

--WHERE MIB045='Yes'
--AND CONVERT(DATE,DateApproved,103) BETWEEN @StartDate AND @EndDate
--) AS AllData
--) AllPayments 
--WHERE [Adjustment Y/N]='N'
END
GO
