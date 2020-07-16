SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [CommercialRecoveries].[LeedLegacyNonMigratedHistoryNotes]
(
@SourceSystemID AS NVARCHAR(100)
)
AS 
BEGIN
--DECLARE  @SourceSystemID AS NVARCHAR(MAX)
--SET @SourceSystemID='13509-4246'

IF OBJECT_ID('tempdb..#FWHistoryUnstructured') IS NOT NULL   DROP TABLE #FWHistoryUnstructured

CREATE TABLE #FWHistoryUnstructured
(
	[SourceSystemID] [NVARCHAR](50) NULL,
	[hinumb] [NUMERIC](8, 0) NULL,
	[hidate] [DATETIME] NULL,
	[hidesc] [VARCHAR](240) NULL,
	[hiamnt] [NUMERIC](10, 2) NULL,
	[hitype] [NUMERIC](8, 0) NULL
) 

INSERT INTO #FWHistoryUnstructured
(
    SourceSystemID,
    hinumb,
    hidate,
    hidesc,
    hiamnt,
    hitype
)
select RTRIM(hiclin)+'-'+RTRIM(himatn) AS SourceSystemID
,hinumb
,hidate
,hidesc
,hiamnt 
,hitype 
FROM [SVR-LIV-3PTY-01].fw_webdb.dbo.dhifile 
WHERE RTRIM(hiclin)+'-'+RTRIM(himatn)=@SourceSystemID
ORDER BY SourceSystemID ASC, hinumb ASC


SELECT  SourceSystemID
,Hidate AS  [HTRY_DateInserted]
,CAST(Hidesc AS NVARCHAR(512)) AS [HTRY_description]
,CAST(Hidate AS DATETIME) ,hinumb AS [HTRY_HistoryNo]
,hiamnt AS [Amount]
,SUM (CASE WHEN hitype IN(0,1,2,3,4) THEN hiamnt ELSE 0 END ) OVER (PARTITION BY SourceSystemID ORDER BY hinumb) AS Balance
,hitype AS [NoteType]

 FROM #FWHistoryUnstructured
 ORDER BY SourceSystemID,hinumb ASC

 END
GO
