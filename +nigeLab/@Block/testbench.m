function varargout = testbench(blockObj,varargin)
%TESTBENCH  For development to work with protected methods on ad hoc basis
%
%  varargout = testbench(blockObj,varargin);

varargout = cell(1,nargout);

varargout{1} = initEvents(blockObj);



end