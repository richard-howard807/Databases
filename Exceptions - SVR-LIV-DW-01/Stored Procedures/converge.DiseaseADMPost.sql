SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
           

CREATE PROCEDURE [converge].[DiseaseADMPost]-- EXEC [Converge].[DiseaseADMPost] '2019-01-01','2019-03-01'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN


SELECT DISTINCT
  cashdr.case_id,
  Client collate database_default AS Client
 ,matter collate database_default AS matter
 ,case_public_desc1 collate database_default AS [Matter Description]
 ,name collate database_default AS [Fee Earner]
 ,hierarchylevel4hist collate database_default AS Team
 ,plan_date AS [Plan Date]
 ,activity_date AS [Completed Date]
 ,CASE WHEN casact.activity_code = 'MOT01001' THEN documt.title ELSE activity_desc END collate database_default AS [Activity Description]
 ,casact.activity_seq
 ,'FED' AS [ReportingTab]
 FROM axxia01.dbo.cashdr (NOLOCK) AS cashdr
 INNER JOIN axxia01.dbo.casact (NOLOCK) AS casact ON cashdr.case_id=casact.case_id
	LEFT JOIN axxia01.dbo.documt (NOLOCK) AS documt ON documt.case_id = casact.case_id AND documt.activity_seq = casact.activity_seq AND documt.document_no = casact.document_no AND documt.title = 'DOCs: ODC outsourced settlement report'
 INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=initiating_entity collate database_default AND dss_current_flag='Y'
 
 LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='NMI980') AS NMI980 
  ON cashdr.case_id=NMI980.case_id
 WHERE 
 (client IN ('Z00004','Z00018','Z00002','Z00014','00513126','00256271','00256272','00256273','00256275','00257277')
 OR (client='Z1001' AND NMI980.case_text IN ('Outsource - Coats','Outsource - HAVS','Outsource - Mesothelioma','Outsource - NIHL' )))
 
 AND activity_date BETWEEN @StartDate AND @EndDate
 AND tran_done IS NULL
 AND p_a_marker='a'
 AND (activity_code IN   ('FTRA3101','LIT0601','FTRA3129','FTRA3132','FTRA3135','FTRA3137')
		
		OR casact.activity_code = 'MOT01001' AND documt.title IS NOT NULL )
 
				

 AND  ( hierarchylevel4hist IN ( 'Disease Liverpool 3','Disease Birmingham 1') or fed_code  in ('5568','5522') 
 )

UNION

SELECT DISTINCT
  case_id
 ,client_code AS  Client
 ,matter_number AS  matter
 ,matter_description AS [Matter Description]
 ,matter_owner_full_name AS [Fee Earner]
 ,hierarchylevel4hist AS Team
 ,tskDue AS [Plan Date]
 ,tskCompleted AS [Completed Date]
 ,tskDesc AS [Activity Description]
 ,tskID AS  activity_seq
 ,'Mattersphere' AS [ReportingTab]
 
FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code collate database_default AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_instruction_type
 ON a.dim_instruction_type_key=dim_instruction_type.dim_instruction_type_key
INNER JOIN MS_Prod.dbo.dbTasks
 ON fileID=ms_fileid
WHERE tskType='PAPERLITE'
AND(
 (client_code IN ('Z00004','Z00018','Z00002','Z00014','00513126','00256271','00256272','00256273','00256275','00257277')
 OR (client_code='Z1001' AND instruction_type IN ('Outsource - Coats','Outsource - HAVS','Outsource - Mesothelioma','Outsource - NIHL' )))
 )
 
 AND tskCompleted BETWEEN @StartDate AND @EndDate
 AND tskComplete=1
 AND hierarchylevel4hist IN ('Disease Liverpool 3','Disease Birmingham 1')
 

 
END

 



                                           

GO
