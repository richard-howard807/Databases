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
 CONVERT(DATE,HTRY_DateInserted,103) AS HTRY_DateInserted
,  CAST(HTRY_TimeInserted AS INT) AS HTRY_TimeInserted
,  CAST(HTRY_description AS VARCHAR (MAX)) AS HTRY_description
,  CAST(HTRY_ExtraText AS VARCHAR (MAX)) AS HTRY_ExtraText
,doc_id AS [Document Number]
,'\\svr-liv-fs-04\VisualFiles\Live\solhist\Debt\'+ sub_path + doc_id  AS [DocumentSource]
FROM VFile_Streamlined.dbo.History
INNER JOIN VFile_Streamlined.dbo.AccountInformation
 ON AccountInformation.mt_int_code = History.mt_int_code
LEFT JOIN VFile_Streamlined.dbo.VFDocuments
 ON HTRY_DocumentName=VFDocuments.doc_id
WHERE MatterCode=@MatterCode
ORDER BY HTRY_DateInserted ASC

END

GO
