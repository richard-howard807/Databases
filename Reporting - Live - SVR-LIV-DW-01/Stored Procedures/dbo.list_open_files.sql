SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 21/10/2019
-- Description:	Returns a list of files for a fed code with the reallocation details.
-- =============================================
CREATE PROCEDURE [dbo].[list_open_files]
	@FeeEarner VARCHAR(10)
AS

SELECT header.master_client_code ,
       header.master_matter_number ,
       header.client_code ,
       header.matter_number ,
       header.matter_description ,
       fe.usrInits [fe_code] ,
       fe.usrFullName [fe_name] ,
       tm.usrInits [tm_code] ,
       tm.usrFullName [tm_name] ,
       pt.usrInits [partner_code] ,
       pt.usrFullName [partner_name] ,
       employee.hierarchylevel4hist [Team]
FROM   red_dw.dbo.dim_matter_header_current header
       INNER JOIN red_dw.dbo.fact_dimension_main main ON main.dim_matter_header_curr_key = header.dim_matter_header_curr_key
       INNER JOIN red_dw.dbo.dim_fed_hierarchy_history employee ON employee.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
       INNER JOIN MS_Prod.config.dbFile dbFile ON dbFile.fileID = header.ms_fileid
       LEFT JOIN MS_Prod.dbo.dbUser fe ON dbFile.filePrincipleID = fe.usrID
       LEFT JOIN MS_Prod.dbo.dbUser tm ON dbFile.fileResponsibleID = tm.usrID
       INNER JOIN MS_Prod.dbo.udExtFile udExtFile ON udExtFile.fileID = dbFile.fileID
       LEFT JOIN MS_Prod.dbo.dbUser pt ON udExtFile.cboPartner = pt.usrID
WHERE  fe.usrInits = @FeeEarner
       AND header.date_closed_case_management IS NULL
       AND header.reporting_exclusions <> 1;


GO
