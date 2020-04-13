function txt = getLastDispText(nChar)
% GETLASTDISPTEXT  Returns the last nChar characters printed to cmd window
%
%  txt = nigeLab.utils.getLastDispText(nChar);
%
%  nChar  --  Number of "most-recent" characters to return that have been
%              recently printed to the Command Window. 
%
%  txt  -- Char array that always contains AT MOST nChar characters
%           (typical use), but in rare instances (such as if there have
%           been no commands issued) could return less than nChar
%           characters (should almost never happen).

% Holy crap Federico how did you find this command? -MM
[cmdWin]=com.mathworks.mde.cmdwin.CmdWin.getInstance;
% I like this style of coding, good job:
cmdWin_comps=get(cmdWin,'Components');
subcomps=get(cmdWin_comps(1),'Components');
text_container=get(subcomps(1),'Components');
output_string=get(text_container(1),'text');
% Do indexing based on number of elements in output_string
nCharTotal = numel(output_string);
if nCharTotal == 0
   txt = '';
   return;
end
% Can never be more than number of chars in string
nChar = min(nCharTotal,nChar); 
% Add 1 to actually return nChar output characters
txt = output_string((nCharTotal - nChar + 1):nCharTotal);

end