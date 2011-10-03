% DPSO extension
classdef DPSO
    methods
        function h = plot_failures(self, obj, varargin)
            p = inputParser;

            p.addOptional('Plot', {});
            p.addOptional('Axes', gca);
            p.addOptional('Iterations', 1:obj.data.iterations)

            p.parse(varargin{:});
            ret = p.Results;

            data = obj.data.dpso.failures;

            h = stairs(ret.Axes, ret.Iterations, data, ret.Plot{:});

            title('DPSO Failures');
            xlabel('Iteration');
            ylabel('Number');
            legend('Failures');
        end

        function h = plot_sample_size(self, obj, varargin)
            p = inputParser;

            p.addOptional('Plot', {});
            p.addOptional('Axes', gca);
            p.addOptional('Iterations', 1:obj.data.iterations)

            p.parse(varargin{:});
            ret = p.Results;

            h = stairs(ret.Axes, ret.Iterations, obj.data.dpso.sample_size, ret.Plot{:});

            title('DPSO Sample Size');
            xlabel('Iteration');
            ylabel('Sample Size');
            legend('Sample Size');
        end
    end
end

% vi:ex:ts=4:et
