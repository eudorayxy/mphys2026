function signal = TCM_signal(PLD, LD, alpha, lambda, SIpd, T1b, T1e, f, ttr, kb)
    PLD = PLD(:); LD = LD(:);
    T1b = T1b(:); T1e = T1e(:);
    f = f(:); ttr = ttr(:); kb = kb(:);
    assert(length(PLD) == length(LD), 'PLD and LD must have the same length')

    num_person = length(T1b);
    assert(length(f) == num_person && length(kb) == num_person && ...
        length(ttr) == num_person, 'f, ttr, kb, and T1b must have the same length')

    if ~isscalar(T1e)
        assert(length(T1e) == num_person, 'T1b and T1e must have the same length')
    else
        T1e = T1e .* ones(size(T1b));
    end

    A = SIpd * 2 * alpha / lambda;
    C = 1 ./ T1e;

    signal = zeros(num_person, length(PLD));
    for i=1:length(PLD)
        t = LD(i) + PLD(i) - ttr;
        D = 1 ./ T1b;
        J = kb + D;

        mask1 = (PLD(i) + LD(i) > ttr) & (PLD(i) <= ttr);
        mask2 = (PLD(i) + LD(i) > ttr) & (PLD(i) > ttr);

        signal(mask1, i) = ( ...
          A.*f(mask1).*exp(-D(mask1).*ttr(mask1)) .* ((1-exp(-J(mask1).*t(mask1))) ./ J(mask1) + ...
          kb(mask1) .* ((J(mask1) - C(mask1) + C(mask1).*exp(-J(mask1).*t(mask1)) - ...
          J(mask1).*exp(-C(mask1).*t(mask1))) ./ (J(mask1).*C(mask1).*(J(mask1) - C(mask1))))) ...
          );
        
        signal(mask2, i) = ( ...
          A.*f(mask2).*exp(-D(mask2).*ttr(mask2)) .* ((1./J(mask2) + kb(mask2) ./...
          (J(mask2).*(C(mask2)-J(mask2)))) .* ...
          (exp(-J(mask2).*t(mask2)) .* (exp(J(mask2).*LD(i))-1)) - ...
          kb(mask2) .* exp(-C(mask2).*t(mask2)) .* (exp(C(mask2).*LD(i))-1) ./...
          (C(mask2).*(C(mask2)-J(mask2)))) ...
          );


        % if PLD(i) + LD(i) > ttr
        % 
        %     if PLD(i) <= ttr
        %       signal(i) = ( ...
        %           A*f*exp(-D*ttr) * ((1-exp(-J*t)) / J + ...
        %           kb * ((J - C + C*exp(-J*t) - J*exp(-C*t)) / (J*C*(J - C)))) ...
        %           );
        %     else
        %       signal(i) = ( ...
        %           A*f*exp(-D*ttr) * ((1/J + kb / (J*(C-J))) * ...
        %           (exp(-J*t) * (exp(J*LD(i))-1)) - ...
        %           kb * exp(-C*t) * (exp(C*LD(i))-1) / (C*(C-J))) ...
        %           );
        %     end
        % end
    end
end