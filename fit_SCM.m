function  [estimates, rmse, chisq] = fit_SCM(PLD, LD, ...
    alpha, lambda, SIpd, T1b, T1e, sblood, outflow, outflow_csf, ...
    data, data_err, start_point, lower_bound, upper_bound, fit_option)

    fit_outflow_csf = outflow_csf > 0 && outflow ~= 1 && sblood ~= 1;

    data = data(:);
    PLD = PLD(:);
    LD = LD(:);
    data_err = data_err(:);
    start_point = start_point(:);
    lower_bound = lower_bound(:);
    upper_bound = upper_bound(:);

    if ~isempty(data_err)
         assert(length(data_err) == length(data), ...
             'data and data_err must have the same length')
    end

    % Ensure that the size of data and PLD is the same
    assert(length(PLD) == length(data) &&...
        length(LD) == length(data), ...
        'data, PLD, and LD must have the same length')

    assert(length(start_point) == length(lower_bound) &&...
        length(start_point) == length(upper_bound),...
        'start_point, lower_bound, and upper_bound must have the same length')
    
     options = optimset('Display','off');

    if strcmp(fit_option,'minimise_chisq')
        if isempty(data_err)
            error('data_err is required when fit_option is minimise_chisq')
        end
        [estimates, resnorm] = lsqcurvefit(@(params, PLD) SCModel(params, PLD)./data_err,...
            start_point, PLD, data./data_err, lower_bound, upper_bound, options);
    else
        [estimates, resnorm] = lsqcurvefit(@(params, PLD) SCModel(params, PLD),...
            start_point, PLD, data, lower_bound, upper_bound, options);
    end

    function FittedCurve = SCModel(params, PLD)
        if any(~isfinite(data))
            FittedCurve = nan(size(PLD));
            disp('data not finite')
            return;
        end
        if any(~isfinite(params)) || any(params < 0)
            FittedCurve = nan(size(PLD));
            disp('params not finite or negative')
            return;
        end
        FittedCurve = zeros(length(PLD), 1);
        f = params(1);
        ttr = params(2); 
        if fit_outflow_csf
            outflow_csf = params(3);
        end
        for i=1:length(PLD)
            FittedCurve(i) = SCM_signal(sblood, outflow, outflow_csf, PLD(i), LD(i), alpha, ...
                lambda, SIpd, T1b, T1e, f, ttr);
        end
            

        if isempty(FittedCurve) || any(~isfinite(FittedCurve))
            FittedCurve = zeros(size(PLD));   
            disp('FittedCurve not finite or empty')
        end
    end
    
    fit = zeros(size(data));
    if fit_outflow_csf
        outflow_csf = estimates(3);
    end
    f = estimates(1); ttr = estimates(2);

    for fi=1:length(PLD)
        fit(fi) = SCM_signal(sblood, outflow, outflow_csf, PLD(fi), LD(fi), alpha, ...
            lambda, SIpd, T1b, T1e, f, ttr);
    end

    rmse = sqrt(mean((data - fit).^2));
    if isempty(data_err)
        chisq = [];
    else
        chisq = sum((fit - data).^2 ./ data_err.^2);
    end

end