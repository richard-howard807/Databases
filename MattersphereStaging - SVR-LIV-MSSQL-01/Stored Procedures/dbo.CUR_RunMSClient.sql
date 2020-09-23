SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[CUR_RunMSClient]
AS
	 DECLARE 
	 @ID				INT,
	 @clName			NVARCHAR (80),
	 @clType			NVARCHAR (12),
	 @clNo				NVARCHAR (12),
	 @cbocligrp			NVARCHAR (50),
	 @cbopartner		BIGINT,
	 @addid				BIGINT,
	 @addLine1			NVARCHAR (50),
	 @addLine2			NVARCHAR (50),
	 @addLine3			NVARCHAR (50),
	 @addLine4			NVARCHAR (50),
	 @addLine5			NVARCHAR (50),
	 @addPostCode		NVARCHAR (15),
	 @addCountry		NVARCHAR (50),
	 @addDXCode			NVARCHAR (80),
	 @contSalut			NVARCHAR (50),
	 @contAddressee		NVARCHAR (50),
	 @contTitle			NVARCHAR (10),
	 @contFirstNames	NVARCHAR (50),
	 @contSurname		NVARCHAR (60),
	 @contSex			NCHAR (1),
	 @contEmail			NVARCHAR (200),
	 @contTelHome		NVARCHAR (30),
	 @contTelWork		NVARCHAR (30),
	 @contTelMob		NVARCHAR (30),
	 @contFAX			NVARCHAR (30),
     @brID				INT,
	 @contSubType		NVARCHAR (15),
	 @IsClient			NVARCHAR (15),
	 @StatusID			TINYINT,
	 @Importerror		INT, 
	 @Importerrormsg	VARCHAR(2000),
	 @dbContactID1		BIGINT,
	 @dbclno  NVARCHAR (12)

	DECLARE @RowID AS INT
	SET @RowID = 0

	WHILE	EXISTS ( 
				 SELECT TOP 1
                        1
                 FROM   [dbo].[ClientContactStage]
                 WHERE  [ID] > @RowID 
                 AND StatusID IN (0,1)
                 ORDER BY [ID]
                 )

	BEGIN

		SET @Importerror = 0;
		SET @Importerrormsg = ''
		SET @dbContactID1=NULL

	SELECT TOP 1
	 @ID			= ID,
	 @clName		= clName,
	 @clType		= clType,
	 @clNo			= clNo,
	 @cbocligrp		= cbocligrp,
	 @cbopartner    = cbopartner,
	 @addid			= addid,
	 @addLine1		= addLine1,
	 @addLine2		= addLine2,
	 @addLine3		= addLine3,
	 @addLine4		= addLine4,
	 @addLine5		= addLine5,
	 @addPostCode   = addPostCode,
	 @addCountry    = addCountry,
	 @addDXCode     = addDXCode,
	 @contSalut		= contSalut,
	 @contAddressee	= contAddressee,
	 @contTitle     = contTitle,
	 @contFirstNames = contFirstNames,
	 @contSurname   = contSurname ,
	 @contSex		= contSex,
	 @contEmail		= contEmail,
	 @contTelHome   = contTelHome ,
	 @contTelWork   = contTelWork ,
	 @contTelMob    = contTelMob,
	 @contFAX		= contFAX,
     @brID			= brID,
	 @contSubType   = contSubType ,
	 @IsClient		= IsClient,
	 @StatusID      = StatusID,
	 @Importerror   = error , 
	 @Importerrormsg = errormsg 
	 

	FROM dbo.ClientContactStage
	WHERE ID > @RowID
	AND StatusID IN (0,1)
	ORDER BY ID

	PRINT 'Run Clients to Mattersphere: ' + CONVERT(VARCHAR(20),@ID)

	EXEC [dbo].RunMSClient 
		@clName ,
	    @clType,
	    @clNo,
	    @cbocligrp,
	    @cbopartner,
	    @addid ,
	    @addLine1 ,
	    @addLine2 ,
	    @addLine3 ,
	    @addLine4 ,
	    @addLine5 ,
	    @addPostCode,
	    @addCountry ,
	    @addDXCode ,
	    @contSalut ,
	    @contAddressee,
	    @contTitle ,
	    @contFirstNames,
	    @contSurname ,
	    @contSex ,
	    @contEmail, 
	    @contTelHome ,
	    @contTelWork,
	    @contTelMob ,
	    @contFAX ,
	    @brID ,
	    @contSubType ,
	    @IsClient ,
	    @dbContactID1 OUTPUT,
	    @dbclno OUTPUT,
	    @Importerror OUTPUT,
	    @Importerrormsg OUTPUT
	

	UPDATE dbo.ClientContactStage
	SET error = ISNULL(@Importerror,0),
		errormsg = @Importerrormsg,
		NewContactID = @dbContactID1,
		NewClientID = @dbclno,
		StatusID = CASE 
					WHEN ISNULL(@Importerror,0) = 0  AND @StatusID=0 THEN 2		-- Success New Client Insert
					WHEN ISNULL(@Importerror,0) = 0  AND @StatusID=1 THEN 3		-- Sucess Update Client
					WHEN ISNULL(@Importerror,0) <> 0  AND @StatusID=0 THEN 4	-- Failed New Client Insert
					WHEN ISNULL(@Importerror,0) <> 0  AND @StatusID=1 THEN 5	-- Failed Update Client
					ELSE 9
					
				END,
		Imported=CASE WHEN ISNULL(@Importerror,0) = 0 THEN GETDATE() ELSE NULL END 
		WHERE ID=@ID
	--PRINT @Importerror
	--Insert into success table and delete from stage table
	IF ISNULL(@Importerror,0) = 0  
	BEGIN

	INSERT INTO dbo.ClientImportSuccess
	        ( ID, extContID, clNo, clName, clType, cbocligrp, cbopartner,
	          addid, addLine1, addLine2, addLine3, addLine4, addLine5,
	          addPostCode, addCountry, addDXCode, contType, contSalut, contTitle,
	          contFirstNames, contSurname, contSex, contNotes, contCreated, contEmail,
	          contTelHome, contTelWork, contTelMob, contFAX,
	          brID, contSubType, InsertDate,
	          Imported, StatusID, error, errormsg, IsClient, NewClientID,NewContactID
	        )
	SELECT
			  ID, extContID, clNo, clName, clType, cbocligrp, cbopartner,
	          addid, addLine1, addLine2, addLine3, addLine4, addLine5,
	          addPostCode, addCountry, addDXCode, contType, contSalut, contTitle,
	          contFirstNames, contSurname, contSex, contNotes, contCreated, contEmail,
	          contTelHome, contTelWork, contTelMob, contFAX, brID, contSubType, InsertDate,
	          Imported, StatusID, error, errormsg, IsClient, NewClientID,NewContactID			  
			  FROM dbo.ClientContactStage 
			  WHERE ID = @ID
	
	DELETE FROM dbo.ClientContactStage WHERE ID = @ID
	END

	--Insert into failure table and leave in stage table so that the value can be fixed and the process call it again
	IF ISNULL(@Importerror,0) <> 0  
	BEGIN
	INSERT INTO dbo.ClientImportFailure
	        ( ID, extContID, clNo, clName, clType, cbocligrp, cbopartner,
	          addid, addLine1, addLine2, addLine3, addLine4, addLine5,
	          addPostCode, addCountry, addDXCode, contType, contSalut, contTitle,
	          contFirstNames, contSurname, contSex, contNotes, contCreated, contEmail,
	          contTelHome, contTelWork, contTelMob, contFAX,brID, contSubType, InsertDate,
	          Imported, StatusID, error, errormsg, IsClient, NewClientID,NewContactID
	        )
	SELECT
			  ID, extContID, clNo, clName, clType, cbocligrp, cbopartner,
	          addid, addLine1, addLine2, addLine3, addLine4, addLine5,
	          addPostCode, addCountry, addDXCode, contType, contSalut, contTitle,
	          contFirstNames, contSurname, contSex, contNotes, contCreated, contEmail,
	          contTelHome, contTelWork, contTelMob, contFAX,brID, contSubType, InsertDate,
	          Imported, StatusID, error, errormsg, IsClient, NewClientID,NewContactID		  
			  FROM dbo.ClientContactStage 
			  WHERE ID = @ID

 END

 END
GO
