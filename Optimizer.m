% OPTIMIZER    Optimizer class
%
%     The optimizer class can be used to load and analyze optimization data.
%     You can construct an optimizer object using Optimizer.create(filename),
%     where 'filename' is either an optimization converted .mat file, or a
%     optimization .db file (in the latter case the .db file will be
%     automatically converted).
%
%     Methods:
%         plot_energy
%         plot_fitness
%         plot_parameters
%
%     Author: Jesse van den Kieboom <jesse.vandenkieboom@epfl.ch>
%
classdef Optimizer < Mixin
    properties (SetAccess = protected)
        data = [];
    end

    properties (Access = protected)
        opts = struct();
    end

    methods(Static)
        function ret = create(filename, varargin)
            p = inputParser;

            p.addRequired('Filename');
            p.addOptional('Extractor', '');
            p.addOptional('ExtractorArgs', '');

            p.parse(filename, varargin{:});
            opts = p.Results;

            data = Optimizer.load_database(opts.Filename, opts.Extractor, opts.ExtractorArgs);

            classname = Optimizer.find_optimizer(data.job.optimizer);

            if isempty(classname)
                classname = 'Optimizer';
            else
                classname = ['optimizers.', classname];
            end

            func = str2func(classname);
            ret = func(data);

            ret.opts = opts;
        end
    end

    methods(Access=protected)
        function ret = Optimizer(data)
            ret = ret@Mixin();

            ret.data = data;
			
			if isfield(data.job, 'extensions')
				for i = 1:length(data.job.extensions)
					ext = Optimizer.find_extension(data.job.extensions{i});

					if ~isempty(ext)
						ret.mix(['extensions.' ext]);
					end
				end
            end
        end
    end

    methods
        function h = plot_fitness(obj, varargin)
            % PLOT_FITNESS    Plot fitness values in each iteration
            %
            %     Plot the fitness values in each iteration.
            %
            %     Options:
            %
            %         Fields      : A cell array of parameters to consider
            %                       (defaults to all parameters)
            %         Axes        : The axes to plot in (defaults to gca)
            %         Plot        : Additional parameters to pass to the plot
            %                       command ({PROP, VALUE, ...})
            %         Iterations  : The iterations to plot (defaults to all iterations)
            %         Smooth      : Smooth the fitness values with a specific window size (defaults to 0)
            %         Average     : Show average fitness values instead of the best (defaults to 0)
            %         Envelope    : Show only improvements in fitness

            if obj.show_help('plot_fitness', varargin{:})
                h = [];
                return;
            end

            p = inputParser;

            p.addParamValue('Fields', {});
            p.addParamValue('Axes', gca);
            p.addParamValue('Plot', {});
            p.addParamValue('Iterations', 1:size(obj.data.fitness_values, 1));
            p.addParamValue('Smooth', 0);
            p.addParamValue('Average', 0);
            p.addParamValue('Envelope', 0);

            p.parse(varargin{:});
            ret = p.Results;

            ind = obj.fitness_indices(ret.Fields);

            if ret.Average
                fit = squeeze(mean(obj.data.fitness_values, 2));
            else
                fit = obj.best_fitness;
            end

            if ret.Smooth > 0
                os = size(fit);
                fit = reshape(smooth(fit, ret.Smooth), os);
            end

            if ret.Envelope
                ismin = strcmp(obj.data.fitness_settings.('__mode__'), 'minimize');
                val = fit(1, :);

                for i = 1:size(fit, 1)
                    if ismin
                        idx = fit(i, :) < val;
                    else
                        idx = fit(i, :) > val;
                    end

                    val(idx) = fit(i, idx);
                    fit(i, :) = val;
                end
            end

            h = plot(ret.Axes, ret.Iterations, fit(ret.Iterations, ind), ret.Plot{:});
            legend(obj.data.fitness_names{ind});

            xlabel('Iteration');
            ylabel('Fitness Value');
            title('Fitness Progression');
        end

        function idx = indices_from_solutions(obj, ids, dim)
            it = double(obj.data.iterations);

            itsel = repmat(1:it, 1, dim);
            solsel = repmat(ids, 1, dim);
            dimsel = repmat(1:dim, it, 1);

            idx = sub2ind([it, obj.data.population_size, dim], itsel, solsel, dimsel(:)');
        end

        function idx = best_indices(obj)
            if obj.overridden('best_indices')
                idx = obj.call_override('best_indices');
                return;
            end

            % For each iteration, select the best solution
            if strcmp(obj.data.fitness_settings.('__mode__'), 'minimize')
                [~, idx] = min(obj.data.fitness_values(:, :, 1), [], 2);
            else
                [~, idx] = max(obj.data.fitness_values(:, :, 1), [], 2);
            end

            idx = idx';
        end

        function ret = best_for_data(obj, data)
            idx = obj.best_indices();
            s = size(data);

            linidx = obj.indices_from_solutions(idx, s(3));

            % Select and reshape
            ret = reshape(data(linidx), obj.data.iterations, s(3));
        end

        function ret = best_fitness(obj)
            ret = obj.best_for_data(obj.data.fitness_values);
        end

        function ret = best_parameters(obj)
            ret = obj.best_for_data(obj.data.parameter_values);
        end

        function ret = best_data(obj)
            ret = obj.best_for_data(obj.data.data_values);
        end

        function h = plot_parameters(obj, varargin)
            % PLOT_PARAMETERS    Plot parameter values in each iteration
            %
            %     Plot the parameter values in each iteration.
            %
            %     Options:
            %
            %         Fields      : A cell array of parameters to consider
            %                       (defaults to all parameters)
            %         Axes        : The axes to plot in (defaults to gca)
            %         Plot        : Additional parameters to pass to the plot
            %                       command ({PROP, VALUE, ...})
            %         Iterations  : The iterations to plot (defaults to all iterations)
            %         ShowError   : Whether to show standard deviation error bars
            %         ShowBest    : Show parameter values of the best solution

            if obj.show_help('plot_parameters', varargin{:})
                h = [];
                return;
            end

            p = inputParser;

            p.addParamValue('Fields', {});
            p.addParamValue('Axes', gca);
            p.addParamValue('Plot', {});
            p.addParamValue('Iterations', 1:size(obj.data.parameter_values, 1));
            p.addOptional('ShowError', 1);
            p.addOptional('ShowBest', 0);

            p.parse(varargin{:});
            ret = p.Results;

            ind = obj.parameter_indices(ret.Fields);

            if ret.ShowBest
                data = obj.best_parameters();
                data = data(:, ind);
            else
                r = obj.data.parameter_values(:, :, ind);

                data = squeeze(mean(r, 2));
                st = squeeze(std(r, 0, 2));
            end

            if ret.ShowError && ~ret.ShowBest
                it = repmat(ret.Iterations', 1, size(data, 2));

                h = errorbar(ret.Axes, it, data, st, ret.Plot{:});
            else
                h = plot(ret.Axes, ret.Iterations, data, ret.Plot{:});
            end

            if isempty(ret.Fields)
                leg = obj.data.parameter_names;
            else
                leg = ret.Fields;
            end

            legend(leg);

            xlabel('Iteration');
            ylabel('Parameter Value');
            title('Parameter Values');

            xlim([ret.Iterations(1), ret.Iterations(end)]);
        end

        function h = plot_energy(obj, varargin)
            % PLOT_ENERGY    Plot the energy in each iteration
            %
            %     Plot the energy of the solutions (change in parameter values
            %     per iteration).
            %
            %     Options:
            %
            %         Fields      : A cell array of parameters to consider
            %                       (defaults to all parameters)
            %         Axes        : The axes to plot in (defaults to gca)
            %         Plot        : Additional parameters to pass to the plot
            %                       command ({PROP, VALUE, ...})
            %         Iterations  : The iterations to plot (defaults to all iterations)

            if obj.show_help('plot_energy', varargin{:})
                h = [];
                return;
            end

            p = inputParser;

            p.addParamValue('Fields', {});
            p.addParamValue('Axes', gca);
            p.addParamValue('Plot', {});
            p.addParamValue('Iterations', 1:size(obj.data.parameter_values, 1) - 1);
            p.addOptional('ShowError', 1);
            p.addOptional('Smooth', 0);

            p.parse(varargin{:});
            ret = p.Results;

            ind = obj.parameter_indices(ret.Fields);
            d = obj.data.parameter_values(:, :, ind);

            speed = abs(diff(d));

            % Scale according to boundaries
            for i = 1:length(ind) - 1
                nm = obj.data.parameter_names{ind(i)};
                param = obj.data.parameters.(strrep(strrep(nm, ':', '_'), '-', '_'));
                bound = obj.data.boundaries.(param);

                df = bound.max - bound.min;

                if df > 0
                    speed(:, :, i) = speed(:, :, i) / df;
                end
            end

            if ret.Smooth > 0
                speed = smooth(speed, ret.Smooth);
            end

            if isempty(ret.Fields)
                % Take the average
                r = sqrt(squeeze(sum(speed.^2, 3)));

                data = mean(r, 2);
                st = std(r, 0, 2);

                leg = {'Average Energy'};
            else
                data = squeeze(mean(speed, 2));
                st = squeeze(std(speed, 0, 2));

                leg = ret.Fields;
            end

            if ret.ShowError
                it = repmat(ret.Iterations', 1, size(data, 2));
                h = errorbar(ret.Axes, it, data, st, ret.Plot{:});
            else
                h = plot(ret.Axes, ret.Iterations, data, ret.Plot{:});
            end

            legend(leg);

            xlabel('Iteration');
            ylabel('Energy');
            title('Energy Progression');

            xlim([ret.Iterations(1), ret.Iterations(end)]);
        end
    end

    methods (Access=protected)
        function out = find_indices(obj, orig, names)
            if isempty(names)
                out = 1:length(orig);
            else
                out = [];

                for j = 1:length(names)
                    for i = 1:length(orig)
                        if strcmp(orig{i}, names{j})
                            out = [out, i];
                            break;
                        end
                    end
                end
            end
        end

        function out = show_help(obj, name, varargin)
            out = 0;

            if length(varargin) == 1 && ischar(varargin{1}) && strcmp(varargin{1}, 'help')
                out = 1;
                help(name);
            end
        end

        function out = fitness_indices(obj, names)
            out = find_indices(obj, obj.data.fitness_names, names);
        end

        function out = parameter_indices(obj, names)
            out = find_indices(obj, obj.data.parameter_names, names);
        end
    end

    methods (Static, Access=private)
        function out = load_database(filename, extractor, extractor_args)
            if ~ischar(filename)
                out = filename;
                return
            end

            if isempty(extractor)
                extractor = 'optiextractor';
            end

            if ~isempty(extractor_args)
                extractor = [extractor, ' ', extractor_args];
            end

            if regexpi(filename, '.db$')
                if ~exist(filename)
                    error(['The database `', filename, '''does not exist...']);
                end

                info = dir(filename);
                matfile = [filename, '.mat'];

                ret = exist(matfile);

                if ret
                    i = dir(matfile);

                    if info.datenum > i.datenum
                        ret = 0;
                    end
                end

                if ~ret
                    disp('Converting database, standby...');
                    [status, result] = system(['LD_LIBRARY_PATH="" ', extractor, ' -e "', filename, '" -o "', matfile, '"']);

                    if status ~= 0
                        error(result);
                    end
                end

                filename = matfile;
            end

            out = load(filename);
        end

        function out = find_mfile_in_dir(name, dirname)
            [thisdir, nm, ext] = fileparts(mfilename('fullpath'));
            lname = lower(name);

            files = dir(fullfile(thisdir, dirname));
            out = '';

            for i = 1:length(files)
                if files(i).isdir
                    continue;
                end

                [dp, nn, ext] = fileparts(files(i).name);

                if strcmp(lname, lower(nn))
                    out = nn;
                    return;
                end
            end
        end

        function out = find_optimizer(name)
            out = Optimizer.find_mfile_in_dir(name, '+optimizers');
        end

        function out = find_extension(name)
            out = Optimizer.find_mfile_in_dir(name, '+extensions');
        end
    end
end

% vi:ex:ts=4:et
