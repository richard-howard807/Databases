SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [VisualFiles].[MattersOnHold]
     @Client	VARCHAR(50)
    ,@Status	VARCHAR(20)

AS 
    set nocount on
    set transaction isolation level read uncommitted

    IF @Client = 'All' 
        BEGIN 
            SELECT
                HIM_AccountNumber AS [AccountNo1]
                ,ARR_AgreementNumber AS ArrowKey
                ,CDE_ClientAccountNumber AS ClientAccountNumber
            ,   AccountDescription AS [description]
            ,   CASE WHEN PIT_MatterOnHoldYesNo=1 THEN 'Yes' ELSE 'No' END [MatterOnHold]
            ,   PIT_ReasonAccountOnHold AS [ReasonOnHold]
            ,   OnHoldData.LatestOnHoldDate AS DateOnHold
            ,   CurrentBalance AS CurrentBalance
            ,MilestoneCode AS Milestone
            FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
             ON AccountInfo.mt_int_code = Clients.mt_int_code 
             LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE 
            ON AccountInfo.mt_int_code=SOLCDE.mt_int_code  
            LEFT OUTER JOIN 
            (
            SELECT mt_int_code,MAX(HTRY_DateInserted) AS LatestOnHoldDate
FROM VFile_Streamlined.dbo.history H
WHERE HTRY_description ='Account Status: On Hold'
GROUP BY mt_int_code) AS OnHoldData
 ON AccountInfo.mt_int_code=OnHoldData.mt_int_code
    
            WHERE
                PIT_MatterOnHoldYesNo = 1
                AND RTRIM(PIT_OnHoldDefended) = @Status

        END
    ELSE 
        BEGIN 
            SELECT
                HIM_AccountNumber AS [AccountNo1]
                                ,ARR_AgreementNumber AS ArrowKey
                ,CDE_ClientAccountNumber AS ClientAccountNumber
            ,   AccountDescription AS [description]
            ,   CASE WHEN PIT_MatterOnHoldYesNo=1 THEN 'Yes' ELSE 'No' END [MatterOnHold]
            ,   PIT_ReasonAccountOnHold AS [ReasonOnHold]
            ,   OnHoldData.LatestOnHoldDate AS DateOnHold
            ,   CurrentBalance AS CurrentBalance
            ,MilestoneCode AS Milestone
            FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
             ON AccountInfo.mt_int_code = Clients.mt_int_code 
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE 
            ON AccountInfo.mt_int_code=SOLCDE.mt_int_code 
            LEFT OUTER JOIN 
            (
            SELECT mt_int_code,MAX(HTRY_DateInserted) AS LatestOnHoldDate
FROM VFile_Streamlined.dbo.history H
WHERE HTRY_description ='Account Status: On Hold'
GROUP BY mt_int_code) AS OnHoldData
 ON AccountInfo.mt_int_code=OnHoldData.mt_int_code
    
            WHERE
                PIT_MatterOnHoldYesNo = 1
                AND RTRIM(PIT_OnHoldDefended) = @Status
                AND ClientName=@Client

        END
GO
