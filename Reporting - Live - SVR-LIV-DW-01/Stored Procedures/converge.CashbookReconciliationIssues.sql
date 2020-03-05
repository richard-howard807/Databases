SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-12-09
Description:		Reconciliation issues Cashbook Only, for Severn Trent, Balance Sheet and Derwent
					Run on or after the first of the month 
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [converge].[CashbookReconciliationIssues]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-----Set Variable----- 
DECLARE  @StartDate AS date
		,@Enddate as date
SET		 @StartDate = (select dateadd(mm, datediff(mm, 0, GetDate()) - 1, 0) ) --Start of last month
SET 	 @EndDate = (select dateadd(mm, datediff(mm, 0, GetDate()), -1)) --End of last month



---Get ST Paid and Recovered Amounts as per the Cashbook

SELECT
 CASE WHEN cb.Category = 'PAYMENT' OR cb.Category =  'UNPRESENTED' THEN 'Paid ST' 
	 WHEN cb.Category = 'RECOVERY' OR CB.Category = 'REFUND' THEN 'Recovered ST'
	  END AS Category
 ,SUM(ISNULL(cb.CreditAmount,0))+SUM(ISNULL(cb.DebitAmount,0)) as Amount

FROM  Reporting.[converge].[cashbook_severntrent] cb
WHERE gl_date between @StartDate and @Enddate and cb.Category IN ('PAYMENT','UNPRESENTED','RECOVERY','REFUND')
GROUP BY
 CASE WHEN cb.Category = 'PAYMENT' OR cb.Category =  'UNPRESENTED' THEN 'Paid ST' 
	 WHEN cb.Category = 'RECOVERY' OR CB.Category = 'REFUND' THEN 'Recovered ST'
	  END
	  
	   
UNION ALL

---Get BSF paid as per Cashbook

SELECT 
 CASE WHEN cb.Category = 'PAYMENT' OR cb.Category =  'UNPRESENTED' THEN 'Paid BSF' 
	    END AS Category
 ,SUM(ISNULL(cb.CreditAmount,0))+SUM(ISNULL(cb.DebitAmount,0)) as Amount

FROM  reporting.converge.cashbook_balancesheetfund cb
WHERE gl_date between @StartDate and @Enddate and cb.Category IN ('PAYMENT','UNPRESENTED')
GROUP BY
 CASE WHEN cb.Category = 'PAYMENT' OR cb.Category =  'UNPRESENTED' THEN 'Paid BSF' 
	   END 


UNION ALL

---Get Derwent Paid and Recovered Amounts as per the Cashbook
 
SELECT 
 CASE WHEN cb.Category = 'PAYMENT' OR cb.Category =  'UNPRESENTED' THEN 'Paid Derwent' 
	 WHEN cb.Category = 'RECOVERY' OR CB.Category = 'REFUND' THEN 'Recovered Derwent'
		END AS Category
 ,SUM(ISNULL(cb.CreditAmount,0))+SUM(ISNULL(cb.DebitAmount,0)) as Amount

FROM  Reporting.[converge].[cashbook_st_derwent] cb
WHERE cb.PostingDate between @StartDate and @Enddate and cb.Category IN ('PAYMENT','UNPRESENTED','RECOVERY','REFUND')
GROUP BY
  CASE WHEN cb.Category = 'PAYMENT' OR cb.Category =  'UNPRESENTED' THEN 'Paid Derwent' 
	 WHEN cb.Category = 'RECOVERY' OR CB.Category = 'REFUND' THEN 'Recovered Derwent'
		END 
END


	


GO
