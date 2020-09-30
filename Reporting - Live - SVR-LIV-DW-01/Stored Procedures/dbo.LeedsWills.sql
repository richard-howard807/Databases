SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- FW Wills
CREATE PROCEDURE [dbo].[LeedsWills]
(
@Search AS NVARCHAR(MAX)
) 
AS 

IF @Search='All'

BEGIN
SELECT  wicust AS [Custody No],
wisurn AS Surname,
       wititl AS Title,
       wifore AS Forename,
       wiwild AS [Date of Will],
       wiexec AS Executors,
       CASE WHEN widecd=0 THEN 'No' ELSE 'Yes' END AS [Deceased],
    --   wicuno AS[],
	   --wicuno,
    --   wisurn,
    --   wititl,
    --   wifore,
       wiadd1 AS Address1,
       wiadd2 AS Address2,
       wiadd3 AS Address3,
       wiadd4 AS Address4,
       wiadd5 AS Address5,
       --wiwild,
       --wicono,
       wifeee AS FeeEarner,
       wistod AS [Date Stored],
       wilocn AS [Location],
       wiremd AS [Date Removed],
       wiwhom AS [By Whom],
       wireas AS [Reason],
       widest AS [Destination],
       --wimemo,
       --wiexec,
       --wicust,
       wiretd AS [Date Returned],
       wicomm AS Comments,
       --wichkd,
       --witype,
       --wifwex,
       --widecd,
       --wiepat,
       --wilpat,
       --wiprob,
       witele AS Telephone,
       --wistat,
       --winrea,
       --wilett,
       --wiprev,
       --wipriv,
       --wideed,
       --wideno,
       --wiepan AS [EPA],
       --wilpan AS [],
       wichda AS [Last Checked]

FROM [SVR-LIV-3PTY-01].fw_webdb.dbo.wifile
WHERE wisurn LIKE '%'

ORDER BY CONVERT(INT, wicust) DESC;


END 

ELSE 


BEGIN
SELECT  wicust AS [Custody No],
wisurn AS Surname,
       wititl AS Title,
       wifore AS Forename,
       wiwild AS [Date of Will],
       wiexec AS Executors,
       CASE WHEN widecd=0 THEN 'No' ELSE 'Yes' END AS [Deceased],
    --   wicuno AS[],
	   --wicuno,
    --   wisurn,
    --   wititl,
    --   wifore,
       wiadd1 AS Address1,
       wiadd2 AS Address2,
       wiadd3 AS Address3,
       wiadd4 AS Address4,
       wiadd5 AS Address5,
       --wiwild,
       --wicono,
       wifeee AS FeeEarner,
       wistod AS [Date Stored],
       wilocn AS [Location],
       wiremd AS [Date Removed],
       wiwhom AS [By Whom],
       wireas AS [Reason],
       widest AS [Destination],
       --wimemo,
       --wiexec,
       --wicust,
       wiretd AS [Date Returned],
       wicomm AS Comments,
       --wichkd,
       --witype,
       --wifwex,
       --widecd,
       --wiepat,
       --wilpat,
       --wiprob,
       witele AS Telephone,
       --wistat,
       --winrea,
       --wilett,
       --wiprev,
       --wipriv,
       --wideed,
       --wideno,
       --wiepan AS [EPA],
       --wilpan AS [],
       wichda AS [Last Checked]

FROM [SVR-LIV-3PTY-01].fw_webdb.dbo.wifile
WHERE wisurn LIKE '%' + @Search + '%'

ORDER BY CONVERT(INT, wicust) DESC;


END 
GO
