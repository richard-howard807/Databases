SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE function [dbo].[ufn_Coalesce_CapacityDetails]
    (
     @case_id int
    ,@capacity_code varchar(8)
    )
    
/*	
'~ZCLAIM' returns Claimants


*/
    
returns varchar(255)
as begin
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
    
    if len(@string) > 2 
        set @string = left(@string, len(@string) - 1)
    
    return @string
   end



GO
GRANT EXECUTE ON  [dbo].[ufn_Coalesce_CapacityDetails] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01]
GO
GRANT EXECUTE ON  [dbo].[ufn_Coalesce_CapacityDetails] TO [ssrs_dynamicsecurity]
GO
