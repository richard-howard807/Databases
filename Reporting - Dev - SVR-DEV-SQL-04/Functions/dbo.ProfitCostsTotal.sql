SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[ProfitCostsTotal]
(
@ClientCode CHAR(8)
)
RETURNS CHAR(8)
AS 

BEGIN

DECLARE @ProfitCostsCurrent AS int
SET @ProfitCostsCurrent =
(SELECT SUM(bill_amount) AS [Profit Costs]
FROM red_dw.dbo.fact_bill_activity
where 
dim_bill_date_key BETWEEN  20160501 AND 20170430
AND client_code=@ClientCode
AND bill_amount<>0)

RETURN @ProfitCostsCurrent

END;
GO
