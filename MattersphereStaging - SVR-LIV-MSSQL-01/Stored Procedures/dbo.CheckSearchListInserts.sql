SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CheckSearchListInserts]
AS
BEGIN
DECLARE @Date AS DATE
SET @Date=(SELECT CONVERT(DATE,GETDATE(),103))


SELECT COUNT(1) AS  AIGStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT195' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS LIT195    
 ON Main.fileID=LIT195.fileID AND Main.seq_no=LIT195.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT196' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS LIT196    
 ON Main.fileID=LIT196.fileID AND Main.seq_no=LIT196.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT197' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS LIT197    
 ON Main.fileID=LIT197.fileID AND Main.seq_no=LIT197.cd_parent
WHERE Main.FEDDetailCode='LIT194'
AND Main.StatusID=7
AND (LIT195.FEDCaseValue IS NOT NULL OR LIT196.FEDCaseDate IS NOT NULL OR LIT197.FEDCaseText  IS NOT NULL)
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS AIGInserted FROM MS_PROD.dbo.udAIGBudgetApproval WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udAIGBudgetApproval')
--AIG BUDGETS 

SELECT COUNT(1) AS EMPStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='EMP167' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS EMP167    
 ON Main.fileID=EMP167.fileID AND Main.seq_no=EMP167.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='EMP169' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS EMP169    
 ON Main.fileID=EMP169.fileID AND Main.seq_no=EMP169.cd_parent
WHERE Main.FEDDetailCode='EMP171'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR EMP167.FEDCaseValue IS NOT NULL OR EMP169.FEDCaseDate IS NOT NULL)
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS EMPInserted FROM MS_PROD.dbo.udEmpRTSearchList WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udEmpRTSearchList')

SELECT COUNT(1) AS HireStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR350' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR350    
 ON Main.fileID=FTR350.fileID AND Main.seq_no=FTR350.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR512' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR512    
 ON Main.fileID=FTR512.fileID AND Main.seq_no=FTR512.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR330' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR330    
 ON Main.fileID=FTR330.fileID AND Main.seq_no=FTR330.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR108' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR108    
 ON Main.fileID=FTR108.fileID AND Main.seq_no=FTR108.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR109' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR109    
 ON Main.fileID=FTR109.fileID AND Main.seq_no=FTR109.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR441' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR441    
 ON Main.fileID=FTR441.fileID AND Main.seq_no=FTR441.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR329' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR329    
 ON Main.fileID=FTR329.fileID AND Main.seq_no=FTR329.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='TPC129' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS TPC129    
 ON Main.fileID=TPC129.fileID AND Main.seq_no=TPC129.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='TPC098' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS TPC098    
 ON Main.fileID=TPC098.fileID AND Main.seq_no=TPC098.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR424' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR424    
 ON Main.fileID=FTR424.fileID AND Main.seq_no=FTR424.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR445' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR445    
 ON Main.fileID=FTR445.fileID AND Main.seq_no=FTR445.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR423' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR423    
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
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS HireInserted FROM MS_PROD.dbo.udHire WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udHire')

SELECT COUNT(1) AS EntityStaged

FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA093' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA093Text    
 ON Main.fileID=FRA093Text.fileID AND Main.seq_no=FRA093Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA093' AND StatusID=7 AND DataType='datetime' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA093Date    
 ON Main.fileID=FRA093Date.fileID AND Main.seq_no=FRA093Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA093' AND StatusID=7 AND DataType='money' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA093Value    
 ON Main.fileID=FRA093Value.fileID AND Main.seq_no=FRA093Value.cd_parent 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA094' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA094Text    
 ON Main.fileID=FRA094Text.fileID AND Main.seq_no=FRA094Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA094' AND StatusID=7 AND DataType='datetime' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA094Date    
 ON Main.fileID=FRA094Date.fileID AND Main.seq_no=FRA094Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA094' AND StatusID=7 AND DataType='money' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA094Value    
 ON Main.fileID=FRA094Value.fileID AND Main.seq_no=FRA094Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA095' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA095Text    
 ON Main.fileID=FRA095Text.fileID AND Main.seq_no=FRA095Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA095' AND StatusID=7 AND DataType='datetime' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA095Date    
 ON Main.fileID=FRA095Date.fileID AND Main.seq_no=FRA095Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA095' AND StatusID=7 AND DataType='money' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA095Value    
 ON Main.fileID=FRA095Value.fileID AND Main.seq_no=FRA095Value.cd_parent  
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA096' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA096Text    
 ON Main.fileID=FRA096Text.fileID AND Main.seq_no=FRA096Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA096' AND StatusID=7 AND DataType='datetime' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA096Date    
 ON Main.fileID=FRA096Date.fileID AND Main.seq_no=FRA096Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA096' AND StatusID=7 AND DataType='money' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA096Value    
 ON Main.fileID=FRA096Value.fileID AND Main.seq_no=FRA096Value.cd_parent  

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA097' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA097Text    
 ON Main.fileID=FRA097Text.fileID AND Main.seq_no=FRA097Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA097' AND StatusID=7 AND DataType='datetime' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA097Date    
 ON Main.fileID=FRA097Date.fileID AND Main.seq_no=FRA097Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA097' AND StatusID=7 AND DataType='money' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA097Value    
 ON Main.fileID=FRA097Value.fileID AND Main.seq_no=FRA097Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA098' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA098Text    
 ON Main.fileID=FRA098Text.fileID AND Main.seq_no=FRA098Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA098' AND StatusID=7 AND DataType='datetime'  AND CONVERT(DATE,InsertDate,103)='2019-02-08') AS FRA098Date    
 ON Main.fileID=FRA098Date.fileID AND Main.seq_no=FRA098Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA098' AND StatusID=7 AND DataType='money' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA098Value    
 ON Main.fileID=FRA098Value.fileID AND Main.seq_no=FRA098Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA100' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA100Text    
 ON Main.fileID=FRA100Text.fileID AND Main.seq_no=FRA100Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA100' AND StatusID=7 AND DataType='datetime' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA100Date    
 ON Main.fileID=FRA100Date.fileID AND Main.seq_no=FRA100Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA100' AND StatusID=7 AND DataType='money'  AND CONVERT(DATE,InsertDate,103)='2019-02-08') AS FRA100Value    
 ON Main.fileID=FRA100Value.fileID AND Main.seq_no=FRA100Value.cd_parent 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA101' AND StatusID=7 AND DataType='nvarchar(60)' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA101Text    
 ON Main.fileID=FRA101Text.fileID AND Main.seq_no=FRA101Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA101' AND StatusID=7 AND DataType='datetime' AND CONVERT(DATE,InsertDate,103)='2019-02-08' ) AS FRA101Date    
 ON Main.fileID=FRA101Date.fileID AND Main.seq_no=FRA101Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA101' AND StatusID=7 AND DataType='money' AND CONVERT(DATE,InsertDate,103)='2019-02-08'  ) AS FRA101Value    
 ON Main.fileID=FRA101Value.fileID AND Main.seq_no=FRA101Value.cd_parent 
  
WHERE Main.FEDDetailCode='FRA099'
AND Main.StatusID=7
AND CONVERT(DATE,Main.InsertDate,103)='2019-02-08'
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

SELECT COUNT(1) AS EntityInserted FROM MS_PROD.dbo.udEntityName WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udEntityName')

SELECT COUNT(1) AS DateAuditStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT119' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT119    
 ON Main.fileID=LIT119.fileID AND Main.seq_no=LIT119.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT129' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT129    
 ON Main.fileID=LIT129.fileID AND Main.seq_no=LIT129.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT118' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT118    
 ON Main.fileID=LIT118.fileID AND Main.seq_no=LIT118.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT127' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT127    
 ON Main.fileID=LIT127.fileID AND Main.seq_no=LIT127.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT123' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT123    
 ON Main.fileID=LIT123.fileID AND Main.seq_no=LIT123.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT126' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT126    
 ON Main.fileID=LIT126.fileID AND Main.seq_no=LIT126.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT125' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT125    
 ON Main.fileID=LIT125.fileID AND Main.seq_no=LIT125.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT115' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT115    
 ON Main.fileID=LIT115.fileID AND Main.seq_no=LIT115.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1082' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1082    
 ON Main.fileID=LIT1082.fileID AND Main.seq_no=LIT1082.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT699' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT699    
 ON Main.fileID=LIT699.fileID AND Main.seq_no=LIT699.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT211' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT211    
 ON Main.fileID=LIT211.fileID AND Main.seq_no=LIT211.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT124' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT124    
 ON Main.fileID=LIT124.fileID AND Main.seq_no=LIT124.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT122' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT122    
 ON Main.fileID=LIT122.fileID AND Main.seq_no=LIT122.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT128' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT128    
 ON Main.fileID=LIT128.fileID AND Main.seq_no=LIT128.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT116' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT116    
 ON Main.fileID=LIT116.fileID AND Main.seq_no=LIT116.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT120' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT120    
 ON Main.fileID=LIT120.fileID AND Main.seq_no=LIT120.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT121' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT121    
 ON Main.fileID=LIT121.fileID AND Main.seq_no=LIT121.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT117' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT117    
 ON Main.fileID=LIT117.fileID AND Main.seq_no=LIT117.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT130' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT130    
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
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS DateauditInserted FROM MS_PROD.dbo.udDateOfAudit WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udDateOfAudit')

SELECT COUNT(1) AS DAPaymentStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB042' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB042    
 ON Main.fileID=MIB042.fileID AND Main.seq_no=MIB042.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB043' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB043    
 ON Main.fileID=MIB043.fileID AND Main.seq_no=MIB043.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB045' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='ucodeLookup:nvarchar(15)' ) AS MIB045Text    
 ON Main.fileID=MIB045Text.fileID AND Main.seq_no=MIB045Text.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB045' AND FEDCaseDate IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='datetime') AS MIB045Date   
 ON Main.fileID=MIB045Date.fileID AND Main.seq_no=MIB045Date.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB046' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB046    
 ON Main.fileID=MIB046.fileID AND Main.seq_no=MIB046.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB040' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB040    
 ON Main.fileID=MIB040.fileID AND Main.seq_no=MIB040.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB047' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB047    
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
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS DAPaymentInserted FROM MS_PROD.dbo.udDAPayment WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udDAPayment')

SELECT COUNT(1) AS DABillsStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB039' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money'  ) AS MIB039    
 ON Main.fileID=MIB039.fileID AND Main.seq_no=MIB039.seq_no 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB049' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB049    
 ON Main.fileID=MIB049.fileID AND Main.seq_no=MIB049.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB048' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB048    
 ON Main.fileID=MIB048.fileID AND Main.seq_no=MIB048.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB041' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB041    
 ON Main.fileID=MIB041.fileID AND Main.seq_no=MIB041.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='MIB044' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS MIB044    
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
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS DABillsInserted FROM MS_PROD.dbo.udDABill WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udDABill')

SELECT COUNT(1) AS RSAStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI932' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND FEDCaseText IS NOT NULL ) AS NMI932    
 ON Main.fileID=NMI932.fileID AND Main.seq_no=NMI932.seq_no 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI952' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI952    
 ON Main.fileID=NMI952.fileID AND Main.seq_no=NMI952.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI972' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI972    
 ON Main.fileID=NMI972.fileID AND Main.seq_no=NMI972.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI954' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI954    
 ON Main.fileID=NMI954.fileID AND Main.seq_no=NMI954.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI951' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI951    
 ON Main.fileID=NMI951.fileID AND Main.seq_no=NMI951.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI971' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI971    
 ON Main.fileID=NMI971.fileID AND Main.seq_no=NMI971.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI947' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI947    
 ON Main.fileID=NMI947.fileID AND Main.seq_no=NMI947.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI941' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI941    
 ON Main.fileID=NMI941.fileID AND Main.seq_no=NMI941.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI944' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI944    
 ON Main.fileID=NMI944.fileID AND Main.seq_no=NMI944.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI938' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI938    
 ON Main.fileID=NMI938.fileID AND Main.seq_no=NMI938.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI936' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI936    
 ON Main.fileID=NMI936.fileID AND Main.seq_no=NMI936.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI934' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI934    
 ON Main.fileID=NMI934.fileID AND Main.seq_no=NMI934.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI948' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI948    
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
)AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS RSAInserted FROM MS_PROD.dbo.udRSADsePayReq WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udRSADsePayReq')

SELECT COUNT(1) AS ConvergePaymentStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00156' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='ucodeLookup:nvarchar(15)' ) AS VE00156    
 ON Main.fileID=VE00156.fileID  AND Main.seq_no=VE00156.seq_no 
 

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE0032' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE0032    
 ON Main.fileID=VE0032.fileID AND Main.seq_no=VE0032.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00160' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00160    
 ON Main.fileID=VE00160.fileID AND Main.seq_no=VE00160.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00158' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00158    
 ON Main.fileID=VE00158.fileID AND Main.seq_no=VE00158.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00159' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00159    
 ON Main.fileID=VE00159.fileID AND Main.seq_no=VE00159.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00152' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00152    
 ON Main.fileID=VE00152.fileID AND Main.seq_no=VE00152.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00154' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00154    
 ON Main.fileID=VE00154.fileID AND Main.seq_no=VE00154.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00141' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00141    
 ON Main.fileID=VE00141.fileID AND Main.seq_no=VE00141.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00140' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00140    
 ON Main.fileID=VE00140.fileID AND Main.seq_no=VE00140.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00153' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00153    
 ON Main.fileID=VE00153.fileID AND Main.seq_no=VE00153.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00155' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00155    
 ON Main.fileID=VE00155.fileID AND Main.seq_no=VE00155.cd_parent      
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00142' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00142    
 ON Main.fileID=VE00142.fileID AND Main.seq_no=VE00142.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00144' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00144    
 ON Main.fileID=VE00144.fileID AND Main.seq_no=VE00144.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00145' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00145    
 ON Main.fileID=VE00145.fileID AND Main.seq_no=VE00145.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00146' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00146    
 ON Main.fileID=VE00146.fileID AND Main.seq_no=VE00146.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00147' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00147    
 ON Main.fileID=VE00147.fileID AND Main.seq_no=VE00147.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00148' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00148    
 ON Main.fileID=VE00148.fileID AND Main.seq_no=VE00148.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00149' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00149    
 ON Main.fileID=VE00149.fileID AND Main.seq_no=VE00149.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00583' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00583    
 ON Main.fileID=VE00583.fileID AND Main.seq_no=VE00583.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00151' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00151    
 ON Main.fileID=VE00151.fileID AND Main.seq_no=VE00151.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00143' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00143    
 ON Main.fileID=VE00143.fileID AND Main.seq_no=VE00143.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00150' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00150    
 ON Main.fileID=VE00150.fileID AND Main.seq_no=VE00150.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00139' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00139    
 ON Main.fileID=VE00139.fileID AND Main.seq_no=VE00139.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00931' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00931    
 ON Main.fileID=VE00931.fileID AND Main.seq_no=VE00931.cd_parent  
 
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
)AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS ConvergePaymentInserted FROM MS_PROD.dbo.udPayment WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udPayment')

SELECT COUNT(1) AS ZeusReserveStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT723' AND Datatype='money' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT723    
 ON Main.fileID=LIT723.fileID AND Main.seq_no=LIT723.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT722' AND Datatype='money' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT722    
 ON Main.fileID=LIT722.fileID AND Main.seq_no=LIT722.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT725' AND Datatype='money' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT725    
 ON Main.fileID=LIT725.fileID AND Main.seq_no=LIT725.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT724' AND Datatype='money' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT724    
 ON Main.fileID=LIT724.fileID AND Main.seq_no=LIT724.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1028' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1028    
 ON Main.fileID=LIT1028.fileID AND Main.seq_no=LIT1028.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1027' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1027    
 ON Main.fileID=LIT1027.fileID AND Main.seq_no=LIT1027.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1030' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1030    
 ON Main.fileID=LIT1030.fileID AND Main.seq_no=LIT1030.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1032' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1032    
 ON Main.fileID=LIT1032.fileID AND Main.seq_no=LIT1032.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1031' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1031    
 ON Main.fileID=LIT1031.fileID AND Main.seq_no=LIT1031.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1025' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1025    
 ON Main.fileID=LIT1025.fileID AND Main.seq_no=LIT1025.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1029' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1029    
 ON Main.fileID=LIT1029.fileID AND Main.seq_no=LIT1029.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1024' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1024    
 ON Main.fileID=LIT1024.fileID AND Main.seq_no=LIT1024.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1033' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1033    
 ON Main.fileID=LIT1033.fileID AND Main.seq_no=LIT1033.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1017' AND Datatype='money'AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1017    
 ON Main.fileID=LIT1017.fileID AND Main.seq_no=LIT1017.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1241' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1241    
 ON Main.fileID=LIT1241.fileID AND Main.seq_no=LIT1241.cd_parent 
LEFT OUTER JOIN (SELECT DISTINCT fileID,seq_no,FEDCaseText,cd_parent FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1071' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1071Text    
 ON Main.fileID=LIT1071Text.fileID AND Main.seq_no=LIT1071Text.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1070' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1070    
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
)AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS ZeusReserveInserted FROM MS_PROD.dbo.udZeusReserve WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udZeusReserve')

SELECT COUNT(1) AS ZeusPaymentsStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT775' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT775Text    
 ON Main.fileID=LIT775Text.fileID AND Main.seq_no=LIT775Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT784' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT784Text    
 ON Main.fileID=LIT784Text.fileID AND Main.seq_no=LIT784Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT785' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT785Text    
 ON Main.fileID=LIT785Text.fileID AND Main.seq_no=LIT785Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT786' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT786Text    
 ON Main.fileID=LIT786Text.fileID AND Main.seq_no=LIT786Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT799' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT799Text    
 ON Main.fileID=LIT799Text.fileID AND Main.seq_no=LIT799Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1098' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT1098Text    
 ON Main.fileID=LIT1098Text.fileID AND Main.seq_no=LIT1098Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1098' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT1098Value   
 ON Main.fileID=LIT1098Value.fileID AND Main.seq_no=LIT1098Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT777' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT777Text    
 ON Main.fileID=LIT777Text.fileID AND Main.seq_no=LIT777Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT777' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT777Value   
 ON Main.fileID=LIT777Value.fileID AND Main.seq_no=LIT777Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1100' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT1100Text    
 ON Main.fileID=LIT1100Text.fileID AND Main.seq_no=LIT1100Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1100' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT1100Value   
 ON Main.fileID=LIT1100Value.fileID AND Main.seq_no=LIT1100Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1102' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT1102Text    
 ON Main.fileID=LIT1102Text.fileID AND Main.seq_no=LIT1102Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1102' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT1102Value   
 ON Main.fileID=LIT1102Value.fileID AND Main.seq_no=LIT1102Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT461' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT461Text    
 ON Main.fileID=LIT461Text.fileID AND Main.seq_no=LIT461Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT461' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT461Value   
 ON Main.fileID=LIT461Value.fileID AND Main.seq_no=LIT461Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT463' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT463Text    
 ON Main.fileID=LIT463Text.fileID AND Main.seq_no=LIT463Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT463' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT463Value   
 ON Main.fileID=LIT463Value.fileID AND Main.seq_no=LIT463Value.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT465' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT465Text    
 ON Main.fileID=LIT465Text.fileID AND Main.seq_no=LIT465Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT465' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT465Value   
 ON Main.fileID=LIT465Value.fileID AND Main.seq_no=LIT465Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT467' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT467Text    
 ON Main.fileID=LIT467Text.fileID AND Main.seq_no=LIT467Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT467' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT467Value   
 ON Main.fileID=LIT467Value.fileID AND Main.seq_no=LIT467Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT469' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='uCodeLookup:nvarchar(15)' ) AS LIT469Text    
 ON Main.fileID=LIT469Text.fileID AND Main.seq_no=LIT469Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT469' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT469Value   
 ON Main.fileID=LIT469Value.fileID AND Main.seq_no=LIT469Value.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT790' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT790   
 ON Main.fileID=LIT790.fileID AND Main.seq_no=LIT790.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT789' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT789   
 ON Main.fileID=LIT789.fileID AND Main.seq_no=LIT789.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT798' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT798   
 ON Main.fileID=LIT798.fileID AND Main.seq_no=LIT798.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT791' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT791   
 ON Main.fileID=LIT791.fileID AND Main.seq_no=LIT791.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT818' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT818   
 ON Main.fileID=LIT818.fileID AND Main.seq_no=LIT818.cd_parent     

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1099' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT1099Text    
 ON Main.fileID=LIT1099Text.fileID AND Main.seq_no=LIT1099Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1099' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT1099Value   
 ON Main.fileID=LIT1099Value.fileID AND Main.seq_no=LIT1099Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1101' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT1101Text    
 ON Main.fileID=LIT1101Text.fileID AND Main.seq_no=LIT1101Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1101' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT1101Value   
 ON Main.fileID=LIT1101Value.fileID AND Main.seq_no=LIT1101Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT460' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT460Text    
 ON Main.fileID=LIT460Text.fileID AND Main.seq_no=LIT460Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT460' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT460Value   
 ON Main.fileID=LIT460Value.fileID AND Main.seq_no=LIT460Value.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT462' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT462Text    
 ON Main.fileID=LIT462Text.fileID AND Main.seq_no=LIT462Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT462' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT462Value   
 ON Main.fileID=LIT462Value.fileID AND Main.seq_no=LIT462Value.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT464' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT464Text    
 ON Main.fileID=LIT464Text.fileID AND Main.seq_no=LIT464Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT464' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT464Value   
 ON Main.fileID=LIT464Value.fileID AND Main.seq_no=LIT464Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT466' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT466Text    
 ON Main.fileID=LIT466Text.fileID AND Main.seq_no=LIT466Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT466' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT466Value   
 ON Main.fileID=LIT466Value.fileID AND Main.seq_no=LIT466Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT468' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT468Text    
 ON Main.fileID=LIT468Text.fileID AND Main.seq_no=LIT468Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT468' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT468Value   
 ON Main.fileID=LIT468Value.fileID AND Main.seq_no=LIT468Value.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT815' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT815Text    
 ON Main.fileID=LIT815Text.fileID AND Main.seq_no=LIT815Text.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT815' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='date' ) AS LIT815Date   
 ON Main.fileID=LIT815Date.fileID AND Main.seq_no=LIT815Date.cd_parent 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT817' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT817   
 ON Main.fileID=LIT817.fileID AND Main.seq_no=LIT817.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1090' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT1090   
 ON Main.fileID=LIT1090.fileID AND Main.seq_no=LIT1090.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1089' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT1089   
 ON Main.fileID=LIT1089.fileID AND Main.seq_no=LIT1089.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1091' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT1091   
 ON Main.fileID=LIT1091.fileID AND Main.seq_no=LIT1091.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1080' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT1080   
 ON Main.fileID=LIT1080.fileID AND Main.seq_no=LIT1080.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1081' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT1081   
 ON Main.fileID=LIT1081.fileID AND Main.seq_no=LIT1081.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT787' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT787   
 ON Main.fileID=LIT787.fileID AND Main.seq_no=LIT787.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT813' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT813   
 ON Main.fileID=LIT813.fileID AND Main.seq_no=LIT813.cd_parent    
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT810' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT810   
 ON Main.fileID=LIT810.fileID AND Main.seq_no=LIT810.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT809' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT809   
 ON Main.fileID=LIT809.fileID AND Main.seq_no=LIT809.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT807' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT807   
 ON Main.fileID=LIT807.fileID AND Main.seq_no=LIT807.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT802' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT802   
 ON Main.fileID=LIT802.fileID AND Main.seq_no=LIT802.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT805' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT805   
 ON Main.fileID=LIT805.fileID AND Main.seq_no=LIT805.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT804' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT804   
 ON Main.fileID=LIT804.fileID AND Main.seq_no=LIT804.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT814' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT814   
 ON Main.fileID=LIT814.fileID AND Main.seq_no=LIT814.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT811' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT811   
 ON Main.fileID=LIT811.fileID AND Main.seq_no=LIT811.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT812' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT812   
 ON Main.fileID=LIT812.fileID AND Main.seq_no=LIT812.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT806' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT806   
 ON Main.fileID=LIT806.fileID AND Main.seq_no=LIT806.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT803' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT803   
 ON Main.fileID=LIT803.fileID AND Main.seq_no=LIT803.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT801' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT801   
 ON Main.fileID=LIT801.fileID AND Main.seq_no=LIT801.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT808' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT808   
 ON Main.fileID=LIT808.fileID AND Main.seq_no=LIT808.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT800' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT800   
 ON Main.fileID=LIT800.fileID AND Main.seq_no=LIT800.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT778' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT778   
 ON Main.fileID=LIT778.fileID AND Main.seq_no=LIT778.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT796' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT796   
 ON Main.fileID=LIT796.fileID AND Main.seq_no=LIT796.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT797' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT797   
 ON Main.fileID=LIT797.fileID AND Main.seq_no=LIT797.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT782' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT782   
 ON Main.fileID=LIT782.fileID AND Main.seq_no=LIT782.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT779' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT779   
 ON Main.fileID=LIT779.fileID AND Main.seq_no=LIT779.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT793' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT793   
 ON Main.fileID=LIT793.fileID AND Main.seq_no=LIT793.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT794' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT794   
 ON Main.fileID=LIT794.fileID AND Main.seq_no=LIT794.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT795' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT795   
 ON Main.fileID=LIT795.fileID AND Main.seq_no=LIT795.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT819' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT819   
 ON Main.fileID=LIT819.fileID AND Main.seq_no=LIT819.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT820' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT820   
 ON Main.fileID=LIT820.fileID AND Main.seq_no=LIT820.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT780' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT780   
 ON Main.fileID=LIT780.fileID AND Main.seq_no=LIT780.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT821' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT821   
 ON Main.fileID=LIT821.fileID AND Main.seq_no=LIT821.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT816' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT816   
 ON Main.fileID=LIT816.fileID AND Main.seq_no=LIT816.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT792' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT792   
 ON Main.fileID=LIT792.fileID AND Main.seq_no=LIT792.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT822' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT822   
 ON Main.fileID=LIT822.fileID AND Main.seq_no=LIT822.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT783' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT783   
 ON Main.fileID=LIT783.fileID AND Main.seq_no=LIT783.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT781' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date  ) AS LIT781   
 ON Main.fileID=LIT781.fileID AND Main.seq_no=LIT781.cd_parent 
WHERE Main.FEDDetailCode='LIT775'
AND Main.DataType='datetime'
AND Main.StatusID=7
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS ZeusPaymentsInserted FROM MS_PROD.dbo.udZeusPaymentApp WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udZeusPaymentApp')

SELECT COUNT(1) AS ZeusExposureStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT354' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT354    
 ON Main.fileID=LIT354.fileID AND Main.seq_no=LIT354.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1077' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1077    
 ON Main.fileID=LIT1077.fileID AND Main.seq_no=LIT1077.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT358' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT358    
 ON Main.fileID=LIT358.fileID AND Main.seq_no=LIT358.cd_parent

LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT431' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT431    
 ON Main.fileID=LIT431.fileID AND Main.seq_no=LIT431.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT405' AND FEDCaseValue IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='money' ) AS LIT405Value    
 ON Main.fileID=LIT405Value.fileID AND Main.seq_no=LIT405Value.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT405' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT405Text    
 ON Main.fileID=LIT405Text.fileID AND Main.seq_no=LIT405Text.cd_parent 
 
 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT701' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT701    
 ON Main.fileID=LIT701.fileID AND Main.seq_no=LIT701.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT351' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT351    
 ON Main.fileID=LIT351.fileID AND Main.seq_no=LIT351.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1021' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1021    
 ON Main.fileID=LIT1021.fileID AND Main.seq_no=LIT1021.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1026' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1026    
 ON Main.fileID=LIT1026.fileID AND Main.seq_no=LIT1026.cd_parent   
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT353' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT353    
 ON Main.fileID=LIT353.fileID AND Main.seq_no=LIT353.cd_parent     
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1079' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1079    
 ON Main.fileID=LIT1079.fileID AND Main.seq_no=LIT1079.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1020' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1020    
 ON Main.fileID=LIT1020.fileID AND Main.seq_no=LIT1020.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT369' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT369    
 ON Main.fileID=LIT369.fileID AND Main.seq_no=LIT369.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1146' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1146    
 ON Main.fileID=LIT1146.fileID AND Main.seq_no=LIT1146.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT370' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT370    
 ON Main.fileID=LIT370.fileID AND Main.seq_no=LIT370.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT857' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT857    
 ON Main.fileID=LIT857.fileID AND Main.seq_no=LIT857.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT430' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT430    
 ON Main.fileID=LIT430.fileID AND Main.seq_no=LIT430.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT368' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT368    
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
AND CONVERT(DATE,Main.InsertDate,103)=@Date 

SELECT COUNT(1) AS ZeusExposureInserted FROM MS_PROD.dbo.udZeusExposure WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udZeusExposure')

SELECT COUNT(1) AS ZeusInsurerContactStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1063' AND FEDCaseDate IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='datetime' ) AS LIT1063Date    
 ON Main.fileID=LIT1063Date.fileID AND Main.seq_no=LIT1063Date.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1063' AND FEDCaseText IS NOT NULL AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date AND DataType='nvarchar(60)' ) AS LIT1063Text   
 ON Main.fileID=LIT1063Text.fileID AND Main.seq_no=LIT1063Text.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1064' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1064   
 ON Main.fileID=LIT1064.fileID AND Main.seq_no=LIT1064.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT1074' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT1074   
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
)AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS ZeusInsurerContactInserted FROM MS_PROD.dbo.udZeusInsurerContact WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udZeusInsurerContact')

SELECT COUNT(1) AS InitialContactStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT340' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT340   
 ON Main.fileID=LIT340.fileID AND Main.seq_no=LIT340.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT339' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT339   
 ON Main.fileID=LIT339.fileID AND Main.seq_no=LIT339.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT341' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT341   
 ON Main.fileID=LIT341.fileID AND Main.seq_no=LIT341.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT342' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT342   
 ON Main.fileID=LIT342.fileID AND Main.seq_no=LIT342.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT343' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT343   
 ON Main.fileID=LIT343.fileID AND Main.seq_no=LIT343.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT338' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT338   
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
)AND CONVERT(DATE,Main.InsertDate,103)=@Date 

SELECT COUNT(1) AS ContactStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT708' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT708   
 ON Main.fileID=LIT708.fileID AND Main.seq_no=LIT708.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT707' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT707   
 ON Main.fileID=LIT707.fileID AND Main.seq_no=LIT707.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT709' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT709   
 ON Main.fileID=LIT709.fileID AND Main.seq_no=LIT709.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT710' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT710   
 ON Main.fileID=LIT710.fileID AND Main.seq_no=LIT710.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT345' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT345   
 ON Main.fileID=LIT345.fileID AND Main.seq_no=LIT345.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT711' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT711   
 ON Main.fileID=LIT711.fileID AND Main.seq_no=LIT711.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT706' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT706   
 ON Main.fileID=LIT706.fileID AND Main.seq_no=LIT706.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT712' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT712   
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
)AND CONVERT(DATE,Main.InsertDate,103)=@Date 

SELECT COUNT(1) AS InitialContactInserted FROM MS_PROD.dbo.udZeusInsuredContact WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udZeusInsuredContact')

SELECT COUNT(1) AS CostofSearchStaged FROM SearchListDetailStageSuccess AS Main
WHERE Main.FEDDetailCode='FRA103'
AND Main.StatusID=7
AND Main.FEDCaseText IS NOT NULL AND CONVERT(DATE,Main.InsertDate,103)=@Date 

SELECT COUNT(1) AS CostOfSearchInserted FROM MS_PROD.dbo.udCostOfSearch WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udCostOfSearch')

SELECT COUNT(1) AS DateofSearchStaged FROM SearchListDetailStageSuccess AS Main
WHERE Main.FEDDetailCode='FRA102'
AND Main.StatusID=7
AND Main.FEDCaseDate IS NOT NULL
AND Main.FEDCaseText IS NOT NULL AND CONVERT(DATE,Main.InsertDate,103)=@Date 

SELECT COUNT(1) AS DateOfSearchInserted FROM MS_PROD.dbo.udDateOfSearch WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udDateOfSearch')

SELECT COUNT(1) AS PostReceivedStaged FROM SearchListDetailStageSuccess AS Main
WHERE Main.FEDDetailCode='LIT057'
AND Main.StatusID=7
AND Main.FEDCaseValue  IS NOT NULL
AND Main.FEDCaseText IS NOT NULL AND CONVERT(DATE,Main.InsertDate,103)=@Date 

SELECT COUNT(1) AS PostReceivedInserted FROM MS_PROD.dbo.udPostReceived WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udPostReceived')


SELECT COUNT(1) AS MedicalExpertStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI786' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS NMI786    
 ON Main.fileID=NMI786.fileID AND Main.seq_no=NMI786.cd_parent
WHERE Main.FEDDetailCode='NMI791'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR NMI786.FEDCaseText IS NOT NULL)
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS MedicalExpertInserted FROM MS_PROD.dbo.udClaimsMedicalExpert WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udClaimsMedicalExpert')
AND (txtClaMeExNmLL IS NOT NULL OR cboMedExtise IS NOT NULL)

SELECT COUNT(1) AS NonMedicalExpertStaged FROM SearchListDetailStageSuccess AS Main 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='NMI801' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS NMI801    
 ON Main.fileID=NMI801.fileID AND Main.seq_no=NMI801.cd_parent
WHERE Main.FEDDetailCode='NMI800'
AND Main.StatusID=7
AND(Main.FEDCaseText IS NOT NULL OR NMI801.FEDCaseText IS NOT NULL)
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS NonMedicalExpertInserted FROM MS_PROD.dbo.udClaimsNonMedicalExpert WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udClaimsNonMedicalExpert')
AND (txtClaNonMedExp IS NOT NULL OR cboNonMedExtise IS NOT NULL)
SELECT COUNT(1) AS LifeCycleStaged FROM SearchListDetailStageSuccess AS Main
WHERE Main.FEDDetailCode='NMI804'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR Main.FEDCaseDate IS NOT NULL)
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS LifeCycleInserted FROM MS_PROD.dbo.udClaimsLifecycle WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udClaimsLifecycle')

SELECT COUNT(1) AS UnpaidBillStaged FROM SearchListDetailStageSuccess AS Main
WHERE Main.FEDDetailCode='NMI816'
AND Main.StatusID=7
AND (Main.FEDCaseText IS NOT NULL OR Main.FEDCaseDate IS NOT NULL) 
AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS UnpaidBillInserted FROM MS_PROD.dbo.udClaimsUnpaidBill WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udClaimsUnpaidBill')

SELECT COUNT(1) AS TPVehicleStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR452' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR452   
 ON Main.fileID=FTR452.fileID AND Main.seq_no=FTR452.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR508' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR508   
 ON Main.fileID=FTR508.fileID AND Main.seq_no=FTR508.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR509' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR509   
 ON Main.fileID=FTR509.fileID AND Main.seq_no=FTR509.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR507' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR507   
 ON Main.fileID=FTR507.fileID AND Main.seq_no=FTR507.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR443' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR443   
 ON Main.fileID=FTR443.fileID AND Main.seq_no=FTR443.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FTR442' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FTR442   
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
) AND CONVERT(DATE,Main.InsertDate,103)=@Date

SELECT COUNT(1) AS TPVehicleInserted FROM MS_PROD.dbo.udClaimsTPVehicle WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udClaimsTPVehicle')
AND (txtTPVehMakMod IS NOT NULL OR cboCredRepairs IS NOT NULL OR cboReceiptPayIn IS NOT NULL Or cboTPVABIGroup IS NOT NULL or txtTPVehReg1 IS NOT NULL OR cboVehTotalLoss IS NOT NULL OR curValuePAVRep IS NOT NULL)
SELECT COUNT(1) AS ClaimNumberStaged FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS276' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS276   
 ON Main.fileID=WPS276.fileID AND Main.seq_no=WPS276.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS335' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS335   
 ON Main.fileID=WPS335.fileID AND Main.seq_no=WPS335.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS332' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS332   
 ON Main.fileID=WPS332.fileID AND Main.seq_no=WPS332.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS280' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS280   
 ON Main.fileID=WPS280.fileID AND Main.seq_no=WPS280.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS281' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS281   
 ON Main.fileID=WPS281.fileID AND Main.seq_no=WPS281.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS277' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS277   
 ON Main.fileID=WPS277.fileID AND Main.seq_no=WPS277.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS340' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS340   
 ON Main.fileID=WPS340.fileID AND Main.seq_no=WPS340.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS278' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS278   
 ON Main.fileID=WPS278.fileID AND Main.seq_no=WPS278.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS282' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS282   
 ON Main.fileID=WPS282.fileID AND Main.seq_no=WPS282.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS284' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS284   
 ON Main.fileID=WPS284.fileID AND Main.seq_no=WPS284.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS283' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS283   
 ON Main.fileID=WPS283.fileID AND Main.seq_no=WPS283.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS341' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS341   
 ON Main.fileID=WPS341.fileID AND Main.seq_no=WPS341.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS279' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS279   
 ON Main.fileID=WPS279.fileID AND Main.seq_no=WPS279.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS262' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS262   
 ON Main.fileID=WPS262.fileID AND Main.seq_no=WPS262.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='WPS344' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS WPS344   
 ON Main.fileID=WPS344.fileID AND Main.seq_no=WPS344.cd_parent
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
)  AND CONVERT(DATE,Main.InsertDate,103)=@Date 

SELECT COUNT(1) AS ClaimNumberInserted FROM MS_PROD.dbo.udClaimsClNumber WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udClaimsClNumber')
AND (txtClaimNum IS NOT NULL OR cboLeadFollow IS NOT NULL OR cboMFU IS NOT NULL OR cboWPType IS NOT NULL OR
curClaiCostPaid IS NOT NULL OR curCRUPaid IS NOT NULL OR curCurrentRes IS NOT NULL OR curFeeBillPanel IS NOT NULL OR
curGenDamPaid IS NOT NULL OR curMonRecovered IS NOT NULL OR  curOurPropCosts IS NOT NULL OR curOurPropDamag IS NOT NULL OR
curOwnDisbs IS NOT NULL OR curSpecDamPaid IS NOT NULL OR  dteDamsPaid IS NOT NULL OR txtPHNamInsured IS NOT NULL OR
cboClaimStat IS NOT NULL OR dteSetFormSeToZ IS NOT NULL) 

SELECT COUNT(1) AS ConvergeRecoveryStaged
FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00167' AND FEDCaseText IS NOT NULL AND StatusID=7 AND DataType='ucodeLookup:nvarchar(15)' AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00167    
 ON Main.fileID=VE00167.fileID  AND Main.seq_no=VE00167.seq_no
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00130' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS VE00130    
 ON Main.fileID=VE00130.fileID AND Main.seq_no=VE00130.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00134' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS VE00134    
 ON Main.fileID=VE00134.fileID AND Main.seq_no=VE00134.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00135' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS VE00135    
 ON Main.fileID=VE00135.fileID AND Main.seq_no=VE00135.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00136' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00136    
 ON Main.fileID=VE00136.fileID AND Main.seq_no=VE00136.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00301' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS VE00301    
 ON Main.fileID=VE00301.fileID AND Main.seq_no=VE00301.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00328' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS VE00328    
 ON Main.fileID=VE00328.fileID AND Main.seq_no=VE00328.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00329' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS VE00329    
 ON Main.fileID=VE00329.fileID AND Main.seq_no=VE00329.cd_parent 
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='VE00330' AND StatusID=7AND CONVERT(DATE,InsertDate,103)=@Date ) AS VE00330    
 ON Main.fileID=VE00330.fileID AND Main.seq_no=VE00330.cd_parent 

WHERE Main.FEDDetailCode='VE00167'
AND Main.DataType='datetime'
AND Main.StatusID=7 
AND CONVERT(DATE,Main.InsertDate,103)=@Date
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

SELECT COUNT(1) AS ConvergeRecoveryInserted FROM MS_PROD.dbo.udClaimsRecovery WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udClaimsRecovery')

SELECT COUNT(1) AS IntelStaged
FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA157' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FRA157    
 ON Main.fileID=FRA157.fileID AND Main.seq_no=FRA157.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA158' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS FRA158    
 ON Main.fileID=FRA158.fileID AND Main.seq_no=FRA158.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA156' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date) AS FRA156    
 ON Main.fileID=FRA156.fileID AND Main.seq_no=FRA156.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA155' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FRA155    
 ON Main.fileID=FRA155.fileID AND Main.seq_no=FRA155.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA152' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FRA152    
 ON Main.fileID=FRA152.fileID AND Main.seq_no=FRA152.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='FRA154' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS FRA154    
 ON Main.fileID=FRA154.fileID AND Main.seq_no=FRA154.cd_parent  
WHERE Main.FEDDetailCode='FRA153'
AND Main.DataType='datetime'
AND Main.StatusID=7 
AND CONVERT(DATE,Main.InsertDate,103)=@Date
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

SELECT COUNT(1) AS IntelInserted FROM MS_PROD.dbo.udIntel WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udIntel')

SELECT COUNT(1) AS ZurichPaymentStaged
FROM SearchListDetailStageSuccess AS Main
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT302' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT302    
 ON Main.fileID=LIT302.fileID AND Main.seq_no=LIT302.cd_parent  
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT303' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT303    
 ON Main.fileID=LIT303.fileID AND Main.seq_no=LIT303.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT304' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT304    
 ON Main.fileID=LIT304.fileID AND Main.seq_no=LIT304.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT305' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT305    
 ON Main.fileID=LIT305.fileID AND Main.seq_no=LIT305.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT306' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT306    
 ON Main.fileID=LIT306.fileID AND Main.seq_no=LIT306.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT307' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT307    
 ON Main.fileID=LIT307.fileID AND Main.seq_no=LIT307.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT308' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT308    
 ON Main.fileID=LIT308.fileID AND Main.seq_no=LIT308.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT309' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT309    
 ON Main.fileID=LIT309.fileID AND Main.seq_no=LIT309.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT310' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT310    
 ON Main.fileID=LIT310.fileID AND Main.seq_no=LIT310.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT311' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT311    
 ON Main.fileID=LIT311.fileID AND Main.seq_no=LIT311.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT312' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT312    
 ON Main.fileID=LIT312.fileID AND Main.seq_no=LIT312.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT313' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT313    
 ON Main.fileID=LIT313.fileID AND Main.seq_no=LIT313.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT314' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT314    
 ON Main.fileID=LIT314.fileID AND Main.seq_no=LIT314.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT315' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT315    
 ON Main.fileID=LIT315.fileID AND Main.seq_no=LIT315.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT316' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT316    
 ON Main.fileID=LIT316.fileID AND Main.seq_no=LIT316.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT317' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT317    
 ON Main.fileID=LIT317.fileID AND Main.seq_no=LIT317.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT318' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT318    
 ON Main.fileID=LIT318.fileID AND Main.seq_no=LIT318.cd_parent
LEFT OUTER JOIN (SELECT * FROM SearchListDetailStageSuccess WHERE FEDDetailCode='LIT319' AND StatusID=7 AND CONVERT(DATE,InsertDate,103)=@Date ) AS LIT319    
 ON Main.fileID=LIT319.fileID AND Main.seq_no=LIT319.cd_parent
WHERE Main.FEDDetailCode='LIT301'
AND Main.StatusID=7 
AND CONVERT(DATE,Main.InsertDate,103)=@Date
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

SELECT COUNT(1) AS ZurichPaymentInserted FROM MS_PROD.dbo.udZurPayReqSL WHERE fileID IN (SELECT DISTINCT fileID FROM SearchListDetailStageSuccess WHERE  CONVERT(DATE,InsertDate,103)=@Date AND MSTable='udZurPayReqSL')


END
GO
