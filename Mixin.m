% Mixin class
classdef Mixin < dynamicprops
    properties(Access=private)
        execute_before = []
    end

    methods
        function ret = Mixin()
            ret = ret@dynamicprops();

            ret.execute_before = [];
        end

        function execute_before_call(obj, func)
            obj.execute_before = func;
        end

        function mix(obj, cname)
            m = meta.class.fromName(cname);

            constructor = str2func(cname);
            oo = constructor();

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

                p.GetMethod = @(obj) obj.get_meta_func(oo, meth);
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

    methods(Access=private)
        function out = get_meta_func(obj, oo, meth)
            out = @(varargin) obj.call_meta_func(oo, meth, varargin{:});
        end

        function out = call_meta_func(obj, oo, meth, varargin)
            ffname = [meth.DefiningClass.Name '.' meth.Name];

            if length(varargin) == 1 && ischar(varargin{1}) && strcmp(varargin{1}, 'help')
                out = [];
                help(ffname);
            else
                if ~isempty(obj.execute_before)
                    obj.execute_before(oo, meth, varargin{:});
                end

                if meth.Static
                    func = str2func(ffname);
                    out = func(obj, varargin{:});
                else
                    func = str2func(meth.Name);
                    out = func(oo, obj, varargin{:});
                end
            end
        end
    end
end

% vi:ex:ts=4:et
