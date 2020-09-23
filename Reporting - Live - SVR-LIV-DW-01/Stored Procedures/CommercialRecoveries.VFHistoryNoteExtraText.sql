SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [CommercialRecoveries].[VFHistoryNoteExtraText]

(
@MatterCode AS INT
)

AS 
BEGIN 


----SET @MatterCode=267512 
SELECT  MatterCode
,Short_name
,
 CONVERT(DATE,[date_inserted],103) AS HTRY_DateInserted
,  CAST([time_inserted] AS INT) AS HTRY_TimeInserted
,  CAST([description] AS VARCHAR (MAX)) AS HTRY_description
,  CAST([extra_text] AS VARCHAR (MAX)) AS HTRY_ExtraText




FROM [SVR-LIV-VISF-01].[Vfile_Live].[dbo].[history] WITH(NOLOCK)
INNER JOIN VFile_Streamlined.dbo.AccountInformation
 ON AccountInformation.mt_int_code = history.mt_int_code
WHERE MatterCode=@MatterCode
ORDER BY [date_inserted] ASC

END

GO
