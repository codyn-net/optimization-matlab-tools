% GCPSO extension
classdef GCPSO
    methods
        function h = plot_sucfail(self, obj, varargin)
            p = inputParser;

            p.addOptional('Plot', {});
            p.addOptional('Axes', gca);
            p.addOptional('Iterations', 1:obj.data.iterations)

            p.parse(varargin{:});
            ret = p.Results;

            data = [obj.data.gcpso.successes; obj.data.gcpso.failures]';

            h = stairs(ret.Axes, ret.Iterations, data, ret.Plot{:});

            title('GCPSO Success/Failure');
            xlabel('Iteration');
            ylabel('Number');
            legend('Successes', 'Failures');
        end

        function h = plot_sample_size(self, obj, varargin)
            p = inputParser;

            p.addOptional('Plot', {});
            p.addOptional('Axes', gca);
            p.addOptional('Iterations', 1:obj.data.iterations)

            p.parse(varargin{:});
            ret = p.Results;

            h = stairs(ret.Axes, ret.Iterations, obj.data.gcpso.sample_size, ret.Plot{:});

            title('GCPSO Sample Size');
            xlabel('Iteration');
            ylabel('Sample Size');
            legend('Sample Size');
        end
    end
end

% vi:ex:ts=4:et
