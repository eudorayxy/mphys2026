function  [estimates, rmse, chisq] = fit_CPLV_model(PLD, LD, ...
    alpha, lambda, SIpd, T1b, T1e, sblood, outflow, f, ttr, T1_csf, ...
    data, data_err, start_point, lower_bound, upper_bound, fit_option)

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
        k_csf = params(1);
        
        for i=1:length(PLD)
            FittedCurve(i) = CP_LV_model(sblood, outflow, PLD(i), LD(i), alpha, lambda, ...
                SIpd, T1b, T1e, f, ttr, T1_csf, k_csf);
        end
            
        if isempty(FittedCurve) || any(~isfinite(FittedCurve))
            FittedCurve = zeros(size(PLD));   
            disp('FittedCurve not finite or empty')
        end
    end
    
    fit = zeros(size(data));
    k_csf = estimates(1);
   
    for fi=1:length(PLD)
        fit(fi) = CP_LV_model(sblood, outflow, PLD(fi), LD(fi), alpha, lambda, ...
            SIpd, T1b, T1e, f, ttr, T1_csf, k_csf);
    end

    rmse = sqrt(mean((data - fit).^2));
    if isempty(data_err)
        chisq = [];
    else
        chisq = sum((fit - data).^2 ./ data_err.^2);
    end

end