function report = importSysML(model, outputDirectory, varargin)
    arguments
        model (1,:) char
        outputDirectory (1,:) char = pwd
    end

    arguments (Repeating)
        varargin
    end

    report = SysMLImport.internal.import(model, outputDirectory, varargin{:});
end
