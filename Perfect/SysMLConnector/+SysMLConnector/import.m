function report = import(modelFilename, outputDirectory, options)
%% import - Import SysML model into System Composer as a MATLAB Project
%
%    report = importSysML(modelFilename, outputDirectory, NameValueArgs)
%    creates a MATLAB project with a set of System Composer architecture
%    models and associated artifacts. The generated project has the same
%    name as the input file. 
%
%    The function returns a MATLAB structure summarizing imported element
%    totals and information on elements that were ignored during the
%    import.
% 
%    The output directory must be specified even in the trial only mode
%    because the directory is used during import as a work area.
% 
%    A report text file is produced in the output directory as well during
%    a non-trial import.
%
%    REQUIRED INPUTS:
%       modelFilename (1,:) char - Full SysML file path. 
%               Supported extensions: '.xml', '.xmi', or '.mdzip'
%    
%    OPTIONAL INPUTS:
%       outputDirectory (1,:) char = pwd
%          Directory path for where to put the generated project folder
%          (default is current directory if not specified)
%
%    OPTIONAL NAME-VALUE ARGUMENTS:
%       Verbose (1,1) logical = false   
%          false - No printing    
%          true - Prints debugging and trace information
%
%       SingleUseArchitectureInlining (1,:) char {mustBeMember(SingleUseArchitectureInlining, {'basic', 'aggressive'})} = 'aggressive'
%          'basic'      - Keeps single use Architectures in separate  
%                         packages as separate model files
%          'aggressive' - Inlines single use Architectures across packages 
%                         yielding fewer files    
%
%       PruneEmptyArchitectures (1,1) logical = false
%          false - Keeps empty Architectures that are not referenced by any 
%                  other Architectures
%          true  - Removes all Architectures that are empty and not
%                  referenced
%
%       TrialOnly (1,1) logical = false
%          false - Import and create projects and models
%          true  - Read XMI and analyze model without creating a project or
%                  any models.
%                  Note that the output directory is still used for
%                  temporary files.    
% 
%        PackagesToIgnore (1,:) string = ""
%           Array of names of packages that should not be imported
%
%        ValidNameStyle (1,:) char {mustBeMember(ValidNameStyle, {'default', 'underscore'})} = 'default'
%           'default'    - Make names of models, interfaces, etc. valid
%                          MATLAB identifiers by preferring camel-casing.
%           'underscore' - Prefer using underscores instead
%
%        SimulinkBehaviorLeafComponents (1,1) logical = false
%           false - Treat leaf components as Architecture models and
%                   components    
%           true  - Make leaf components Simulink behavior models
%
%        DatatypeMapping (:,2) string = ""
%          An N x 2 string array specifying mapping of UML Datatypes. 
%          This is used to map into primitive System Composer datatypes.
%          The first column is the name of the UML Datatype (e.g Integer).
%          The second column is the name of System Composer primitive type
%          (e.g. int16). This is especially useful for interface elements.
%
%       AdditionalURIs (:,3) string = ""
%          Multiple dependent files can be imported into one project by
%          specifying the dependencies as additional URIs. Each file should
%          be included as a row in an n-by-3 string array with columns for:
%          the full URI as it appears in the XMI files, the corresponding
%          short name, and the file path. 
%
%          UML, UML Primitive Types, and SysML are included by default and
%          do not need to be specified.
%
%          ["http://url/to/MySpecialURI.xml" "MySpecialURI.xml" "c:\Working\URIs\MySpecialURI.xml"]
% 
%    USAGE:
%       SysMLConnector.import('MySysMLFile.xml');
%

    arguments
        modelFilename (1,:) char {mustBeNonempty}
        outputDirectory (1,:) char = pwd
        options.Verbose (1,1) logical = false
        options.SingleUseArchitectureInlining (1,:) char {mustBeMember(options.SingleUseArchitectureInlining, {'basic', 'aggressive'})} = 'aggressive'
        options.PruneEmptyArchitectures (1,1) logical = false
        options.TrialOnly (1,1) logical = false
        options.PackagesToIgnore (1,:) string = string.empty
        options.ValidNameStyle (1,:) char {mustBeMember(options.ValidNameStyle, {'default', 'underscore'})} = 'default'
        options.SimulinkBehaviorLeafComponents (1,1) logical = false
        options.DatatypeMapping (:,2) string = string.empty
        options.AdditionalURIs (:,3) string = string.empty
        options.UseRealSysMLURIs (1,1) logical = false
    end

    optionArgs = namedargs2cell(options);

    internalReport = SysMLConnector.internal.import(modelFilename, outputDirectory, optionArgs{:});

    report.NotImported = internalReport.NotImported;
    report.ImportedTotals = internalReport.ImportedTotals;
end
