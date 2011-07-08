% SPSO optimizer
classdef StagePSO
    methods(Static)
        function h = plot_stages(obj, varargin)
            % PLOT_STAGES    Plot number of particles per stage
            %
            %     Plot the number of particles in each stage per iteration.
            %     You can use this to get an insight into the distribution of
            %     the particles over the different fitness functions during
            %     the optimization.
            %
            %     Options:
            %
            %     'Axes'        : The axes to plot in (defaults to gca)
            %     'Plot'        : Additional parameters to the plot command
            %                     {PROP, VALUE,...}
            %     'Iterations'  : The iterations to plot (defaults to all)
            %
            % Author: Jesse van den Kieboom <jesse.vandenkieboom@epfl.ch>
                        p = inputParser;

            p.addParamValue('Axes', gca);
            p.addParamValue('Plot', {});
            p.addParamValue('Iterations', 1:size(obj.data.parameter_values, 1));

            p.parse(varargin{:});
            ret = p.Results;

            num = length(obj.data.stages);
            idx = Utils.find_string(obj.data.data_names, 'StagePSO::stage');

            % For each iteration, count for each stage the number of particles
            data = zeros(length(ret.Iterations), num);

            for i = 1:length(ret.Iterations)
                for j = 1:size(obj.data.data_values, 2)
                    stage = int32(obj.data.data_values(ret.Iterations(i), j, idx)) + 1;
                    data(i, stage) = data(i, stage) + 1;
                end
            end

            leg = {};
            maxlen = 0;

            for i = 1:num
                maxlen = max(maxlen, length(obj.data.stages(i).expression));
            end

            for i = 1:num
                expr = obj.data.stages(i).expression;
                cond = obj.data.stages(i).condition;

                leg = {leg{:}, ['Stage ', num2str(i), ': ', expr, repmat(' ', 1, maxlen - length(expr)), '  if \leftarrow ', cond]};
            end

            h = area(ret.Iterations, data, ret.Plot{:});
            legend(leg, 'Location', 'SouthWest', 'FontName', 'Monospace');

            xlabel('Iteration');
            ylabel('Particles');
            title('Stage Distribution');
        end

        function idx = best_indices(obj)
            it = obj.data.iterations;
            idx = zeros(1, it);

            stidx = Utils.find_string(obj.data.data_names, 'StagePSO::stage');

            for i = 1:it
                % Find max stage
                mstage = max(obj.data.data_values(i, :, stidx));

                % Find max fitness value for particles with this stage
                ii = find(obj.data.data_values(i, :, stidx) == mstage);

                [~, id] = max(obj.data.fitness_values(i, ii, 1), [], 2);
                idx(i) = ii(id);
            end
        end
    end
end

% vi:ex:ts=4:et
