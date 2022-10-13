SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- FW Probate
CREATE PROCEDURE [dbo].[LeedsProbate]
(
@Search AS NVARCHAR(MAX)
) 
AS 

IF @Search='All'

BEGIN
SELECT prcust AS [Number]
,prsurn AS [Surname]
,prtitl AS [Title]
,prfore AS Forename
,pradd1 AS [Address1]
,pradd2 AS [Address2]
,pradd3 AS [Address3]
,pradd4 AS [Address4]
,pradd5 AS [Address5]
,prprod AS [Date of Probate]
,prdead AS [Date of Death]
,prwild AS [Date of Will]
,prexec AS [Executors]
,prfeee AS [Fee Earner]
,prstod AS [Date Stored]
,prlocn AS [Location]
,prremd AS [Date Removed]
,prwhom AS [By Whome]
,prreas AS [Reason]
,prdest AS [Destination]
,prretd AS [Returned Date]
,prchkd AS [Checked]
,prcomm AS [Comments]
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[webdb].[dbo].[prfile]


END 

ELSE 

BEGIN
SELECT prcust AS [Number]
,prsurn AS [Surname]
,prtitl AS [Title]
,prfore AS Forename
,pradd1 AS [Address1]
,pradd2 AS [Address2]
,pradd3 AS [Address3]
,pradd4 AS [Address4]
,pradd5 AS [Address5]
,prprod AS [Date of Probate]
,prdead AS [Date of Death]
,prwild AS [Date of Will]
,prexec AS [Executors]
,prfeee AS [Fee Earner]
,prstod AS [Date Stored]
,prlocn AS [Location]
,prremd AS [Date Removed]
,prwhom AS [By Whome]
,prreas AS [Reason]
,prdest AS [Destination]
,prretd AS [Returned Date]
,prchkd AS [Checked]
,prcomm AS [Comments]
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[webdb].[dbo].[prfile]
WHERE prsurn LIKE '%' + @Search + '%'

END 
GO
