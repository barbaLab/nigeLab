function val = get(ro, prop)
% 'Get' for ROLLOVER objects

if nargin == 1
    % Return whole object
    val = struct(ro);
else
    % Return given property
    try
        val = ro.(prop);
    catch
        error([prop,' is not a valid memeber of a ROLLOVER object !!'])
    end
end