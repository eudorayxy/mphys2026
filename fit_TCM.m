function [estimates, rmse, chisq] = fit_TCM(PLD, LD, alpha, lambda, SIpd,...
T1b, T1e, f, ttr, fit_kb_only, fit_kb_T1b, data, data_err, start_point,...
lower_bound, upper_bound, fit_option)
    data = data(:);
    PLD = PLD(:);
    LD = LD(:);
    data_err = data_err(:);

    if ~isempty(data_err)
         assert(length(data_err) == length(data), ...
             'data and data_err must have the same length')
    end

    if ~isscalar(start_point) && ~isscalar(lower_bound) && ~isscalar(upper_bound)
        start_point = start_point(:);
        lower_bound = lower_bound(:);
        upper_bound = upper_bound(:);
        assert(length(start_point) == length(lower_bound) &&...
            length(start_point) == length(upper_bound),...
            'start_point, lower_bound, and upper_bound must have the same length')
    end
    
    % Ensure that the size of data and PLD is the same
    assert(length(PLD) == length(data)  &&...
        length(LD) == length(data), ...
        'data,  PLD, and LD must have the same length')

    options = optimset('Display','off');
    if strcmp(fit_option, 'minimise_chisq')
        [estimates, resnorm] = lsqcurvefit(@(params, PLD) TCModel(params, PLD)./data_err, ...
            start_point, PLD, data./data_err, lower_bound, upper_bound, options);
    elseif strcmp(fit_option, 'log_kb')
        % HARD CODE - ASSUME FITTING THREE PARAMETERS
        if lower_bound(3) < 10^(-5)
            lower_bound(3) = log(10^(-5));
        end
        upper_bound(3) = log(upper_bound(3));
        start_point(3) = log(start_point(3));

         [estimates, resnorm] = lsqcurvefit(@(params, PLD) TCModel(params, PLD), ...
            start_point, PLD, data, lower_bound, upper_bound, options);
         
    elseif ismember('2d', fit_option)
        options = optimoptions('lsqnonlin', 'Display', 'off');
        [estimates, resnorm] = lsqnonlin(@(params) residual_fun(params), start_point(2:end), ...
            lower_bound(2:end), upper_bound(2:end), options);
    else
        [estimates, resnorm] = lsqcurvefit(@(params, PLD) TCModel(params, PLD), ...
            start_point, PLD, data, lower_bound, upper_bound, options);
    end

    function FittedCurve = TCModel(params, PLD)

        if fit_kb_only
            kb = params;
        elseif fit_kb_T1b
            kb = params(1); T1b = params(2);
        else
            f = params(1); ttr = params(2); kb = params(3);
        end

        FittedCurve = TCM_signal(PLD, LD, alpha, lambda, SIpd,...
            T1b, T1e, f, ttr, kb);
        FittedCurve = FittedCurve(:);
        
    end

    function residuals = residual_fun(params)

        ttr = params(1);
        kb = params(2);
    
        FittedCurve_no_f = TCM_signal_no_f(PLD, LD, alpha, lambda, SIpd, ...
            T1b, T1e, ttr, kb);
        FittedCurve_no_f = FittedCurve_no_f(:);

        if sum(FittedCurve_no_f) == 0
            ttr = rand() * (PLD(1)+LD(1));
            FittedCurve_no_f = TCM_signal_no_f(PLD, LD, alpha, lambda, SIpd, ...
            T1b, T1e, ttr, kb);
            FittedCurve_no_f = FittedCurve_no_f(:);
        end

        if strcmp(fit_option, '2d_minimise_chisq')
            % weights
            weights = 1 ./ data_err.^2;
            denom = sum(weights .* FittedCurve_no_f.^2);
            if denom < 1e-12
                f = 0;
            else
                f = sum(weights .* data .* FittedCurve_no_f) / denom;
            end
            prediction = f .* FittedCurve_no_f;
            % weighted residuals
            residuals = (prediction - data) ./ data_err;
        else
            f = sum(data.*FittedCurve_no_f) / sum(FittedCurve_no_f.^2);
            prediction = f .* FittedCurve_no_f;
            residuals = prediction - data;
        end
    end

    if ismember('2d', fit_option)
        ttr = estimates(1); kb = estimates(2);
        fit_no_f = TCM_signal_no_f(PLD, LD, alpha, lambda, SIpd, ...
                T1b, T1e, ttr, kb);
        fit_no_f = fit_no_f(:);
        if strcmp(fit_option, '2d_minimise_chisq')
            weights = 1 ./ data_err.^2;
            denom = sum(weights .* fit_no_f.^2);
            if denom < 1e-12
                f = 0;
            else
                f = sum(weights .* data .* fit_no_f) / denom;
            end
        else
            f = sum(data.*fit_no_f) ./ sum(fit_no_f.^2);
        end

        estimates(1) = f; estimates(2) = ttr; estimates(3) = kb;
    else

        if fit_kb_only
            kb = estimates;
        elseif fit_kb_T1b
            kb = estimates(1); T1b = estimates(2);
        else
            f = estimates(1); ttr = estimates(2);
            if strcmp(fit_option, 'log_kb')
                 kb = exp(estimates(3));
                 estimates(3) = kb;
                 if kb < 0
                     disp('negative kb')
                 end
            else
                kb = estimates(3);
            end
           
        end
    end

    fit = TCM_signal(PLD, LD, alpha, lambda, SIpd,...
            T1b, T1e, f, ttr, kb);
    fit = fit(:);
    
    rmse = sqrt(mean((data - fit).^2));
    if isempty(data_err)
        chisq = [];
    else
        chisq = sum((fit - data).^2 ./ data_err.^2);
    end
end