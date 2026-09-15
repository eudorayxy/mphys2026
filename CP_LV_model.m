function signal_csf = CP_LV_model(sblood, outflow, PLD, LD, alpha, lambda, ...
    SIpd, T1b, T1e, f, ttr, T1_csf, k_csf)
    PLD = PLD(:); LD = LD(:);
    T1b = T1b(:); T1e = T1e(:); T1_csf = T1_csf(:); k_csf = k_csf(:);
    f = f(:); ttr = ttr(:);
    assert(length(PLD) == length(LD), 'PLD and LD must have the same length')

    num_person = length(T1b);
    assert(length(f) == num_person && ...
        length(ttr) == num_person, 'f, ttr, and T1b must have the same length')

    if ~isscalar(T1e)
        assert(length(T1e) == num_person, 'T1b and T1e must have the same length')
    else
        T1e = T1e .* ones(size(T1b));
        T1_csf = T1_csf .* ones(size(T1b));
    end

    if sblood == 1 && outflow ~= 1
        T1app = T1b;
    elseif outflow == 1 && sblood ~= 1
        T1app = 1./(1./T1e + f/lambda);
    elseif outflow ~= 1 && sblood ~= 1 
        T1app = T1e;
    else
        error('invalid SCM_signal input for sblood and outflow')
    end

    A = SIpd * 2 * alpha / lambda;
    
    % Initialize output array
    signal_csf = zeros(num_person, length(PLD));
    
    % Inverse time difference factor: (1/T1_csf - 1/T1_app)
    K = 1./T1_csf - 1./T1app;
    
    for i = 1:length(PLD)
        t = LD(i) + PLD(i);
        tL = LD(i);
        
        % Mask definitions
        mask1 = (PLD(i) + LD(i) > ttr) & (PLD(i) <= ttr); % Phase 1: Wash-in
        mask2 = (PLD(i) + LD(i) > ttr) & (PLD(i) > ttr);  % Phase 2: Wash-out
        
        % --- PHASE 1 (mask1): Wash-in Phase ---
        if any(mask1)
            C1 = A .* f(mask1) .* T1app(mask1) .* exp(-ttr(mask1) ./ T1b(mask1));
            dt1 = t - ttr(mask1);
            
            term1 = T1_csf(mask1) .* (1 - exp(-dt1 ./ T1_csf(mask1)));
            term2 = (exp(-dt1 ./ T1app(mask1)) - exp(-dt1 ./ T1_csf(mask1))) ./ K(mask1);
            
            signal_csf(mask1, i) = k_csf(mask1) .* C1 .* (term1 - term2);
        end
        
        % --- PHASE 2 (mask2): Wash-out Phase ---
        if any(mask2)
            C2 = A .* f(mask2) .* T1app(mask2) .* exp(-ttr(mask2) ./ T1b(mask2));
            decay_phase = t - (ttr(mask2) + tL);
            
            % 1. Residual accumulated signal carried over from Phase 1 (at t = ttr + LD)
            M_phase1_end = k_csf(mask2) .* C2 .* ( ...
                T1_csf(mask2) .* (1 - exp(-tL ./ T1_csf(mask2))) - ...
                (exp(-tL ./ T1app(mask2)) - exp(-tL ./ T1_csf(mask2))) ./ K(mask2) ...
            );
            term_carried_over = M_phase1_end .* exp(-decay_phase ./ T1_csf(mask2));
            
            % 2. Newly generated wash-out signal during Phase 2
            washout_term = k_csf(mask2) .* C2 .* (exp(tL ./ T1app(mask2)) - 1) .* ( ...
                exp((ttr(mask2) - t) ./ T1app(mask2)) - ...
                exp(-tL ./ T1app(mask2)) .* exp((ttr(mask2) + tL - t) ./ T1_csf(mask2)) ...
            ) ./ K(mask2);
            
            signal_csf(mask2, i) = term_carried_over + washout_term;
        end
    end
end