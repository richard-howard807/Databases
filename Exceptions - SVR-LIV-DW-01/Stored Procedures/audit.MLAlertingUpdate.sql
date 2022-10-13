SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [audit].[MLAlertingUpdate]
(
@ClientNo AS char(8)
,@MattersToExcludeInitial AS INT
)

AS

BEGIN

DECLARE @MattersToExclude AS INT

SET @MattersToExclude=@MattersToExcludeInitial - 1

DECLARE @check  AS char(8)

SET @check=(SELECT  ClientNo FROM MoneyLaunderingAlerting WHERE ClientNo=@ClientNo)


SELECT  * FROM MoneyLaunderingAlerting WHERE ClientNo=@ClientNo

IF RTRIM(@check)=RTRIM(@clientNo)
BEGIN

UPDATE MoneyLaunderingAlerting 
SET MattersToExclude=MattersToExclude+@MattersToExclude
WHERE ClientNo=@ClientNo


END 


ELSE 

BEGIN 

INSERT INTO MoneyLaunderingAlerting
(ClientNo,MattersToExclude)
SELECT @ClientNo,@MattersToExclude

END 


SELECT  * FROM MoneyLaunderingAlerting WHERE ClientNo=@ClientNo


END
GO
