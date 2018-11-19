function spikeDetection(tankObj)

for ii=1:numel(tankObj.Animals)
    A=tankObj.Animals(ii);
    % parralel
%     f(ii)=parfeval(@A.CAR,0);
%     fprintf(1,'Submitted work %d\n',ii);
    %serial
    A.spikeDetection;
end

end

