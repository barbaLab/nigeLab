function a = fread_QString(FID)
% FREAD_QSTRING  Read Qt style QString
%
%  a = nigeLab.utils.read_QString(FID)
%
% The first 32-bit unsigned number indicates the length of the string (in 
%  bytes).  If this number equals 0xFFFFFFFF, the string is null.
%
% From: Intan-provided Matlab extraction code.

a = '';
length = fread(FID, 1, 'uint32');
if length == hex2num('ffffffff')
   return;
end
% convert length from bytes to 16-bit Unicode words
length = length / 2;

for i=1:length
   a(i) = fread(FID, 1, 'uint16');
end

end