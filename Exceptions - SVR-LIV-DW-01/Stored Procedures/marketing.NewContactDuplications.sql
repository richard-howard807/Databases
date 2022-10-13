SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-06-16
-- Description:	#101761, new report for marketing to look at new contacts created and identify potential duplications
-- =============================================
CREATE PROCEDURE [marketing].[NewContactDuplications]
	
	@StartDate AS date
	, @EndDate AS date 
AS

--for testing
--DECLARE @StartDate AS DATE 
--SET @StartDate='2021-06-01'
--DECLARE @EndDate AS DATE 
--SET @EndDate='2021-06-16'

BEGIN

	SET NOCOUNT ON;

	SELECT dbContact.contID AS [Contact ID]
       ,dbContact.contName AS [Contact Name]
       ,dbAddress.addLine1 AS [Address Line 1]
       ,dbAddress.addLine2 AS [Address Line 2]
       ,dbAddress.addLine3 AS [Address Line 3]
       ,dbAddress.addLine4 AS [Address Line 4]
       ,dbAddress.addLine5 AS [Address Line 5]
       ,dbAddress.addPostcode AS [Postcode]
       ,Email AS [Email]
       ,usrFullName AS [Created By]
       ,[red_dw].[dbo].[datetimelocal](dbContact.Created) AS [Date Created]
       ,CAST(STRING_AGG(PossibleDups.contID, ', ') AS VARCHAR(MAX)) AS [Possible Dups]

FROM MS_Prod.config.dbContact
    INNER JOIN MS_Prod.dbo.dbUser
        ON dbUser.usrID = dbContact.CreatedBy
    INNER JOIN MS_Prod.dbo.dbAddress
        ON contDefaultAddress = addID
    
	LEFT OUTER JOIN
    (
        SELECT Email.contID,
               Email.Email
        FROM
        (
            SELECT contID,
                   contEmail AS Email,
                   ROW_NUMBER() OVER (PARTITION BY contID ORDER BY contDefaultOrder ASC) AS xorder
            FROM MS_Prod.dbo.dbContactEmails
            WHERE contActive = 1
        ) AS Email
        WHERE Email.xorder = 1
    ) AS Email
        ON Email.contID = dbContact.contID
    
	LEFT OUTER JOIN
    (
        SELECT contName,
               addPostcode,
               contID
        FROM MS_Prod.config.dbContact
            INNER JOIN MS_Prod.dbo.dbAddress
                ON contDefaultAddress = addID
    ) AS PossibleDups
        ON PossibleDups.addPostcode = dbAddress.addPostcode
           AND PossibleDups.contName = dbContact.contName
           --AND dbContact.contID <> PossibleDups.contID

WHERE [red_dw].[dbo].[datetimelocal](dbContact.Created)
	  BETWEEN @StartDate AND @EndDate

     --AND dbContact.contID IN (5770975)--,5481437,5509850,5519241)

GROUP BY dbContact.contID,
         dbContact.contName,
         dbAddress.addLine1,
         dbAddress.addLine2,
         dbAddress.addLine3,
         dbAddress.addLine4,
         dbAddress.addLine5,
         dbAddress.addPostcode,
         Email,
         usrFullName,
         [red_dw].[dbo].[datetimelocal](dbContact.Created)

HAVING LEN(CAST(STRING_AGG(PossibleDups.contID, ', ') AS VARCHAR(MAX)))>7

END
GO
