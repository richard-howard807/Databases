SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [dbo].[ufn_Coalesce_CapacityDetails_Postcode]   
    (
     @case_id INT
    ,@capacity_code VARCHAR(8)
    )
    
/*	
'~ZCLAIM' returns Claimants


*/
    
RETURNS VARCHAR(255)
AS BEGIN
    DECLARE @string VARCHAR(255)
    SET @string = ''
    SELECT TOP 1
        @string = @string +     -- dv update = the following nested case statement determines the best combination of title, initials and name.
			(fm_poscod) + ', '
    FROM
        axxia01.dbo.capac capac WITH (NOLOCK)
    INNER JOIN axxia01.dbo.invol invol WITH (NOLOCK)
    ON  capac.capacity_code = invol.capacity_code
    INNER JOIN axxia01.dbo.caclient caclient WITH (NOLOCK)
    ON  invol.entity_code = caclient.cl_accode
        INNER JOIN axxia01.dbo.fmsaddr 
     ON invol.entity_code=fmsaddr.fm_clinum
    WHERE
        capac.capacity_code = @capacity_code
        AND invol.case_id = @case_id
    ORDER BY invol.seq_no DESC
    
    IF LEN(@string) > 2 
        SET @string = LEFT(@string, LEN(@string) - 1)
    
    RETURN @string
   END



GO
