function s = parseVidFileExpr(blockObj,ext)
%PARSEVIDFILEEXPR  Parses expression for finding matched videos
%
%  s = blockObj.parseVidFileExpr(ext);
%
%  ext      :     (Optional) char array of file extension to use in
%                       matching expression. Typically '.MP4' but could be
%                       for example '.avi' etc
%
%  s        :     Char array that is a series of delimited tokens, each of
%                    which is either '*' or a fixed variable that must be
%                    matched in order to be considered a video from the
%                    same camera of the same recording.
%
%  --> NOTE: This RESETS table of video metadata (Block.Meta.Video) because
%              the assumption is that this is called to restart the parsing
%              procedure of videos (to get the expression to match
%              filename)

if nargin < 2
   ext = blockObj.Pars.Video.FileExt; % From +defaults/Video.m
   if isfield(blockObj.Paths,'V')
      if isfield(blockObj.Paths.V,'FileExt')
         ext = blockObj.Paths.V.FileExt; % use parsed
      end
   end
end

% Use static method of VideosFieldType class
blockObj.Meta.Video = []; % (Re-)Initialize as empty
meta = blockObj.Meta;
pars = blockObj.Pars.Video;
s = nigeLab.libs.VideosFieldType.parse(meta,pars,ext);
end