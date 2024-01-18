function impReport = import(xmiFileName, outputDirectory, varargin)
% IMPORT Creates a project with a set of System Composer models from an XMI file
%
%    impReport = systemcomposer.xmi.import(XMIFILENAME, OUTPUTDIR) creates a MATLAB project with a
%    set of Architecture models and associated artifacts. The project's name is the same as the
%    specified XMI file. The function returns a MATLAB structure summarizing imported element totals
%    and information on elements that were ignored during the import. The output directory must be
%    specified even in the trial only mode because the directory is used during import as a work
%    area. A report text file is produced in the output directory as well during a non-trial import.
%
%    Optional input parameters that may be specified as comma separated 
%    name-value pairs are:
%
%    - 'Verbose' : {false} | true    
%
%       false - No printing    
%       true - Prints debugging and trace information
%
%    - 'SingleUseArchitectureInlining' : 'basic' | {'aggressive'}
%
%       'basic' - Keeps single use Architectures in separate packages as separate 
%       model files
%       'aggressive' - Inlines single use Architectures across packages yielding
%       fewer files    
%
%    - 'PruneEmptyArchitectures' : false | {true}
%
%       false - Keeps empty Architectures that are not referenced by any 
%       other Architectures
%       true - Removes all Architectures that are empty and not referenced
%
%    - 'TrialOnly' : {false} | true
%
%       false - Import and create projects and models
%       true - Read XMI and analyze model without creating a project or any models.
%              Note that the output directory is still used for temporary files.    
% 
%     - 'PackagesToIgnore' : Array of names of packages that should not be imported
%
%     - 'ValidNameStyle' : Make names of models, interfaces, etc. valid MATLAB identifiers by
%     preferring camel casing ('default') or 'underscore'.
%
%     - 'SimulinkBehaviorLeafComponents' : {false} | true
%
%       {false} - Treat as Architecture models or components    
%       true - Make leaf components Simulink behavior models
%
%     - 'DatatypeMapping' : A Mx2 string array specifying mapping of UML Datatypes.
%
%          This is used to map into primitive System Composer datatypes.  The first
%          column is the name of the UML Datatype (e.g Integer).  The second column is
%          the name of System Composer primitive type (e.g. int16). This is
%          especially useful for interface elements.
% 
%   Copyright 2022 The MathWorks, Inc.

    
% List of pending enhancements:
% + Support for custom stereotype property datatypes (all strings right now)
% + Maintain enough information on transformations we made (e.g. bidirectionality)
%   so we can export back an XMI that undoes these transformations    
    
    %% Default options
    % Verbose printing during import
    defVerboseImport = false;
    % Inline Architectures used once even if in separate pkgs
    defSingleUseArchitectureInlining = "basic"; 
    % Remove empty unreferenced and empty architectures
    defPruneEmptyArchsWithNoRefAndNoChildren = true; 
    % Option to ask for no artifacts to be built and simply to try
    defTryOnly = false;
    % Names of packages to ignore during load
    defPkgsToIgnore = [];
    % Leaf components are Simulink behaviors
    defSimulinkLeaf = false;
    % Name styles for making valid names
    defValidNameStyle = "default";
    % Datatype mapping table
    defDtypeMapping = strings(0);
    % Enabling feature level
    defFeatureLevel = "";
    % Additional URIs
    defAdditionalURIs = [];
    % Default patch MDZIP SysML Block ID to real URIs
    defPatchMDZipSysMLBlockURIs = false;
    
    systemcomposer.xmi.CandidateElement.idMap("reset");
    
    %% Parse input args
    ip = inputParser;
    addOptional(ip, 'Verbose', defVerboseImport, @islogical);
    expectedInlineOptions = ["basic", "aggressive"];
    addOptional(ip, 'SingleUseArchitectureInlining', ...
                defSingleUseArchitectureInlining, ...
                @(x) isstring(validatestring(x,expectedInlineOptions)));
    addOptional(ip, 'PruneEmptyArchitectures', ...
                defPruneEmptyArchsWithNoRefAndNoChildren, ...
                @islogical);
    addOptional(ip, 'TrialOnly', ...
                defTryOnly, ...
                @islogical);
    addOptional(ip, 'PackagesToIgnore', ...
                defPkgsToIgnore, ...
                @(x) isstring(x) || all(cellfun(@ischar,x)));
    addOptional(ip, 'SimulinkBehaviorLeafComponents', ...
                defSimulinkLeaf, ...
                @islogical);
    expectedValidNameStyleOptions = ["default", "underscore"];
    addOptional(ip, 'ValidNameStyle', ...
                defValidNameStyle, ...
                @(x) isstring(validatestring(x,expectedValidNameStyleOptions)));
    addOptional(ip, 'DatatypeMapping', ...
                defDtypeMapping, ...
                @(x) isstring(x) || ischar(x));
    addOptional(ip, 'FeatureLevel', ...
                defFeatureLevel, ...
                @(x) isstring(x) || ischar(x));
    addOptional(ip, 'AdditionalURIs', ...
                defAdditionalURIs, ...
                @(x) isstring(x));
    addOptional(ip, 'PatchMDZipSysMLBlockURIs', ...
                defPatchMDZipSysMLBlockURIs, ...
                @islogical);
    parse(ip, varargin{:});
    
    
    %% Options from parser
    verboseImport = ip.Results.Verbose;
    inlineSingleUseArchsAcrossPackages = ...
        ip.Results.SingleUseArchitectureInlining == "aggressive";
    pruneEmptyArchsWithNoRefAndNoChildren = ip.Results.PruneEmptyArchitectures;
    tryOnly        = ip.Results.TrialOnly;
    pkgsToIgnore   = ip.Results.PackagesToIgnore;
    simulinkLeaf   = ip.Results.SimulinkBehaviorLeafComponents;
    validNameStyle = ip.Results.ValidNameStyle;
    featureLevel   = ip.Results.FeatureLevel;
    dtypeMapping   = ip.Results.DatatypeMapping;
    additionalURIs = ip.Results.AdditionalURIs;
    patchMDZipSysMLBlockURIs = ip.Results.PatchMDZipSysMLBlockURIs;
    if ~isempty(additionalURIs)
        [~,nTmp] = size(additionalURIs); 
        if nTmp ~= 3
            error(['Additional URIs must be a [nx3] string matrix with each row ', ...
                   'specifying a full URI, its corresponding short name, and file location.']);
        end
    end

    
    %% Check feature control
    % if ~(strcmp(featureLevel, "R2021a") || ...
    %         strcmp(featureLevel, "R2021b") || ...
    %         strcmp(featureLevel, "InternalTesting"))
    %     error(['This functionality is not available for general use. ', ...
    %            'Please contact MathWorks for access to this trial functionality.']);
    % end
    
    %% Check mapping table
    if ~isempty(dtypeMapping)
        [~,dN] = size(dtypeMapping);
        if dN ~= 2
            error('Datatype mapping must be a Mx2 table of strings');
        end
    end
    

    %% Create a temp version of fixed up XMI file
    outputDirectory = string(outputDirectory);
    if outputDirectory == ""
        outputDirectory = pwd;
    end
    if ~exist(xmiFileName, 'file')
        error('Input file not found.');
    end
    if ~exist(outputDirectory, 'dir')
        error('Output directory does not exist.');
    end
    
    [~,outputProjName] = fileparts(xmiFileName);
    outputProjName = string(outputProjName);
    
    xmiFid = fopen(xmiFileName, "r");
    xmiTmpDir = outputDirectory + filesep + outputProjName + "_tmp";
    xmiTmpFname = outputProjName + "_tmp.xml";

    mkdir(xmiTmpDir);

    if patchMDZipSysMLBlockURIs
        xmiTmpFid = fopen(xmiTmpFname, "w");
    else
        copyfile(xmiFileName, xmiTmpDir + filesep + xmiTmpFname);
    end
        
    umlTok = [];
    sysmlTok = [];
    primTok = [];
    xmiStartDir = cd(xmiTmpDir);
    while 1
        tline = fgetl(xmiFid);
        if ~ischar(tline), break, end
        
        tok = regexp(tline, "http:\/\/www\.omg\.org\/spec\/UML\/(\d+)\/UML",'tokens');
        if ~isempty(tok)
            umlTok = tok{1}{1};
        else
            tok = regexp(tline, "http:\/\/www\.omg\.org\/spec\/UML\/(\d+)",'tokens');
            if ~isempty(tok)
                umlTok = tok{1}{1};
            end
        end
        tok = regexp(tline, "http:\/\/www\.omg\.org\/spec\/UML\/(\d+)\/PrimitiveTypes\.xmi",'tokens');
        if ~isempty(tok)
            primTok = tok{1}{1};
        end
        tok = regexp(tline, "http:\/\/www\.omg\.org\/spec\/SysML\/(\d+)\/SysML",'tokens');
        if ~isempty(tok)
            sysmlTok = tok{1}{1};
        end
        if patchMDZipSysMLBlockURIs
            if contains(tline, 'SysML Profile.mdzip#_11_5EAPbeta_be00301_1147424179914_458922_958')
                tline = strrep(tline, 'SysML Profile.mdzip#_11_5EAPbeta_be00301_1147424179914_458922_958', ...
                               "http://www.omg.org/spec/SysML/" + sysmlTok + "/SysML.xmi#" + ...
                               "SysML.package_packagedElement_Blocks.stereotype_packagedElement_Block");
            end
            fprintf(xmiTmpFid, "%s\n", tline);
        elseif ~isempty(umlTok) && ~isempty(sysmlTok) && ~isempty(primTok)
            break;
        end
        
    end
    fclose(xmiFid);
    if patchMDZipSysMLBlockURIs
        fclose(xmiTmpFid);
    end
    
    xmiLoc = string(fileparts(which('systemcomposer.xmi.import'))); 
    unzip(xmiLoc + filesep + "xmi" + filesep + "supportFiles.zip", pwd);
    if (isempty(additionalURIs) || ~any(additionalURIs(:,1) == "SysML.xmi")) && ...
            contains(sysmlTok, "2018")
        % Copy correct variant of SysML XMI
        movefile("SysML.xmi.2018", "SysML.xmi");
    end
    
    %% Load XMI to UML model
    if verboseImport
        M3IUserMessages.show;
        log = M3I.Logger;
        log.instance.setTestMode;
        log.instance.Level='All';
    end
    
    f = M3I.XmiReaderFactory();
    s = M3I.XmiReaderSettings;
    s.InputFormat = "MagicDraw";
    s.InLineProfiles = true;
    s.ProcessTopLevelSettings=true;
    s.UseCurrentXMIUri = true;

    s.FlattenProfiles = true;
    s.ProfileURIPrefix = "http://www.magicdraw.com/schemas/";
    
    if ~isempty(primTok)
        primURI = "http://www.omg.org/spec/UML/" + primTok + "/PrimitiveTypes.xmi";
        s.addRemoteUri(primURI, "PrimitiveTypes.xmi", {});
        if verboseImport || tryOnly
            fprintf("Adding URI: %s\n", primURI);
        end
    end
    if ~isempty(umlTok)
        umlURI = "http://www.omg.org/spec/UML/" + umlTok + "/UML.xmi";
        umlURI2 = "http://www.omg.org/spec/uml/" + umlTok + "/uml.xml";
        s.addRemoteUri(umlURI,"UML.xmi",{});
        s.addRemoteUri(umlURI2,"UML.xmi",{});
        if verboseImport || tryOnly
            fprintf("Adding URI: %s\n", umlURI);
        end
    end
    if ~isempty(sysmlTok) && (isempty(additionalURIs) || ~any(additionalURIs(:,1) == "SysML.xmi"))
        sysmlURI = "http://www.omg.org/spec/SysML/" + sysmlTok + "/SysML.xmi";
        s.addRemoteUri(sysmlURI,"SysML.xmi",{});
        if verboseImport || tryOnly
            fprintf("Adding URI: %s\n", sysmlURI);
        end
    end
    if ~isempty(additionalURIs)
        mTmp = size(additionalURIs); 
        for k = 1:mTmp
            s.addRemoteUri(additionalURIs(k,1), additionalURIs(k,2), {});
            copyfile(additionalURIs(k,3), string(pwd) + filesep + additionalURIs(k,2));
        end
    end

    rdr = f.createXmiReader(s);
    m3imod = rdr.read(xmiTmpFname);
    mod = m3imod.content.at(1);
    
    %% Survey the model and build up a projection into ZC
    
    % Process the UML Model
    umlmmV = xmi.UMLVisitor();
    umlmmV.PackagesToIgnore = string(pkgsToIgnore);
    umlmmV.apply(mod);

    % Extract profiles and steoreotypes
    m3iprofs = umlmmV.ProfilesFound;
    candProfiles = [];
    for k = 1:length(m3iprofs)
        newProf = systemcomposer.xmi.CandidateProfile(string(m3iprofs(k).name));
        candProfiles = [candProfiles newProf]; %#ok
        
        numProfTypes = m3iprofs(k).ownedType.size;
        for m = 1:numProfTypes
            pType = m3iprofs(k).ownedType.at(m);
            if isa(pType, 'M3I.ImmutableCustomStereotype')
                
                % Get stereotype superclass ID
                scExtID = "";
                if pType.superClass.size > 0
                    sc = pType.superClass.at(1);
                    if ~strncmp(sc.qualifiedName, 'SysML.', 6)
                        scExtID = systemcomposer.xmi.UMLVisitor.getExtID(sc);
                    end
                end
                
                newStype = systemcomposer.xmi.CandidateStereotype(...
                    string(pType.toString()), string(pType.name), ...
                    newProf, string(pType.qualifiedName), scExtID);
                newProf.addStereotype(newStype);
                
                % Get stereotype properties
                for p = 1:pType.ownedAttribute.size
                    pElem = pType.ownedAttribute.at(p);
                    if ~strncmp(pElem.name, 'base_', 5)
                        tName = "";
                        if ~isempty(pElem.type)
                            tName = string(pElem.type.name);
                        end
                        newStype.addProperty(string(pElem.name), tName);
                    end
                end
            end
        end
    end
    
    % Link stereotype inheritance
    for k = 1:length(candProfiles)
        candProf = candProfiles(k);
        if ~isempty(candProf.Stereotypes)
            for m = 1:length(candProf.Stereotypes)
                candProf.Stereotypes(m).link;
            end
        end
    end
    
    % Cleanup
    rdr.unloadProfiles;
    cd(xmiStartDir);
    rmdir(xmiTmpDir, 's');

    % -----------------------------------------------------------
    % Summary of transformations performed on model
    % -----------------------------------------------------------
    % 1. When an Architecture is a specialization of another, 
    %    merge in all of the "superclass" ports, components, and
    %    connectors
    % 2. When an Architecture is used only once, inline it if its
    %    in the same package (project)
    % 3. Split bidirectional interfaces and corresponding ports
    %    into separate input and output interfaces/ports
    % 4. Transform deep nested connectors to be wired all the
    %    way through parent components
    % 5. Do not realize any architectures that are both empty 
    %    and have no references
    % 6. Make multiple fan in connectors to a single input invalid
    % -----------------------------------------------------------
    

    % Fetch lists of elements
    candArchs = systemcomposer.xmi.CandidateElement.idMap(...
        "getElems", "systemcomposer.xmi.CandidateArchitecture");
    candPkgs = systemcomposer.xmi.CandidateElement.idMap(...
        "getElems", "systemcomposer.xmi.CandidatePackage");
    candIntfs = systemcomposer.xmi.CandidateElement.idMap(...
        "getElems", "systemcomposer.xmi.CandidateInterface");
    candReqs = systemcomposer.xmi.CandidateElement.idMap(...
        "getElems", "systemcomposer.xmi.CandidateRequirement");
    candReqLinks = systemcomposer.xmi.CandidateElement.idMap(...
        "getElems", "systemcomposer.xmi.CandidateReqLink");

    % Merge in generalizations
    for k = 1:length(candArchs)
        thisArch = candArchs{k};
        thisArch.mergeGeneralizations();
    end    
    
    % Link packages in parent-child relationships
    rootPkg  = [];
    for k = 1:length(candPkgs)
        % Link pkg to owner
        thisPkg = candPkgs{k};
        thisPkg.link();
        if thisPkg.OwnerExtElementID == ""
            assert(isempty(rootPkg));
            rootPkg = thisPkg;
        end
    end
    
    % Link Components to Architectures and Ports to Interfaces
    for k = 1:length(candArchs)
        thisArch = candArchs{k};
        thisArch.linkComponentsPortsPackage();
    end
    
    % Check for reference cycles (Component referring to ancestor Architecture)
    for k = 1:length(candArchs)
        thisArch = candArchs{k};
        thisArch.Visited = false;
    end
    for k = 1:length(candArchs)
        thisArch = candArchs{k};
        thisArch.checkArchReferenceCycles();
    end
    
    % Set interface direction. Split bidirectional interfaces
    for k = 1:length(candIntfs)
        candIntfs{k}.setDirectionAndSplitBidirectional(true);
    end
    
    % Split bidirectional ports and check port validity
    for k = 1:length(candArchs)
        thisArch = candArchs{k};
        thisArch.setPortDirection(true);
    end
    
    % Link Connectors to Ports, expand indirect and bidirectional connectors
    for k = 1:length(candArchs)
        thisArch = candArchs{k};
        thisArch.linkAndExpandConnectors();
    end
    
    % Limitation: Disallow multiple Connectors coming to an Input port.
    % Support using Adapters?
    for k = 1:length(candArchs)
        thisArch = candArchs{k};
        thisArch.fixFanInConnectors();
    end
    
    
    %% Link requirements to each other and model elements
    for k = 1:length(candReqs)
        thisReq = candReqs{k};
        thisReq.link();
    end
    
    for k = 1:length(candReqLinks)
        thisLink = candReqLinks{k};
        thisLink.link();
    end
    % Refresh to get new links that may have been added
    candReqLinks = systemcomposer.xmi.CandidateElement.idMap(...
        "getElems", "systemcomposer.xmi.CandidateReqLink");
    
    
    %% Prune pkg tree
    buildRootPkg = rootPkg.visitAndPrunePackageBuildTree(...
        inlineSingleUseArchsAcrossPackages, ...
        pruneEmptyArchsWithNoRefAndNoChildren, ...
        simulinkLeaf);

    impReport.NotImported = umlmmV.NotImported;
    if isempty(buildRootPkg)
        warning('No suitable model found in XMI');
    end
    
    
    %% Build model
    repFileName = "";
    if ~tryOnly && (~isempty(buildRootPkg) || ~isempty(candReqs))
        if exist(outputDirectory + filesep + outputProjName, 'dir')
            error('Output project already exists. Cannot overwrite.')
        end
        repFileName = outputDirectory + filesep + outputProjName + "_report.txt";

        builder = xmi.Builder(...
            outputDirectory, outputProjName, dtypeMapping, validNameStyle);
        builder.createProfiles(candProfiles);
        
        if ~isempty(buildRootPkg)
            buildRootPkg.prelimBuild(builder);
            buildRootPkg.finishBuild(builder);
        end
        
        if ~isempty(candReqs)
           builder.createRequirementsFile(candReqs);
        end
        
        if ~isempty(candReqLinks)
           builder.createReqLinks(candReqLinks);
        end
        
        impReport.ImportedTotals = builder.Stats;
        
        delete(builder);
    end

    %% Print for reporting
    printer = systemcomposer.xmi.Printer(repFileName, verboseImport, tryOnly);
    
    printer.startSection('NOT IMPORTED FROM XML');
    for k = 1:length(umlmmV.NotImported)
        printer.print(umlmmV.NotImported(k).Type    + sprintf('\t') + ...
                      umlmmV.NotImported(k).Element + sprintf('\t') + ...
                      umlmmV.NotImported(k).Reason  + sprintf('\t') + ...        
                      umlmmV.NotImported(k).Stereotype);
    end
    printer.endSection('NOT IMPORTED FROM XML');
    
    printer.startSection('MODEL STRUCTURE');
    if ~isempty(buildRootPkg)
        buildRootPkg.print(printer);
    end
    printer.endSection('MODEL STRUCTURE');

    printer.startSection('REQUIREMENTS');
    for k = 1:length(candReqs)
        if isempty(candReqs{k}.ParentRequirement)
            candReqs{k}.print(printer);
        end
    end
    printer.endSection('REQUIREMENTS');
    
    printer.startSection('LINKS');
    for k = 1:length(candReqLinks)
        candReqLinks{k}.print(printer);
    end
    printer.endSection('LINKS');
    
    delete(printer);
end

%% EOF