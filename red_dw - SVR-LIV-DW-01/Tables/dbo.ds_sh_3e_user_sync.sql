CREATE TABLE [dbo].[ds_sh_3e_user_sync]
(
[timekeeperindex] [int] NULL,
[Entity] [int] NULL,
[TRE_user] [char] (36) COLLATE Latin1_General_BIN NULL,
[payrollid] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[firstname] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[surname] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[knownas] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[name] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[DOB] [datetime] NULL,
[prefix] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[gender] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[email] [nvarchar] (320) COLLATE Latin1_General_BIN NULL,
[phonenumber] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[username] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[startdate] [datetime] NULL,
[office] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[officename] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[address] [int] NULL,
[sitetype] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[businessline] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[team] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[jobrole] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[hrtitle] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[payrollid_BCM] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[ratetype] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[defaultrate] [int] NULL,
[tkrtype] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[userstatusid] [int] NULL,
[userstatus] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[leaverdate] [datetime] NULL,
[rate_class] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[dss_create_time] [datetime] NULL,
[dss_update_time] [datetime] NULL,
[effstart] [datetime] NULL,
[employeeid] [char] (36) COLLATE Latin1_General_BIN NULL,
[ms_usrid] [int] NULL
) ON [DS_TAB]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[TSUINSdbods_sh_3e_user_sync_SSIS] ON [dbo].[ds_sh_3e_user_sync] FOR insert AS

BEGIN
  /*************************************************
  INTAPP TRIGGER -- DO NOT MODIFY!
  This trigger was generated automatically by
  Integration Builder. Do not edit or
  modify this trigger in any way. Modifying or
  removing this trigger will result in
  rule(s) no longer operating correctly.
  Copyright 2010 IntApp, Inc.

  <events>
    <event id="22" app_id="3921" version="4.9.2" app_name="intapp" created="Mon Mar 25 03:51:18 PDT 2019">
      <filter />
    </event>
  </events>

  *************************************************/
  SET NOCOUNT ON
    DECLARE @paramone VARCHAR(50)
    DECLARE @detectBiDir INT
    DECLARE @historyField VARCHAR(255)
    DECLARE @uniqueID VARCHAR(50)
    DECLARE @data NVARCHAR(20)
    DECLARE @newMax INT

	/*All Fields within ds_sh_3e_user_sync - POST Indicating newly inserted value. */
    DECLARE @timekeeperindex_POST INT 
    DECLARE @Entity_POST INT
    DECLARE @TRE_user_POST CHAR (36)
    DECLARE @payrollid_POST NVARCHAR(50) 
    DECLARE @firstname_POST NVARCHAR(50)
    DECLARE @surname_POST NVARCHAR(50) 
    DECLARE @knownas_POST NVARCHAR(50) 
    DECLARE @name_POST NVARCHAR(50) 
	DECLARE @DOB_POST DATETIME
	DECLARE @prefix_POST NVARCHAR(50)
	DECLARE @gender_POST VARCHAR(6)
	DECLARE @email_POST NVARCHAR(320) 
	DECLARE @phonenumber_POST NVARCHAR(50)
	DECLARE @username_POST NVARCHAR(50) 
	DECLARE @startdate_POST DATETIME 
	DECLARE @office_POST NVARCHAR(16)
	DECLARE @officename_POST NVARCHAR(50)
	DECLARE @address_POST INT
	DECLARE @sitetype_POST NVARCHAR(16) 
	DECLARE @businessline_POST NVARCHAR(16)
	DECLARE @team_POST NVARCHAR(16) 
	DECLARE @jobrole_POST NVARCHAR(16) 
	DECLARE @hrtitle_POST NVARCHAR(100) 
	DECLARE @payrollid_BCM_POST NVARCHAR(50) 
	DECLARE @ratetype_POST VARCHAR (6) 
	DECLARE @defaultrate_POST INT 
	DECLARE @tkrtype_POST NVARCHAR(50) 
	DECLARE @userstatusid_POST INT
	DECLARE @userstatus_POST VARCHAR(8) 
	DECLARE @leaverdate_POST DATETIME 
	DECLARE @rate_class_POST VARCHAR(16) 
	DECLARE @effstart_POST DATETIME 
	DECLARE @employeeid_POST CHAR(36) 
	DECLARE @ms_usrid_POST INT



  /*BODY:3921_22*/
  SET @historyField = ''
  SELECT @detectBiDir = MIN(RID) FROM dbo.tsu_insert WHERE TableID = 48625
  IF @detectBiDir IS NOT NULL
  BEGIN
    SELECT @historyField = History FROM dbo.tsu_insert WHERE RID=@detectBiDir
  END
  DECLARE insert_cursor_4000_01 
  CURSOR FOR SELECT 
   INSERTED."timekeeperindex"
  ,INSERTED."Entity"
  ,INSERTED."TRE_user"
  ,INSERTED."payrollid"
  ,INSERTED."firstname"
  ,INSERTED."surname"
  ,INSERTED."knownas"
  ,INSERTED."name"
  ,CONVERT(VARCHAR,INSERTED."DOB", 121)
  ,INSERTED."prefix"
  ,INSERTED."gender"
  ,INSERTED."email"
  ,INSERTED."phonenumber" 
  ,INSERTED."username"
  ,CONVERT(VARCHAR,INSERTED."startdate", 121)
  ,INSERTED."office"
  ,INSERTED."officename"
  ,INSERTED."address"
  ,INSERTED."sitetype"
  ,INSERTED."businessline"
  ,INSERTED."team"   
  ,INSERTED."jobrole"
  ,INSERTED."hrtitle"
  ,INSERTED."payrollid_BCM"
  ,INSERTED."ratetype"
  ,INSERTED."defaultrate"
  ,INSERTED."tkrtype"
  ,INSERTED."userstatusid"
  ,INSERTED."userstatus"
  ,CONVERT(VARCHAR, INSERTED."leaverdate", 121)
  ,INSERTED."rate_class" 
  ,CONVERT(VARCHAR,INSERTED."effstart", 121)
  ,INSERTED."employeeid"
  ,INSERTED."ms_usrid"
  
  FROM INSERTED
  OPEN insert_cursor_4000_01
  FETCH NEXT FROM insert_cursor_4000_01 INTO       
   @timekeeperindex_POST  
  ,@Entity_POST   
  ,@TRE_user_POST       
  ,@payrollid_POST   
  ,@firstname_POST 
  ,@surname_POST 
  ,@knownas_POST  
  ,@name_POST 
  ,@DOB_POST    
  ,@prefix_POST   
  ,@gender_POST    
  ,@email_POST  
  ,@phonenumber_POST     
  ,@username_POST    
  ,@startdate_POST       
  ,@office_POST    
  ,@officename_POST    
  ,@address_POST            
  ,@sitetype_POST  
  ,@businessline_POST 
  ,@team_POST 
  ,@jobrole_POST    
  ,@hrtitle_POST 
  ,@payrollid_BCM_POST          
  ,@ratetype_POST  
  ,@defaultrate_POST 
  ,@tkrtype_POST 
  ,@userstatusid_POST 
  ,@userstatus_POST 
  ,@leaverdate_POST 
  ,@rate_class_POST 
  ,@effstart_POST 
  ,@employeeid_POST 
  ,@ms_usrid_POST 



  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SELECT @newMax = MAX(RID) FROM dbo.tsu_insert;

  SET TRANSACTION ISOLATION LEVEL READ COMMITTED
  IF @newMax IS NULL SET @newMax = 1 ELSE SET @newMax  = @newMax + 1
  WHILE (@@FETCH_STATUS <> -1)
  BEGIN
    IF (@@FETCH_STATUS <> -2)
    BEGIN
      SET @uniqueID = NEWID()
	  SET @data = 'INSERT'
	  SET @timekeeperindex_POST     =  @timekeeperindex_POST 
      SET @Entity_POST   			=  @Entity_POST   		 
      SET @TRE_user_POST       		=  @TRE_user_POST         
      SET @payrollid_POST   		=  @payrollid_POST   	  
      SET @firstname_POST 			=  @firstname_POST 		  
      SET @surname_POST 			=  @surname_POST 		 
      SET @knownas_POST  			=  @knownas_POST  		 
      SET @name_POST 				=  @name_POST 			 
      SET @DOB_POST    				=  @DOB_POST    		 
      SET @prefix_POST   			=  ISNULL(@prefix_POST, ':n' ) 		 
      SET @gender_POST    			=  ISNULL(@gender_POST , ':n')   		  
      SET @email_POST  				=  @email_POST  		 
      SET @phonenumber_POST     	=  ISNULL(@phonenumber_POST , '0')     
      SET @username_POST    		=  @username_POST    	  
      SET @startdate_POST       	=  @startdate_POST        
      SET @office_POST    			=  @office_POST    		  
      SET @officename_POST    		=  @officename_POST    	  
      SET @address_POST            	=  @address_POST            
      SET @sitetype_POST  			=  @sitetype_POST  		  
      SET @businessline_POST 		=  @businessline_POST 	 
      SET @team_POST 				=  @team_POST 			 
      SET @jobrole_POST    			=  @jobrole_POST    	 
      SET @hrtitle_POST 			=  @hrtitle_POST 		 
      SET @payrollid_BCM_POST       =  @payrollid_BCM_POST         
      SET @ratetype_POST  			=  @ratetype_POST  		  
      SET @defaultrate_POST 		=  @defaultrate_POST 	 
      SET @tkrtype_POST 			=  @tkrtype_POST 		 
      SET @userstatusid_POST 		=  @userstatusid_POST 	 
      SET @userstatus_POST 			=  @userstatus_POST 	 
      SET @leaverdate_POST 			=  ISNULL(@leaverdate_POST, '1900-01-01 00:00:00.000')
      SET @rate_class_POST 			=  @rate_class_POST 	 
      SET @effstart_POST 			=  @effstart_POST 		 
      SET @employeeid_POST 			=  @employeeid_POST 	 
      SET @ms_usrid_POST 			=  @ms_usrid_POST 		 


      INSERT INTO dbo.tsu_insert (RID, TransID, Data, History, timekeeperindex_POST ,Entity_POST ,TRE_user_POST ,payrollid_POST ,firstname_POST ,surname_POST ,knownas_POST,name_POST ,DOB_POST ,prefix_POST   		,gender_POST    		,email_POST  			,phonenumber_POST     ,username_POST    	,startdate_POST       ,office_POST    		,officename_POST    	,address_POST         ,sitetype_POST  		,businessline_POST 	,team_POST 			,jobrole_POST    		,hrtitle_POST 		,payrollid_BCM_POST   ,ratetype_POST  		,defaultrate_POST 	,tkrtype_POST 		,userstatusid_POST 	,userstatus_POST 		,leaverdate_POST 		,rate_class_POST 		,effstart_POST 		,employeeid_POST 		,ms_usrid_POST 		
	  
	  ) 
	  
	  VALUES (
	  @newMax, @uniqueID, @data, @historyField, @timekeeperindex_POST ,@Entity_POST,@TRE_user_POST,@payrollid_POST,@firstname_POST ,@surname_POST ,@knownas_POST ,@name_POST ,@DOB_POST ,@prefix_POST   		,@gender_POST    		,@email_POST  			,@phonenumber_POST     ,@username_POST    	,@startdate_POST       ,@office_POST    		,@officename_POST    	,@address_POST         ,@sitetype_POST  		,@businessline_POST 	,@team_POST 			,@jobrole_POST    		,@hrtitle_POST 		,@payrollid_BCM_POST   ,@ratetype_POST  		,@defaultrate_POST 	,@tkrtype_POST 		,@userstatusid_POST 	,@userstatus_POST 		,@leaverdate_POST 		,@rate_class_POST 		,@effstart_POST 		,@employeeid_POST 		,@ms_usrid_POST 		
	  
	  )

    SET @newMax = @newMax + 1
    END
    FETCH NEXT FROM insert_cursor_4000_01 INTO    @timekeeperindex_POST  
  ,@Entity_POST   
  ,@TRE_user_POST       
  ,@payrollid_POST   
  ,@firstname_POST 
  ,@surname_POST 
  ,@knownas_POST  
  ,@name_POST 
  ,@DOB_POST    
  ,@prefix_POST   
  ,@gender_POST    
  ,@email_POST  
  ,@phonenumber_POST     
  ,@username_POST    
  ,@startdate_POST       
  ,@office_POST    
  ,@officename_POST    
  ,@address_POST            
  ,@sitetype_POST  
  ,@businessline_POST 
  ,@team_POST 
  ,@jobrole_POST    
  ,@hrtitle_POST 
  ,@payrollid_BCM_POST          
  ,@ratetype_POST  
  ,@defaultrate_POST 
  ,@tkrtype_POST 
  ,@userstatusid_POST 
  ,@userstatus_POST 
  ,@leaverdate_POST 
  ,@rate_class_POST 
  ,@effstart_POST 
  ,@employeeid_POST 
  ,@ms_usrid_POST 	
  END
  CLOSE insert_cursor_4000_01
  DEALLOCATE insert_cursor_4000_01
  /*BODY*/

  SET NOCOUNT OFF
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[TSUUPDdbods_sh_3e_user_sync_SSIS] ON [dbo].[ds_sh_3e_user_sync] FOR update AS
IF UPDATE("DOB") OR UPDATE("Entity") OR UPDATE("TRE_user") OR UPDATE("address") OR UPDATE("businessline") OR UPDATE("defaultrate") OR UPDATE("dss_update_time") OR UPDATE("email") OR UPDATE("firstname") OR UPDATE("gender") OR UPDATE("hrtitle") OR UPDATE("jobrole") OR UPDATE("knownas") OR UPDATE("leaverdate") OR UPDATE("name") OR UPDATE("office") OR UPDATE("officename") OR UPDATE("payrollid") OR UPDATE("payrollid_BCM") OR UPDATE("phonenumber") OR UPDATE("prefix") OR UPDATE("rate_class") OR UPDATE("ratetype") OR UPDATE("sitetype") OR UPDATE("startdate") OR UPDATE("surname") OR UPDATE("team") OR UPDATE("timekeeperindex") OR UPDATE("tkrtype") OR UPDATE("username") OR UPDATE("userstatus") OR UPDATE("userstatusid") 
BEGIN
SET NOCOUNT ON
  /*************************************************
 
		Disabled and replaced with [TSUUPDdbods_sh_3e_user_sync_SSIS_new] as was causing issues with  RED 

		All code commented out incase this trigger is reenabled again.


  
  DECLARE @paramone VARCHAR(50)
  DECLARE @detectBiDir INT
  DECLARE @historyField VARCHAR(255)
  DECLARE @uniqueID VARCHAR(50)
  DECLARE @data NVARCHAR(20)
  DECLARE @newMax INT

  /*DECLARE:3921_23*/
  DECLARE @timekeeperindex_PRE      INT
  DECLARE @Entity_PRE               INT
  DECLARE @payrollid_PRE            NVARCHAR(50)
  DECLARE @firstname_PRE            NVARCHAR(50)
  DECLARE @surname_PRE              NVARCHAR(50)
  DECLARE @knownas_PRE              NVARCHAR(50)
  DECLARE @name_PRE                 NVARCHAR(50)
  DECLARE @DOB_PRE                  DATETIME
  DECLARE @prefix_PRE               NVARCHAR(50)
  DECLARE @gender_PRE               VARCHAR(6)
  DECLARE @email_PRE                NVARCHAR(320)
  DECLARE @phonenumber_PRE          NVARCHAR(50)
  DECLARE @username_PRE				NVARCHAR(50)
  DECLARE @startdate_PRE		    DATETIME
  DECLARE @office_PRE				NVARCHAR(16)
  DECLARE @officename_PRE			NVARCHAR(50)
  DECLARE @businessline_PRE			NVARCHAR(16)
  DECLARE @team_PRE					NVARCHAR(16)
  DECLARE @jobrole_PRE				NVARCHAR(16)
  DECLARE @hrtitle_PRE				NVARCHAR(100)
  DECLARE @payrollid_BCM_PRE	    NVARCHAR(50)
  DECLARE @ratetype_PRE				VARCHAR(6)
  DECLARE @defaultrate_PRE			INT
  DECLARE @tkrtype_PRE				NVARCHAR(50)
  DECLARE @userstatusid_PRE			INT
  DECLARE @userstatus_PRE			VARCHAR(8)
  DECLARE @leaverdate_PRE			DATETIME
  DECLARE @dss_update_time_PRE		DATETIME
  DECLARE @sitetype_PRE				NVARCHAR(16)
  DECLARE @address_PRE				INT
  DECLARE @TRE_user_PRE				CHAR(36)
  DECLARE @rate_class_PRE			VARCHAR(16)
  DECLARE @timekeeperindex_POST		INT
  DECLARE @Entity_POST				INT
  DECLARE @payrollid_POST			NVARCHAR(50)
  DECLARE @firstname_POST			NVARCHAR(50)
  DECLARE @surname_POST				NVARCHAR(50)
  DECLARE @knownas_POST				NVARCHAR(50)
  DECLARE @name_POST				NVARCHAR(50)
  DECLARE @DOB_POST					DATETIME
  DECLARE @prefix_POST				NVARCHAR(50)
  DECLARE @gender_POST				VARCHAR(6)
  DECLARE @email_POST				NVARCHAR(320)
  DECLARE @phonenumber_POST			NVARCHAR(50)
  DECLARE @username_POST			NVARCHAR(50)
  DECLARE @startdate_POST			DATETIME
  DECLARE @office_POST				NVARCHAR(16)
  DECLARE @officename_POST			NVARCHAR(50)
  DECLARE @businessline_POST		NVARCHAR(16)
  DECLARE @team_POST				NVARCHAR(16)
  DECLARE @jobrole_POST				NVARCHAR(16)
  DECLARE @hrtitle_POST				NVARCHAR(100)
  DECLARE @payrollid_BCM_POST		NVARCHAR(50)
  DECLARE @ratetype_POST			VARCHAR(6)
  DECLARE @defaultrate_POST			INT      
  DECLARE @tkrtype_POST				NVARCHAR(50)
  DECLARE @userstatusid_POST		INT
  DECLARE @userstatus_POST			VARCHAR(8)             
  DECLARE @leaverdate_POST			DATETIME
  DECLARE @dss_update_time_POST     DATETIME                                     
  DECLARE @sitetype_POST			NVARCHAR(16)
  DECLARE @address_POST				INT
  DECLARE @TRE_user_POST			CHAR(36)
  DECLARE @rate_class_POST			VARCHAR(16)
  DECLARE @effstart_PRE             DATETIME
  DECLARE @effstart_POST            DATETIME
  DECLARE @employeeid_PRE           CHAR(36)
  DECLARE @employeeid_POST          CHAR(36)
  DECLARE @ms_usrid_PRE             INT
  DECLARE @ms_usrid_POST            INT

  /*DECLARE*/

  /*BODY:3921_23*/
  SET @historyField = ''
  SELECT MIN(RID) FROM dbo.tsu_update WHERE TableID = 48625
  IF @detectBiDir IS NOT NULL
  BEGIN
    SELECT @historyField = History FROM dbo.tsu_update WHERE RID=@detectBiDir
  END

  DECLARE update_cursor_4000_02 CURSOR FOR SELECT DELETED."timekeeperindex",DELETED."Entity",DELETED."payrollid",DELETED."firstname",DELETED."surname",DELETED."knownas",DELETED."name",try_CONVERT(VARCHAR, DELETED."DOB", 121),DELETED."prefix",DELETED."gender",DELETED."email",DELETED."phonenumber",DELETED."username",try_CONVERT(VARCHAR, DELETED."startdate", 121),DELETED."office",DELETED."officename",DELETED."businessline",DELETED."team",DELETED."jobrole",DELETED."hrtitle",DELETED."payrollid_BCM",DELETED."ratetype",DELETED."defaultrate",DELETED."tkrtype",DELETED."userstatusid",DELETED."userstatus",try_CONVERT(VARCHAR, DELETED."leaverdate", 121),try_CONVERT(VARCHAR, DELETED."dss_update_time", 121),DELETED."sitetype",DELETED."address",DELETED."TRE_user",DELETED."rate_class", DELETED."effstart", DELETED."employeeid" , DELETED."ms_usrid"    ,INSERTED."timekeeperindex",INSERTED."Entity",INSERTED."payrollid",INSERTED."firstname",INSERTED."surname",INSERTED."knownas",INSERTED."name",try_CONVERT(VARCHAR, INSERTED."DOB", 121),INSERTED."prefix",INSERTED."gender",INSERTED."email",INSERTED."phonenumber",INSERTED."username",try_CONVERT(VARCHAR, INSERTED."startdate", 121),INSERTED."office",INSERTED."officename",INSERTED."businessline",INSERTED."team",INSERTED."jobrole",INSERTED."hrtitle",INSERTED."payrollid_BCM",INSERTED."ratetype",INSERTED."defaultrate",INSERTED."tkrtype",INSERTED."userstatusid",INSERTED."userstatus",try_CONVERT(VARCHAR, INSERTED."leaverdate", 121),try_CONVERT(VARCHAR, INSERTED."dss_update_time", 121),INSERTED."sitetype",INSERTED."address",INSERTED."TRE_user",INSERTED."rate_class", INSERTED."effstart", INSERTED."employeeid" , INSERTED."ms_usrid" FROM DELETED, INSERTED WHERE DELETED."payrollid"=INSERTED."payrollid" 
  OPEN update_cursor_4000_02
  FETCH NEXT FROM update_cursor_4000_02 INTO		@timekeeperindex_PRE,@Entity_PRE,@payrollid_PRE,			@firstname_PRE,		@surname_PRE,@knownas_PRE,@name_PRE,@DOB_PRE,@prefix_PRE,@gender_PRE,                                                                                  @email_PRE,@phonenumber_PRE ,@username_PRE                             ,@startdate_PRE,  @office_PRE         ,@officename_PRE,     @businessline_PRE ,      @team_PRE,     @jobrole_PRE,   @hrtitle_PRE,        @payrollid_BCM_PRE,      @ratetype_PRE,  @defaultrate_PRE , @tkrtype_PRE,  @userstatusid_PRE,  @userstatus_PRE ,@leaverdate_PRE, @dss_update_time_PRE,                                                               @sitetype_PRE      ,@address_PRE,         @TRE_user_PRE,  @rate_class_PRE ,  @effstart_PRE, @employeeid_PRE, @ms_usrid_PRE,         @timekeeperindex_POST,            @Entity_POST,  @payrollid_POST,    @firstname_POST,        @surname_POST  ,@knownas_POST,        @name_POST,   @DOB_POST,                            @prefix_POST        ,@gender_POST,   @email_POST ,        @phonenumber_POST      ,@username_POST,            @startdate_POST              ,@office_POST,           @officename_POST,          @businessline_POST,@team_POST,@jobrole_POST,     @hrtitle_POST     ,@payrollid_BCM_POST,     @ratetype_POST,@defaultrate_POST           ,@tkrtype_POST   ,@userstatusid_POST  , @userstatus_POST                    ,@leaverdate_POST,@dss_update_time_POST                                          ,@sitetype_POST,         @address_POST,@TRE_user_POST,   @rate_class_POST, @effstart_POST, @employeeid_POST, @ms_usrid_POST
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SELECT @newMax = MAX(RID) FROM dbo.tsu_update
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED
  IF @newMax IS NULL SET @newMax = 1 ELSE SET @newMax  = @newMax + 1

  WHILE (@@FETCH_STATUS <> -1)
  BEGIN
    IF (@@FETCH_STATUS <> -2)
    BEGIN
	 
      SET @data = 'UPDATE'
      SET @uniqueID = NEWID()
      SET @timekeeperindex_PRE  =  @timekeeperindex_PRE
      SET @Entity_PRE           =  @Entity_PRE         
      SET @payrollid_PRE        =  @payrollid_PRE      
      SET @firstname_PRE        =  @firstname_PRE      
      SET @surname_PRE          =  @surname_PRE        
      SET @knownas_PRE          =  @knownas_PRE        
      SET @name_PRE             =  @name_PRE           
      SET @DOB_PRE              =  @DOB_PRE            
      SET @prefix_PRE           =  ISNULL(@prefix_PRE , ':n')        
      SET @gender_PRE           =  @gender_PRE         
      SET @email_PRE            =  @email_PRE          
      SET @phonenumber_PRE      =  ISNULL(@phonenumber_PRE  , '0')  
      SET @username_PRE			=  @username_PRE		 
      SET @startdate_PRE		=  @startdate_PRE		
      SET @office_PRE			=  @office_PRE			
      SET @officename_PRE		=  @officename_PRE		
      SET @businessline_PRE		=  @businessline_PRE	
      SET @team_PRE				=  @team_PRE			
      SET @jobrole_PRE			=  @jobrole_PRE			
      SET @hrtitle_PRE			=  @hrtitle_PRE			
      SET @payrollid_BCM_PRE	=  @payrollid_BCM_PRE	
      SET @ratetype_PRE			=  @ratetype_PRE		
      SET @defaultrate_PRE		=  @defaultrate_PRE		
      SET @tkrtype_PRE			=  @tkrtype_PRE			
      SET @userstatusid_PRE		=  @userstatusid_PRE	
      SET @userstatus_PRE		=  @userstatus_PRE		
      SET @leaverdate_PRE		=  @leaverdate_PRE	
      SET @dss_update_time_PRE	=  @dss_update_time_PRE
      SET @sitetype_PRE			=  @sitetype_PRE		
      SET @address_PRE			=  @address_PRE			
      SET @TRE_user_PRE			=  @TRE_user_PRE		
      SET @rate_class_PRE		=  @rate_class_PRE		
      SET @timekeeperindex_POST	=  @timekeeperindex_POST
      SET @Entity_POST			=  @Entity_POST			
      SET @payrollid_POST		=  @payrollid_POST		
      SET @firstname_POST		=  @firstname_POST		
      SET @surname_POST			=  @surname_POST		
      SET @knownas_POST			=  @knownas_POST		
      SET @name_POST			=  @name_POST			
      SET @DOB_POST				=  @DOB_POST			
      SET @prefix_POST			=  ISNULL(@prefix_POST	, ':n')		
      SET @gender_POST			=  @gender_POST			
      SET @email_POST			=  @email_POST			
      SET @phonenumber_POST		=  ISNULL(@phonenumber_POST	, '0')
      SET @username_POST		=  @username_POST		
      SET @startdate_POST		=  @startdate_POST		
      SET @office_POST			=  @office_POST			
      SET @officename_POST		=  @officename_POST		
      SET @businessline_POST	=  @businessline_POST	
      SET @team_POST			=  @team_POST			
      SET @jobrole_POST			=  @jobrole_POST		
      SET @hrtitle_POST			=  @hrtitle_POST		
      SET @payrollid_BCM_POST	=  @payrollid_BCM_POST	
      SET @ratetype_POST		=  @ratetype_POST		
      SET @defaultrate_POST		=  @defaultrate_POST	
      SET @tkrtype_POST			=  @tkrtype_POST		
      SET @userstatusid_POST	=  @userstatusid_POST	
      SET @userstatus_POST		=  @userstatus_POST		
      SET @leaverdate_POST		=  @leaverdate_POST		
      SET @dss_update_time_POST =  @dss_update_time_POST
      SET @sitetype_POST		=  @sitetype_POST		
      SET @address_POST			=  @address_POST		
      SET @TRE_user_POST		=  @TRE_user_POST		
      SET @rate_class_POST		=  @rate_class_POST	
	  SET @effstart_PRE         =  ISNULL(@effstart_PRE, '1900-01-01 00:00:00.000')
	  SET @effstart_POST        =  ISNULL(@effstart_POST, '1900-01-01 00:00:00.000')
	  SET @employeeid_PRE       =  @employeeid_PRE 
	  SET @employeeid_POST      =  @employeeid_POST 
	  SET @ms_usrid_PRE         =  @ms_usrid_PRE      
	  SET @ms_usrid_POST        =  @ms_usrid_POST 


	 

      INSERT INTO dbo.tsu_update (RID, TransID, Data, History,timekeeperindex_PRE,Entity_PRE,payrollid_PRE,firstname_PRE,surname_PRE,knownas_PRE,name_PRE,DOB_PRE,prefix_PRE,gender_PRE,email_PRE,phonenumber_PRE,username_PRE,startdate_PRE,office_PRE,officename_PRE,businessline_PRE,team_PRE,jobrole_PRE,hrtitle_PRE,payrollid_BCM_PRE,ratetype_PRE,defaultrate_PRE,tkrtype_PRE,userstatusid_PRE,userstatus_PRE,leaverdate_PRE,dss_update_time_PRE,sitetype_PRE,address_PRE,TRE_user_PRE,rate_class_PRE,timekeeperindex_POST,Entity_POST,payrollid_POST,firstname_POST,surname_POST,knownas_POST,name_POST,DOB_POST,prefix_POST,gender_POST,email_POST,phonenumber_POST,username_POST,startdate_POST,office_POST,officename_POST,businessline_POST,team_POST,jobrole_POST,hrtitle_POST,payrollid_BCM_POST,ratetype_POST,defaultrate_POST,tkrtype_POST,userstatusid_POST,userstatus_POST,leaverdate_POST,dss_update_time_POST,sitetype_POST,address_POST,TRE_user_POST,rate_class_POST, effstart_PRE, effstart_POST, employeeid_PRE, employeeid_POST, ms_usrid_PRE, ms_usrid_POST  ) 
	  VALUES (@newMax, @uniqueID, @data, @historyField,@timekeeperindex_PRE  ,@Entity_PRE           ,@payrollid_PRE        ,@firstname_PRE        ,@surname_PRE          ,@knownas_PRE          ,@name_PRE             ,@DOB_PRE              ,@prefix_PRE           ,@gender_PRE           ,@email_PRE            ,@phonenumber_PRE      ,@username_PRE			,@startdate_PRE		,@office_PRE			,@officename_PRE		,@businessline_PRE		,@team_PRE				,@jobrole_PRE			,@hrtitle_PRE			,@payrollid_BCM_PRE	,@ratetype_PRE			,@defaultrate_PRE		,@tkrtype_PRE			,@userstatusid_PRE		,@userstatus_PRE		,@leaverdate_PRE		,@dss_update_time_PRE	,@sitetype_PRE			,@address_PRE			,@TRE_user_PRE			,@rate_class_PRE		,@timekeeperindex_POST	,@Entity_POST			,@payrollid_POST		,@firstname_POST		,@surname_POST			,@knownas_POST			,@name_POST			,@DOB_POST				,@prefix_POST			,@gender_POST			,@email_POST			,@phonenumber_POST		,@username_POST		,@startdate_POST		,@office_POST			,@officename_POST		,@businessline_POST	,@team_POST			,@jobrole_POST			,@hrtitle_POST			,@payrollid_BCM_POST	,@ratetype_POST		,@defaultrate_POST		,@tkrtype_POST			,@userstatusid_POST	,@userstatus_POST		,@leaverdate_POST		,@dss_update_time_POST ,@sitetype_POST		,@address_POST			,@TRE_user_POST		,@rate_class_POST	, @effstart_PRE, @effstart_POST, @employeeid_PRE, @employeeid_POST, @ms_usrid_PRE, @ms_usrid_POST   	)

      SET @newMax = @newMax + 1
    END

	  PRINT 'begin fetch'


    FETCH NEXT FROM update_cursor_4000_02 INTO @timekeeperindex_PRE,@Entity_PRE,@payrollid_PRE,			@firstname_PRE,		@surname_PRE,@knownas_PRE,@name_PRE,@DOB_PRE,@prefix_PRE,@gender_PRE,                                                                                  @email_PRE,@phonenumber_PRE ,@username_PRE                             ,@startdate_PRE,  @office_PRE         ,@officename_PRE,     @businessline_PRE ,      @team_PRE,     @jobrole_PRE,   @hrtitle_PRE,        @payrollid_BCM_PRE,      @ratetype_PRE,  @defaultrate_PRE , @tkrtype_PRE,  @userstatusid_PRE,  @userstatus_PRE ,@leaverdate_PRE, @dss_update_time_PRE,                                                               @sitetype_PRE      ,@address_PRE,         @TRE_user_PRE,  @rate_class_PRE ,  @effstart_PRE, @employeeid_PRE, @ms_usrid_PRE,         @timekeeperindex_POST,            @Entity_POST,  @payrollid_POST,    @firstname_POST,        @surname_POST  ,@knownas_POST,        @name_POST,   @DOB_POST,                            @prefix_POST        ,@gender_POST,   @email_POST ,        @phonenumber_POST      ,@username_POST,            @startdate_POST              ,@office_POST,           @officename_POST,          @businessline_POST,@team_POST,@jobrole_POST,     @hrtitle_POST     ,@payrollid_BCM_POST,     @ratetype_POST,@defaultrate_POST           ,@tkrtype_POST   ,@userstatusid_POST  , @userstatus_POST                    ,@leaverdate_POST,@dss_update_time_POST                                          ,@sitetype_POST,         @address_POST,@TRE_user_POST,   @rate_class_POST, @effstart_POST, @employeeid_POST, @ms_usrid_POST
 
	END
  CLOSE update_cursor_4000_02
  DEALLOCATE update_cursor_4000_02
  /*BODY*/

  SET NOCOUNT OFF

    *************************************************/

END

GO
DISABLE TRIGGER [dbo].[TSUUPDdbods_sh_3e_user_sync_SSIS] ON [dbo].[ds_sh_3e_user_sync]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[TSUUPDdbods_sh_3e_user_sync_SSIS_new] ON [dbo].[ds_sh_3e_user_sync] FOR update AS

IF UPDATE("DOB") OR UPDATE("Entity") OR UPDATE("TRE_user") OR UPDATE("address") OR UPDATE("businessline") OR UPDATE("defaultrate") OR UPDATE("dss_update_time") OR UPDATE("email") OR UPDATE("firstname") OR UPDATE("gender") OR UPDATE("hrtitle") OR UPDATE("jobrole") OR UPDATE("knownas") OR UPDATE("leaverdate") OR UPDATE("name") OR UPDATE("office") OR UPDATE("officename") OR UPDATE("payrollid") OR UPDATE("payrollid_BCM") OR UPDATE("phonenumber") OR UPDATE("prefix") OR UPDATE("rate_class") OR UPDATE("ratetype") OR UPDATE("sitetype") OR UPDATE("startdate") OR UPDATE("surname") OR UPDATE("team") OR UPDATE("timekeeperindex") OR UPDATE("tkrtype") OR UPDATE("username") OR UPDATE("userstatus") OR UPDATE("userstatusid") 
BEGIN
 
  SET NOCOUNT ON
  DECLARE @paramone VARCHAR(50)
  DECLARE @detectBiDir INT
  DECLARE @historyField VARCHAR(255)
  DECLARE @uniqueID VARCHAR(50)
  DECLARE @data NVARCHAR(20)
  DECLARE @newMax INT

  /*DECLARE*/

  /*BODY:3921_23*/
  SET @historyField = ''
  SELECT @newMax = MIN(RID) FROM dbo.tsu_update WHERE TableID = 48625

  IF exists (SELECT  *
			 FROM DELETED, INSERTED WHERE DELETED."payrollid"=INSERTED."payrollid" 
			AND ( DELETED."timekeeperindex" <> INSERTED."timekeeperindex" or
				 DELETED."Entity" <> INSERTED."Entity" or
				 DELETED."TRE_user" <> INSERTED."TRE_user" or
				 DELETED."firstname" <> INSERTED."firstname" or
				 DELETED."surname" <> INSERTED."surname" or
				 DELETED."knownas" <> INSERTED."knownas" or
				 DELETED."name" <> INSERTED."name" or
				 DELETED."DOB" <> INSERTED."DOB" or
				 DELETED."prefix" <> INSERTED."prefix" or
				 DELETED."gender" <> INSERTED."gender" or
				 DELETED."email" <> INSERTED."email" or
				 DELETED."phonenumber" <> INSERTED."phonenumber" or
				 DELETED."username" <> INSERTED."username" or
				 DELETED."startdate" <> INSERTED."startdate" or
				 DELETED."office" <> INSERTED."office" or
				 DELETED."officename" <> INSERTED."officename" or
				 DELETED."address" <> INSERTED."address" or
				 DELETED."sitetype" <> INSERTED."sitetype" or
				 DELETED."businessline" <> INSERTED."businessline" or
				 DELETED."team" <> INSERTED."team" or
				 DELETED."jobrole" <> INSERTED."jobrole" or
				 DELETED."hrtitle" <> INSERTED."hrtitle" or
				 DELETED."payrollid_BCM" <> INSERTED."payrollid_BCM" or
				 DELETED."ratetype" <> INSERTED."ratetype" or
				 DELETED."defaultrate" <> INSERTED."defaultrate" or
				 DELETED."tkrtype" <> INSERTED."tkrtype" or
				 DELETED."userstatusid" <> INSERTED."userstatusid" or
				 DELETED."userstatus" <> INSERTED."userstatus" or
				 DELETED."leaverdate" <> INSERTED."leaverdate" or
				 DELETED."rate_class" <> INSERTED."rate_class" or
				 DELETED."effstart" <> INSERTED."effstart" or
				 DELETED."employeeid" <> INSERTED."employeeid" or
				 DELETED."ms_usrid" <> INSERTED."ms_usrid" OR 
				 DELETED."dss_update_time" <> INSERTED."dss_update_time"
			 )
	)

		 BEGIN     
		 		 
			INSERT INTO dbo.tsu_update (RID, TransID, Data, History,timekeeperindex_PRE,Entity_PRE,payrollid_PRE,firstname_PRE,surname_PRE,knownas_PRE,									name_PRE,DOB_PRE,prefix_PRE,gender_PRE,email_PRE,phonenumber_PRE,username_PRE,startdate_PRE,office_PRE,officename_PRE,businessline_PRE,team_PRE,								jobrole_PRE,hrtitle_PRE,															payrollid_BCM_PRE,ratetype_PRE,defaultrate_PRE,tkrtype_PRE,userstatusid_PRE,userstatus_PRE,leaverdate_PRE,dss_update_time_PRE,																				sitetype_PRE,address_PRE,TRE_user_PRE,rate_class_PRE,																							timekeeperindex_POST,Entity_POST,payrollid_POST,firstname_POST,surname_POST,knownas_POST,name_POST,DOB_POST,prefix_POST,gender_POST,email_POST,phonenumber_POST,username_POST,startdate_POST,office_POST,officename_POST,businessline_POST,team_POST,																	jobrole_POST,hrtitle_POST,payrollid_BCM_POST,ratetype_POST,defaultrate_POST,tkrtype_POST,userstatusid_POST,userstatus_POST,leaverdate_POST,dss_update_time_POST,																															sitetype_POST,address_POST,TRE_user_POST,rate_class_POST, effstart_PRE, effstart_POST, employeeid_PRE, employeeid_POST, ms_usrid_PRE, ms_usrid_POST  ) 
			SELECT ISNULL(@newMax, 1), NEWID(), 'Update', @historyField, DELETED."timekeeperindex", DELETED."Entity",DELETED."payrollid",DELETED."firstname",DELETED."surname",DELETED."knownas",DELETED."name",try_CONVERT(VARCHAR, DELETED."DOB", 121), ISNULL(DELETED."prefix" , ':n')   ,DELETED."gender",DELETED."email",ISNULL(DELETED."phonenumber"   , '0')  ,DELETED."username",try_CONVERT(VARCHAR, DELETED."startdate", 121),DELETED."office",DELETED."officename",DELETED."businessline",DELETED."team",DELETED."jobrole",DELETED."hrtitle",DELETED."payrollid_BCM",DELETED."ratetype",DELETED."defaultrate",DELETED."tkrtype",DELETED."userstatusid",DELETED."userstatus",try_CONVERT(VARCHAR, DELETED."leaverdate", 121),try_CONVERT(VARCHAR, DELETED."dss_update_time", 121),DELETED."sitetype",DELETED."address",DELETED."TRE_user",DELETED."rate_class", INSERTED."timekeeperindex",INSERTED."Entity",INSERTED."payrollid",INSERTED."firstname",INSERTED."surname",INSERTED."knownas",INSERTED."name",try_CONVERT(VARCHAR, INSERTED."DOB", 121), ISNULL(INSERTED."prefix" , ':n'),INSERTED."gender",INSERTED."email",ISNULL(INSERTED."phonenumber"   , '0'),INSERTED."username",try_CONVERT(VARCHAR, INSERTED."startdate", 121),INSERTED."office",INSERTED."officename",INSERTED."businessline",INSERTED."team",INSERTED."jobrole",INSERTED."hrtitle",INSERTED."payrollid_BCM",INSERTED."ratetype",INSERTED."defaultrate",INSERTED."tkrtype",INSERTED."userstatusid",INSERTED."userstatus",try_CONVERT(VARCHAR, INSERTED."leaverdate", 121),try_CONVERT(VARCHAR, INSERTED."dss_update_time", 121),INSERTED."sitetype",INSERTED."address",INSERTED."TRE_user",INSERTED."rate_class", ISNULL(DELETED."effstart", '1900-01-01 00:00:00.000'), ISNULL(INSERTED."effstart", '1900-01-01 00:00:00.000'), DELETED."employeeid" , INSERTED."employeeid" , DELETED."ms_usrid", INSERTED."ms_usrid" FROM DELETED, INSERTED WHERE DELETED."payrollid"=INSERTED."payrollid" 
  
		END


  SET NOCOUNT OFF
END

GO
CREATE UNIQUE NONCLUSTERED INDEX [ds_sh_3e_user_sync_idx_A] ON [dbo].[ds_sh_3e_user_sync] ([payrollid]) ON [DS_IDX]
GO
GRANT DELETE ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\ewilli02]
GO
GRANT INSERT ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\ewilli02]
GO
GRANT SELECT ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\ewilli02]
GO
GRANT UPDATE ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\ewilli02]
GO
GRANT ALTER ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\itappSQLlive]
GO
GRANT INSERT ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\ldicki]
GO
GRANT SELECT ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\ldicki]
GO
GRANT UPDATE ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\ldicki]
GO
GRANT SELECT ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\rmccab]
GO
GRANT UPDATE ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\rmccab]
GO
GRANT SELECT ON  [dbo].[ds_sh_3e_user_sync] TO [SBC\SQL - FinanceSystems]
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was created in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_3e_user_sync', 'COLUMN', N'dss_create_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_3e_user_sync', 'COLUMN', N'dss_update_time'
GO
