SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [dbo].[ufn_Coalesce_CapacityDetails]
    (
     @case_id INT
    ,@capacity_code VARCHAR(8)
    )
    
/*	
'~ZCLAIM' returns Claimants


*/
    
RETURNS VARCHAR(255)
AS BEGIN
    declare @string varchar(255)
    set @string = ''
    SELECT
        @string = @string +     -- dv update = the following nested case statement determines the best combination of title, initials and name.
			(CASE WHEN LEN(LTRIM(cl_title))>0 THEN
				(CASE WHEN RTRIM(cl_clname) LIKE RTRIM(cl_title)+'%' THEN
					(CASE WHEN (LEN(LTRIM(cl_inits))>0) THEN
						(CASE WHEN RTRIM(cl_clname) LIKE '% %' THEN
							RTRIM(cl_clname)
						 ELSE
							RTRIM(cl_inits) + ' ' + RTRIM(cl_clname)
						 END)
					 ELSE
						(CASE WHEN RTRIM(cl_clname) LIKE '% %' THEN
							RTRIM(cl_clname)
						 ELSE
							RTRIM(cl_title) + ' ' + RTRIM(cl_clname)
						 END)
					 END)
				 ELSE
					(CASE WHEN (LEN(LTRIM(cl_inits))>0 AND NOT RTRIM(cl_clname) LIKE RTRIM(cl_title)+' '+RTRIM(cl_inits)+'%') THEN
						RTRIM(cl_title) + ' ' + RTRIM(cl_inits) + ' ' + RTRIM(cl_clname)
					 ELSE
						RTRIM(cl_title) + ' ' + RTRIM(cl_clname)
					 END)
				 END)
			 ELSE
				(CASE WHEN LEN(LTRIM(cl_inits))>0 THEN
					(CASE WHEN RTRIM(cl_clname) LIKE '% %' THEN
						RTRIM(cl_clname)
					 ELSE
						RTRIM(cl_inits) + ' ' + RTRIM(cl_clname)
					 END)
				ELSE
					RTRIM(cl_clname)
				END)
			 END) + ', '
    FROM
        axxia01.dbo.capac capac WITH (NOLOCK)
    INNER JOIN axxia01.dbo.invol invol WITH (NOLOCK)
    ON  capac.capacity_code = invol.capacity_code
    INNER JOIN axxia01.dbo.caclient caclient WITH (NOLOCK)
    ON  invol.entity_code = caclient.cl_accode
    WHERE
        capac.capacity_code = @capacity_code
        AND invol.case_id = @case_id
    
    IF LEN(@string) > 2 
        SET @string = LEFT(@string, LEN(@string) - 1)
    
    RETURN @string
   END



GO
