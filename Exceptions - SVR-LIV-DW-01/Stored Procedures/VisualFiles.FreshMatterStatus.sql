SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [VisualFiles].[FreshMatterStatus]

AS 
       SELECT
        ClientName AS clientname
    , HIM_AccountNumber AS AccountNumber
    ,   RIGHT(AccountInfo.level_fee_earner, 3) + ' / ' + CAST(AccountInfo.MatterCode AS VARCHAR (30)) AS weightmansref
    ,   AccountInfo.originalbalance AS Originalbalance
    ,   AccountInfo.CurrentBalance  AS Balance
    ,   MilestoneDescription AS milestone
    ,   AccountInfo.CLO_ClosureReason AS ClosureReason
    ,CCT_Claimnumber9 AS ClaimNumber
    FROM
        VFile_Streamlined.dbo.AccountInformation AS AccountInfo WITH (NOLOCK)
    INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients   WITH (NOLOCK)
    ON  AccountInfo.mt_int_code = Clients.mt_int_code
    
    LEFT OUTER JOIN VFile_Streamlined.dbo.IssueDetails AS Issue
     ON AccountInfo.mt_int_code=Issue.mt_int_code
    LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE  AS SOLCDE
     ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
    
    WHERE ClientName='Fresh Insurance'




GO
