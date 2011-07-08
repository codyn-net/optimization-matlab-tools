% Utils class
classdef Utils
    methods(Static)
        function out = find_string(cell, str)
            out = [];

            for i = 1:length(cell)
                if strcmp(cell{i}, str)
                    out = [out, i];
                end
            end
        end
    end
end

% vi:ex:ts=4:et
