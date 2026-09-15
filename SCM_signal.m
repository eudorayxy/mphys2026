function signal = SCM_signal(sblood, outflow, outflow_csf, PLD, LD, alpha, lambda, SIpd, T1b, T1e, f, ttr)
    PLD = PLD(:); LD = LD(:);
    T1b = T1b(:); T1e = T1e(:);
    f = f(:); ttr = ttr(:);
    assert(length(PLD) == length(LD), 'PLD and LD must have the same length')

    num_person = length(T1b);
    assert(length(f) == num_person && ...
        length(ttr) == num_person, 'f, ttr, and T1b must have the same length')

    if ~isscalar(T1e)
        assert(length(T1e) == num_person, 'T1b and T1e must have the same length')
    else
        T1e = T1e .* ones(size(T1b));
    end

    if sblood == 1 && outflow ~= 1
        T1app = T1b;
    elseif outflow == 1 && sblood ~= 1
        T1app = 1./(1./T1e + f/lambda);
    elseif ~any(outflow_csf <= 0) && outflow ~= 1 && sblood ~= 1 
        T1app = 1./(1./T1e + outflow_csf);
    elseif outflow ~= 1 && sblood ~= 1 
        T1app = T1e;
    else
        error('invalid SCM_signal input for sblood, outflow, and outflow_csf')
    end

    A = SIpd * 2 * alpha / lambda;
    
    signal = zeros(num_person, length(PLD));
    for i=1:length(PLD)
        t = LD(i) + PLD(i);

        mask1 = (PLD(i) + LD(i) > ttr) & (PLD(i) <= ttr);
        mask2 = (PLD(i) + LD(i) > ttr) & (PLD(i) > ttr);

        signal(mask1, i) = A .* f(mask1) .* T1app(mask1) .* ...
            exp(-ttr(mask1)./T1b(mask1)) .* ...
            (1 - exp(-(t - ttr(mask1))./T1app(mask1)));
        
        signal(mask2, i) = A .* f(mask2) .* T1app(mask2) .* ...
            exp(-ttr(mask2)./T1b(mask2)) .* ...
            exp(-(t - ttr(mask2))./T1app(mask2)) .* ...
            (exp(LD(i)./T1app(mask2)) - 1);
       
        % if PLD(i) + LD(i) > ttr
        %     if PLD(i) <= ttr
        %         signal(:, i) = A .* f .* T1app .* exp(-ttr./T1b) .* (1 - exp(-(t-ttr)./T1app));
        %     else
        %         signal(:, i) = A .* f .* T1app .* exp(-ttr./T1b) .* ...
        %             exp(-(t-ttr)./T1app).*(exp(LD(i)./T1app)-1);
        %     end
        % end
    end
        
end