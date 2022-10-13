SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* 
-------------------------------------------------------------
-------------------------------------------------------------
   Author: Max Taylor
   Created : 09/06/2022
--------------------------------------------------------------
--------------------------------------------------------------
   */

CREATE PROCEDURE [dbo].[Process_MatterOwnerSearch]

--(
-- @OldClient AS NVARCHAR(20) ,
-- @OldMatter AS NVARCHAR(20) ,
-- @NewClient AS NVARCHAR(20) ,
-- @NewMatter AS NVARCHAR(20) 


--)

AS


--/*Testing*/
--DECLARE @OldClient AS NVARCHAR(20) = ''
--DECLARE @OldMatter AS NVARCHAR(20) = ''
--DECLARE @NewClient AS NVARCHAR(20) =  'W15381'
--DECLARE @NewMatter AS NVARCHAR(20) = '491'
DECLARE @DAX AS NVARCHAR(2000) 



SET @DAX = 

'
SELECT * FROM Openquery(lnksvrlivdwh03_bills,''

evaluate ( 
	calculatetable ( 
				summarize ( 
							Matters,
							dimClient[ClientCode],
dimClient[ClientName],
dimClientPartnerFEDHierarchy[ClientPartnerDisplayName],
							Matters[MatterNumber],
							Matters[MatterDesc],
							dimMatterFEDHierarchy[MatterFEDDisplayName],
Matters[MasterClientMatterCombined],
							"ClientMatterCombined", dimClient[ClientCode] & "-" & Matters[MatterNumber]
							)
						
				  )
			)

			'')
			'


EXEC sp_executesql @DAX


					--dimClient[ClientCode] = if(isblank('+@OldClient+'), dimClient[ClientCode], trim('+@OldClient+')),
					--Matters[MatterNumber] = if(isblank('+@OldMatter+'), Matters[MatterNumber], trim('+@OldMatter+')),
					--Matters[MasterClientCode] = if(isblank('+@NewClient+'), Matters[MasterClientCode], trim('+@NewClient+')),
					--Matters[MasterMatterNumber] = if(isblank('+@NewMatter+'), Matters[MasterMatterNumber], trim('+@NewMatter+'))


					
			--		dimClient[ClientCode] = if(isblank(@OldClient), dimClient[ClientCode], trim(@OldClient)),
			--		Matters[MatterNumber] = if(isblank(@OldMatter), Matters[MatterNumber], trim(@OldMatter)),
			--		Matters[MasterClientCode] = if(isblank(@NewClient), Matters[MasterClientCode], trim(@NewClient)),
			--		Matters[MasterMatterNumber] = if(isblank(@NewMatter), Matters[MasterMatterNumber], trim(@NewMatter))
			--		)
			--)
GO
