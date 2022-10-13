SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =========================================================
-- Author:Peter Asemota
-- Date: 2010/11/18
--
-- Description:MIB Trace report using Vfile_streamlined
-- =========================================================
CREATE PROCEDURE [VisualFiles].[MIBTrace]
      @StartDate  DATE
    , @EndDate  DATE
    , @ClientName Varchar(25)
      
AS 

    set nocount on
    set transaction isolation level read uncommitted
 

 SELECT     distinct
                      Clients.MIB_ClaimNumber AS ClaimNumber
                  ,   Clients.MIB_DefendantForeName As FirstName
                  ,   Clients.MIB_DefendantInitials As Initials
                  ,   Clients.MIB_DefendantSurname As Surname
                  ,   Entity.a_address1 As [Address 1]
                  ,   Entity.a_address2 As [Address 2]
                  ,   Entity.a_address3 As [Address 3]
                  ,   Entity.a_address4 As [Address 4]
                  ,   '' As [Address 5]
                  ,   Entity.a_postcode As Postcode
                  ,   Clients.MIB_DefVehReg AS VehReg
              --  ,   Clients.MIE_BatchDate AS Batchdate       
                  ,   CurrentBalance AS Balance
                  ,   AdditionalInfo As Additionalinfo
                  ,   Clients.MIB_AccDate AS DateOfAccident
                  	,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END  AS [ADA28]
                      
              FROM     Vfile_streamlined.dbo.AccountInformation AS AccountInfo --[Vfile_streamlined].dbo.matdb AS matdb WITH ( NOLOCK )
              INNER JOIN Vfile_streamlined.dbo.ClientScreens AS Clients WITH ( NOLOCK )
                        ON AccountInfo.mt_int_code = Clients.mt_int_code
              INNER JOIN Vfile_streamlined.dbo.link   As Link    
              INNER JOIN Vfile_streamlined.dbo.Entities AS Entity WITH ( NOLOCK )
                        ON Link.from_owner_code = Entity.Code
                        ON AccountInfo.mt_int_code = Link.to_owner_code
              LEFT OUTER JOIN 
              (
              SELECT mt_int_code,RTRIM(ud_field##1) AS  AdditionalInfo FROM VFile_Streamlined.dbo.uddetail
              WHERE uds_type='MTC'
              )    AS AdditionalInfo
              ON AccountInfo.mt_int_code=AdditionalInfo.mt_int_code   
              LEFT OUTER JOIN 
              (
              SELECT mt_int_code
               , HTRY_DateInserted
               , RTRIM(HTRY_description) AS  TraceInfo FROM VFile_Streamlined.dbo.History
              WHERE HTRY_description Like 'TRACE REQUIRED%'  
              )    AS HistoryInfo
              ON AccountInfo.mt_int_code = HistoryInfo.mt_int_code  
              LEFT JOIN (
			SELECT mt_int_code,ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON AccountInfo.mt_int_code=ADA.mt_int_code
               WHERE   (Link.to_subcode IN (';DTOR;1;DEB;19', ';DTOR;2;DEB;19'))
                        AND (Entity.entity_type_code = 'INDI')
                        AND Clients.MIB_TraceDate between @StartDate and @EndDate
                        AND AccountInfo.FileStatus <> 'COMP'
                        AND HistoryInfo.TraceInfo is not NULL -- added by pete
                        AND ClientName = @ClientName
                        
                ORDER BY Clients.MIB_ClaimNumber        
      
      
   

GO
