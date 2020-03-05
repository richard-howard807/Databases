SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--[VisualFiles].[HFCMatterStatus] 'HFC'

CREATE  PROCEDURE [VisualFiles].[HFCMatterStatus]
(
    @ClientName VARCHAR(50)
    )
   
AS 

DECLARE @VClientName AS VARCHAR(50)


SET @VClientName = @ClientName

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SELECT  HIM_AccountNumber AS AccountNo ,
            Short_name AS Debtor ,
            CurrentBalance AS Balance ,
            MilestoneCode AS Milestone ,
            OriginalBalance AS RefBalance ,
            CASE WHEN PaymentArrangementAmount <> 0
                      OR PaymentArrangementAmount <> '' THEN 'Yes'
                 ELSE 'No'
            END AS InstPlan ,
            PaymentArrangementAmount AS Payments ,
            PaymentsToDate.PaymentsMade AS PaymentsToDate ,
            CASE WHEN FileStatus = 'COMP' THEN 'Closed'
                 ELSE 'Open'
            END AS Status ,
            AccountInfo.mt_int_code ,
            DateOpened AS OpenDate ,
            ChargingOrderDetails.InterimDate ,
            ChargingOrderDetails.FinalhearingDate ,
            JudgmentDetails.JudgmentBalance ,
            JudgmentDetails.JudgmentDisb ,
            JudgmentDetails.JudgmentCosts ,
            JudgmentDetails.JudgmentTotal ,
            Warrants.DateOfWarrant ,
            AoE.AoEDate ,
            StatDemands.StatDemandDate ,
            DisbsIncurred.DisbsIncurred ,
            PaidDetails.DisbsPaid ,
            ISNULL(DisbsIncurred.DisbsIncurred,0) - ISNULL(PaidDetails.DisbsPaid,0) AS DisbsOutstanding ,
            CostsIncurred.CostsIncurred ,
            PaidDetails.CostsPaid ,
            ISNULL(CostsIncurred.CostsIncurred,0) - ISNULL(PaidDetails.CostsPaid,0) AS CostsOutstanding ,
            CASE WHEN ChargingOrderDetails.ChargePriority IS NULL
                 THEN 'Unknown'
                 ELSE ChargingOrderDetails.ChargePriority
            END AS ChargePriority ,
            CASE WHEN VoluntaryCharges.VolChargeDate IS NOT NULL THEN 'Yes'
                 ELSE 'No'
            END AS VoluntaryCharges,
            CASE WHEN HIM_AccountType = 'N' THEN 'Non Divisionalised' --added by PA on request 6025
                 WHEN HIM_AccountType = 'D' THEN 'Divisionalised'
                 WHEN HIM_AccountType = 'P' THEN 'Agency'
                 ELSE HIM_AccountType
                 END AS AccountType,
           HIM_AccountType AS [Account Type Abb],
           LastPayment.LastPaymentDate AS LastpaymentDate,
           LastPayment.Amount AS LastPaymentAmount,
           PaymentArrangementSetupDate,
           PaymentArrangementNextDate,
           PaymentArrangementAmount,
           CASE WHEN PaymentArrangementFrequency='m' THEN 'Monthly'
           WHEN PaymentArrangementFrequency='f' THEN 'Fortnightly'
           WHEN PaymentArrangementFrequency='w' THEN 'Weekly' 
           WHEN PaymentArrangementFrequency='y' THEN 'Yearly' END AS PaymentArrangementFrequency,
           CRD_DateClaimFormIssued AS DateClaimFormIssued,
           CCT_ClaimNumber9 AS ClaimNumber,
           CRD_DateJudgmentGranted AS DateJudgmentGranted,
           JudgmentCourt AS JudgmentCourt,
           VC_CourtName AS IssueCourt,
           CRD_DateClaimFormIssued,
           
           
           CASE WHEN CHOAddress IS NULL THEN VCOAddress ELSE CHOAddress END AS ChargeAddress,
           CASE WHEN CHOTitleNumber IS NULL THEN   VCO_PropertyTitleNumber ELSE CHOTitleNumber END AS TitleNumber
                
    FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
         LEFT OUTER JOIN VFile_Streamlined.dbo.IssueDetails AS IssueDetails
         ON AccountInfo.mt_int_code=IssueDetails.mt_int_code
         -- Charging Order Details
            LEFT OUTER JOIN ( SELECT    SOLCHO.mt_int_code ,
                                        SOLCHO.CHO_PriorityOfCharge AS ChargePriority ,
                                        SOLCHO.CHO_PropertyTitleNumber19 AS CHOTitleNumber,
                                        MAX(CHO_Interimdate) AS InterimDate ,
                                        MAX(CHO_Hearingdate) AS FinalHearingDate
                                        ,ISNULL(CHO_ApplicantsPropertyAddressLn1,'') + ' ' + 
										ISNULL(CHO_ApplicantsPropertyAddressLn2,'') + ' ' + 
										ISNULL(CHO_ApplicantsPropertyAddressLn3,'') + ' ' + 
										ISNULL(CHO_ApplicantsPropertyAddressLn4,'') + ' ' + 
										ISNULL(CHO_ApplicantsPropertyPostCode,'')  AS CHOAddress
                              FROM      VFile_Streamlined.dbo.Charges AS SOLCHO
                              GROUP BY  SOLCHO.mt_int_code ,
                                        SOLCHO.CHO_PriorityOfCharge,SOLCHO.CHO_PropertyTitleNumber19,
                                        CHO_ApplicantsPropertyAddressLn1,CHO_ApplicantsPropertyAddressLn2
                                        ,CHO_ApplicantsPropertyAddressLn3,CHO_ApplicantsPropertyAddressLn4
                                        ,CHO_ApplicantsPropertyPostCode
                              HAVING    ( (( MAX(CHO_Interimdate) ) <> '01/01/1900') )
                            ) AS ChargingOrderDetails ON AccountInfo.mt_int_code = ChargingOrderDetails.mt_int_code
         LEFT OUTER JOIN 
         (
         SELECT mt_int_code
,ISNULL(VCO_PropertyToBeChargedAddressLine1,'') + ' ' + 
ISNULL(VCO_PropertyToBeChargedAddressLine2,'') + ' ' + 
ISNULL(VCO_PropertyToBeChargedAddressLine3,'') + ' ' + 
ISNULL(VCO_PropertyToBeChargedAddressLine4,'') + ' ' + 
ISNULL(VCO_PropertyToBeChargedPostCode,'')  AS VCOAddress

,VCO_PropertyTitleNumber AS VCO_PropertyTitleNumber
FROM VFile_Streamlined.dbo.Charges AS SOLCHO
WHERE VCO_DateRestrictionRegistered IS NOT NULL
AND VCO_DateRestrictionRegistered <> '1900-01-01 00:00:00.000'
         ) AS VCODetails
          ON AccountInfo.mt_int_code=VCODetails.mt_int_code
         -- Judgment Details
            LEFT OUTER JOIN ( SELECT    SOLCCJ.mt_int_code ,
                                        CCJ_JudgmentTotalAmountPayableByDefendant
                                        - CCJ_SolicitorsCostsOnIssuingClaim
                                        + CCJ_SolicitorsCostsOnEnteringJudgment
                                        - CCJ_CourtFeesShownOnClaim AS JudgmentBalance ,
                                        CCJ_CourtFeesShownOnClaim AS JudgmentDisb ,
                                        CCJ_SolicitorsCostsOnIssuingClaim
                                        + CCJ_SolicitorsCostsOnEnteringJudgment AS JudgmentCosts ,
                                        CCJ_JudgmentTotalAmountPayableByDefendant AS JudgmentTotal,
                                        CCJ_JudgmentCourt AS JudgmentCourt
                                FROM      VFile_Streamlined.dbo.Judgment AS SOLCCJ
                            ) AS JudgmentDetails ON AccountInfo.mt_int_code = JudgmentDetails.mt_int_code
      -- Disbursements Paid and Costs Paid
            LEFT OUTER JOIN ( SELECT    SOLPYR.mt_int_code ,
                                        SUM(SOLPYR.PYR_AmountDisbursementPaid) AS DisbsPaid ,
                                        SUM(PYR_AmountRecoverableCostsPaid) AS CostsPaid
                              FROM      VFile_Streamlined.dbo.Payments AS SOLPYR
                              GROUP BY  SOLPYR.mt_int_code
                            ) AS PaidDetails ON AccountInfo.mt_int_code = PaidDetails.mt_int_code
 -- Disbursements Incurred
            LEFT OUTER JOIN ( SELECT    ledger.mt_int_code ,
                                        SUM(ledger.Amount) AS DisbsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
                              WHERE     ledger.TransactionType = 'OP'
                                        AND DebtOrLedger = 'Ledger'
                              GROUP BY  ledger.mt_int_code
                            ) AS DisbsIncurred ON AccountInfo.mt_int_code = DisbsIncurred.mt_int_code
-- Costs Incurred
            LEFT OUTER JOIN ( SELECT    debt.mt_int_code ,
                                        SUM(debt.amount) AS CostsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS Debt
                              WHERE     debt.TransactionType = 'COST'
                                        AND DebtOrLedger = 'Debt'
                              GROUP BY  debt.mt_int_code
                            ) AS CostsIncurred ON AccountInfo.mt_int_code = CostsIncurred.mt_int_code
-- Voluntary Charges
            LEFT OUTER JOIN ( SELECT    history.mt_int_code ,
                                        MAX(history.HTRY_DateInserted) AS VolChargeDate
                              FROM      VFile_Streamlined.dbo.History AS history
                              WHERE     history.HTRY_description IN (
                                        'AP1: Application to change the register',
                                        'AN1: Application to enter an agreed notice' )
                              GROUP BY  history.mt_int_code
                            ) AS VoluntaryCharges ON AccountInfo.mt_int_code = VoluntaryCharges.mt_int_code
-- Warrant of Executions
            LEFT OUTER JOIN ( SELECT    SOLCWA.mt_int_code ,
                                        SOLCWA.CWA_WarrantNumber ,
                                        MAX(SOLCWA.CWA_DatewarrantIssued) AS DateOfWarrant
                              FROM      VFile_Streamlined.dbo.Warrant AS SOLCWA
                              GROUP BY  SOLCWA.mt_int_code ,
                                        SOLCWA.CWA_WarrantNumber
                              HAVING    SOLCWA.CWA_WarrantNumber <> ''
                                        AND MAX(SOLCWA.CWA_DatewarrantIssued) > '01-Jan-2005'
                            ) AS Warrants ON AccountInfo.mt_int_code = Warrants.mt_int_code         
 -- AoE Dates
            LEFT OUTER JOIN ( SELECT    history.mt_int_code ,
                                        MAX(history.HTRY_description) AS AoEDate ,
                                        history.HTRY_description ,
                                        'Y' AS AE
                              FROM      VFile_Streamlined.dbo.History AS history
                              GROUP BY  History.mt_int_code ,
                                        History.HTRY_description
                              HAVING    History.HTRY_description LIKE 'AE request prepared%'
                            ) AS AoE ON AccountInfo.mt_int_code = AoE.mt_int_code        
-- Stat Demands
            LEFT OUTER JOIN ( SELECT    history.mt_int_code ,
                                        MAX(history.HTRY_DateInserted) AS StatDemandDate ,
                                        history.HTRY_description ,
                                        'Y' AS StatDemand
                              FROM      VFile_Streamlined.dbo.History AS history
                              GROUP BY  history.mt_int_code ,
                                        history.HTRY_description
                              HAVING    history.HTRY_description = 'Statutory Demand form'
                            ) AS StatDemands ON AccountInfo.mt_int_code = StatDemands.mt_int_code
            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                        SUM(PYR_PaymentAmount) AS PaymentsMade
                                        ,MAX(PYR_PaymentDate) AS PaymentDate -- added by pete
                              FROM      VFile_Streamlined.dbo.Payments AS Payments
                              GROUP BY  mt_int_code
                            ) AS PaymentsToDate ON AccountInfo.mt_int_code = PaymentsToDate.mt_int_code
   
LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        COUNT(mt_int_code) AS Number ,
                                                        SUM(SubTotal) AS Amount ,
                                                        [Payment Date12] AS LastPaymentDate
                                              FROM      ( SELECT
                                                              mt_int_code ,
                                                              SubTotal ,
                                                              [Payment Date12] ,
                                                              ROW_NUMBER() OVER ( PARTITION BY mt_int_code ORDER BY [Payment Date12] DESC ) AS OrderID
                                                          FROM
                                                              ( SELECT
                                                              SOLPYR.mt_int_code ,
                                                              SUM(PYR_PaymentAmount) AS SubTotal ,
                                                              PYR_PaymentDate AS [Payment Date12]
                                                              FROM
                                                              VFile_Streamlined.dbo.AccountInformation
                                                              AS AccountInfo
                                                              INNER JOIN VFile_Streamlined.dbo.Payments
                                                              AS SOLPYR ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
                                                              WHERE
                                                              PYR_PaymentType <> 'Historical Payment'
                                                              GROUP BY SOLPYR.mt_int_code ,
                                                              PYR_PaymentDate
                                                              ) subq1
                                                        ) subq2
                                              WHERE     OrderID = 1
                                              GROUP BY  [Payment Date12] ,
                                                        mt_int_code
                                            ) AS LastPayment ON   AccountInfo.mt_int_code= LastPayment.mt_int_code

    WHERE   ClientName = @VClientName
    
    OPTION  ( OPTIMIZE FOR UNKNOWN ) 


GO
