function sig = SUPPR_SALPA3(sig,p)

    inargs = struct2cell(p.SUPPR_SALPA3);
    inargs = inargs(~cellfun(@isempty,inargs));
    [sig, ~] = nigeLab.utils.SALPA3( single(sig(:)),p.StimI(p.stimIdx),inargs{:} );
end