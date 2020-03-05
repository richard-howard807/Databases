SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		J.Robinson
-- Create date: 2015/04/02
-- Description:	Marlin Batch Summary with Date Range
-- exec  [VisualFiles].[MarlinUnsecuredBookByPlacementAndDateRange] '20140501','20150401'
-- =============================================
CREATE PROCEDURE [VisualFiles].[MarlinUnsecuredBookByPlacementAndDateRange] 
(
	@StartDate DATE,
	@EndDate DATE
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Exceptions') IS NOT NULL 
        DROP TABLE #Exceptions
      
SELECT  mt_int_code
INTO #Exceptions
FROM    ( SELECT    mt_int_code
          FROM      VFile_Streamlined.dbo.AttachmentOfEarnings
          WHERE     ATT_DateAttachmentOfEarningsReq <> '1900-01-01'
          
          UNION
          
          SELECT    mt_int_code
          FROM      VFile_Streamlined.dbo.Warrant AS Warrant
          WHERE     CWA_DatewarrantIssued <> '1900-01-01'
          
          UNION
          
          SELECT    mt_int_code
          FROM      VFile_Streamlined.dbo.Charges AS CHO
          WHERE     CHO_Interimdate <> '1900-01-01'
          
          UNION
          
          SELECT    mt_int_code
          FROM      VFile_Streamlined.dbo.Charges AS VCO
          WHERE     VCO_DateRestrictionRegistered <> '1900-01-01'
          
          UNION
          
          SELECT  DISTINCT History.mt_int_code 
          FROM VFile_Streamlined.dbo.History AS History
		  INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account ON History.mt_int_code=Account.mt_int_code
		  WHERE HTRY_description  LIKE '%Application for Charging Order Prepared%'
		  AND Account.ClientName  = 'Marlin'
                              
          UNION
          
          SELECT    mt_int_code
          FROM      VFile_Streamlined.dbo.AccountInformation AS AccountInfo
          WHERE     MilestoneCode = 'DEFE'
          OR PIT_MatterOnHoldYesNo = 1
         ) AS AllExceptions		
         
BEGIN

SELECT 
	Worktypes.SecuredBookType,
	YearOpened,
	MonthOpened,
	MonthYearOpened,
    NoOfAccounts ,
    DateReportGenerated ,
    Worktypes.xorder  
    
FROM (SELECT 'Pre Litigation Negative or Positive' AS SecuredBookType,1 AS xorder 
	  
	  UNION
	  
	  SELECT 'Pre Litigation Response to 2nd Letter' AS SecuredBookType,2 AS xorder 
			 
      UNION
      
      SELECT 'Litigated Pre Judgment' AS SecuredBookType,3 AS xorder
			 
	  UNION
	  
	  SELECT 'Judgment Pre Enforcement' AS SecuredBookType,4 AS xorder 
	  
	  UNION
	  
	  SELECT 'AOE' AS SecuredBookType,5 AS xorder  

	  UNION
	  
	  SELECT 'Charging Order Applications' AS SecuredBookType,6 AS xorder 

	  UNION
	  
	  SELECT 'Interim Charging Order' AS SecuredBookType,7 AS xorder 

	  UNION
	  
	  SELECT 'Final Charging Order' AS SecuredBookType,8 AS xorder 

	  UNION
	  
	  SELECT 'Voluntary Charging Order' AS SecuredBookType,9 AS xorder 

	  UNION
	  
	  SELECT 'Warrant' AS SecuredBookType ,10 AS xorder 
	  
	  UNION
	  
	  SELECT 'On Hold OR Defended' AS SecuredBookType,11 AS xorder 
     ) AS WorkTypes           

LEFT JOIN  (SELECT 'Pre Litigation Negative or Positive' AS SecuredBookType 
					--,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
					,DATEPART(yy,DateOpened) AS YearOpened
					,DATEPART(MM,DateOpened) AS MonthOpened
					,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
					,COUNT(Account.mt_int_code) AS NoOfAccounts 
					,GETDATE() AS DateReportGenerated 
					,1 AS xorder

			FROM    VFile_Streamlined.dbo.AccountInformation AS Account
			LEFT JOIN VFile_Streamlined.dbo.Schedule sched ON Account.mt_int_code=sched.mt_int_code
			WHERE Account.MilestoneCode = 'INST'
            AND Account.FileStatus <> 'COMP'
            AND Account.ClientName = 'Marlin'
		    AND Account.SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
		    AND (SCH_desc_awaiting LIKE '%Marlin LRS Negative Letter%' OR SCH_desc_awaiting LIKE '%Marlin LRS Positive Letter%')
			AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
            GROUP BY  CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
           
            UNION
            
            SELECT 'Pre Litigation Response to 2nd Letter' AS SecuredBookType 
					--,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
					,DATEPART(yy,DateOpened) AS YearOpened
					,DATEPART(MM,DateOpened) AS MonthOpened
					,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
					,COUNT(Account.mt_int_code) AS NoOfAccounts 
					,GETDATE() AS DateReportGenerated 
					,2 AS xorder

			FROM    VFile_Streamlined.dbo.AccountInformation AS Account
			LEFT JOIN VFile_Streamlined.dbo.Schedule sched ON Account.mt_int_code=sched.mt_int_code
			WHERE Account.MilestoneCode = 'INST'
            AND Account.FileStatus <> 'COMP'
            AND Account.ClientName = 'Marlin'
		    AND Account.SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
		    AND SCH_desc_awaiting LIKE 'Response to Second Letter?%'
			AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
            GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
                    ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
            
            UNION
            
            SELECT  'Litigated Pre Judgment' AS SecuredBookType
					--,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
					,DATEPART(yy,DateOpened) AS YearOpened
					,DATEPART(MM,DateOpened) AS MonthOpened
					,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
					,COUNT(Account.mt_int_code) AS NoOfAccounts 
					,GETDATE() AS DateReportGenerated 
					,3 AS xorder
            FROM    VFile_Streamlined.dbo.AccountInformation AS Account
            LEFT OUTER JOIN ( SELECT    mt_int_code AS mt_int_code 
										,SUM(PYR_PaymentAmount) AS PaidLast30Days
                              FROM      VFile_Streamlined.dbo.Payments AS Payments
                              WHERE     PYR_PaymentDate BETWEEN GETDATE()- 35 AND GETDATE()
                              AND PYR_PaymentType <> 'Historical Payment'
                              GROUP BY  mt_int_code
                             ) AS Payments ON Account.mt_int_code = Payments.mt_int_code
            WHERE   MilestoneCode IN ( 'ISSU', 'SERV' )
            AND FileStatus <> 'COMP'
            AND Account.ClientName = 'Marlin'
			AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
            AND Account.mt_int_code NOT IN (SELECT mt_int_code FROM #Exceptions)
            AND Account.DateOpened BETWEEN @StartDate AND @EndDate
		    GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
		            ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
		    
		    UNION
		    
		    SELECT  'Judgment Pre Enforcement' AS SecuredBookType 
					--,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
					,DATEPART(yy,DateOpened) AS YearOpened
					,DATEPART(MM,DateOpened) AS MonthOpened
					,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
					,COUNT(Account.mt_int_code) AS NoOfAccounts 
					,GETDATE() AS DateReportGenerated 
					,4 AS xorder
            FROM    VFile_Streamlined.dbo.AccountInformation AS Account
            LEFT OUTER JOIN ( SELECT    mt_int_code AS mt_int_code 
										,SUM(PYR_PaymentAmount) AS PaidLast30Days
                              FROM      VFile_Streamlined.dbo.Payments AS Payments
                              WHERE     PYR_PaymentDate BETWEEN GETDATE()- 35 AND GETDATE()
                              AND PYR_PaymentType <> 'Historical Payment'
                              GROUP BY  mt_int_code
                             ) AS Payments ON Account.mt_int_code = Payments.mt_int_code
            WHERE   MilestoneCode IN ( 'JUDG', 'ENFO', 'CHAR' )
            AND FileStatus <> 'COMP'
            AND Account.ClientName = 'Marlin'
			AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
            AND Account.mt_int_code NOT IN (SELECT mt_int_code FROM #Exceptions)
            AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
            GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
            
            UNION
            
            SELECT  'AOE' AS SecuredBookType 
					--,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
					,DATEPART(yy,DateOpened) AS YearOpened
					,DATEPART(MM,DateOpened) AS MonthOpened
					,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
					,COUNT(Account.mt_int_code) AS NoOfAccounts 
					,GETDATE() AS DateReportGenerated 
					,5 AS xorder
            FROM    VFile_Streamlined.dbo.AccountInformation AS Account
            INNER JOIN ( SELECT mt_int_code
                         FROM   VFile_Streamlined.dbo.AttachmentOfEarnings
                         WHERE  ATT_DateAttachmentOfEarningsReq <> '1900-01-01'
                        ) AS AEO ON Account.mt_int_code = AEO.mt_int_code
             LEFT OUTER JOIN ( SELECT    mt_int_code AS mt_int_code 
										,SUM(PYR_PaymentAmount) AS PaidLast30Days
                               FROM      VFile_Streamlined.dbo.Payments AS Payments
                               WHERE     PYR_PaymentDate BETWEEN GETDATE()- 35 AND GETDATE()
                               AND PYR_PaymentType <> 'Historical Payment'
                               GROUP BY  mt_int_code
                              ) AS Payments ON Account.mt_int_code = Payments.mt_int_code
             WHERE   FileStatus <> 'COMP'
             AND Account.ClientName ='Marlin'
			 AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
			 AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
             GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
             
             UNION
             
             SELECT  'Charging Order Applications' AS SecuredBookType 
                   --,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
                     ,DATEPART(yy,DateOpened) AS YearOpened
					 ,DATEPART(MM,DateOpened) AS MonthOpened
					 ,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
					 ,COUNT(Account.mt_int_code) AS NoOfAccounts 
					 ,GETDATE() AS DateReportGenerated 
					 ,6 AS xorder
		     FROM VFile_Streamlined.dbo.History AS History
			 INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account ON History.mt_int_code=Account.mt_int_code
			 WHERE HTRY_description  LIKE '%Application for Charging Order Prepared%'
             AND FileStatus <> 'COMP'
             AND Account.ClientName = 'Marlin'
			 AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
			 AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
             GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
             
             UNION
             
             SELECT  'Interim Charging Order' AS SecuredBookType 
					 --,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
					 ,DATEPART(yy,DateOpened) AS YearOpened
					 ,DATEPART(MM,DateOpened) AS MonthOpened
					 ,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
					 ,COUNT(Account.mt_int_code) AS NoOfAccounts 
					 ,GETDATE() AS DateReportGenerated 
					 ,7 AS xorder
			 FROM    VFile_Streamlined.dbo.Charges AS Charges
             INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account ON Charges.mt_int_code = Account.mt_int_code
             WHERE     CHO_Interimdate <> '1900-01-01'
             AND CHO_Finalorderdated ='1900-01-01'
             AND FileStatus <> 'COMP'
             AND Account.ClientName = 'Marlin'
			 AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
			 AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
             GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
             
             UNION
             
             SELECT  'Final Charging Order' AS SecuredBookType 
                     --,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
                     ,DATEPART(yy,DateOpened) AS YearOpened
					 ,DATEPART(MM,DateOpened) AS MonthOpened
                     ,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
                     ,COUNT(Account.mt_int_code) AS NoOfAccounts 
                     ,GETDATE() AS DateReportGenerated 
                     ,8 AS xorder

             FROM    VFile_Streamlined.dbo.Charges AS Charges
             INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account ON Charges.mt_int_code = Account.mt_int_code
             WHERE     CHO_Interimdate <> '1900-01-01'
             AND CHO_Finalorderdated <>'1900-01-01'
             AND FileStatus <> 'COMP'
             AND Account.ClientName = 'Marlin'
			 AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
			 AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
             GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
             
             UNION
             
             SELECT  'Voluntary Charging Order' AS SecuredBookType 
					 --,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
					 ,DATEPART(yy,DateOpened) AS YearOpened
					 ,DATEPART(MM,DateOpened) AS MonthOpened
					 ,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
                     ,COUNT(Account.mt_int_code) AS NoOfAccounts 
                     ,GETDATE() AS DateReportGenerated 
                     ,9 AS xorder

             FROM    VFile_Streamlined.dbo.Charges AS Charges
             INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account ON Charges.mt_int_code = Account.mt_int_code
             WHERE VCO_DateRestrictionRegistered <> '1900-01-01'
             AND FileStatus <> 'COMP'
             AND Account.ClientName = 'Marlin'
			 AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
			 AND Account.DateOpened BETWEEN @StartDate AND @EndDate 
             GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
             
             UNION
             
             SELECT  'Warrant' AS SecuredBookType 
             	   --,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
             	     ,DATEPART(yy,DateOpened) AS YearOpened
					 ,DATEPART(MM,DateOpened) AS MonthOpened
					 ,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
                     ,COUNT(Account.mt_int_code) AS NoOfAccounts 
                     ,GETDATE() AS DateReportGenerated 
                     ,10 AS xorder
             FROM    VFile_Streamlined.dbo.AccountInformation AS Account
             INNER JOIN ( SELECT mt_int_code
                          FROM   VFile_Streamlined.dbo.Warrant AS Warrant
                          WHERE  CWA_DatewarrantIssued <> '1900-01-01'
                         ) AS Warrants ON Account.mt_int_code = Warrants.mt_int_code
             LEFT  JOIN ( SELECT    mt_int_code AS mt_int_code 
									,SUM(PYR_PaymentAmount) AS PaidLast30Days
                          FROM      VFile_Streamlined.dbo.Payments AS Payments
                          WHERE     PYR_PaymentDate BETWEEN GETDATE()- 35 AND GETDATE()
                          AND PYR_PaymentType <> 'Historical Payment'
                          GROUP BY  mt_int_code
                         ) AS Payments ON Account.mt_int_code = Payments.mt_int_code
             WHERE   FileStatus <> 'COMP'
             AND Account.ClientName = 'Marlin'
			 AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
			 AND Account.DateOpened BETWEEN @StartDate AND @EndDate
             GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
             
             UNION
             
             SELECT  'On Hold OR Defended' AS SecuredBookType 
                     --,DATEADD(MONTH, DATEDIFF(MONTH, 0, DateOpened), 0) as MonthOpened
                     ,DATEPART(yy,DateOpened) AS YearOpened
					 ,DATEPART(MM,DateOpened) AS MonthOpened
                     ,CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4)) AS MonthYearOpened
                     ,COUNT(Account.mt_int_code) AS NoOfAccounts 
                     ,GETDATE() AS DateReportGenerated 
                     ,11 AS xorder
             FROM    VFile_Streamlined.dbo.AccountInformation AS Account
             INNER JOIN ( SELECT mt_int_code
                          FROM   VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                          WHERE  MilestoneCode = 'DEFE'
                          OR PIT_MatterOnHoldYesNo = 1
                         ) AS OnHoldDEf ON Account.mt_int_code = OnHoldDEf.mt_int_code
             LEFT  JOIN ( SELECT    mt_int_code AS mt_int_code 
									,SUM(PYR_PaymentAmount) AS PaidLast30Days
                          FROM      VFile_Streamlined.dbo.Payments AS Payments
                          WHERE     PYR_PaymentDate BETWEEN GETDATE()- 35 AND GETDATE()
                          AND PYR_PaymentType <> 'Historical Payment'
                          GROUP BY  mt_int_code
                         ) AS Payments ON Account.mt_int_code = Payments.mt_int_code
             WHERE   FileStatus <> 'COMP'
             AND Account.ClientName = 'Marlin'
			 AND SubClient IN ('Cabot Financial (UK) Limited','Cabot Financial (Europe) Ltd','Cabot Financial (Europe) Limited')
			 AND Account.DateOpened BETWEEN @StartDate AND @EndDate
             GROUP BY CONVERT(CHAR(3),DateOpened,0) + ' - ' + CAST(DATEPART(yy,DateOpened) AS CHAR(4))
					 ,DATEPART(yy,DateOpened),DATEPART(MM,DateOpened)
            ) AS Data  ON WorkTypes.SecuredBookType=Data.SecuredBookType
           
END


END


--select convert(char(3), GETDATE(), 0) AS OrderMonth
GO
