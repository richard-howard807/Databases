SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =========================================================================================
-- Author:		Max Taylor
-- Create date: 08/11/2021
-- Ticket:		119900
-- Description:	Initial Create SQL Matters - Dates
--=========================================================================================

-- =========================================================================================
CREATE PROCEDURE [dbo].[CapacityPlanningClaims_Hours_Dates]

AS

SELECT DISTINCT 
DatePeriod = REPLACE(RIGHT(fin_period,9),')',''),
fin_period ,
YearPeriod = CAST(RIGHT(MIN(cal_year)  OVER(), 2) AS varchar(2))  +'/'+ CAST(RIGHT(MAX(cal_year)  OVER() , 2) AS VARCHAR(2))
FROM red_dw.dbo.dim_date 
WHERE calendar_date BETWEEN GETDATE() AND DATEADD(MONTH, 11, GETDATE())

ORDER BY fin_period
GO
