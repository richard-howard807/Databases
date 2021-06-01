SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [audit].[CDDProcedure] --'Real Estate','Real Estate Liverpool','5709:Alan Woodward'
(
	@Department AS NVARCHAR(MAX),
    @Team AS NVARCHAR(MAX),
    @FeeEarner AS NVARCHAR(MAX)
)
AS
BEGIN

--

    DROP TABLE IF EXISTS #team;
    DROP TABLE IF EXISTS #feeearners;
	DROP TABLE IF EXISTS #Department

    SELECT *
    INTO #team
    FROM dbo.split_delimited_to_rows(@Team, ',');
    SELECT *
    INTO #feeearners
    FROM dbo.split_delimited_to_rows(@FeeEarner, ',');
	 SELECT *
    INTO #Department
    FROM dbo.split_delimited_to_rows(@Department, ',');

    SELECT [MS Ref],
           [Client Name],
           [Fed Ref],
           [Matter Description],
           [Date File Opened],
           usrFullName,
           usrInits,
           fileID,
           tskDue,
           [Date Last Ran],
           DaysIncomplete,
           DaysSinceLastRan,
           [Division],
           [Department],
           [Team],
           last_time_transaction_date AS LastTransaction,
		   filemilestonecode
    FROM
    (
        SELECT clNo + '.' + fileNo AS [MS Ref],
               clName AS [Client Name],
               udextfile.FEDCode AS [Fed Ref],
               fileDesc AS [Matter Description],
               dbFile.Created AS [Date File Opened],
               dbUser.usrFullName,
               dbUser.usrInits,
               dbFile.fileID,
               tskDue,
               [Date Last Ran],
               DATEDIFF(DAY, tskDue, GETDATE()) AS DaysIncomplete,
			   -- LD 20190919 replaced the below
			   DATEDIFF(DAY, [Date Last Ran],GETDATE())   AS DaysSinceLastRan,
               --DATEDIFF(DAY, tskDue, [Date Last Ran]) * -1 AS DaysSinceLastRan,
               hierarchylevel2hist AS [Division],
               hierarchylevel3hist AS [Department],
               hierarchylevel4hist AS [Team],
			   ft.filemilestonecode,
               CASE
                   WHEN udextfile.FEDCode IS NULL THEN
               (CASE
                    WHEN ISNUMERIC(clNo) = 1 THEN
                        RIGHT('00000000' + CONVERT(VARCHAR, clNo), 8)
                    ELSE
                        CAST(RTRIM(clNo) AS VARCHAR(8))
                END
               )
                   ELSE
               (CAST(SUBSTRING(
                                  RTRIM(udextfile.FEDCode),
                                  1,
                                  CASE
                                      WHEN CHARINDEX('-', RTRIM(udextfile.FEDCode)) > 0 THEN
                                          CHARINDEX('-', RTRIM(udextfile.FEDCode)) - 1
                                      ELSE
                                          LEN(RTRIM(udextfile.FEDCode))
                                  END
                              ) AS CHAR(8))
               )
               END AS mg_client,
               CASE
                   WHEN udextfile.FEDCode IS NULL THEN
                       RIGHT('00000000' + CONVERT(VARCHAR, fileNo), 8)
                   ELSE
                       CAST(RIGHT(RTRIM(udextfile.FEDCode), LEN(RTRIM(udextfile.FEDCode))
                                                            - CHARINDEX('-', RTRIM(udextfile.FEDCode))) AS CHAR(8))
               END AS mg_matter
        FROM MS_Prod.config.dbFile
            INNER JOIN MS_Prod.config.dbClient
                ON dbFile.clID = dbClient.clID
            LEFT OUTER JOIN MS_Prod.dbo.dbUser
                ON filePrincipleID = dbUser.usrID
            LEFT OUTER JOIN MS_Prod.dbo.udExtFile
                ON dbFile.fileID = udextfile.fileID
			LEFT OUTER JOIN MS_PROD.dbo.dbFileType ft  WITH(NOLOCK) on ft.typeCode = dbfile.fileType
			
            LEFT OUTER JOIN
            (
                SELECT *
                FROM red_dw.dbo.dim_fed_hierarchy_history
                WHERE dss_current_flag = 'Y'
            ) AS Structure
                ON dbUser.usrInits = fed_code COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN
            (
                SELECT dbTasks.fileID,
                       tskDue,
                       [Date Last Ran]
                FROM MS_Prod.dbo.dbTasks
                    LEFT OUTER JOIN
                    (
                        SELECT a.fileID AS fileID,
                               MAX(evWhen) AS [Date Last Ran]
                        FROM MS_Prod.dbo.dbFileEvents AS a
                        WHERE evDesc = 'CDD form completed'
                        GROUP BY a.fileID
                    ) AS LastRan
                        ON dbTasks.fileID = LastRan.fileID
                WHERE tskDesc IN ( 'Complete CDD procedure', 'Complete CDD form procedure',
                                   'ADM: Complete CDD form procedure'
                                 )
            ) AS CDD
                ON dbFile.fileID = CDD.fileID
				INNER JOIN #team ON Structure.hierarchylevel4hist COLLATE DATABASE_DEFAULT = #team.val COLLATE DATABASE_DEFAULT
				INNER JOIN #feeearners ON #feeearners.val COLLATE DATABASE_DEFAULT = Structure.fed_code COLLATE DATABASE_DEFAULT
				INNER JOIN #Department ON #Department.val COLLATE DATABASE_DEFAULT = Structure.hierarchylevel3hist COLLATE DATABASE_DEFAULT
        WHERE fileStatus = 'LIVE'
              --AND
              --(
              --    hierarchylevel3hist = 'Real Estate'
              --    OR hierarchylevel4hist = 'Family'
              --    OR hierarchylevel4hist = 'Glasgow'
              --    OR hierarchylevel3hist = 'Corp-Comm'
              --)

              --AND hierarchylevel4hist IN ( @Team )
              --AND fed_code IN ( @FeeEarner )
              AND clNo NOT IN ( '30645', 'FW18355', 'FW19029', 'FW25614', 'FW22350', '905309', '905311', '787558',
                                '787561', '787560', '787559', '190593P', 'R1001', '774963'
                              )
              AND fileNo NOT IN ( '0', 'ML' )
    ) AS AllData
        LEFT OUTER JOIN
        (
            SELECT client_code,
                   matter_number,
                   last_time_transaction_date
            FROM red_dw.dbo.fact_matter_summary_current
            WHERE last_time_transaction_date IS NOT NULL
        ) AS LastTimePostingFED
            ON mg_client = client_code COLLATE DATABASE_DEFAULT
               AND mg_matter = matter_number COLLATE DATABASE_DEFAULT
    WHERE (
              last_time_transaction_date IS NULL
              OR last_time_transaction_date >= '2017-12-01'
          )
          AND
          (
              DaysIncomplete IS NULL
              OR DaysIncomplete > 28
          )
          AND [Client Name] NOT LIKE 'Green King%'
          AND [Client Name] NOT LIKE 'BDW T%'
          AND UPPER([Client Name]) NOT LIKE '%TEST%';

END;



GO
