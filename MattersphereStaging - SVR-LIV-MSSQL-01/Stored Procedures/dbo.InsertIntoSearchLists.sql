SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertIntoSearchLists]
AS
BEGIN

INSERT INTO MS_PROD.dbo.udAIGBudgetApproval
(fileID,txtBudgetApprov,curBudgetTotal,dteBudgetApprov,cboBudgetApprov)

SELECT Main.fileID
,Main.FEDCaseText AS [txtBudgetApprov]
,LIT195.FEDCaseValue AS [curBudgetTotal]
,LIT196.FEDCaseDate AS [dteBudgetApprov]
,LIT197.FEDCaseText AS [cboBudgetApprov]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT195' AND StatusID=7) AS LIT195    
 ON Main.fileID=LIT195.fileID AND Main.seq_no=LIT195.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT196' AND StatusID=7) AS LIT196    
 ON Main.fileID=LIT196.fileID AND Main.seq_no=LIT196.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT197' AND StatusID=7) AS LIT197    
 ON Main.fileID=LIT197.fileID AND Main.seq_no=LIT197.cd_parent
WHERE Main.FEDDetailCode='LIT194'
AND Main.StatusID=7
AND (LIT195.FEDCaseValue IS NOT NULL OR LIT196.FEDCaseDate IS NOT NULL OR LIT197.FEDCaseText  IS NOT NULL)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--AIG BUDGETS 

INSERT INTO MS_PROD.dbo.udEmpRTSearchList
(fileID,txtTrainingDesc,curTrainSessAg,dteTrainingDel)

SELECT Main.fileID
,Main.FEDCaseText AS txtTrainingDesc
,EMP167.FEDCaseValue AS curTrainSessAg
,EMP169.FEDCaseDate AS dteTrainingDel
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='EMP167' AND StatusID=7) AS EMP167    
 ON Main.fileID=EMP167.fileID AND Main.seq_no=EMP167.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='EMP169' AND StatusID=7) AS EMP169    
 ON Main.fileID=EMP169.fileID AND Main.seq_no=EMP169.cd_parent
WHERE Main.FEDDetailCode='EMP171'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR EMP167.FEDCaseValue IS NOT NULL OR EMP169.FEDCaseDate IS NOT NULL)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--Employment Training Search List

INSERT INTO MS_PROD.dbo.udHire
(fileID,[txtHireAgree],[cboCHO],[curDRClaimGross],[curDRClaimNet],[curHireClaimed]
,[curHirePaid],[curNoHireAgrmts],[curWaivExtChged],[dteHireEndDate],[dteHireStart]
,[txtCHOPostcode],[txtCHORef],[txtCHOther])

SELECT Main.fileID
,Main.FEDCaseText AS [txtHireAgree]
,FTR350.FEDCaseText	AS [cboCHO]
,FTR512.FEDCaseValue AS [curDRClaimGross]
,FTR330.FEDCaseValue AS	[curDRClaimNet]
,FTR108.FEDCaseValue AS	[curHireClaimed]
,FTR109.FEDCaseValue AS	[curHirePaid]
,FTR441.FEDCaseValue AS	[curNoHireAgrmts]
,FTR329.FEDCaseValue AS	[curWaivExtChged]
,TPC129.FEDCaseDate	AS [dteHireEndDate]
,TPC098.FEDCaseDate	AS [dteHireStart]
,FTR424.FEDCaseText	AS [txtCHOPostcode]
,FTR445.FEDCaseText	AS [txtCHORef]
,FTR423.FEDCaseText	AS [txtCHOther]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR350' AND StatusID=7 ) AS FTR350    
 ON Main.fileID=FTR350.fileID AND Main.seq_no=FTR350.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR512' AND StatusID=7 ) AS FTR512    
 ON Main.fileID=FTR512.fileID AND Main.seq_no=FTR512.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR330' AND StatusID=7 ) AS FTR330    
 ON Main.fileID=FTR330.fileID AND Main.seq_no=FTR330.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR108' AND StatusID=7 ) AS FTR108    
 ON Main.fileID=FTR108.fileID AND Main.seq_no=FTR108.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR109' AND StatusID=7 ) AS FTR109    
 ON Main.fileID=FTR109.fileID AND Main.seq_no=FTR109.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR441' AND StatusID=7 ) AS FTR441    
 ON Main.fileID=FTR441.fileID AND Main.seq_no=FTR441.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR329' AND StatusID=7 ) AS FTR329    
 ON Main.fileID=FTR329.fileID AND Main.seq_no=FTR329.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='TPC129' AND StatusID=7 ) AS TPC129    
 ON Main.fileID=TPC129.fileID AND Main.seq_no=TPC129.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='TPC098' AND StatusID=7 ) AS TPC098    
 ON Main.fileID=TPC098.fileID AND Main.seq_no=TPC098.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR424' AND StatusID=7 ) AS FTR424    
 ON Main.fileID=FTR424.fileID AND Main.seq_no=FTR424.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR445' AND StatusID=7 ) AS FTR445    
 ON Main.fileID=FTR445.fileID AND Main.seq_no=FTR445.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR423' AND StatusID=7 ) AS FTR423    
 ON Main.fileID=FTR423.fileID AND Main.seq_no=FTR423.cd_parent
 
  
WHERE Main.FEDDetailCode='FTR446'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR 
FTR350.FEDCaseText IS NOT NULL OR 
FTR512.FEDCaseValue IS NOT NULL OR 
FTR330.FEDCaseValue	IS NOT NULL OR 
FTR108.FEDCaseValue	IS NOT NULL OR 
FTR109.FEDCaseValue	IS NOT NULL OR 
FTR441.FEDCaseValue	IS NOT NULL OR 
FTR329.FEDCaseValue	IS NOT NULL OR 
TPC129.FEDCaseDate	IS NOT NULL OR 
TPC098.FEDCaseDate	IS NOT NULL OR 
FTR424.FEDCaseText	IS NOT NULL OR 
FTR445.FEDCaseText	IS NOT NULL OR 
FTR423.FEDCaseText	IS NOT NULL)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 


--Hire Agreements

INSERT INTO MS_PROD.dbo.udEntityName
(fileID,txtEntityName,txtCachePI,dteCachePI,curCachePI
,dteCacheMotor,curCacheMotor,txtCacheMotor,txtCacheMinder
,dteCacheMinder,curCacheMinder,txtExpECon,dteExpECon
,curExpECon,dteExpGoldcar,curExpGoldcar,txtExpGoldcar
,txtAssoc,dteAssoc,curAssoc,txtAppoint
,dteAppoint,curAppoint,txtCompDocs,dteCompDocs,curCompDocs
)

SELECT Main.fileID
,Main.FEDCaseText AS txtEntityName
,FRA093Text.FEDCaseText AS txtCachePI
,FRA093Date.FEDCaseDate AS dteCachePI
,FRA093Value.FEDCaseValue AS curCachePI
,FRA094Date.FEDCaseDate AS dteCacheMotor
,FRA094Value.FEDCaseValue AS curCacheMotor
,FRA094Text.FEDCaseText AS txtCacheMotor
,FRA095Text.FEDCaseText AS txtCacheMinder
,FRA095Date.FEDCaseDate AS dteCacheMinder
,FRA095Value.FEDCaseValue AS curCacheMinder
,FRA096Text.FEDCaseText AS txtExpECon
,FRA096Date.FEDCaseDate AS dteExpECon
,FRA096Value.FEDCaseValue AS curExpECon
,FRA097Date.FEDCaseDate AS dteExpGoldcar
,FRA097Value.FEDCaseValue AS curExpGoldcar
,FRA097Text.FEDCaseText AS txtExpGoldcar
,FRA098Text.FEDCaseText AS txtAssoc
,FRA098Date.FEDCaseDate AS dtcAssoc
,FRA098Value.FEDCaseValue AS curAssoc
,FRA100Text.FEDCaseText AS txtAppoint
,FRA100Date.FEDCaseDate AS dteAppoint
,FRA100Value.FEDCaseValue AS curAppoint
,FRA101Text.FEDCaseText AS txtCompDocs
,FRA101Date.FEDCaseDate AS dteCompDocs
,FRA101Value.FEDCaseValue AS curCompDocs

FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA093' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA093Text    
 ON Main.fileID=FRA093Text.fileID AND Main.seq_no=FRA093Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA093' AND StatusID=7 AND DataType='datetime' ) AS FRA093Date    
 ON Main.fileID=FRA093Date.fileID AND Main.seq_no=FRA093Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA093' AND StatusID=7 AND DataType='money' ) AS FRA093Value    
 ON Main.fileID=FRA093Value.fileID AND Main.seq_no=FRA093Value.cd_parent 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA094' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA094Text    
 ON Main.fileID=FRA094Text.fileID AND Main.seq_no=FRA094Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA094' AND StatusID=7 AND DataType='datetime' ) AS FRA094Date    
 ON Main.fileID=FRA094Date.fileID AND Main.seq_no=FRA094Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA094' AND StatusID=7 AND DataType='money' ) AS FRA094Value    
 ON Main.fileID=FRA094Value.fileID AND Main.seq_no=FRA094Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA095' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA095Text    
 ON Main.fileID=FRA095Text.fileID AND Main.seq_no=FRA095Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA095' AND StatusID=7 AND DataType='datetime' ) AS FRA095Date    
 ON Main.fileID=FRA095Date.fileID AND Main.seq_no=FRA095Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA095' AND StatusID=7 AND DataType='money' ) AS FRA095Value    
 ON Main.fileID=FRA095Value.fileID AND Main.seq_no=FRA095Value.cd_parent  
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA096' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA096Text    
 ON Main.fileID=FRA096Text.fileID AND Main.seq_no=FRA096Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA096' AND StatusID=7 AND DataType='datetime' ) AS FRA096Date    
 ON Main.fileID=FRA096Date.fileID AND Main.seq_no=FRA096Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA096' AND StatusID=7 AND DataType='money' ) AS FRA096Value    
 ON Main.fileID=FRA096Value.fileID AND Main.seq_no=FRA096Value.cd_parent  

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA097' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA097Text    
 ON Main.fileID=FRA097Text.fileID AND Main.seq_no=FRA097Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA097' AND StatusID=7 AND DataType='datetime' ) AS FRA097Date    
 ON Main.fileID=FRA097Date.fileID AND Main.seq_no=FRA097Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA097' AND StatusID=7 AND DataType='money' ) AS FRA097Value    
 ON Main.fileID=FRA097Value.fileID AND Main.seq_no=FRA097Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA098' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA098Text    
 ON Main.fileID=FRA098Text.fileID AND Main.seq_no=FRA098Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA098' AND StatusID=7 AND DataType='datetime' ) AS FRA098Date    
 ON Main.fileID=FRA098Date.fileID AND Main.seq_no=FRA098Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA098' AND StatusID=7 AND DataType='money' ) AS FRA098Value    
 ON Main.fileID=FRA098Value.fileID AND Main.seq_no=FRA098Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA100' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA100Text    
 ON Main.fileID=FRA100Text.fileID AND Main.seq_no=FRA100Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA100' AND StatusID=7 AND DataType='datetime' ) AS FRA100Date    
 ON Main.fileID=FRA100Date.fileID AND Main.seq_no=FRA100Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA100' AND StatusID=7 AND DataType='money' ) AS FRA100Value    
 ON Main.fileID=FRA100Value.fileID AND Main.seq_no=FRA100Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA101' AND StatusID=7 AND DataType='nvarchar(60)' ) AS FRA101Text    
 ON Main.fileID=FRA101Text.fileID AND Main.seq_no=FRA101Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA101' AND StatusID=7 AND DataType='datetime' ) AS FRA101Date    
 ON Main.fileID=FRA101Date.fileID AND Main.seq_no=FRA101Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA101' AND StatusID=7 AND DataType='money' ) AS FRA101Value    
 ON Main.fileID=FRA101Value.fileID AND Main.seq_no=FRA101Value.cd_parent 
  
WHERE Main.FEDDetailCode='FRA099'
AND Main.StatusID=7
AND (  
Main.FEDCaseText IS NOT NULL OR 
FRA093Text.FEDCaseText IS NOT NULL OR 
FRA093Date.FEDCaseDate  IS NOT NULL OR 
FRA093Value.FEDCaseValue  IS NOT NULL OR 
FRA094Date.FEDCaseDate  IS NOT NULL OR 
FRA094Value.FEDCaseValue  IS NOT NULL OR 
FRA094Text.FEDCaseText  IS NOT NULL OR 
FRA095Text.FEDCaseText  IS NOT NULL OR 
FRA095Date.FEDCaseDate  IS NOT NULL OR 
FRA095Value.FEDCaseValue  IS NOT NULL OR 
FRA096Text.FEDCaseText  IS NOT NULL OR 
FRA096Date.FEDCaseDate  IS NOT NULL OR 
FRA096Value.FEDCaseValue  IS NOT NULL OR 
FRA097Date.FEDCaseDate  IS NOT NULL OR 
FRA097Value.FEDCaseValue  IS NOT NULL OR 
FRA097Text.FEDCaseText  IS NOT NULL OR 
FRA098Text.FEDCaseText  IS NOT NULL OR 
FRA098Date.FEDCaseDate  IS NOT NULL OR 
FRA098Value.FEDCaseValue  IS NOT NULL OR 
FRA100Text.FEDCaseText  IS NOT NULL OR 
FRA100Date.FEDCaseDate  IS NOT NULL OR 
FRA100Value.FEDCaseValue  IS NOT NULL OR 
FRA101Text.FEDCaseText  IS NOT NULL OR 
FRA101Date.FEDCaseDate  IS NOT NULL OR 
FRA101Value.FEDCaseValue  IS NOT NULL
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC 
--udEntityName

INSERT INTO MS_PROD.dbo.udDateOfAudit
(
fileID,[dteAudit],[cboCorrectAlloc],[cbo5daysCompl],[cboDupEvidence],[cboCaseClosure]
,[cboInitialLtr],[cboMediaReport],[cboPreTrialRep],[cboFEDealing],[curInitLtrLate]
,[curInitRepLate],[cboStratReport],[cboInitialRep],[cboIsInitialLtr],[cboIsEvidCompl]
,[cboIsPartnSup],[cboCallNotRet],[cboEmailNotRet],[cboHourlyRate],[cboReferralTM])

SELECT Main.fileID
,Main.FEDCaseDate AS [dteAudit]
,LIT119.FEDCaseText AS [cboCorrectAlloc]
,LIT129.FEDCaseText AS [cbo5daysCompl]
,LIT118.FEDCaseText AS [cboDupEvidence]
,LIT127.FEDCaseText AS [cboCaseClosure]
,LIT123.FEDCaseText AS [cboInitialLtr]
,LIT126.FEDCaseText AS [cboMediaReport]
,LIT125.FEDCaseText AS [cboPreTrialRep]
,LIT115.FEDCaseText AS [cboFEDealing]
,LIT1082.FEDCaseValue AS [curInitLtrLate]
,LIT699.FEDCaseValue AS [curInitRepLate]
,LIT211.FEDCaseText AS [cboStratReport]
,LIT124.FEDCaseText AS [cboInitialRep]
,LIT122.FEDCaseText AS [cboIsInitialLtr]
,LIT128.FEDCaseText AS [cboIsEvidCompl]
,LIT116.FEDCaseText AS [cboIsPartnSup]
,LIT120.FEDCaseText AS [cboCallNotRet]
,LIT121.FEDCaseText AS [cboEmailNotRet]
,LIT117.FEDCaseText AS [cboHourlyRate]
,LIT130.FEDCaseText AS [cboReferralTM]

FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT119' AND StatusID=7 ) AS LIT119    
 ON Main.fileID=LIT119.fileID AND Main.seq_no=LIT119.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT129' AND StatusID=7 ) AS LIT129    
 ON Main.fileID=LIT129.fileID AND Main.seq_no=LIT129.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT118' AND StatusID=7 ) AS LIT118    
 ON Main.fileID=LIT118.fileID AND Main.seq_no=LIT118.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT127' AND StatusID=7 ) AS LIT127    
 ON Main.fileID=LIT127.fileID AND Main.seq_no=LIT127.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT123' AND StatusID=7 ) AS LIT123    
 ON Main.fileID=LIT123.fileID AND Main.seq_no=LIT123.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT126' AND StatusID=7 ) AS LIT126    
 ON Main.fileID=LIT126.fileID AND Main.seq_no=LIT126.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT125' AND StatusID=7 ) AS LIT125    
 ON Main.fileID=LIT125.fileID AND Main.seq_no=LIT125.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT115' AND StatusID=7 ) AS LIT115    
 ON Main.fileID=LIT115.fileID AND Main.seq_no=LIT115.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1082' AND StatusID=7 ) AS LIT1082    
 ON Main.fileID=LIT1082.fileID AND Main.seq_no=LIT1082.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT699' AND StatusID=7 ) AS LIT699    
 ON Main.fileID=LIT699.fileID AND Main.seq_no=LIT699.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT211' AND StatusID=7 ) AS LIT211    
 ON Main.fileID=LIT211.fileID AND Main.seq_no=LIT211.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT124' AND StatusID=7 ) AS LIT124    
 ON Main.fileID=LIT124.fileID AND Main.seq_no=LIT124.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT122' AND StatusID=7 ) AS LIT122    
 ON Main.fileID=LIT122.fileID AND Main.seq_no=LIT122.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT128' AND StatusID=7 ) AS LIT128    
 ON Main.fileID=LIT128.fileID AND Main.seq_no=LIT128.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT116' AND StatusID=7 ) AS LIT116    
 ON Main.fileID=LIT116.fileID AND Main.seq_no=LIT116.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT120' AND StatusID=7 ) AS LIT120    
 ON Main.fileID=LIT120.fileID AND Main.seq_no=LIT120.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT121' AND StatusID=7 ) AS LIT121    
 ON Main.fileID=LIT121.fileID AND Main.seq_no=LIT121.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT117' AND StatusID=7 ) AS LIT117    
 ON Main.fileID=LIT117.fileID AND Main.seq_no=LIT117.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT130' AND StatusID=7 ) AS LIT130    
 ON Main.fileID=LIT130.fileID AND Main.seq_no=LIT130.cd_parent  
WHERE Main.FEDDetailCode='LIT114'
AND Main.StatusID=7
AND (
Main.FEDCaseDate IS NOT NULL OR 
LIT119.FEDCaseText IS NOT NULL OR 
LIT129.FEDCaseText IS NOT NULL OR 
LIT118.FEDCaseText IS NOT NULL OR 
LIT127.FEDCaseText  IS NOT NULL OR 
LIT123.FEDCaseText  IS NOT NULL OR 
LIT126.FEDCaseText  IS NOT NULL OR 
LIT125.FEDCaseText  IS NOT NULL OR 
LIT115.FEDCaseText IS NOT NULL OR 
LIT1082.FEDCaseValue  IS NOT NULL OR 
LIT699.FEDCaseValue  IS NOT NULL OR 
LIT211.FEDCaseText  IS NOT NULL OR 
LIT124.FEDCaseText  IS NOT NULL OR 
LIT122.FEDCaseText  IS NOT NULL OR 
LIT128.FEDCaseText  IS NOT NULL OR 
LIT116.FEDCaseText IS NOT NULL OR 
LIT120.FEDCaseText  IS NOT NULL OR 
LIT121.FEDCaseText  IS NOT NULL OR 
LIT117.FEDCaseText  IS NOT NULL OR 
LIT130.FEDCaseText  IS NOT NULL 
)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--Date of Audit

INSERT INTO MS_PROD.dbo.udDAPayment
(
fileID,[cboDAPayment],[curAmtPI],[curAmtPropDmg],[cboApproved]
,[dteApproved],[dteOrigPayment],[txtPayeeName],[cboStatus],
[dteDAPayment],[curDAPayment])

SELECT  Main.fileID
,Main.FEDCaseText AS [cboDAPayment]
,MIB042.FEDCaseValue AS [curAmtPI]
,MIB043.FEDCaseValue AS [curAmtPropDmg]
,MIB045Text.FEDCaseText AS [cboApproved]
,MIB045Date.FEDCaseDate AS [dteApproved]
,MIB046.FEDCaseDate AS [dteOrigPayment]
,MIB040.FEDCaseText AS [txtPayeeName]
,MIB047.FEDCaseValue AS [cboStatus]
,MIB038Date.FEDCaseDate AS [dteDAPayment]
,MIB038Value.FEDCaseValue AS [curDAPayment]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB038' AND StatusID=7 AND DataType='datetime' ) AS MIB038Date    
 ON Main.fileID=MIB038Date.fileID  AND Main.seq_no=MIB038Date.seq_no 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB038' AND StatusID=7 AND DataType='money' ) AS MIB038Value    
 ON Main.fileID=MIB038Value.fileID  AND Main.seq_no=MIB038Value.seq_no  
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB042' AND StatusID=7 ) AS MIB042    
 ON Main.fileID=MIB042.fileID AND Main.seq_no=MIB042.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB043' AND StatusID=7 ) AS MIB043    
 ON Main.fileID=MIB043.fileID AND Main.seq_no=MIB043.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB045' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='ucodeLookup:nvarchar(15)' ) AS MIB045Text    
 ON Main.fileID=MIB045Text.fileID AND Main.seq_no=MIB045Text.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB045' AND FEDCaseDate IS NOT NULL AND StatusID=7 AND DataType='datetime') AS MIB045Date   
 ON Main.fileID=MIB045Date.fileID AND Main.seq_no=MIB045Date.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB046' AND StatusID=7 ) AS MIB046    
 ON Main.fileID=MIB046.fileID AND Main.seq_no=MIB046.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB040' AND StatusID=7 ) AS MIB040    
 ON Main.fileID=MIB040.fileID AND Main.seq_no=MIB040.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB047' AND StatusID=7 ) AS MIB047    
 ON Main.fileID=MIB047.fileID AND Main.seq_no=MIB047.cd_parent      
WHERE Main.FEDDetailCode='MIB038'
AND Main.DataType='ucodeLookup:nvarchar(15)'
AND Main.StatusID=7
AND 
(
Main.FEDCaseText IS NOT NULL OR 
MIB042.FEDCaseValue IS NOT NULL OR 
MIB043.FEDCaseValue IS NOT NULL OR 
MIB045Text.FEDCaseText IS NOT NULL OR 
MIB045Date.FEDCaseDate IS NOT NULL OR 
MIB046.FEDCaseDate IS NOT NULL OR 
MIB040.FEDCaseText IS NOT NULL OR 
MIB047.FEDCaseValue IS NOT NULL 
)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

---MIB DA Payments

INSERT INTO MS_PROD.dbo.udDABill
(fileID,[cboDABill],[curDABill],[dteApprove]
,[dteBill],[txtBillNo],[dteOrigPayment])

SELECT Main.fileID
,Main.FEDCaseText AS [cboDABill]
,MIB039.FEDCaseValue AS [curDABill]
,MIB049.FEDCaseDate AS [dteApprove]
,MIB048.FEDCaseDate AS [dteBill]
,MIB041.FEDCaseText AS [txtBillNo]
,MIB044.FEDCaseDate AS [dteOrigPayment]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB039' AND StatusID=7 AND DataType='money'  ) AS MIB039    
 ON Main.fileID=MIB039.fileID AND Main.seq_no=MIB039.seq_no 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB049' AND StatusID=7 ) AS MIB049    
 ON Main.fileID=MIB049.fileID AND Main.seq_no=MIB049.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB048' AND StatusID=7 ) AS MIB048    
 ON Main.fileID=MIB048.fileID AND Main.seq_no=MIB048.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB041' AND StatusID=7 ) AS MIB041    
 ON Main.fileID=MIB041.fileID AND Main.seq_no=MIB041.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='MIB044' AND StatusID=7 ) AS MIB044    
 ON Main.fileID=MIB044.fileID AND Main.seq_no=MIB044.cd_parent 

     
WHERE Main.FEDDetailCode='MIB039'
AND Main.FEDCaseText IS NOT NULL
AND Main.DataType<>'money'
AND Main.StatusID=7
AND 
(
Main.FEDCaseText IS NOT NULL OR
MIB039.FEDCaseValue  IS NOT NULL OR
MIB049.FEDCaseDate  IS NOT NULL OR
MIB048.FEDCaseDate  IS NOT NULL OR
MIB041.FEDCaseText  IS NOT NULL OR
MIB044.FEDCaseDate  IS NOT NULL
)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--MIB DA Bills

INSERT INTO MS_PROD.dbo.udRSADsePayReq
(
fileID,[cboPaymentReq],[txtAuthBy],[cboChequePaid],[dteDateAuth],[dteDateReq]
,[cboDelAddChq],[curPayAmtGross],[curPayAmtNet],[curPayAmtTax],[txtPaymentNotes]
,[txtPaymentWhom],[cboPaymentType],[txtRequestedBy])
SELECT Main.fileID
,NMI932.FEDCaseText AS [cboPaymentReq]
,NMI952.FEDCaseText AS [txtAuthBy]
,NMI972.FEDCaseText AS [cboChequePaid]
,NMI954.FEDCaseDate AS [dteDateAuth]
,NMI951.FEDCaseDate AS [dteDateReq]
,NMI971.FEDCaseText AS [cboDelAddChq]
,NMI947.FEDCaseValue AS [curPayAmtGross]
,NMI941.FEDCaseValue AS [curPayAmtNet]
,NMI944.FEDCaseValue AS [curPayAmtTax]
,NMI938.FEDCaseText AS [txtPaymentNotes]
,NMI936.FEDCaseText AS [txtPaymentWhom]
,NMI934.FEDCaseText AS [cboPaymentType]
,NMI948.FEDCaseText AS [txtRequestedBy]

FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI932' AND StatusID=7 AND FEDCaseText IS NOT NULL ) AS NMI932    
 ON Main.fileID=NMI932.fileID AND Main.seq_no=NMI932.seq_no 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI952' AND StatusID=7 ) AS NMI952    
 ON Main.fileID=NMI952.fileID AND Main.seq_no=NMI952.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI972' AND StatusID=7 ) AS NMI972    
 ON Main.fileID=NMI972.fileID AND Main.seq_no=NMI972.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI954' AND StatusID=7 ) AS NMI954    
 ON Main.fileID=NMI954.fileID AND Main.seq_no=NMI954.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI951' AND StatusID=7 ) AS NMI951    
 ON Main.fileID=NMI951.fileID AND Main.seq_no=NMI951.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI971' AND StatusID=7 ) AS NMI971    
 ON Main.fileID=NMI971.fileID AND Main.seq_no=NMI971.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI947' AND StatusID=7 ) AS NMI947    
 ON Main.fileID=NMI947.fileID AND Main.seq_no=NMI947.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI941' AND StatusID=7 ) AS NMI941    
 ON Main.fileID=NMI941.fileID AND Main.seq_no=NMI941.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI944' AND StatusID=7 ) AS NMI944    
 ON Main.fileID=NMI944.fileID AND Main.seq_no=NMI944.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI938' AND StatusID=7 ) AS NMI938    
 ON Main.fileID=NMI938.fileID AND Main.seq_no=NMI938.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI936' AND StatusID=7 ) AS NMI936    
 ON Main.fileID=NMI936.fileID AND Main.seq_no=NMI936.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI934' AND StatusID=7 ) AS NMI934    
 ON Main.fileID=NMI934.fileID AND Main.seq_no=NMI934.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI948' AND StatusID=7 ) AS NMI948    
 ON Main.fileID=NMI948.fileID AND Main.seq_no=NMI948.cd_parent 

WHERE Main.FEDDetailCode='NMI932'
AND Main.StatusID=7
AND
(
NMI932.FEDCaseText IS NOT NULL OR 
NMI952.FEDCaseText IS NOT NULL OR 
NMI972.FEDCaseText IS NOT NULL OR 
NMI954.FEDCaseDate IS NOT NULL OR 
NMI951.FEDCaseDate IS NOT NULL OR 
NMI971.FEDCaseText  IS NOT NULL OR 
NMI947.FEDCaseValue IS NOT NULL OR 
NMI941.FEDCaseValue  IS NOT NULL OR 
NMI944.FEDCaseValue IS NOT NULL OR 
NMI938.FEDCaseText IS NOT NULL OR 
NMI936.FEDCaseText  IS NOT NULL OR 
NMI934.FEDCaseText  IS NOT NULL OR 
NMI948.FEDCaseText  IS NOT NULL 
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--RSA DSE Payment Request

INSERT INTO MS_PROD.dbo.udPayment
(
fileID,[cboPayment],[dtePayment],[txtTransactNo],[curAmountGross],[curAmountNet]
,[curAmountTax],[txtAuthWhom],[txtAuthWhom2],[dteChequeDate],[txtChequeNo]
,[dteAuth],[dteAuth2],[cboInclude],[txtInvoiceNo],[txtNotes1],[txtNotes2]
,[txtNotes3],[txtNotes4],[txtNotes5],[txtPortalRef],[txtReqbyWhom]
,[cboSingle],[cboStatus],[txtToWhom],[cboReInsurerPay],[cboInvoiceAddST])


SELECT Main.fileID
,VE00156.FEDCaseText AS [cboPayment]
,Main.FEDCaseDate AS [dtePayment]
,VE0032.FEDCaseText AS [txtTransactNo]
,VE00160.FEDCaseValue AS [curAmountGross]
,VE00158.FEDCaseValue AS [curAmountNet]
,VE00159.FEDCaseValue AS [curAmountTax]
,VE00152.FEDCaseText AS [txtAuthWhom]
,VE00154.FEDCaseText AS [txtAuthWhom2]
,VE00141.FEDCaseDate AS [dteChequeDate]
,VE00140.FEDCaseText AS [txtChequeNo]
,VE00153.FEDCaseDate AS [dteAuth]
,VE00155.FEDCaseDate AS [dteAuth2]
,VE00142.FEDCaseText AS [cboInclude]
,VE00144.FEDCaseText AS [txtInvoiceNo]
,VE00145.FEDCaseText AS [txtNotes1]
,VE00146.FEDCaseText AS [txtNotes2]
,VE00147.FEDCaseText AS [txtNotes3]
,VE00148.FEDCaseText AS [txtNotes4]
,VE00149.FEDCaseText AS [txtNotes5]
,VE00583.FEDCaseText AS [txtPortalRef]
,VE00151.FEDCaseText AS [txtReqbyWhom]
,VE00143.FEDCaseText AS [cboSingle]
,VE00150.FEDCaseText AS [cboStatus]
,VE00139.FEDCaseText AS [txtToWhom]
,VE00931.FEDCaseText AS [cboReInsurerPay]
,VE00990.FEDCaseText AS [cboInvoiceAddST]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00156' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='ucodeLookup:nvarchar(15)' ) AS VE00156    
 ON Main.fileID=VE00156.fileID  AND Main.seq_no=VE00156.seq_no 
 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE0032' AND StatusID=7 ) AS VE0032    
 ON Main.fileID=VE0032.fileID AND Main.seq_no=VE0032.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00160' AND StatusID=7 ) AS VE00160    
 ON Main.fileID=VE00160.fileID AND Main.seq_no=VE00160.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00158' AND StatusID=7 ) AS VE00158    
 ON Main.fileID=VE00158.fileID AND Main.seq_no=VE00158.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00159' AND StatusID=7 ) AS VE00159    
 ON Main.fileID=VE00159.fileID AND Main.seq_no=VE00159.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00152' AND StatusID=7 ) AS VE00152    
 ON Main.fileID=VE00152.fileID AND Main.seq_no=VE00152.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00154' AND StatusID=7 ) AS VE00154    
 ON Main.fileID=VE00154.fileID AND Main.seq_no=VE00154.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00141' AND StatusID=7 ) AS VE00141    
 ON Main.fileID=VE00141.fileID AND Main.seq_no=VE00141.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00140' AND StatusID=7 ) AS VE00140    
 ON Main.fileID=VE00140.fileID AND Main.seq_no=VE00140.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00153' AND StatusID=7 ) AS VE00153    
 ON Main.fileID=VE00153.fileID AND Main.seq_no=VE00153.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00155' AND StatusID=7 ) AS VE00155    
 ON Main.fileID=VE00155.fileID AND Main.seq_no=VE00155.cd_parent      
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00142' AND StatusID=7 ) AS VE00142    
 ON Main.fileID=VE00142.fileID AND Main.seq_no=VE00142.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00144' AND StatusID=7 ) AS VE00144    
 ON Main.fileID=VE00144.fileID AND Main.seq_no=VE00144.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00145' AND StatusID=7 ) AS VE00145    
 ON Main.fileID=VE00145.fileID AND Main.seq_no=VE00145.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00146' AND StatusID=7 ) AS VE00146    
 ON Main.fileID=VE00146.fileID AND Main.seq_no=VE00146.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00147' AND StatusID=7 ) AS VE00147    
 ON Main.fileID=VE00147.fileID AND Main.seq_no=VE00147.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00148' AND StatusID=7 ) AS VE00148    
 ON Main.fileID=VE00148.fileID AND Main.seq_no=VE00148.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00149' AND StatusID=7 ) AS VE00149    
 ON Main.fileID=VE00149.fileID AND Main.seq_no=VE00149.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00583' AND StatusID=7 ) AS VE00583    
 ON Main.fileID=VE00583.fileID AND Main.seq_no=VE00583.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00151' AND StatusID=7 ) AS VE00151    
 ON Main.fileID=VE00151.fileID AND Main.seq_no=VE00151.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00143' AND StatusID=7 ) AS VE00143    
 ON Main.fileID=VE00143.fileID AND Main.seq_no=VE00143.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00150' AND StatusID=7 ) AS VE00150    
 ON Main.fileID=VE00150.fileID AND Main.seq_no=VE00150.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00139' AND StatusID=7 ) AS VE00139    
 ON Main.fileID=VE00139.fileID AND Main.seq_no=VE00139.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00931' AND StatusID=7 ) AS VE00931    
 ON Main.fileID=VE00931.fileID AND Main.seq_no=VE00931.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00990' AND StatusID=7 ) AS VE00990    
 ON Main.fileID=VE00990.fileID AND Main.seq_no=VE00990.cd_parent  
 
 WHERE Main.FEDDetailCode='VE00156'
AND Main.DataType='datetime'
AND Main.StatusID=7
AND 
(
VE00156.FEDCaseText IS NOT NULL OR 
Main.FEDCaseDate IS NOT NULL OR 
VE0032.FEDCaseText IS NOT NULL OR 
VE00160.FEDCaseValue IS NOT NULL OR 
VE00158.FEDCaseValue IS NOT NULL OR 
VE00159.FEDCaseValue IS NOT NULL OR   
VE00152.FEDCaseText IS NOT NULL  OR 
VE00154.FEDCaseText IS NOT NULL  OR 
VE00141.FEDCaseDate IS NOT NULL  OR 
VE00140.FEDCaseText IS NOT NULL OR 
VE00153.FEDCaseDate IS NOT NULL OR 
VE00155.FEDCaseDate IS NOT NULL OR 
VE00142.FEDCaseText IS NOT NULL OR 
VE00144.FEDCaseText IS NOT NULL OR 
VE00145.FEDCaseText IS NOT NULL OR 
VE00146.FEDCaseText IS NOT NULL OR 
VE00147.FEDCaseText IS NOT NULL OR 
VE00148.FEDCaseText IS NOT NULL OR 
VE00149.FEDCaseText IS NOT NULL OR 
VE00583.FEDCaseText IS NOT NULL OR 
VE00151.FEDCaseText IS NOT NULL OR 
VE00143.FEDCaseText IS NOT NULL OR 
VE00150.FEDCaseText IS NOT NULL OR 
VE00139.FEDCaseText IS NOT NULL OR 
VE00931.FEDCaseText IS NOT NULL  
)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--Converge Payments

INSERT INTO MS_PROD.dbo.udZeusReserve
(
fileID,[txtExpRes],[curClCstHirRes],[curClCstLosDmRs],[curClCstOthRes],[curClExInvCtRes]
,[curCRURes],[curFutCareRes],[curFutLosEarRes],[curFutLosMisRes],[curNHSChaRes]
,[curPastCareRes],[curPastLosEaRes],[curPerInjRes],[curSpeDamMisRes]
,[curZurExpEst],[dteExpConc],[cboIntResApp],[dteResSub])

SELECT Main.fileID
,Main.FEDCaseText AS [txtExpRes]
,LIT723.FEDCaseValue AS [curClCstHirRes]
,LIT722.FEDCaseValue AS [curClCstLosDmRs]
,LIT725.FEDCaseValue AS [curClCstOthRes]
,LIT724.FEDCaseValue AS [curClExInvCtRes]
,LIT1028.FEDCaseValue AS [curCRURes]
,LIT1027.FEDCaseValue AS [curFutCareRes]
,LIT1030.FEDCaseValue AS [curFutLosEarRes]
,LIT1032.FEDCaseValue AS [curFutLosMisRes]
,LIT1031.FEDCaseValue AS [curNHSChaRes]
,LIT1025.FEDCaseValue AS [curPastCareRes]
,LIT1029.FEDCaseValue AS [curPastLosEaRes]
,LIT1024.FEDCaseValue AS [curPerInjRes]
,LIT1033.FEDCaseValue AS [curSpeDamMisRes]
,LIT1017.FEDCaseValue AS [curZurExpEst]
,LIT1241.FEDCaseDate AS [dteExpConc]
,LIT1071Text.FEDCaseText AS [cboIntResApp]
,LIT1070.FEDCaseDate AS [dteResSub]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT723' AND Datatype='money' AND StatusID=7 ) AS LIT723    
 ON Main.fileID=LIT723.fileID AND Main.seq_no=LIT723.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT722' AND Datatype='money' AND StatusID=7 ) AS LIT722    
 ON Main.fileID=LIT722.fileID AND Main.seq_no=LIT722.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT725' AND Datatype='money' AND StatusID=7 ) AS LIT725    
 ON Main.fileID=LIT725.fileID AND Main.seq_no=LIT725.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT724' AND Datatype='money' AND StatusID=7 ) AS LIT724    
 ON Main.fileID=LIT724.fileID AND Main.seq_no=LIT724.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1028' AND Datatype='money'AND StatusID=7 ) AS LIT1028    
 ON Main.fileID=LIT1028.fileID AND Main.seq_no=LIT1028.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1027' AND Datatype='money'AND StatusID=7 ) AS LIT1027    
 ON Main.fileID=LIT1027.fileID AND Main.seq_no=LIT1027.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1030' AND Datatype='money'AND StatusID=7 ) AS LIT1030    
 ON Main.fileID=LIT1030.fileID AND Main.seq_no=LIT1030.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1032' AND Datatype='money'AND StatusID=7 ) AS LIT1032    
 ON Main.fileID=LIT1032.fileID AND Main.seq_no=LIT1032.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1031' AND Datatype='money'AND StatusID=7 ) AS LIT1031    
 ON Main.fileID=LIT1031.fileID AND Main.seq_no=LIT1031.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1025' AND Datatype='money'AND StatusID=7 ) AS LIT1025    
 ON Main.fileID=LIT1025.fileID AND Main.seq_no=LIT1025.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1029' AND Datatype='money'AND StatusID=7 ) AS LIT1029    
 ON Main.fileID=LIT1029.fileID AND Main.seq_no=LIT1029.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1024' AND Datatype='money'AND StatusID=7 ) AS LIT1024    
 ON Main.fileID=LIT1024.fileID AND Main.seq_no=LIT1024.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1033' AND Datatype='money'AND StatusID=7 ) AS LIT1033    
 ON Main.fileID=LIT1033.fileID AND Main.seq_no=LIT1033.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1017' AND Datatype='money'AND StatusID=7 ) AS LIT1017    
 ON Main.fileID=LIT1017.fileID AND Main.seq_no=LIT1017.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1241' AND StatusID=7 ) AS LIT1241    
 ON Main.fileID=LIT1241.fileID AND Main.seq_no=LIT1241.cd_parent 
LEFT OUTER JOIN (SELECT DISTINCT fileID,seq_no,FEDCaseText,cd_parent FROM SearchListDetailStage WHERE FEDDetailCode='LIT1071' AND FEDCaseText IS NOT NULL AND StatusID=7 ) AS LIT1071Text    
 ON Main.fileID=LIT1071Text.fileID AND Main.seq_no=LIT1071Text.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1070') AS LIT1070    
 ON Main.fileID=LIT1070.fileID AND Main.seq_no=LIT1070.cd_parent

      
WHERE Main.FEDDetailCode='LIT1016'
AND Main.StatusID=7
AND 
(
Main.FEDCaseText IS NOT NULL OR 
LIT723.FEDCaseValue IS NOT NULL OR 
LIT722.FEDCaseValue IS NOT NULL OR 
LIT725.FEDCaseValue IS NOT NULL OR 
LIT724.FEDCaseValue  IS NOT NULL OR 
LIT1028.FEDCaseValue IS NOT NULL OR 
LIT1027.FEDCaseValue  IS NOT NULL OR 
LIT1030.FEDCaseValue  IS NOT NULL OR 
LIT1032.FEDCaseValue IS NOT NULL OR 
LIT1031.FEDCaseValue  IS NOT NULL OR 
LIT1025.FEDCaseValue  IS NOT NULL OR 
LIT1029.FEDCaseValue  IS NOT NULL OR 
LIT1024.FEDCaseValue  IS NOT NULL OR 
LIT1033.FEDCaseValue  IS NOT NULL OR 
LIT1017.FEDCaseValue  IS NOT NULL OR 
LIT1241.FEDCaseDate  IS NOT NULL OR 
LIT1071Text.FEDCaseText  IS NOT NULL OR 
LIT1070.FEDCaseDate IS NOT NULL  
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC

--ZEUS Reserves

INSERT INTO MS_PROD.dbo.udZeusPaymentApp
(
fileID,[dteExpPayApp],[txtExpPayApp],[cboFeePay],[cboFinalPay],[cboForceRef],[cboNewPayee],[cboPay1NetExc]
,[cboPay1Type],[cboPay2NetExc],[cboPay3NetExc],[cboPay4NetExc],[cboPay5NetExc],[cboPay6NetExc],[cboPay7NetExc]
,[cboPay8NetExc],[cboPayMethod],[cboPayNetVAT],[cboPayVATReg],[cboPreAuth],[curPay1NetExc],[curPay1Val],[curPay2NetExc]
,[curPay2Val],[curPay3NetExc],[curPay3Val],[curPay4NetExc],[curPay4Val],[curPay5NetExc],[curPay5Val],[curPay6NetExc]
,[curPay6Val],[curPay7NetExc],[curPay7Val],[curPay8NetExc],[curPay8Val],[dteReqRecZurich],[dteTMApp],[txtAckReceived]
,[txtAuthCode],[txtAuthorised],[txtAuthReason],[txtDALimitEx],[txtFeeLimitExc],[txtForceRefReas],[txtNewPayAcNo],[txtNewPayCount],[txtNewPayCounty]
,[txtNewPayDist],[txtNewPayFore],[txtNewPayHsName],[txtNewPayHsNum],[txtNewPayNotes],[txtNewPayPCode],[txtNewPaySortCd],[txtNewPayStreet],[txtNewPaySurnam]
,[txtNewPayTitle],[txtNewPayTown],[txtNewPayType],[txtPartytoBPaid],[cboPay2Type],[cboPay3Type],[cboPay4Type],[cboPay5Type],[cboPay6Type]
,[cboPay7Type],[cboPay8Type],[txtPayBankACNo],[txtPayBankSortC],[txtPayeeGna],[txtPayeeName],[txtPayHouseName],[txtPayHouseNo],[txtPayHousePCod]
,[txtPayMethod],[txtPayReferred],[txtPayRefInvNo],[txtPayStatus],[txtPayUniqueID],[txtPreAuthCode],[txtReasonPayDec],[txtRemPartyGna],[txtSupPartyGna],[txtTMApp]
)

SELECT Main.fileID
,Main.FEDCaseDate AS [dteExpPayApp]
,LIT775Text.FEDCaseText AS [txtExpPayApp]
,LIT784Text.FEDCaseText AS [cboFeePay]
,LIT785Text.FEDCaseText AS [cboFinalPay]
,LIT786Text.FEDCaseText AS [cboForceRef]
,LIT799Text.FEDCaseText AS [cboNewPayee]
,LIT1098Text.FEDCaseText AS [cboPay1NetExc]
,LIT777Text.FEDCaseText AS [cboPay1Type]
,LIT1100Text.FEDCaseText AS [cboPay2NetExc]
,LIT1102Text.FEDCaseText AS [cboPay3NetExc]
,LIT461Text.FEDCaseText AS [cboPay4NetExc]
,LIT463Text.FEDCaseText AS [cboPay5NetExc]
,LIT465Text.FEDCaseText AS [cboPay6NetExc]
,LIT467Text.FEDCaseText AS [cboPay7NetExc]
,LIT469Text.FEDCaseText AS [cboPay8NetExc]
,LIT790.FEDCaseText AS [cboPayMethod]
,LIT789.FEDCaseText AS [cboPayNetVAT]
,LIT798.FEDCaseText AS [cboPayVATReg]
,LIT791.FEDCaseText AS [cboPreAuth]
,LIT1098Value.FEDCaseValue AS [curPay1NetExc]
,LIT777Value.FEDCaseValue AS [curPay1Val]
,LIT1100Value.FEDCaseValue AS [curPay2NetExc]
,LIT1099Value.FEDCaseValue AS [curPay2Val]
,LIT1102Value.FEDCaseValue AS [curPay3NetExc]
,LIT1101Value.FEDCaseValue AS [curPay3Val]
,LIT461Value.FEDCaseValue AS [curPay4NetExc]
,LIT460Value.FEDCaseValue AS [curPay4Val]
,LIT463Value.FEDCaseValue AS [curPay5NetExc]
,LIT462Value.FEDCaseValue AS [curPay5Val]
,LIT465Value.FEDCaseValue AS [curPay6NetExc]
,LIT464Value.FEDCaseValue AS [curPay6Val]
,LIT467Value.FEDCaseValue AS [curPay7NetExc]
,LIT466Value.FEDCaseValue AS [curPay7Val]
,LIT469Value.FEDCaseValue AS [curPay8NetExc]
,LIT468Value.FEDCaseValue AS [curPay8Val]
,LIT818.FEDCaseDate AS [dteReqRecZurich]
,LIT815Date.FEDCaseDate AS [dteTMApp]
,LIT817.FEDCaseText AS [txtAckReceived]
,LIT1090.FEDCaseText AS [txtAuthCode]
,LIT1089.FEDCaseText AS [txtAuthorised]
,LIT1091.FEDCaseText AS [txtAuthReason]
,LIT1080.FEDCaseText AS [txtDALimitEx]
,LIT1081.FEDCaseText AS [txtFeeLimitExc]
,LIT787.FEDCaseText AS [txtForceRefReas]
,LIT813.FEDCaseText AS [txtNewPayAcNo]
,LIT810.FEDCaseText AS [txtNewPayCount]
,LIT809.FEDCaseText AS [txtNewPayCounty]
,LIT807.FEDCaseText AS [txtNewPayDist]
,LIT802.FEDCaseText AS [txtNewPayFore]
,LIT805.FEDCaseText AS [txtNewPayHsName]
,LIT804.FEDCaseText AS [txtNewPayHsNum]
,LIT814.FEDCaseText AS [txtNewPayNotes]
,LIT811.FEDCaseText AS [txtNewPayPCode]
,LIT812.FEDCaseText AS [txtNewPaySortCd]
,LIT806.FEDCaseText AS [txtNewPayStreet]
,LIT803.FEDCaseText AS [txtNewPaySurnam]
,LIT801.FEDCaseText AS [txtNewPayTitle]
,LIT808.FEDCaseText AS [txtNewPayTown]
,LIT800.FEDCaseText AS [txtNewPayType]
,LIT778.FEDCaseText AS [txtPartytoBPaid]
,LIT1099Text.FEDCaseText AS [cboPay2Type]
,LIT1101Text.FEDCaseText AS [cboPay3Type]
,LIT460Text.FEDCaseText AS [cboPay4Type]
,LIT462Text.FEDCaseText AS [cboPay5Type]
,LIT464Text.FEDCaseText AS [cboPay6Type]
,LIT466Text.FEDCaseText AS [cboPay7Type]
,LIT468Text.FEDCaseText AS [cboPay8Type]
,LIT796.FEDCaseText AS [txtPayBankACNo]
,LIT797.FEDCaseText AS [txtPayBankSortC]
,LIT782.FEDCaseText AS [txtPayeeGna]
,LIT779.FEDCaseText AS [txtPayeeName]
,LIT793.FEDCaseText AS [txtPayHouseName]
,LIT794.FEDCaseText AS [txtPayHouseNo]
,LIT795.FEDCaseText AS [txtPayHousePCod]
,LIT819.FEDCaseText AS [txtPayMethod]
,LIT820.FEDCaseText AS [txtPayReferred]
,LIT780.FEDCaseText AS [txtPayRefInvNo]
,LIT821.FEDCaseText AS [txtPayStatus]
,LIT816.FEDCaseText AS [txtPayUniqueID]
,LIT792.FEDCaseText AS [txtPreAuthCode]
,LIT822.FEDCaseText AS [txtReasonPayDec]
,LIT783.FEDCaseText AS [txtRemPartyGna]
,LIT781.FEDCaseText AS [txtSupPartyGna]
,LIT815Text.FEDCaseText AS [txtTMApp]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT775' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT775Text    
 ON Main.fileID=LIT775Text.fileID AND Main.seq_no=LIT775Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT784' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT784Text    
 ON Main.fileID=LIT784Text.fileID AND Main.seq_no=LIT784Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT785' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT785Text    
 ON Main.fileID=LIT785Text.fileID AND Main.seq_no=LIT785Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT786' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT786Text    
 ON Main.fileID=LIT786Text.fileID AND Main.seq_no=LIT786Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT799' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT799Text    
 ON Main.fileID=LIT799Text.fileID AND Main.seq_no=LIT799Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1098' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT1098Text    
 ON Main.fileID=LIT1098Text.fileID AND Main.seq_no=LIT1098Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1098' AND StatusID=7 AND DataType='money' ) AS LIT1098Value   
 ON Main.fileID=LIT1098Value.fileID AND Main.seq_no=LIT1098Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT777' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT777Text    
 ON Main.fileID=LIT777Text.fileID AND Main.seq_no=LIT777Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT777' AND StatusID=7 AND DataType='money' ) AS LIT777Value   
 ON Main.fileID=LIT777Value.fileID AND Main.seq_no=LIT777Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1100' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT1100Text    
 ON Main.fileID=LIT1100Text.fileID AND Main.seq_no=LIT1100Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1100' AND StatusID=7 AND DataType='money' ) AS LIT1100Value   
 ON Main.fileID=LIT1100Value.fileID AND Main.seq_no=LIT1100Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1102' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT1102Text    
 ON Main.fileID=LIT1102Text.fileID AND Main.seq_no=LIT1102Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1102' AND StatusID=7 AND DataType='money' ) AS LIT1102Value   
 ON Main.fileID=LIT1102Value.fileID AND Main.seq_no=LIT1102Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT461' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT461Text    
 ON Main.fileID=LIT461Text.fileID AND Main.seq_no=LIT461Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT461' AND StatusID=7 AND DataType='money' ) AS LIT461Value   
 ON Main.fileID=LIT461Value.fileID AND Main.seq_no=LIT461Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT463' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT463Text    
 ON Main.fileID=LIT463Text.fileID AND Main.seq_no=LIT463Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT463' AND StatusID=7 AND DataType='money' ) AS LIT463Value   
 ON Main.fileID=LIT463Value.fileID AND Main.seq_no=LIT463Value.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT465' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT465Text    
 ON Main.fileID=LIT465Text.fileID AND Main.seq_no=LIT465Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT465' AND StatusID=7 AND DataType='money' ) AS LIT465Value   
 ON Main.fileID=LIT465Value.fileID AND Main.seq_no=LIT465Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT467' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT467Text    
 ON Main.fileID=LIT467Text.fileID AND Main.seq_no=LIT467Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT467' AND StatusID=7 AND DataType='money' ) AS LIT467Value   
 ON Main.fileID=LIT467Value.fileID AND Main.seq_no=LIT467Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT469' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT469Text    
 ON Main.fileID=LIT469Text.fileID AND Main.seq_no=LIT469Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT469' AND StatusID=7 AND DataType='money' ) AS LIT469Value   
 ON Main.fileID=LIT469Value.fileID AND Main.seq_no=LIT469Value.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT790' AND StatusID=7  ) AS LIT790   
 ON Main.fileID=LIT790.fileID AND Main.seq_no=LIT790.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT789' AND StatusID=7  ) AS LIT789   
 ON Main.fileID=LIT789.fileID AND Main.seq_no=LIT789.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT798' AND StatusID=7  ) AS LIT798   
 ON Main.fileID=LIT798.fileID AND Main.seq_no=LIT798.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT791' AND StatusID=7  ) AS LIT791   
 ON Main.fileID=LIT791.fileID AND Main.seq_no=LIT791.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT818' AND StatusID=7  ) AS LIT818   
 ON Main.fileID=LIT818.fileID AND Main.seq_no=LIT818.cd_parent     

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1099' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT1099Text    
 ON Main.fileID=LIT1099Text.fileID AND Main.seq_no=LIT1099Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1099' AND StatusID=7 AND DataType='money' ) AS LIT1099Value   
 ON Main.fileID=LIT1099Value.fileID AND Main.seq_no=LIT1099Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1101' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT1101Text    
 ON Main.fileID=LIT1101Text.fileID AND Main.seq_no=LIT1101Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1101' AND StatusID=7 AND DataType='money' ) AS LIT1101Value   
 ON Main.fileID=LIT1101Value.fileID AND Main.seq_no=LIT1101Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT460' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT460Text    
 ON Main.fileID=LIT460Text.fileID AND Main.seq_no=LIT460Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT460' AND StatusID=7 AND DataType='money' ) AS LIT460Value   
 ON Main.fileID=LIT460Value.fileID AND Main.seq_no=LIT460Value.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT462' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT462Text    
 ON Main.fileID=LIT462Text.fileID AND Main.seq_no=LIT462Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT462' AND StatusID=7 AND DataType='money' ) AS LIT462Value   
 ON Main.fileID=LIT462Value.fileID AND Main.seq_no=LIT462Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT464' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT464Text    
 ON Main.fileID=LIT464Text.fileID AND Main.seq_no=LIT464Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT464' AND StatusID=7 AND DataType='money' ) AS LIT464Value   
 ON Main.fileID=LIT464Value.fileID AND Main.seq_no=LIT464Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT466' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT466Text    
 ON Main.fileID=LIT466Text.fileID AND Main.seq_no=LIT466Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT466' AND StatusID=7 AND DataType='money' ) AS LIT466Value   
 ON Main.fileID=LIT466Value.fileID AND Main.seq_no=LIT466Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT468' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT468Text    
 ON Main.fileID=LIT468Text.fileID AND Main.seq_no=LIT468Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT468' AND StatusID=7 AND DataType='money' ) AS LIT468Value   
 ON Main.fileID=LIT468Value.fileID AND Main.seq_no=LIT468Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT815' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT815Text    
 ON Main.fileID=LIT815Text.fileID AND Main.seq_no=LIT815Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT815' AND StatusID=7 AND DataType='date' ) AS LIT815Date   
 ON Main.fileID=LIT815Date.fileID AND Main.seq_no=LIT815Date.cd_parent 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT817' AND StatusID=7  ) AS LIT817   
 ON Main.fileID=LIT817.fileID AND Main.seq_no=LIT817.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1090' AND StatusID=7  ) AS LIT1090   
 ON Main.fileID=LIT1090.fileID AND Main.seq_no=LIT1090.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1089' AND StatusID=7  ) AS LIT1089   
 ON Main.fileID=LIT1089.fileID AND Main.seq_no=LIT1089.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1091' AND StatusID=7  ) AS LIT1091   
 ON Main.fileID=LIT1091.fileID AND Main.seq_no=LIT1091.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1080' AND StatusID=7  ) AS LIT1080   
 ON Main.fileID=LIT1080.fileID AND Main.seq_no=LIT1080.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1081' AND StatusID=7  ) AS LIT1081   
 ON Main.fileID=LIT1081.fileID AND Main.seq_no=LIT1081.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT787' AND StatusID=7  ) AS LIT787   
 ON Main.fileID=LIT787.fileID AND Main.seq_no=LIT787.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT813' AND StatusID=7  ) AS LIT813   
 ON Main.fileID=LIT813.fileID AND Main.seq_no=LIT813.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT810' AND StatusID=7  ) AS LIT810   
 ON Main.fileID=LIT810.fileID AND Main.seq_no=LIT810.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT809' AND StatusID=7  ) AS LIT809   
 ON Main.fileID=LIT809.fileID AND Main.seq_no=LIT809.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT807' AND StatusID=7  ) AS LIT807   
 ON Main.fileID=LIT807.fileID AND Main.seq_no=LIT807.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT802' AND StatusID=7  ) AS LIT802   
 ON Main.fileID=LIT802.fileID AND Main.seq_no=LIT802.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT805' AND StatusID=7  ) AS LIT805   
 ON Main.fileID=LIT805.fileID AND Main.seq_no=LIT805.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT804' AND StatusID=7  ) AS LIT804   
 ON Main.fileID=LIT804.fileID AND Main.seq_no=LIT804.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT814' AND StatusID=7  ) AS LIT814   
 ON Main.fileID=LIT814.fileID AND Main.seq_no=LIT814.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT811' AND StatusID=7  ) AS LIT811   
 ON Main.fileID=LIT811.fileID AND Main.seq_no=LIT811.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT812' AND StatusID=7  ) AS LIT812   
 ON Main.fileID=LIT812.fileID AND Main.seq_no=LIT812.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT806' AND StatusID=7  ) AS LIT806   
 ON Main.fileID=LIT806.fileID AND Main.seq_no=LIT806.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT803' AND StatusID=7  ) AS LIT803   
 ON Main.fileID=LIT803.fileID AND Main.seq_no=LIT803.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT801' AND StatusID=7  ) AS LIT801   
 ON Main.fileID=LIT801.fileID AND Main.seq_no=LIT801.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT808' AND StatusID=7  ) AS LIT808   
 ON Main.fileID=LIT808.fileID AND Main.seq_no=LIT808.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT800' AND StatusID=7  ) AS LIT800   
 ON Main.fileID=LIT800.fileID AND Main.seq_no=LIT800.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT778' AND StatusID=7  ) AS LIT778   
 ON Main.fileID=LIT778.fileID AND Main.seq_no=LIT778.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT796' AND StatusID=7  ) AS LIT796   
 ON Main.fileID=LIT796.fileID AND Main.seq_no=LIT796.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT797' AND StatusID=7  ) AS LIT797   
 ON Main.fileID=LIT797.fileID AND Main.seq_no=LIT797.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT782' AND StatusID=7  ) AS LIT782   
 ON Main.fileID=LIT782.fileID AND Main.seq_no=LIT782.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT779' AND StatusID=7  ) AS LIT779   
 ON Main.fileID=LIT779.fileID AND Main.seq_no=LIT779.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT793' AND StatusID=7  ) AS LIT793   
 ON Main.fileID=LIT793.fileID AND Main.seq_no=LIT793.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT794' AND StatusID=7  ) AS LIT794   
 ON Main.fileID=LIT794.fileID AND Main.seq_no=LIT794.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT795' AND StatusID=7  ) AS LIT795   
 ON Main.fileID=LIT795.fileID AND Main.seq_no=LIT795.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT819' AND StatusID=7  ) AS LIT819   
 ON Main.fileID=LIT819.fileID AND Main.seq_no=LIT819.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT820' AND StatusID=7  ) AS LIT820   
 ON Main.fileID=LIT820.fileID AND Main.seq_no=LIT820.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT780' AND StatusID=7  ) AS LIT780   
 ON Main.fileID=LIT780.fileID AND Main.seq_no=LIT780.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT821' AND StatusID=7  ) AS LIT821   
 ON Main.fileID=LIT821.fileID AND Main.seq_no=LIT821.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT816' AND StatusID=7  ) AS LIT816   
 ON Main.fileID=LIT816.fileID AND Main.seq_no=LIT816.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT792' AND StatusID=7  ) AS LIT792   
 ON Main.fileID=LIT792.fileID AND Main.seq_no=LIT792.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT822' AND StatusID=7  ) AS LIT822   
 ON Main.fileID=LIT822.fileID AND Main.seq_no=LIT822.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT783' AND StatusID=7  ) AS LIT783   
 ON Main.fileID=LIT783.fileID AND Main.seq_no=LIT783.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT781' AND StatusID=7  ) AS LIT781   
 ON Main.fileID=LIT781.fileID AND Main.seq_no=LIT781.cd_parent 
WHERE Main.FEDDetailCode='LIT775'
AND Main.DataType='datetime'
AND Main.StatusID=7

ORDER BY Main.FEDCaseID,Main.seq_no ASC

-- Zeus Payments

INSERT INTO MS_PROD.dbo.udZeusExposure
(
fileId,[txtExposure],[cboInsType],txtIntExp,[cboUrgInst],[curInsNumVer],[curZurClEst]
,[dteClInsCreDate],[txtClaimAssoc],[txtClaimNum],[txtContID],[txtEDITrkRef],[txtInsClID]
,[txtInsNumRef],[txtOthUpdtRea],[txtPartyID],[txtReaCanInst],[txtReasonInst],[txtSupType]
,[txtUpdateRea],[txtZurClEst])

SELECT Main.fileId
,Main.FEDCaseText  AS [txtExposure]
,LIT354.FEDCaseText AS [cboInsType]
,LIT1077.FEDCaseText AS [txtIntExp]
,LIT358.FEDCaseText AS [cboUrgInst]
,LIT431.FEDCaseValue AS [curInsNumVer]
,LIT405Value.FEDCaseValue AS [curZurClEst]
,LIT701.FEDCaseDate AS [dteClInsCreDate]
,LIT351.FEDCaseText AS [txtClaimAssoc]
,LIT1021.FEDCaseText AS [txtClaimNum]
,LIT1026.FEDCaseText AS [txtContID]
,LIT353.FEDCaseText AS [txtEDITrkRef]
,LIT1079.FEDCaseText AS [txtInsClID]
,LIT1020.FEDCaseText AS [txtInsNumRef]
,LIT369.FEDCaseText AS [txtOthUpdtRea]
,LIT1146.FEDCaseText AS [txtPartyID]
,LIT370.FEDCaseText AS [txtReaCanInst]
,LIT857.FEDCaseText AS [txtReasonInst]
,LIT430.FEDCaseText AS [txtSupType]
,LIT368.FEDCaseText AS [txtUpdateRea]
,LIT405Text.FEDCaseText AS [txtZurClEst]

FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT354' AND StatusID=7 ) AS LIT354    
 ON Main.fileID=LIT354.fileID AND Main.seq_no=LIT354.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1077' AND StatusID=7 ) AS LIT1077    
 ON Main.fileID=LIT1077.fileID AND Main.seq_no=LIT1077.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT358' AND StatusID=7 ) AS LIT358    
 ON Main.fileID=LIT358.fileID AND Main.seq_no=LIT358.cd_parent

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT431' AND StatusID=7 ) AS LIT431    
 ON Main.fileID=LIT431.fileID AND Main.seq_no=LIT431.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT405' AND FEDCaseValue IS NOT NULL AND StatusID=7 AND DataType='money' ) AS LIT405Value    
 ON Main.fileID=LIT405Value.fileID AND Main.seq_no=LIT405Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT405' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT405Text    
 ON Main.fileID=LIT405Text.fileID AND Main.seq_no=LIT405Text.cd_parent 
 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT701' AND StatusID=7 ) AS LIT701    
 ON Main.fileID=LIT701.fileID AND Main.seq_no=LIT701.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT351' AND StatusID=7 ) AS LIT351    
 ON Main.fileID=LIT351.fileID AND Main.seq_no=LIT351.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1021' AND StatusID=7 ) AS LIT1021    
 ON Main.fileID=LIT1021.fileID AND Main.seq_no=LIT1021.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1026' AND StatusID=7 ) AS LIT1026    
 ON Main.fileID=LIT1026.fileID AND Main.seq_no=LIT1026.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT353' AND StatusID=7 ) AS LIT353    
 ON Main.fileID=LIT353.fileID AND Main.seq_no=LIT353.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1079' AND StatusID=7 ) AS LIT1079    
 ON Main.fileID=LIT1079.fileID AND Main.seq_no=LIT1079.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1020' AND StatusID=7 ) AS LIT1020    
 ON Main.fileID=LIT1020.fileID AND Main.seq_no=LIT1020.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT369' AND StatusID=7 ) AS LIT369    
 ON Main.fileID=LIT369.fileID AND Main.seq_no=LIT369.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1146' AND StatusID=7 ) AS LIT1146    
 ON Main.fileID=LIT1146.fileID AND Main.seq_no=LIT1146.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT370' AND StatusID=7 ) AS LIT370    
 ON Main.fileID=LIT370.fileID AND Main.seq_no=LIT370.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT857' AND StatusID=7 ) AS LIT857    
 ON Main.fileID=LIT857.fileID AND Main.seq_no=LIT857.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT430' AND StatusID=7 ) AS LIT430    
 ON Main.fileID=LIT430.fileID AND Main.seq_no=LIT430.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT368' AND StatusID=7 ) AS LIT368    
 ON Main.fileID=LIT368.fileID AND Main.seq_no=LIT368.cd_parent 
 

WHERE Main.FEDDetailCode='LIT1015'
AND Main.StatusID=7
AND 
(
Main.FEDCaseText IS NOT NULL OR 
LIT354.FEDCaseText IS NOT NULL OR 
LIT1077.FEDCaseText IS NOT NULL OR 
LIT358.FEDCaseText IS NOT NULL OR 
LIT431.FEDCaseValue IS NOT NULL OR 
LIT405Value.FEDCaseValue IS NOT NULL OR 
LIT701.FEDCaseDate IS NOT NULL OR 
LIT351.FEDCaseText IS NOT NULL OR 
LIT1021.FEDCaseText IS NOT NULL OR 
LIT1026.FEDCaseText IS NOT NULL OR 
LIT353.FEDCaseText IS NOT NULL OR 
LIT1079.FEDCaseText IS NOT NULL OR 
LIT1020.FEDCaseText IS NOT NULL OR 
LIT369.FEDCaseText IS NOT NULL OR 
LIT1146.FEDCaseText IS NOT NULL OR 
LIT370.FEDCaseText IS NOT NULL OR 
LIT857.FEDCaseText IS NOT NULL OR 
LIT430.FEDCaseText IS NOT NULL OR 
LIT368.FEDCaseText IS NOT NULL OR 
LIT405Text.FEDCaseText IS NOT NULL 
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--ZEUS Exposure

INSERT INTO MS_PROD.dbo.udZeusInsurerContact
(
fileId,[dteRepContDate],[cboDocType]
,[dteApproved],[dteRepStreDate],[txtApproved]
)
SELECT Main.fileId
,Main.FEDCaseDate AS [dteRepContDate]
,LIT1064.FEDCaseText AS [cboDocType]
,LIT1063Date.FEDCaseDate AS [dteApproved]
,LIT1074.FEDCaseDate AS [dteRepStreDate]
,LIT1063Text.FEDCaseText AS [txtApproved]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1063' AND FEDCaseDate IS NOT NULL AND StatusID=7 AND DataType='datetime' ) AS LIT1063Date    
 ON Main.fileID=LIT1063Date.fileID AND Main.seq_no=LIT1063Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1063' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='nvarchar(60)' ) AS LIT1063Text   
 ON Main.fileID=LIT1063Text.fileID AND Main.seq_no=LIT1063Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1064' AND StatusID=7 ) AS LIT1064   
 ON Main.fileID=LIT1064.fileID AND Main.seq_no=LIT1064.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT1074' AND StatusID=7 ) AS LIT1074   
 ON Main.fileID=LIT1074.fileID AND Main.seq_no=LIT1074.cd_parent 
 
WHERE Main.FEDDetailCode='LIT1062'
AND Main.StatusID=7
AND
(
Main.FEDCaseDate IS NOT NULL OR 
LIT1064.FEDCaseText IS NOT NULL OR 
LIT1063Date.FEDCaseDate IS NOT NULL OR 
LIT1074.FEDCaseDate IS NOT NULL OR 
LIT1063Text.FEDCaseText IS NOT NULL
)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--Zeus Insuerer Contact


INSERT INTO MS_PROD.dbo.udZeusInsuredContact
(
fileId,dteContDate,cboContType,[cboDirection]
,[cboOutcome],[cboReasonCont],[txtNotes],[txtOtherPartInv]
)


SELECT Main.fileId
,Main.FEDCaseDate AS [dteInitialContact]
,LIT340.FEDCaseText AS [cboContactType]
,LIT339.FEDCaseText AS [cboDirection]
,LIT341.FEDCaseText AS [cboOutcome]
,LIT342.FEDCaseText AS [cboReasonCont]
,LIT343.FEDCaseText AS [txtNotes]
,LIT338.FEDCaseText AS [txtOtherPartInv]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT340' AND StatusID=7 ) AS LIT340   
 ON Main.fileID=LIT340.fileID AND Main.seq_no=LIT340.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT339' AND StatusID=7 ) AS LIT339   
 ON Main.fileID=LIT339.fileID AND Main.seq_no=LIT339.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT341' AND StatusID=7 ) AS LIT341   
 ON Main.fileID=LIT341.fileID AND Main.seq_no=LIT341.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT342' AND StatusID=7 ) AS LIT342   
 ON Main.fileID=LIT342.fileID AND Main.seq_no=LIT342.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT343' AND StatusID=7 ) AS LIT343   
 ON Main.fileID=LIT343.fileID AND Main.seq_no=LIT343.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT338' AND StatusID=7 ) AS LIT338   
 ON Main.fileID=LIT338.fileID AND Main.seq_no=LIT338.cd_parent

WHERE Main.FEDDetailCode='LIT336'
AND Main.StatusID=7
AND 
(
Main.FEDCaseDate IS NOT NULL OR 
LIT340.FEDCaseText IS NOT NULL OR 
LIT339.FEDCaseText IS NOT NULL OR 
LIT341.FEDCaseText IS NOT NULL OR 
LIT342.FEDCaseText IS NOT NULL OR 
LIT343.FEDCaseText IS NOT NULL OR 
LIT338.FEDCaseText IS NOT NULL  
)
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--Zeus Insuered Contact Initial


INSERT INTO MS_PROD.dbo.udZeusInsuredContact
(
fileId,[dteContDate],[cboContType],[cboDirection],[cboOutcome]
,[cboReasonCont],[txtContTime],[txtNotes],[txtOtherPartInv],[txtReasonOther]
)

SELECT Main.fileId
,Main.FEDCaseDate AS [dteContDate]
,LIT708.FEDCaseText AS [cboContType]
,LIT707.FEDCaseText AS [cboDirection]
,LIT709.FEDCaseText AS [cboOutcome]
,LIT710.FEDCaseText AS [cboReasonCont]
,LIT345.FEDCaseText AS [txtContTime]
,LIT711.FEDCaseText AS [txtNotes]
,LIT706.FEDCaseText AS [txtOtherPartInv]
,LIT712.FEDCaseText AS [txtReasonOther]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT708' AND StatusID=7 ) AS LIT708   
 ON Main.fileID=LIT708.fileID AND Main.seq_no=LIT708.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT707' AND StatusID=7 ) AS LIT707   
 ON Main.fileID=LIT707.fileID AND Main.seq_no=LIT707.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT709' AND StatusID=7 ) AS LIT709   
 ON Main.fileID=LIT709.fileID AND Main.seq_no=LIT709.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT710' AND StatusID=7 ) AS LIT710   
 ON Main.fileID=LIT710.fileID AND Main.seq_no=LIT710.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT345' AND StatusID=7 ) AS LIT345   
 ON Main.fileID=LIT345.fileID AND Main.seq_no=LIT345.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT711' AND StatusID=7 ) AS LIT711   
 ON Main.fileID=LIT711.fileID AND Main.seq_no=LIT711.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT706' AND StatusID=7 ) AS LIT706   
 ON Main.fileID=LIT706.fileID AND Main.seq_no=LIT706.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT712' AND StatusID=7 ) AS LIT712   
 ON Main.fileID=LIT712.fileID AND Main.seq_no=LIT712.cd_parent
WHERE Main.FEDDetailCode='LIT344'
AND Main.StatusID=7
AND
(
Main.FEDCaseDate IS NOT NULL OR 
LIT708.FEDCaseText IS NOT NULL OR 
LIT707.FEDCaseText IS NOT NULL OR 
LIT709.FEDCaseText IS NOT NULL OR 
LIT710.FEDCaseText IS NOT NULL OR 
LIT345.FEDCaseText IS NOT NULL OR 
LIT711.FEDCaseText IS NOT NULL OR 
LIT706.FEDCaseText IS NOT NULL OR 
LIT712.FEDCaseText IS NOT NULL  
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--Zeus Insuered Contact Current

INSERT INTO MS_PROD.dbo.udCostOfSearch
(fileid,cboCostOfSearch)
SELECT Main.fileId
,Main.FEDCaseText AS [cboCostOfSearch]
FROM SearchListDetailStage AS Main
WHERE Main.FEDDetailCode='FRA103'
AND Main.StatusID=7
AND Main.FEDCaseText IS NOT NULL
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--- Cost of Search

INSERT INTO MS_PROD.dbo.udDateOfSearch
(fileid,dteDateOfSearch)
SELECT Main.fileId
,Main.FEDCaseDate AS [dteDateOfSearch]
FROM SearchListDetailStage AS Main
WHERE Main.FEDDetailCode='FRA102'
AND Main.StatusID=7
AND Main.FEDCaseDate IS NOT NULL
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--- Date of Search


INSERT INTO MS_PROD.dbo.udPostReceived
(fileid,curPostReceived)
SELECT Main.fileId
,Main.FEDCaseValue AS [curPostReceived]
FROM SearchListDetailStage AS Main
WHERE Main.FEDDetailCode='LIT057'
AND Main.StatusID=7
AND Main.FEDCaseValue  IS NOT NULL
ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--- Post Received

INSERT INTO MS_PROD.dbo.udClaimsMedicalExpert
(fileID,txtClaMeExNmLL,cboMedExtise)
SELECT Main.fileID
,Main.FEDCaseText AS [txtClaMeExNmLL]
,NMI786.FEDCaseText AS [cboMedExtise]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI786' AND StatusID=7) AS NMI786    
 ON Main.fileID=NMI786.fileID AND Main.seq_no=NMI786.cd_parent
WHERE Main.FEDDetailCode='NMI791'
AND Main.StatusID=7
AND 
(Main.FEDCaseText IS NOT NULL OR NMI786.FEDCaseText IS NOT NULL)
ORDER BY Main.FEDCaseID,Main.seq_no ASC

---ClaimsMedicalExpert


INSERT INTO MS_PROD.dbo.udClaimsNonMedicalExpert
(fileid,txtClaNonMedExp,cboNonMedExtise)
SELECT Main.fileID
,Main.FEDCaseText AS [txtClaNonMedExp]
,NMI801.FEDCaseText AS [cboNonMedExtise]
FROM SearchListDetailStage AS Main 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='NMI801' AND StatusID=7) AS NMI801    
 ON Main.fileID=NMI801.fileID AND Main.seq_no=NMI801.cd_parent
WHERE Main.FEDDetailCode='NMI800'
AND Main.StatusID=7
AND(Main.FEDCaseText IS NOT NULL OR NMI801.FEDCaseText IS NOT NULL)
ORDER BY Main.FEDCaseID,Main.seq_no ASC

--ClaimsNonMedicalExpert

 INSERT INTO MS_PROD.dbo.udClaimsLifecycle
 (fileid,[cboNotes],[dteNotes])
 SELECT Main.fileid
,Main.FEDCaseText AS [cboNotes]
,Main.FedCaseDate AS [dteNotes]

 FROM SearchListDetailStage AS Main
WHERE Main.FEDDetailCode='NMI804'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR Main.FEDCaseDate IS NOT NULL)
ORDER BY Main.FEDCaseID,Main.seq_no ASC

--MIB Claims Lifecycle

 INSERT INTO MS_PROD.dbo.udClaimsUnpaidBill
 (fileid,[txtUnpaidBillNo],[dteUnpaidBillNo])
 SELECT Main.fileid
,Main.FEDCaseText AS [txtUnpaidBillNo]
,Main.FedCaseDate AS [dteUnpaidBillNo]

 FROM SearchListDetailStage AS Main
WHERE Main.FEDDetailCode='NMI816'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR Main.FEDCaseDate IS NOT NULL)
ORDER BY Main.FEDCaseID,Main.seq_no ASC

-- Claims Unpaid Bill

INSERT INTO MS_PROD.dbo.udClaimsTPVehicle
(
fileId
,[txtTPVehMakMod]
,[cboCredRepairs]
,[cboReceiptPayIn]
,[cboTPVABIGroup]
,[txtTPVehReg1]
,[cboVehTotalLoss]
,[curValuePAVRep]
)
 
SELECT Main.fileId
,Main.FEDCaseText AS [txtTPVehMakMod]
,FTR452.FEDCaseText AS [cboCredRepairs]
,FTR508.FEDCaseText AS [cboReceiptPayIn]
,FTR509.FEDCaseText AS [cboTPVABIGroup]
,FTR507.FEDCaseText AS [txtTPVehReg1]
,FTR443.FEDCaseText AS [cboVehTotalLoss]
,FTR442.FEDCaseText AS [curValuePAVRep]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR452' AND StatusID=7 ) AS FTR452   
 ON Main.fileID=FTR452.fileID AND Main.seq_no=FTR452.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR508' AND StatusID=7 ) AS FTR508   
 ON Main.fileID=FTR508.fileID AND Main.seq_no=FTR508.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR509' AND StatusID=7 ) AS FTR509   
 ON Main.fileID=FTR509.fileID AND Main.seq_no=FTR509.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR507' AND StatusID=7 ) AS FTR507   
 ON Main.fileID=FTR507.fileID AND Main.seq_no=FTR507.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR443' AND StatusID=7 ) AS FTR443   
 ON Main.fileID=FTR443.fileID AND Main.seq_no=FTR443.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FTR442' AND StatusID=7 ) AS FTR442   
 ON Main.fileID=FTR442.fileID AND Main.seq_no=FTR442.cd_parent
WHERE Main.FEDDetailCode='TPC004'
AND Main.StatusID=7
AND 
(
Main.FEDCaseText IS NOT NULL  OR 
FTR452.FEDCaseText IS NOT NULL OR 
FTR508.FEDCaseText IS NOT NULL OR 
FTR509.FEDCaseText IS NOT NULL OR 
FTR507.FEDCaseText IS NOT NULL OR 
FTR443.FEDCaseText IS NOT NULL OR 
FTR442.FEDCaseText IS NOT NULL 
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC 

--- Claims TP Vehicle


INSERT INTO MS_PROD.dbo.udClaimsClNumber
(
fileid
,[txtClaimNum]
,[cboLeadFollow]
,[cboMFU]
,[cboWPType]
,[curClaiCostPaid]
,[curCRUPaid]
,[curCurrentRes]
,[curFeeBillPanel]
,[curGenDamPaid]
,[curMonRecovered]
,[curOurPropCosts]
,[curOurPropDamag]
,[curOwnDisbs]
,[curSpecDamPaid]
,[dteDamsPaid]
,[txtPHNamInsured]
,[cboClaimStat]
,[dteSetFormSeToZ]
)
SELECT Main.fileid
,Main.FEDCaseText AS [txtClaimNum]
,WPS276.FEDCaseText AS [cboLeadFollow]
,WPS335.FEDCaseText AS [cboMFU]
,WPS332.FEDCaseText AS [cboWPType]
,WPS280.FEDCaseValue AS [curClaiCostPaid]
,WPS281.FEDCaseValue AS [curCRUPaid]
,WPS277.FEDCaseValue AS [curCurrentRes]
,WPS340.FEDCaseValue AS [curFeeBillPanel]
,WPS278.FEDCaseValue AS [curGenDamPaid]
,WPS282.FEDCaseValue AS [curMonRecovered]
,WPS284.FEDCaseValue AS [curOurPropCosts]
,WPS283.FEDCaseValue AS [curOurPropDamag]
,WPS341.FEDCaseValue AS [curOwnDisbs]
,WPS279.FEDCaseValue AS [curSpecDamPaid]
,WPS262.FEDCaseDate AS [dteDamsPaid]
,WPS344.FEDCaseText AS [txtPHNamInsured]
,WPS387.FEDCaseText AS [cboClaimStat]
,WPS386.FEDCaseDate AS [dteSetFormSeToZ]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS276' AND StatusID=7 ) AS WPS276   
 ON Main.fileID=WPS276.fileID AND Main.seq_no=WPS276.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS335' AND StatusID=7 ) AS WPS335   
 ON Main.fileID=WPS335.fileID AND Main.seq_no=WPS335.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS332' AND StatusID=7 ) AS WPS332   
 ON Main.fileID=WPS332.fileID AND Main.seq_no=WPS332.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS280' AND StatusID=7 ) AS WPS280   
 ON Main.fileID=WPS280.fileID AND Main.seq_no=WPS280.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS281' AND StatusID=7 ) AS WPS281   
 ON Main.fileID=WPS281.fileID AND Main.seq_no=WPS281.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS277' AND StatusID=7 ) AS WPS277   
 ON Main.fileID=WPS277.fileID AND Main.seq_no=WPS277.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS340' AND StatusID=7 ) AS WPS340   
 ON Main.fileID=WPS340.fileID AND Main.seq_no=WPS340.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS278' AND StatusID=7 ) AS WPS278   
 ON Main.fileID=WPS278.fileID AND Main.seq_no=WPS278.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS282' AND StatusID=7 ) AS WPS282   
 ON Main.fileID=WPS282.fileID AND Main.seq_no=WPS282.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS284' AND StatusID=7 ) AS WPS284   
 ON Main.fileID=WPS284.fileID AND Main.seq_no=WPS284.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS283' AND StatusID=7 ) AS WPS283   
 ON Main.fileID=WPS283.fileID AND Main.seq_no=WPS283.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS341' AND StatusID=7 ) AS WPS341   
 ON Main.fileID=WPS341.fileID AND Main.seq_no=WPS341.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS279' AND StatusID=7 ) AS WPS279   
 ON Main.fileID=WPS279.fileID AND Main.seq_no=WPS279.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS262' AND StatusID=7 ) AS WPS262   
 ON Main.fileID=WPS262.fileID AND Main.seq_no=WPS262.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS344' AND StatusID=7 ) AS WPS344   
 ON Main.fileID=WPS344.fileID AND Main.seq_no=WPS344.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS387' AND StatusID=7 ) AS WPS387   
 ON Main.fileID=WPS387.fileID AND Main.seq_no=WPS387.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='WPS386' AND StatusID=7 ) AS WPS386   
 ON Main.fileID=WPS386.fileID AND Main.seq_no=WPS386.cd_parent

WHERE Main.FEDDetailCode='WPS275'
AND Main.StatusID=7
AND 
(
Main.FEDCaseText IS NOT NULL OR 
WPS276.FEDCaseText IS NOT NULL OR 
WPS335.FEDCaseText IS NOT NULL OR 
WPS332.FEDCaseText IS NOT NULL OR 
WPS280.FEDCaseValue IS NOT NULL OR 
WPS281.FEDCaseValue IS NOT NULL OR 
WPS277.FEDCaseValue IS NOT NULL OR 
WPS340.FEDCaseValue IS NOT NULL OR 
WPS278.FEDCaseValue IS NOT NULL OR 
WPS282.FEDCaseValue IS NOT NULL OR 
WPS284.FEDCaseValue IS NOT NULL OR 
WPS283.FEDCaseValue IS NOT NULL OR 
WPS341.FEDCaseValue IS NOT NULL OR 
WPS279.FEDCaseValue IS NOT NULL OR 
WPS262.FEDCaseDate IS NOT NULL OR 
WPS344.FEDCaseText IS NOT NULL
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC

--- ClaimsClNumber

INSERT INTO MS_PROD.dbo.udClaimsRecovery
(
fileID
,[dteRecovery]
,[cboRecovery]
,[curRecAmount]
,[txtRecWhom]
,[txtRecNote1]
,[txtRecNote2]
,[txtRecNote3]
,[txtRecTransNum]
,[curNetULRAch]
,[curULRCosts]
)
SELECT Main.fileID
,Main.FEDCaseDate AS [dteRecovery]
,VE00167.FEDCaseText AS [cboRecovery]
,VE00130.FEDCaseValue AS [curRecAmount]
,VE00134.FEDCaseText AS [txtRecWhom]
,VE00135.FEDCaseText AS [txtRecNote1]
,VE00136.FEDCaseText AS [txtRecNote2]
,VE00301.FEDCaseText AS [txtRecNote3]
,VE00328.FEDCaseText AS [txtRecTransNum]
,VE00329.FEDCaseValue AS [curNetULRAch]
,VE00330.FEDCaseValue AS [curULRCosts]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00167' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='ucodeLookup:nvarchar(15)' ) AS VE00167    
 ON Main.fileID=VE00167.fileID  AND Main.seq_no=VE00167.seq_no
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00130' AND StatusID=7 ) AS VE00130    
 ON Main.fileID=VE00130.fileID AND Main.seq_no=VE00130.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00134' AND StatusID=7 ) AS VE00134    
 ON Main.fileID=VE00134.fileID AND Main.seq_no=VE00134.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00135' AND StatusID=7 ) AS VE00135    
 ON Main.fileID=VE00135.fileID AND Main.seq_no=VE00135.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00136' AND StatusID=7 ) AS VE00136    
 ON Main.fileID=VE00136.fileID AND Main.seq_no=VE00136.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00301' AND StatusID=7 ) AS VE00301    
 ON Main.fileID=VE00301.fileID AND Main.seq_no=VE00301.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00328' AND StatusID=7 ) AS VE00328    
 ON Main.fileID=VE00328.fileID AND Main.seq_no=VE00328.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00329' AND StatusID=7 ) AS VE00329    
 ON Main.fileID=VE00329.fileID AND Main.seq_no=VE00329.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='VE00330' AND StatusID=7 ) AS VE00330    
 ON Main.fileID=VE00330.fileID AND Main.seq_no=VE00330.cd_parent 

WHERE Main.FEDDetailCode='VE00167'
AND Main.DataType='datetime'
AND Main.StatusID=7 
AND 
(
Main.FEDCaseDate IS NOT NULL OR 
VE00167.FEDCaseText  IS NOT NULL OR 
VE00130.FEDCaseValue  IS NOT NULL OR 
VE00134.FEDCaseText  IS NOT NULL OR 
VE00135.FEDCaseText  IS NOT NULL OR 
VE00136.FEDCaseText  IS NOT NULL OR 
VE00301.FEDCaseText  IS NOT NULL OR 
VE00328.FEDCaseText  IS NOT NULL OR 
VE00329.FEDCaseValue  IS NOT NULL OR 
VE00330.FEDCaseValue  IS NOT NULL  
)
ORDER BY Main.FEDCaseID,Main.seq_no ASC

--Converge Recoveries

INSERT INTO MS_PROD.dbo.udIntel
(
fileID
,[dteInstruction]
,[dteHandlerAlloc]
,[txtOpName]
,[cboInstructType]
,[dteIntelInstrCo]
,[cboIntelInstr]
,[txtHandler]
)

SELECT Main.fileID
,Main.FEDCaseDate AS [dteInstruction]
,FRA157.FEDCaseDate AS [dteHandlerAlloc]
,FRA158.FEDCaseText AS [txtOpName]
,FRA156.FEDCaseText AS [cboInstructType]
,FRA155.FEDCaseDate AS [dteIntelInstrCo]
,FRA152.FEDCaseText AS [cboIntelInstr]
,FRA154.FEDCaseText AS [txtHandler]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA157' AND StatusID=7 ) AS FRA157    
 ON Main.fileID=FRA157.fileID AND Main.seq_no=FRA157.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA158' AND StatusID=7 ) AS FRA158    
 ON Main.fileID=FRA158.fileID AND Main.seq_no=FRA158.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA156' AND StatusID=7 ) AS FRA156    
 ON Main.fileID=FRA156.fileID AND Main.seq_no=FRA156.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA155' AND StatusID=7 ) AS FRA155    
 ON Main.fileID=FRA155.fileID AND Main.seq_no=FRA155.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA152' AND StatusID=7 ) AS FRA152    
 ON Main.fileID=FRA152.fileID AND Main.seq_no=FRA152.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='FRA154' AND StatusID=7 ) AS FRA154    
 ON Main.fileID=FRA154.fileID AND Main.seq_no=FRA154.cd_parent  
WHERE Main.FEDDetailCode='FRA153'
AND Main.DataType='datetime'
AND Main.StatusID=7 
AND 
(
Main.FEDCaseDate  IS NOT NULL OR 
FRA157.FEDCaseDate  IS NOT NULL OR 
FRA158.FEDCaseText  IS NOT NULL OR 
FRA156.FEDCaseText  IS NOT NULL OR 
FRA155.FEDCaseDate  IS NOT NULL OR 
FRA152.FEDCaseText IS NOT NULL OR 
FRA154.FEDCaseText  IS NOT NULL 
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC

--Intel Details


INSERT INTO  MS_PROD.dbo.udZurPayReqSL
(
fileID
,[cboZurPayReq]
,[cboZurPayType]
,[txtPayReqDate]
,[txtCheqRef]
,[cboFeeType]
,[txtPayWhom]
,[curTPSolProf]
,[curTPSolIns]
,[curTPSolFeeAm]
,[curOwnCounFee]
,[curOtherDisbs]
,[curTPSpecDam]
,[curTPStorage]
,[curTPVehRep]
,[curTPHire]
,[curTPGenDam]
,[curDWP]
,[curVATonTPCos]
,[curTotReqZur]
)
SELECT Main.fileID
,Main.FEDCaseDate AS [cboZurPayReq]
,LIT302.FEDCaseText AS [cboZurPayType]
,LIT303.FEDCaseText AS [txtPayReqDate]
,LIT304.FEDCaseText AS [txtCheqRef]
,LIT305.FEDCaseText AS [cboFeeType]
,LIT306.FEDCaseText AS [txtPayWhom]
,LIT307.FEDCaseValue AS [curTPSolProf]
,LIT308.FEDCaseValue AS [curTPSolIns]
,LIT309.FEDCaseValue AS [curTPSolFeeAm]
,LIT310.FEDCaseValue AS [curOwnCounFee]
,LIT311.FEDCaseValue AS [curOtherDisbs]
,LIT312.FEDCaseValue AS [curTPSpecDam]
,LIT313.FEDCaseValue AS [curTPStorage]
,LIT314.FEDCaseValue AS [curTPVehRep]
,LIT315.FEDCaseValue AS [curTPHire]
,LIT316.FEDCaseValue AS [curTPGenDam]
,LIT317.FEDCaseValue AS [curDWP]
,LIT318.FEDCaseValue AS [curVATonTPCos]
,LIT319.FEDCaseValue AS [curTotReqZur]
FROM SearchListDetailStage AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT302' AND StatusID=7 ) AS LIT302    
 ON Main.fileID=LIT302.fileID AND Main.seq_no=LIT302.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT303' AND StatusID=7 ) AS LIT303    
 ON Main.fileID=LIT303.fileID AND Main.seq_no=LIT303.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT304' AND StatusID=7 ) AS LIT304    
 ON Main.fileID=LIT304.fileID AND Main.seq_no=LIT304.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT305' AND StatusID=7 ) AS LIT305    
 ON Main.fileID=LIT305.fileID AND Main.seq_no=LIT305.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT306' AND StatusID=7 ) AS LIT306    
 ON Main.fileID=LIT306.fileID AND Main.seq_no=LIT306.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT307' AND StatusID=7 ) AS LIT307    
 ON Main.fileID=LIT307.fileID AND Main.seq_no=LIT307.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT308' AND StatusID=7 ) AS LIT308    
 ON Main.fileID=LIT308.fileID AND Main.seq_no=LIT308.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT309' AND StatusID=7 ) AS LIT309    
 ON Main.fileID=LIT309.fileID AND Main.seq_no=LIT309.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT310' AND StatusID=7 ) AS LIT310    
 ON Main.fileID=LIT310.fileID AND Main.seq_no=LIT310.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT311' AND StatusID=7 ) AS LIT311    
 ON Main.fileID=LIT311.fileID AND Main.seq_no=LIT311.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT312' AND StatusID=7 ) AS LIT312    
 ON Main.fileID=LIT312.fileID AND Main.seq_no=LIT312.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT313' AND StatusID=7 ) AS LIT313    
 ON Main.fileID=LIT313.fileID AND Main.seq_no=LIT313.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT314' AND StatusID=7 ) AS LIT314    
 ON Main.fileID=LIT314.fileID AND Main.seq_no=LIT314.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT315' AND StatusID=7 ) AS LIT315    
 ON Main.fileID=LIT315.fileID AND Main.seq_no=LIT315.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT316' AND StatusID=7 ) AS LIT316    
 ON Main.fileID=LIT316.fileID AND Main.seq_no=LIT316.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT317' AND StatusID=7 ) AS LIT317    
 ON Main.fileID=LIT317.fileID AND Main.seq_no=LIT317.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT318' AND StatusID=7 ) AS LIT318    
 ON Main.fileID=LIT318.fileID AND Main.seq_no=LIT318.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStage WHERE FEDDetailCode='LIT319' AND StatusID=7 ) AS LIT319    
 ON Main.fileID=LIT319.fileID AND Main.seq_no=LIT319.cd_parent
WHERE Main.FEDDetailCode='LIT301'
AND Main.StatusID=7 
AND
(
Main.FEDCaseDate IS NOT NULL OR
LIT302.FEDCaseText IS NOT NULL OR
LIT303.FEDCaseText IS NOT NULL OR
LIT304.FEDCaseText IS NOT NULL OR
LIT305.FEDCaseText IS NOT NULL OR
LIT306.FEDCaseText IS NOT NULL OR
LIT307.FEDCaseValue IS NOT NULL OR
LIT308.FEDCaseValue IS NOT NULL OR
LIT309.FEDCaseValue IS NOT NULL OR
LIT310.FEDCaseValue IS NOT NULL OR
LIT311.FEDCaseValue IS NOT NULL OR
LIT312.FEDCaseValue IS NOT NULL OR
LIT313.FEDCaseValue IS NOT NULL OR
LIT314.FEDCaseValue IS NOT NULL OR
LIT315.FEDCaseValue IS NOT NULL OR
LIT316.FEDCaseValue IS NOT NULL OR
LIT317.FEDCaseValue IS NOT NULL OR
LIT318.FEDCaseValue IS NOT NULL OR
LIT319.FEDCaseValue IS NOT NULL
)

ORDER BY Main.FEDCaseID,Main.seq_no ASC

--ZURICH Payments
END



GO
