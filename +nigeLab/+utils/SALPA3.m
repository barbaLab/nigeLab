function [Vm_, art_blank] = SALPA3( Vm,artefact,N,win,d,hw_blank,sig_v )
% This function implements Wagenaar et al.'s algorithm SALPA. It's important
% to use single's for the Vm, otherwise the algorithm is slow like thick
% shit through a funnel (folkloristic Dutch expression).
%
% The definition and computation of the goodness-of-fit criterion is computed
% slightly different from the original paper. One should check the performance
% of the algorithm by inspecting individual traces!
%
% PL Baljon, July 2009
%

    if( nargin < 5 ), d = single(5);         end
    if( nargin < 6 ), hw_blank = single(20); end
    if( nargin < 7 ), sig_v    = std( Vm(1:artefact(1)-1) ); end

    % T is a matrix N-by-4 (n-n_c)^k, n row index, k column index
    T = single( [ones(1,2*N+1);-N:N;(-N:N).^2;(-N:N).^3]' );
    
%     D_thresh = 3^2 * d * sig_v^2;
    D_thresh = d * sig_v^2; % no beta is considered
    % function of variable t and a
    poly = @(t,a) a(1) + a(2) .* t + a(3) .* t.^2 + a(4) .* t.^3;
    artefact  = sort( artefact(:) );
    artefact_ = [1; artefact; length(Vm)];
    art_blank = zeros( length(artefact),1 ,'single');
    a   = zeros( length(Vm),1,'single' );
    
    % for every artefact
    i_a = single(0);
    while i_a < length(artefact)
        i_a    = i_a + 1;

%         n_c    = artefact(i_a) + N + 1;
        % from the hardware blanking point, to N points after, subtract the actual
        % polynomial upto point N, then continue with pointwise polynomials.
        n_c    = int64(artefact(i_a) + N + hw_blank);
        t      = n_c + int64(-N:N);
        alpha  = T(t-n_c+N+1,:)\Vm(t);
        a(n_c + int64(-N:0)) = poly(-N:0,alpha);
        % continue with fitting a polynomial for each point until either the next
        % artefact, the end of the recording, or the end of the window.
        while( n_c < artefact_(i_a+2) && ...
               n_c < artefact(i_a) + win )
            n_c    = n_c + 1;
            t      = max(n_c-N,artefact_(i_a)):min(n_c+N,artefact_(i_a+2));
            alpha  = T(t-n_c+N+1,:) \ Vm(t);
            a(n_c) = alpha(1);
        end
% Window comprising the entire fit, new version considers only the assymetric window for fit-refuse
% an evoked burst can cause the fit to be refused.
        this_win = (artefact(i_a)+hw_blank):min(artefact_(i_a+2),artefact(i_a)+win); % original
%         this_win = (artefact(i_a)+hw_blank):min(artefact_(i_a+2),artefact(i_a)+N+hw_blank); % hard blanking only non-symmetric window
        idx      = ones(d,1)*this_win + (0:(d-1))'*ones(1,length(this_win));
        
% Original distance measure
%         D        = sum( Vm(idx)-a(idx) ).^2;
        D        = sum( (Vm(idx)-a(idx)).^2 );
        art_blank(i_a) = hw_blank + find( [D .5*D_thresh] < D_thresh,1,'first' );
        a(artefact(i_a)+(0:art_blank(i_a))) = Vm(artefact(i_a)+(0:art_blank(i_a)));
    end
    Vm_ = Vm - a;
end