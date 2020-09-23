SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Lucy 
-- Create date: <Create Date,,>
-- Description:	Testing : pasting a cte into Tableau doesn't appear to work properly so using this procedure
-- TODO 20191114 :  Just checked with Greg and gets the employee breakdown directly from Ben in HR.  I assume we can get the same info from Cascade.
--					If Richard can just arrange an insert into the [Visualisation].[dbo].[target_operating_model_employee] of all live employees 
--					as of the last day of the month.
-- 
-- =============================================
CREATE PROCEDURE [dbo].[tom_revenue_per_casehandler]
AS

DECLARE @prev_fin_year INT 

SELECT @prev_fin_year = fin_year -1 FROM red_dw.dbo.dim_date WHERE calendar_date = CAST(GETDATE() AS DATE)

	;WITH Revenue
AS ( SELECT   bill_date.fin_period ,
              employee.hierarchylevel2hist [Division] ,
              employee.hierarchylevel3hist [Department] ,
              SUM(bill_amount) [revenue]
     FROM     red_dw.dbo.fact_bill_activity bill
              INNER JOIN red_dw.dbo.dim_date bill_date ON bill.dim_bill_date_key = bill_date.dim_date_key
              INNER JOIN red_dw.dbo.dim_fed_hierarchy_history employee ON employee.dim_fed_hierarchy_history_key = bill.dim_fed_hierarchy_history_key
     WHERE    1 = 1
              AND bill_date.fin_year >= @prev_fin_year
     GROUP BY bill_date.fin_period ,
              employee.hierarchylevel2hist ,
              employee.hierarchylevel3hist ) ,
      case_handler_cte
AS ( SELECT   [nDate].[fin_period] ,
              [Month] ,
			  [fin_year],
              [division] ,
              [department] ,
              SUM([fte]) [CaseHandlerFTE]
     FROM     [Visualisation].[dbo].[target_operating_model_employee] a
              INNER JOIN red_dw.dbo.dim_date nDate ON a.[Month] = nDate.calendar_date
     WHERE    [Role] = 'Casehandler'
     GROUP BY [nDate].[fin_period] ,
              [Month] ,
			    [fin_year],
              [division] ,
              [department] )
SELECT   a.[Month] ,
         a.[fin_year],
         a.division ,
         a.department ,
         b.revenue ,
         a.CaseHandlerFTE 
       
FROM     case_handler_cte a
         INNER JOIN Revenue b ON b.Department = a.department COLLATE DATABASE_DEFAULT
                                 AND b.Division = a.division COLLATE DATABASE_DEFAULT
                                 AND b.fin_period = a.fin_period COLLATE DATABASE_DEFAULT
ORDER BY a.fin_period ,
         a.division ,
         a.department

GO
