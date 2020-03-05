SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [VisualFiles].[HFCThirdPartyNew]-- EXEC [VisualFiles].[HFCThirdPartyNew] '2013-01-01','2013-10-10','HFC'
    @StartDate	DATE
,   @EndDate	DATE
,   @ClientName	VARCHAR(50)
AS 
    set nocount on
    set transaction isolation level read uncommitted

select	
'WEIGHTMA' as thirdpartyidentifier
, HIM_AccountNumber as accountno
,'FEE PAYMENT' as transactiondescription
,PYR_PaymentAmount as amount
,PYR_AmountDisbursementPaid + PYR_AmountRecoverableCostsPaid as othercosts
,PYR_PaymentDate  as posteddate
,right(level_fee_earner,3) + ' / ' + CAST(AccountInformation.MatterCode AS VARCHAR(10)) as ourref
,AccountInformation.mt_int_code as mt_int_code
,row_number() over (partition by AccountInformation.mt_int_code order by AccountInformation.mt_int_code desc) as ranking
,DateOpened AS DateOpened
,CASE WHEN ClientName='HFC' AND (CAS_BatchNumber<>'Yes' OR CAS_BatchNumber IS NULL) THEN '0.1408934'
WHEN ClientName='HFC' AND (CAS_BatchNumber='Yes' OR CAS_BatchNumber IS NULL) THEN '0.10'
WHEN ClientName='HFC New Contract' AND (CAS_BatchNumber='Yes' OR CAS_BatchNumber IS NULL) THEN '0.10'
WHEN ClientName='HFC New Contract' AND (CAS_BatchNumber<>'Yes' OR CAS_BatchNumber IS NULL) THEN '0.10'
WHEN ClientName='HFC New Contract' AND (CAS_BatchNumber<>'Yes' OR CAS_BatchNumber IS NULL) AND MilestoneCode <> 'INST' THEN '0.075'

END AS Commission


into #payments
from	VFile_Streamlined.dbo.AccountInformation AS AccountInformation
INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clientscreen
 ON AccountInformation.mt_int_code = Clientscreen.mt_int_code
INNER JOIN VFile_Streamlined.dbo.Payments AS Payments WITH (NOLOCK)  
 ON AccountInformation.mt_int_code = Payments.mt_int_code
where PYR_PaymentDate BETWEEN @StartDate AND @EndDate
AND PDE_MilestonePaymentReceviedIn <> 'COMP'
AND PYR_PaymentType NOT IN ('Historical Payment','CCA Request','SAR')
and (PYR_PaymentTakenByClient = 'No' 
OR PYR_PaymentTakenByClient = '')
AND PYR_PaymentDeletedSameDay <> 'Yes'  --exclude payments deleted on same day
AND ClientName=@ClientName


select [#payments].[thirdpartyidentifier],
	   [#payments].[accountno],
	   'PAYPRI' as transcationcode,
	   'PRINCIPAL PAYMENT' as transactiondescription,
        row_number() over (partition by [#payments].[mt_int_code] order by [#payments].[mt_int_code] desc) as ranking,
	   [#payments].[amount]as amount,
	   [#payments].[posteddate],
	   [#payments].[ourref]
into #paypri
from [#payments]



select 
'WEIGHTMA' as thirdpartyidentifier
,HIM_AccountNumber as accountnumber


,case when DebtLedger.ItemCode='aeof'  then 
           'ATTACHMENT EARNINGS FEE' 
            
      when DebtLedger.ItemCode='corc' then 
           'CHARGING ORDER COSTS'
           
      when DebtLedger.ItemCode in ('csf1','lpc1','lpcl','NCI1')then 
           'COURT ATTENDANCE FEE'
           
      when DebtLedger.ItemCode in ('ccif','choc','coaf','conm','nrca','sc10','sc50','sc70','sc80','warc','wcif') then
		   'GENERAL COURT COST'
		   
      when DebtLedger.ItemCode in ('ccbi','ci10','ci11','ci20','ci23','ci24','ci31','ci43','ci50','ci73','hcif','rcif','rhif') then
		   'ISSUE FEE COURT CLAIM'
		   
	  when DebtLedger.ItemCode in ('cjca','cjcd','cjcr','cjmc','jc22','jc25','jc30','jc40','jc55','jc70','rjca','rjcd','rjcr','rjmc') then
	       'JUDGEMENT COSTS'
	  
	  when DebtLedger.ItemCode in ('cauf','leos','lrbi','lrch','lroc','lrtr','ofcf','roic','rorf') then 
	       'LAND REGISTRY'
	  when DebtLedger.ItemCode ='oeif' then
	       'ORAL EXAMINATION FEE'
	       
	  when DebtLedger.ItemCode ='ccbw' then
	       'WARRENT OF EXECUTION FEE'
	       
	  when DebtLedger.ItemCode ='circ' then
	       'COSTS COURT CLAIM'
	  WHEN DebtLedger.ItemCode ='allo'
	  THEN 'ALLOCATION QUESTIONAIRE FEES'
	  
           
      else DebtLedger.ItemCode end as transactiondescription
,'' as ref
,DebtLedger.Amount as amount                
,PostedDate as posteddate
,right(level_fee_earner,3) + ' / ' + CAST(MatterCode AS VARCHAR(10))as ourref
into #transactions
from VFile_Streamlined.dbo.DebtLedger AS DebtLedger
INNER JOIN VFile_Streamlined.dbo.ClientScreens AS ClientsScreen
 ON DebtLedger.mt_int_code = ClientsScreen.mt_int_code
INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON DebtLedger.mt_int_code = AccountInfo.mt_int_code
 
where PostedDate BETWEEN @StartDate AND @EndDate  and DebtLedger.ItemCode is not null
AND DebtOrLedger='Debt' AND ClientName=@ClientName 
 --group by HIM_AccountNumber,ItemCode,Amount,PostedDate,level_fee_earner,MatterCode
 
 
 

SELECT * FROM #paypri
UNION


SELECT [#transactions].thirdpartyidentifier
	   ,[#transactions].[accountnumber]
	   ,CASE WHEN [#transactions].[transactiondescription] 
	   IN ('ATTACHMENT EARNINGS FEE'
,'CHARGING ORDER COSTS'
,'COURT ATTENDANCE FEE'
,'GENERAL COURT COST'
,'ISSUE FEE COURT CLAIM'
,'JUDGEMENT COSTS'
,'LAND REGISTRY'
,'ORAL EXAMINATION FEE'
,'WARRENT OF EXECUTION FEE'
,'COSTS COURT CLAIM'
,'ALLOCATION QUESTIONAIRE FEES') THEN 'FEEGEN'
	   WHEN [#transactions].[transactiondescription] ='PAYMENT' THEN 'PAYPRI' 
	   
	   END AS transactioncode
	   ,[#transactions].[transactiondescription]
       ,'' AS ranking
	   ,[#transactions].[amount]
	   ,[#transactions].[posteddate]
	   ,[#transactions].[ourref]
FROM [#transactions]
WHERE  [#transactions].[transactiondescription] <> ''

UNION

SELECT 
'WEIGHTMA' AS thirdpartyidentifier
,HIM_AccountNumber AS accountnumber
,'JUDGEM' AS transactioncode
,'COURT JUDGEMENT'  AS transactiondescription
,'' AS ranking
,CCJ_JudgmentTotalAmountPayableByDefendant AS amount  
,CCJ_JudgmentInfullBy AS posteddate
,RIGHT(level_fee_earner,3) + ' / ' + CAST(MatterCode AS VARCHAR(10)) AS ourref
FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
INNER JOIN VFile_Streamlined.dbo.Judgment AS Judgment
 ON AccountInfo.mt_int_code = Judgment.mt_int_code
INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
 ON AccountInfo.mt_int_code = Clients.mt_int_code
 
WHERE CCJ_JudgmentInfullBy BETWEEN @StartDate AND @EndDate

--group by HIM_AccountNumber,CCJ_JudgmentTotalAmountPayableByDefendant,CCJ_JudgmentInfullBy,level_fee_earner,MatterCode



DROP TABLE #payments
DROP TABLE #paypri
DROP TABLE #transactions
GO
