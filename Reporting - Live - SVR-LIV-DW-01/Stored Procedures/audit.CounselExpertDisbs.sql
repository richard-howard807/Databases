SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[CounselExpertDisbs]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
DECLARE @Directory AS NVARCHAR(MAX)
SET @Directory='\\svr-liv-3efn-01\TE_3E_Share\TE_3E_PROD\Inetpub\Attachment\Voucher\' --LIVE
DECLARE @test AS INT
SET @test=0

SELECT[Client Code]
,[Matter Number]
,[3e References]
,[Matter Description]
,[Fee Earner]
,hierarchylevel2hist As [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,Payee As[Supplier]
,DisbType As [Suplier Type]
,[Inv Number] AS [Invoice Number]
,[Disb Date] AS [Invoice Date]
,[Bill Amount] AS [Invoice Total Amount]
,[Invoice Link] AS [Invoice Link]

FROM 
(
SELECT 
dbfile.fileID
,CASE WHEN FEDCode is null THEN (CASE WHEN ISNUMERIC(clno)=1 THEN  RIGHT('00000000' + CONVERT(VARCHAR,clno), 8) ELSE CAST(RTRIM(clNo)  AS VARCHAR(8)) END) ELSE (CAST(SUBSTRING(RTRIM(FEDCode), 1, CASE WHEN CHARINDEX('-', RTRIM(FEDCode)) > 0 THEN CHARINDEX('-', RTRIM(FEDCode))-1 ELSE LEN(RTRIM(FEDCode)) END) AS CHAR(8))) END  AS [Client Code] 
,CASE WHEN FEDCode is null THEN RIGHT('00000000' + CONVERT(VARCHAR,fileno), 8) ELSE CAST(RIGHT(RTRIM(FEDCode),LEN(RTRIM(FEDCode))-CHARINDEX('-',RTRIM(FEDCode)))AS CHAR(8)) END  AS [Matter Number]
,clNo + '-'+ fileNo AS [3e References]
,dbFile.fileDesc AS [Matter Description]
,dbFile.Created AS [Date Opened]
,dbUser.usrFullName AS [Fee Earner]
,dbUser.usrAlias AS [Fee Earner Code]
,CASE  
	  WHEN hierarchylevel4hist IN ('Fraud and Credit Hire Liverpool','Motor Liverpool','Motor Management') THEN 'MotorBillDistribution@weightmans.com'
	  ELSE (CASE WHEN @test=1 THEN 'ExcludeTime@weightmans.com' ELSE  dbUser.usrEmail END)  END collate database_default AS [Fee Earner Email]
,InvNum AS [Inv Number]
,Voucher.TranDate AS [Disb Date]
,Voucher.Amount AS [Bill Amount]
,@Directory + LOWER(VoucherID)+ '\' + [FileName] AS [Invoice Link]
,CASE WHEN VchrStatus='COUN' THEN 'Counsel' WHEN VchrStatus ='EXPERT' THEN 'Expert' END As DisbType
,Payee.Name AS Payee
,Voucher.VchrIndex
,hierarchylevel2hist
,hierarchylevel3hist
,hierarchylevel4hist
 FROM  TE_3E_Prod.dbo.Voucher WITH(NOLOCK)
 INNER JOIN TE_3E_Prod.dbo.VchrDetail WITH(NOLOCK)
  ON Voucher.VchrIndex=VchrDetail.Voucher
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
 ON VchrDetail.Matter=MattIndex
INNER JOIN MS_PROD.config.dbFile WITH(NOLOCK) ON VchrDetail.Matter=dbFile.fileExtLinkID
INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK) ON dbFile.clID=dbClient.clID
INNER JOIN MS_PROD.dbo.udExtFile WITH(NOLOCK) ON dbFile.fileID=udExtFile.fileID
INNER JOIN MS_PROD.dbo.dbUser WITH(NOLOCK) ON dbFile.filePrincipleID=dbUser.usrID
LEFT OUTER JOIN [red_dw].[dbo].[dim_fed_hierarchy_history] WITH(NOLOCK)  ON usrAlias=fed_code collate database_default AND dss_current_flag='Y'
LEFT OUTER JOIN (SELECT PayeeIndex,Name FROM  TE_3E_Prod.dbo.Payee WITH(NOLOCK) ) AS Payee
 ON Voucher.Payee=Payee.PayeeIndex
LEFT  JOIN TE_3E_Prod.dbo.NxAttachment WITH(NOLOCK)
 ON Voucher.VoucherID=NxAttachment.ParentItemID

WHERE VchrStatus IN ('COUN','EXPERT')
AND CONVERT(DATe,Voucher.TranDate,103)  BETWEEN  @StartDate AND @EndDate --DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0) AND DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0))
--AND hierarchylevel3hist='Motor'
--AND fed_code IN ('4079','372','1067','1651','1663','5798','4343','4668'
--,'3209','4317','5497','5593','1856','4283','3257','1792','4157','5405'
--,'3419','1500','5608','4997','4195','551','5651','4203','5378','5616'
--,'5265','5467','5848','1580','5635','5131','5386','4558','3709','4348'
--,'5508','642','2043','579','3080','594','4797','1590','1687','1785','6032')
) AS AutoDibs
LEFT OUTER JOIN (SELECT client,matter,case_id FROM axxia01.dbo.cashdr) AS b
 ON [Client Code]=b.client collate database_default
AND [Matter Number]=b.matter collate database_default
END
GO
