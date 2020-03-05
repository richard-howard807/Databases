SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[HistoryNoteList] --264883  
(
@MatterCode AS INT
)
AS
BEGIN
SELECT AccountInformation.MatterCode
,CASE WHEN ClientName LIKE '%MIB%' THEN MIB_ClaimNumber
	  WHEN ClientName LIKE '%HFC%' THEN HIM_AccountNumber
	  ELSE 
	  (
	  COALESCE(
	  CASE WHEN CDE_ClientAccountNumber='' THEN NULL ELSE CDE_ClientAccountNumber END, 
	  CASE WHEN HIM_AccountNumber='' THEN NULL ELSE HIM_AccountNumber END
		      )
	  )
	   END AS AccountNumber


,Short_name AS [Description]
,AccountInformation.OriginalBalance AS [Original Balance]
,CurrentBalance AS [Current Balance]
,History.HTRY_DateInserted AS [Date Added]
--, AS [Description]
,ISNULL(History.HTRY_description,'') + ' ' + ISNULL(History.HTRY_ExtraText,'') AS [Extra Text]
,History.HTRY_LastEdited AS [Date Updated]
,fee.name AS [Fee Earner]
,fee1.name AS [Owner]
,CASE WHEN AccountInformation.FileStatus='COMP' THEN 'Closed' ELSE 'Open' END  AS [Status]
,CLO_ClosedDate AS [Date Closed]

FROM VFile_Streamlined.dbo.AccountInformation
INNER JOIN VFile_Streamlined.dbo.History
 ON AccountInformation.mt_int_code=History.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON RIGHT(History.HTRY_LevelFeeEarner,3)=fee.fee_earner 
LEFT OUTER JOIN VFile_Streamlined.dbo.fee AS fee1 ON RIGHT(level_fee_earner,3)=fee1.fee_earner  
LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE ON AccountInformation.mt_int_code=SOLCDE.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens ON AccountInformation.mt_int_code=ClientScreens.mt_int_code
WHERE MatterCode=@MatterCode
ORDER BY HTRY_DateInserted
END
GO
