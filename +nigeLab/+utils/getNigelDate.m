function todays_date = getNigelDate(dt)
%GETNIGELDATE  Returns today's date in standardized "nigeLab" format
%
%  todays_date = nigeLab.utils.getNigelDate();
%  todays_date = nigeLab.utils.getNigelDate(dt);
%
%  inputs:
%  dt  --  Numeric equivalent of a DATE (years, months, days)
%
%  outputs:
%  todays_date  --  Returned as char array of 'YYYY-mm-DD' format


if nargin < 1
   dt = datenum(datetime);
end

todays_date = datestr(floor(dt),'YYYY-mm-dd');

end