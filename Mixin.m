% Mixin class
classdef Mixin < dynamicprops
    methods
        function mix(obj, cname)
            m = meta.class.fromName(cname);

            for i = 1:length(m.Methods)
                meth = m.Methods{i};

                if meth.DefiningClass.Name ~= cname
                    continue;
                end

                if ~isempty(regexp(cname, ['\.', meth.Name, '$']))
                    continue;
                end

                ffname = [meth.DefiningClass.Name '.' meth.Name];

                p = addprop(obj, meth.Name);
                p.SetAccess = 'private';
                p.DetailedDescription = help(ffname);

                p.GetMethod = @(obj) Mixin.get_meta_func(obj, meth);
            end
        end

        function out = overridden(obj, funcname)
            prop = findprop(obj, funcname);
            out = ~isempty(prop);
        end

        function out = call_override(obj, funcname, varargin)
            prop = findprop(obj, funcname);

            if isempty(prop)
                out = 0;
            else
                method = prop.GetMethod(obj);
                out = method(varargin{:});
            end
        end
    end

    methods(Static, Access=private)
        function out = get_meta_func(obj, meth)
            out = @(varargin) Mixin.call_meta_func(obj, meth, varargin{:});
        end

        function out = call_meta_func(obj, meth, varargin)
            ffname = [meth.DefiningClass.Name '.' meth.Name];

            if length(varargin) == 1 && ischar(varargin{1}) && strcmp(varargin{1}, 'help')
                out = [];
                help(ffname);
            else
                func = str2func(ffname);
                out = func(obj, varargin{:});
            end
        end
    end
end

% vi:ex:ts=4:et
