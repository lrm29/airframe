function report = importSysML(model, outputDirectory, varargin)
%% importSysML - Import SysML model into System Composer as a MATLAB Project
%
%    report = importSysML(model, outputDirectory, NameValueArgs) creates a
%    MATLAB project with a set of Architecture models and associated
%    artifacts. 
%
%    The project's name is the same as the specified XMI file. The function
%    returns a MATLAB structure summarizing imported element totals and
%    information on elements that were ignored during the import.
% 
%    The output directory must be specified even in the trial only mode
%    because the directory is used during import as a work area.
% 
%    A report text file is produced in the output directory as well during
%    a non-trial import.
%
%    REQUIRED INPUTS:
%       model (1,:) char - Full XMI file path
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
%       PruneEmptyArchitectures (1,1) logical = true
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
%          Additional URIs to import with columns specifying full URI, its
%          corresponding short name, and file location.
% 
%    USAGE:
%       importSysML('myXMIFile.xml');
%

    arguments
        model (1,:) char
        outputDirectory (1,:) char = pwd
    end

    arguments (Repeating)
        varargin
    end

    report = SysMLImport.internal.import(model, outputDirectory, varargin{:});
end
