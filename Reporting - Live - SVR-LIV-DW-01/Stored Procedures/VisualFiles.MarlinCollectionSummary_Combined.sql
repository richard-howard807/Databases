SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MarlinCollectionSummary_Combined]
    @StartDate DATE
  , @EndDate DATE
  , @ExecType TINYINT
  , @ClientName VARCHAR(100)
AS 
    set nocount on
    set transaction isolation level read uncommitted

    IF @ExecType < 4 
        begin

            Select  pd.[date] as [Date]
                  , IsNull(NewInstruction.NumberAccounts, 0) AS NumberofAccounts
                  , IsNull(NewInstruction.ValueOfAccounts, 0) AS ValueofAccounts
                  , IsNull(potentialsettlement.NumberAccounts, 0) AS Numberpotentialsettlement
                  , IsNull(potentialsettlement.ValueOfAccounts, 0) AS Valuepotentialsettlement
                  , IsNull(TelOutContact, 0) as TelOutContact
                  , IsNull(OutgoingAttempts, 0) as Attempts
                  , IsNull(TelOutNoContact, 0) as TelOutNoContact
                  , IsNull(IncomingCall, 0) as TelIN
                  , IsNull(AllOutgoingLetters.OutgoingLetters, 0) as LetterOUT
                  , IsNull(AllIncomingLetters.IncomingLetters, 0) as LetterIN
                  , IsNull(ArrangementNo, 0) as ArrangementNo
                  , IsNull(ArrangementValue, 0) as ArrangementValue
	-- No data for settlements count or total value:
	--,   ''							as SettlementNo
	--,   ''							as SettlementValue
                  , IsNull(TotalCollections, 0) as AllCollections
                  , IsNull(ClientPayments, 0) as ClientPayments
                  , IsNull(SettlementInstall, 0) as SettlementInstalments
                  , IsNull(SettlementLumpSum, 0) as SettlementLumpSum
            from    dbo.PeriodDates pd with ( nolock )
            LEFT OUTER JOIN (
                              SELECT    COUNT(MatterCode) AS NumberAccounts
                                      , SUM(OriginalBalance) AS ValueOfAccounts
                                      , DateOpened AS date_
                              FROM      VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo
                              WHERE     ClientName = @ClientName
                                        AND ISNULL(CAS_BatchName,'') <> 'GPB'
                                        AND DateOpened BETWEEN @StartDate AND @EndDate
                                        AND case when @ExecType = 1 THEN 1
                                                 when @ExecType = 2
                                                      AND [OriginalBalance] < 750
                                                 THEN 1
                                                 when @ExecType = 3
                                                      AND [OriginalBalance] >= 750
                                                 THEN 1
                                            END = 1
                              GROUP BY  DateOpened,ClientName
                            ) AS NewInstruction
                    ON pd.Date = NewInstruction.date_
            LEFT OUTER JOIN (
                              SELECT    COUNT(MatterCode) AS NumberAccounts
                                      , SUM(Convert(Decimal(11, 2), VFile_Streamlined.dbo.VarcharToDecimal(PYR2424))) AS ValueOfAccounts
                                      , Convert(datetime, VFile_Streamlined.dbo.VarcharToDate(PYR2323), 103) AS date_
                              FROM      VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo
                              INNER JOIN VFile_Streamlined.dbo.SOLPYS AS SOLPYR
                                        ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
                              WHERE     ClientName = @ClientName
                                        AND ISNULL(CAS_BatchName,'') <> 'GPB'
                                        AND Convert(datetime, VFile_Streamlined.dbo.VarcharToDate(PYR2323), 103) BETWEEN @StartDate
                                                                                                               AND     @EndDate
                                        AND case when @ExecType = 1 THEN 1
                                                 when @ExecType = 2
                                                      AND OriginalBalance < 750
                                                 THEN 1
                                                 when @ExecType = 3
                                                      AND OriginalBalance >= 750
                                                 THEN 1
                                            END = 1
                              GROUP BY  Convert(datetime, VFile_Streamlined.dbo.VarcharToDate(PYR2323), 103)
                            ) AS potentialsettlement
                    ON pd.Date = potentialsettlement.date_
            left outer join (
                              Select    date_inserted as [date]
                                      , sum(TelOutContact) as TelOutContact
                                      , sum(OutgoingAttempts) as OutgoingAttempts
                                      , sum(NoContact) as TelOutNoContact
                                      , sum(IncomingCall) as IncomingCall
                                      --, sum(OutgoingLetters) as OutgoingLetters
                                      --, sum(IncomingLetters) as IncomingLetters
                              From      (
                                          SELECT    HTRY_DateInserted AS date_inserted
                                                  , case when H.HTRY_description IN ( 'Outgoing call - contact with authorised', 'Outgoing call - contact with debtor' )
                                                         then 1
                                                    end as TelOutContact
                                                  , case when H.HTRY_description IN ( 'Outgoing call - contact with employer', 'Outgoing call - contact with other', 'Outgoing call - contact with court', 'Outgoing call - contact with unauthorised' )
                                                         then 1
                                                    end as OutgoingAttempts
                                                  , case when H.HTRY_description LIKE 'Outgoing Call - No Contact%'
                                                         then 1
                                                    end as NoContact
                                                  , case when H.HTRY_description LIKE 'Incoming Call - %'
                                                         then 1
                                                    end as IncomingCall
                                                  --, case when H.HTRY_description LIKE 'Letter to%'
                                                  --       then 1
                                                  --       when H.HTRY_description IN ( 'Home Owner Second Letter', 'Neg LR Second Letter' )
                                                  --       then 1
                                                  --  end as OutgoingLetters
                                                  --, case when H.HTRY_description LIKE 'Letter from%'
                                                  --       then 1
                                                  --  end as IncomingLetters
                                          FROM      VFile_Streamlined.dbo.History
                                                    AS H
                                          INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                                    AS AccountInfo
                                                    ON H.mt_int_code = AccountInfo.mt_int_code
                                          WHERE     H.HTRY_DateInserted BETWEEN @StartDate
                                                                        AND     @EndDate
                                                    AND ClientName = @ClientName
                                                    AND ISNULL(CAS_BatchName,'') != 'GPB'
                                                    AND (
                                                          H.HTRY_description LIKE 'Outgoing Call%'
                                                          OR H.HTRY_description LIKE 'Incoming Call%'
                                                         ---- OR H.HTRY_description LIKE 'Letter%'
                                                         --- OR H.HTRY_description LIKE '%Letter'
                                                        )
				-- filter by the £750 magic number, distinguished high value & low value cases:
                                                    AND case when @ExecType = 1
                                                             THEN 1
                                                             when @ExecType = 2
                                                                  AND [OriginalBalance] < 750
                                                             THEN 1
                                                             when @ExecType = 3
                                                                  AND [OriginalBalance] >= 750
                                                             THEN 1
                                                        END = 1
                                        ) as All_Contacts
                              GROUP BY  All_Contacts.date_inserted
                            ) contacts
                    ON pd.[date] = contacts.[date]
                   LEFT  OUTER  JOIN 
 (SELECT HTRY_DateInserted AS [date],SUM(IncomingLetters.IncomingLetters) AS IncomingLetters FROM
 (
 SELECT HTRY_DateInserted ,
        1 AS IncomingLetters
 FROM   VFile_Streamlined.dbo.History AS h
        INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo ON h.mt_int_code = AccountInfo.mt_int_code
 WHERE  (
 (HTRY_DocumentType = 'U'  AND NOT HTRY_description LIKE '%LRS%') OR (HTRY_description LIKE '%Letter in%' OR  HTRY_description LIKE 'Letter FROM'))
        
        AND HTRY_DateInserted BETWEEN @StartDate AND @EndDate
        AND ClientName = @ClientName
      
        AND ISNULL(CAS_BatchName, '') != 'GPB'
        AND CASE WHEN @ExecType = 1 THEN 1
                 WHEN @ExecType = 2
                      AND [OriginalBalance] < 750 THEN 1
                 WHEN @ExecType = 3
                      AND [OriginalBalance] >= 750 THEN 1
            END = 1
            ) AS IncomingLetters
            GROUP BY IncomingLetters.HTRY_DateInserted
            ) AllIncomingLetters
              ON pd.[date] = AllIncomingLetters.[date]
              LEFT  OUTER  JOIN 
 (SELECT HTRY_DateInserted AS [date],SUM(OutgoingLetters.OutgoingLetters) AS OutgoingLetters FROM
 (
 SELECT HTRY_DateInserted ,
        CASE WHEN HTRY_DocumentType = 'D' THEN 1
             ELSE 0
        END AS OutgoingLetters
 FROM   VFile_Streamlined.dbo.History AS h
        INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo ON h.mt_int_code = AccountInfo.mt_int_code
 WHERE  HTRY_DocumentType = 'D'
        AND NOT HTRY_description LIKE '%Certificate%'
        AND HTRY_DateInserted BETWEEN @StartDate AND @EndDate
        AND ClientName = @ClientName
        AND ISNULL(CAS_BatchName, '') != 'GPB'
        AND CASE WHEN @ExecType = 1 THEN 1
                 WHEN @ExecType = 2
                      AND [OriginalBalance] < 750 THEN 1
                 WHEN @ExecType = 3
                      AND [OriginalBalance] >= 750 THEN 1
            END = 1
            ) AS OutGoingLetters
            GROUP BY OutGoingLetters.HTRY_DateInserted
            ) AllOutgoingLetters
              ON pd.[date] = AllOutgoingLetters.[date]   
            left outer join (
                              Select    date_paid as [date]
                                      , sum(ClientPayments) as ClientPayments
                                      , sum(TotalCollections) as TotalCollections
                                      , sum(SettlementInstall) as SettlementInstall
                                      , sum(SettlementLumpSum) as SettlementLumpSum
                              from      (
                                          SELECT    PYR_PaymentDate as date_paid
                                                  , CASE WHEN PYR_PaymentArrangementType IN ( 'Payment Arrangement', 'Other', '' )
                                                              AND PYR_PaymentTakenByClient = 'Yes'
                                                         THEN PYR_PaymentAmount
                                                    END AS ClientPayments
                                                  , CASE WHEN PYR_PaymentArrangementType IN ( 'Payment Arrangement', 'Other', '' )
                                                         THEN PYR_PaymentAmount
                                                    END AS TotalCollections
                                                  , CASE WHEN PYR_PaymentArrangementType IN ( 'Settlement - Instalments' )
                                                         THEN PYR_PaymentAmount
                                                    END AS SettlementInstall
                                                  , CASE WHEN PYR_PaymentArrangementType IN ( 'Settlement - Lump Sum' )
                                                         THEN PYR_PaymentAmount
                                                    END AS SettlementLumpSum
                                          FROM      VFile_Streamlined.dbo.Payments
                                                    AS SOLPYR
                                          INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                                    AS AccountInfo
                                                    ON SOLPYR.mt_int_code = AccountInfo.mt_int_code
                                          WHERE     ClientName = @ClientName
                                                    AND PYR_PaymentArrangementType IN (
                                                    'Payment Arrangement',
                                                    'Other', '',
                                                    'Settlement - Instalments',
                                                    'Settlement - Lump Sum' )
                                                    AND PYR_PaymentType NOT IN (
                                                    'Historical Payment',
                                                    'CCA Request', 'SAR' )
                                                    AND ISNULL(CAS_BatchName,'') != 'GPB'
                                                    AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
				-- filter by the £750 magic number, distinguished high value & low value cases:
                                                    AND case when @ExecType = 1
                                                             THEN 1
                                                             when @ExecType = 2
                                                                  AND [OriginalBalance] < 750
                                                             THEN 1
                                                             when @ExecType = 3
                                                                  AND [OriginalBalance] >= 750
                                                             THEN 1
                                                        END = 1
                                        ) as All_Collections
                              GROUP BY  date_paid
                            ) as payments
                    ON pd.[date] = payments.[date]
            left outer join (
                              Select    date_arranged as [date]
                                      , COUNT(1) as ArrangementNo
                                      , sum(pay_arr_amount) as ArrangementValue
                              from      (
                                          SELECT    SOLMGS.MGS20 AS date_arranged
                                                  , PaymentArrangementAmount AS pay_arr_amount
                                          FROM      (
                                                      SELECT    mt_int_code AS mt_int_code
                                                              , CONVERT(datetime, VFile_Streamlined.dbo.VarcharToDate(ud_field##20), 103) AS MGS20
                                                      FROM      VFile_Streamlined.dbo.uddetail WITH ( NOLOCK )
                                                      WHERE     uds_type = 'MGS'
                                                    ) AS SOLMGS
                                          INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                                    AS AccountInfo
                                                    ON SOLMGS.mt_int_code = AccountInfo.mt_int_code
                                          WHERE     [MGS20] BETWEEN @StartDate AND @EndDate
                                                    AND ISNULL(CAS_BatchName,'') != 'GPB'
                                                    AND ClientName = @ClientName
				-- filter by the £750 magic number, distinguished high value & low value cases:
                                                    AND case when @ExecType = 1
                                                             THEN 1
                                                             when @ExecType = 2
                                                                  AND [OriginalBalance] < 750
                                                             THEN 1
                                                             when @ExecType = 3
                                                                  AND [OriginalBalance] >= 750
                                                             THEN 1
                                                        END = 1
                                        ) as All_Arrangements
                              Group by  date_arranged
                            ) as arrangements
                    on pd.[date] = arrangements.[date]
            WHERE   pd.[date] between @StartDate AND @EndDate
	-- sorting done by the report .rdl

        END

    ELSE 
        IF @ExecType = 4 
            BEGIN
-- Summary Block:

                SELECT  DATENAME(MONTH, pd.[date]) + ' '
                        + CONVERT(VARCHAR(4), YEAR(pd.[date])) AS MonthYear
                      , ISNULL(MAX(Payments.Qty), 0) AS ReceiveOnePayment
                      , ISNULL(MAX(Issued.Qty), 0) AS Issued
                      , ISNULL(MAX(Enforcements.Qty), 0) AS Enforcement
                      , ISNULL(MAX(SDIssued.Qty), 0) AS SDIssued
                FROM    dbo.PeriodDates pd WITH ( NOLOCK )
                LEFT OUTER JOIN -- count the accounts with at least one payment:
                        (
                          SELECT    DATENAME(MONTH, PYR_PaymentDate) + ' '
                                    + CONVERT(VARCHAR(4), YEAR(PYR_PaymentDate)) AS MonthYear
                                  , COUNT(DISTINCT SOLPYR.mt_int_code) AS Qty
                          FROM      VFile_Streamlined.dbo.Payments AS SOLPYR
                          INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                    AS AccountInfo
                                    ON SOLPYR.mt_int_code = AccountInfo.mt_int_code
                          WHERE     PYR_PaymentArrangementType IN (
                                    'Payment Arrangement', 'Other', '',
                                    'Settlement' )
                                    AND PYR_PaymentType NOT IN (
                                    'Historical Payment', 'CCA Request', 'SAR' )
			--AND SOLPYR.PYR1616 = 'No'
                                    AND ISNULL(CAS_BatchName,'') != 'GPB'
                                    AND ClientName = @ClientName
                                    AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                          GROUP BY  DATENAME(MONTH, PYR_PaymentDate) + ' '
                                    + CONVERT(VARCHAR(4), YEAR(PYR_PaymentDate))
                        ) AS Payments
                        ON DATENAME(MONTH, pd.[date]) + ' '
                           + CONVERT(VARCHAR(4), YEAR(pd.[date])) = Payments.MonthYear
                LEFT OUTER JOIN -- count the accounts with a Claim Issued:
                        (
                          SELECT    DATENAME(MONTH, CRD_DateClaimFormIssued)
                                    + ' '
                                    + CONVERT(VARCHAR(4), YEAR(CRD_DateClaimFormIssued)) AS MonthYear
                                  , COUNT(1) AS Qty
                          FROM      VFile_Streamlined.dbo.AccountInformation
                                    AS AccountInfo
                          WHERE     CRD_DateClaimFormIssued BETWEEN @StartDate
                                                            AND     @EndDate
                                    AND ISNULL(CAS_BatchName,'') <> 'GPB'
                                    AND ClientName = @ClientName
                          GROUP BY  DATENAME(MONTH, CRD_DateClaimFormIssued)
                                    + ' '
                                    + CONVERT(VARCHAR(4), YEAR(CRD_DateClaimFormIssued))
                        ) AS Issued
                        ON DATENAME(MONTH, pd.[date]) + ' '
                           + CONVERT(VARCHAR(4), YEAR(pd.[date])) = Issued.MonthYear
                LEFT OUTER JOIN -- count the accounts with Enforcement:
                        (
                          SELECT    DATENAME(MONTH, EnforcementDate) + ' '
                                    + CONVERT(VARCHAR(4), YEAR(EnforcementDate)) AS MonthYear
                                  , COUNT(1) AS Qty
                          FROM      (
                                      SELECT    MGS.mt_int_code
                                              , CASE WHEN DateOfApplicationForAOE = '1900-01-01 00:00:00.000'
                                                     THEN DateOfApplicationForCO
                                                     WHEN DateOfApplicationForCO = '1900-01-01 00:00:00.000'
                                                     THEN DateOfApplicationForAOE
                                                END AS EnforcementDate
                                      FROM      Reporting.dbo.SOLMGS AS MGS
                                      INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                                AS AccountInfo
                                                ON MGS.mt_int_code = AccountInfo.mt_int_code
                                      WHERE     ISNULL(CAS_BatchName,'') != 'GPB'
                                                AND ClientName = @ClientName
                                                AND (
                                                      DateOfApplicationForAOE BETWEEN @StartDate
                                                                              AND     @EndDate
                                                      OR DateOfApplicationForCO BETWEEN @StartDate
                                                                                AND     @EndDate
                                                    )
                                    ) enforcements_sub
                          GROUP BY  DATENAME(MONTH, EnforcementDate) + ' '
                                    + CONVERT(VARCHAR(4), YEAR(EnforcementDate))
                        ) AS enforcements
                        ON DATENAME(MONTH, pd.[date]) + ' '
                           + CONVERT(VARCHAR(4), YEAR(pd.[date])) = enforcements.MonthYear
                LEFT OUTER JOIN (
                                  SELECT    DATENAME(MONTH, HTRY_DateInserted)
                                            + ' '
                                            + CONVERT(VARCHAR(4), YEAR(HTRY_DateInserted)) AS MonthYear
                                          , COUNT(1) AS Qty
                                  FROM      VFile_Streamlined.dbo.history AS SOLSTA
                                  INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                            AS AccountInfo
                                            ON SOLSTA.mt_int_code = AccountInfo.mt_int_code
                                  WHERE     HTRY_DateInserted BETWEEN @StartDate AND @EndDate
                                            AND ClientName = @ClientName
                                            AND ISNULL(CAS_BatchName,'') <> 'GPB'
                                            AND (
                                                  HTRY_description LIKE 'Statutory Demand Form - Marlin Europe I Limited%'
                                                  OR HTRY_description LIKE 'Statutory Demand Form'
                                                )
                                  GROUP BY  DATENAME(MONTH, HTRY_DateInserted)
                                            + ' '
                                            + CONVERT(VARCHAR(4), YEAR(HTRY_DateInserted))
                                ) AS SDIssued
                        ON DATENAME(MONTH, pd.[date]) + ' '
                           + CONVERT(VARCHAR(4), YEAR(pd.[date])) = SDIssued.MonthYear
                WHERE   pd.[Date] BETWEEN @StartDate AND @EndDate
                GROUP BY DATENAME(MONTH, pd.[date]) + ' '
                        + CONVERT(VARCHAR(4), YEAR(pd.[date]))


            END




GO
