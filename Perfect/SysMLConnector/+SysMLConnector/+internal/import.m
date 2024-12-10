function report = import(modelFilename, outputDirectory, options)
% IMPORT Creates a project with a set of System Composer models from an XMI file
%
%    report = SysMLConnector.internal.import(modelFilename, outputDirectory, NameValueArgs)
%    creates a MATLAB project with a set of Architecture models and
%    associated artifacts. The generated project has the same name as the
%    input file.
%
%    The function returns a MATLAB structure summarizing imported element
%    totals and information on elements that were ignored during the
%    import. The output directory must be specified even in the trial only
%    mode because the directory is used during import as a work area. A
%    report text file is produced in the output directory as well during a
%    non-trial import.
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
%    - 'PruneEmptyArchitectures' : {false} | true
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
    options.DebugMode (1,1) logical = false
    options.ListenerCallback = [];
    options.CancelRequestCallback = [];
    options.SourceTool (1,:) char {mustBeMember(options.SourceTool, {'', 'Cameo', 'EA', 'MagicDraw', 'SystemComposer'})} = ''
end

% Reset cached functions
SysMLConnector.internal.utils.reset;

% Set up output object
report.NotImported    = [];
report.ImportedTotals = [];
report.imported       = [];

if options.DebugMode
    SysMLConnector.internal.StatusMonitor.enableDebug;
    verboseImport = true;
else
    warnState = warning('off', 'backtrace');
    cleanupWarning = onCleanup(@() warning(warnState));
    verboseImport = options.Verbose;
end

if ~isempty(options.ListenerCallback)
    statusListener =  SysMLConnector.internal.StatusMonitor.registerListener(options.ListenerCallback);
    listenerCleanup = onCleanup(@() SysMLConnector.internal.StatusMonitor.unregisterListener(statusListener));
end

if ~isempty(options.CancelRequestCallback)
    SysMLConnector.internal.StatusMonitor.addCancelRequestCallback(options.CancelRequestCallback);
    cancelCleanup = onCleanup(@SysMLConnector.internal.StatusMonitor.removeCancelRequestCallback);
end

% Gather input arguments:
inlineSingleUseArchsAcrossPackages = options.SingleUseArchitectureInlining == "aggressive";
pruneEmptyArchsWithNoRefAndNoChildren = options.PruneEmptyArchitectures;
tryOnly        = options.TrialOnly;
pkgsToIgnore   = options.PackagesToIgnore;
simulinkLeaf   = options.SimulinkBehaviorLeafComponents;
validNameStyle = options.ValidNameStyle;
dtypeMapping   = options.DatatypeMapping;
additionalURIs = options.AdditionalURIs;
patchMDZipSysMLBlockURIs = options.UseRealSysMLURIs;
sourceTool = options.SourceTool;
if isequal(sourceTool, 'Cameo')
    sourceTool = 'MagicDraw';
end

if ~isempty(additionalURIs)
    [~,nTmp] = size(additionalURIs);
    assert(nTmp == 3, 'SysMLConnector:internal:import:InvalidAdditionalURIFormat', ...
        'Additional URIs must be a [nx3] string matrix with each row specifying a full URI, its corresponding short name, and file location.');
end

%% Check mapping table
if ~isempty(dtypeMapping)
    [~,dN] = size(dtypeMapping);
    assert(dN == 2, 'SysMLConnector:internal:import:InvalidDatatypeMappingFormat', 'Datatype mapping must be a Mx2 table of strings');
end


%% Create a temp version of fixed up XMI file
outputDirectory = string(outputDirectory);
if outputDirectory == ""
    outputDirectory = string(pwd);
end

% Tolerate missing extension on file name.
originalModelFilename = modelFilename;

fullFilePath = which(modelFilename);

if ~isempty(fullFilePath) % if which() resolves, use it instead.
    modelFilename = fullFilePath;
end

[fpath, fname, fext] = fileparts(modelFilename);

if isempty(fext)
    % Check for xml first
    fext = '.xml';
    modelFilename = fullfile(fpath, [fname fext]);

    if ~isfile(modelFilename)
        % Check for mdzip file
        fext = '.mdzip';
        modelFilename = fullfile(fpath, [fname fext]);
    end
end

assert(isfile(modelFilename), 'SysMLConnector:internal:import:InputFileNotFound', 'Input file ''%s'' not found.', originalModelFilename);

assert(isfolder(outputDirectory), 'SysMLConnector:internal:import:OutputDirectoryNotFound', 'Output directory does not exist.');

outputProjName = string(fname);

if options.DebugMode
    xmiTmpDir = outputDirectory + filesep + outputProjName + "_tmp";
else
    importStartDirectory = pwd;
    xmiTmpDir = tempname;
    cleanupTempDir = onCleanup(@() SysMLConnector.internal.utils.cleanupTempDirectory(importStartDirectory, xmiTmpDir));
end

xmiTmpFname = outputProjName + "_tmp.xml";

assert(~isfolder(xmiTmpDir), 'SysMLConnector:internal:import:TemporaryDirectoryExists', 'Temporary directory %s already exists. Please delete it then try the import again.', xmiTmpDir);

SysMLConnector.internal.StatusMonitor.publishEvent('ParsingSourceFile', originalModelFilename, sprintf('Parsing source file %s.', originalModelFilename));

mkdir(xmiTmpDir);

% Check if the file is an mdzip archive and if so, retrieve the model
% file.
if strcmp(fext, '.mdzip')
    modelFilename = SysMLConnector.internal.utils.getModelFile(modelFilename, xmiTmpDir);
end

xmiFid = fopen(modelFilename, "r");
modelFileCleanup = onCleanup(@() fclose(xmiFid));

if patchMDZipSysMLBlockURIs
    useTempFile = true;

    xmiTmpFid = fopen(xmiTmpFname, "w");
    cleanupTempFile = onCleanup(@() fclose(xmiTmpFid));
else
    useTempFile = false;

    copyfile(modelFilename, fullfile(xmiTmpDir, xmiTmpFname));
end

umlTok   = [];
sysMLTag = [];
sysmlTok = [];
primTok  = [];

xmiStartDir = cd(xmiTmpDir);
while 1
    tline = fgetl(xmiFid);
    if ~ischar(tline), break, end

    if isempty(umlTok)
        tok = regexp(tline, "http:\/\/www\.omg\.org\/spec\/UML\/(\d+)\/UML",'tokens');

        if ~isempty(tok)
            umlTok = tok{1}{1};
        else
            tok = regexp(tline, "http:\/\/www\.omg\.org\/spec\/UML\/(\d+)",'tokens');
            if ~isempty(tok)
                umlTok = tok{1}{1};
            end
        end
    end

    if isempty(primTok)
        tok = regexp(tline, "http:\/\/www\.omg\.org\/spec\/UML\/(\d+)\/PrimitiveTypes\.xmi",'tokens');

        if ~isempty(tok)
            primTok = tok{1}{1};
        end
    end

    if isempty(sysmlTok)
        tok = regexp(tline, "xmlns:(?<SysMLTag>(?i)sysml)=['""]http:\/\/www\.omg\.org\/spec\/SysML\/(?<SysMLRelease>\d+)\/SysML['""]",'names');
        if ~isempty(tok)
            sysMLTag = tok.SysMLTag;
            sysmlTok = tok.SysMLRelease;
        end
    end

    if isempty(sourceTool)
        match = regexp(tline, '<xmi:exporter>([^<]*)<\/xmi:exporter>', 'tokens');
        if ~isempty(match) && contains(match{1}, 'MagicDraw')
            sourceTool = 'MagicDraw';
        else
            match = regexp(tline, '<xmi:Documentation exporter="([^"]*)"', 'tokens');
            if ~isempty(match) && contains(match{1}, 'Enterprise Architect')
                sourceTool = 'EA';
            elseif contains(tline, 'M3I XmiWriter')
                sourceTool = 'SystemComposer';
            end
        end
    end

    if patchMDZipSysMLBlockURIs
        if contains(tline, 'SysML Profile.mdzip#_11_5EAPbeta_be00301_1147424179914_458922_958')
            tline = strrep(tline, 'SysML Profile.mdzip#_11_5EAPbeta_be00301_1147424179914_458922_958', ...
                "http://www.omg.org/spec/SysML/" + sysmlTok + "/SysML.xmi#" + ...
                "SysML.package_packagedElement_Blocks.stereotype_packagedElement_Block");
        end
        fprintf(xmiTmpFid, "%s\n", tline);
    elseif ~isempty(umlTok) && ~isempty(sysmlTok) && ~isempty(primTok) && ~isempty(sourceTool)
        break;
    end
end
delete(modelFileCleanup);

% Cache the source tool for reference during import.
SysMLConnector.internal.StatusMonitor.setSourceTool(sourceTool);

if useTempFile
    delete(cleanupTempFile);
end

xmiLoc = string(fileparts(mfilename('fullpath')));
unzip(xmiLoc + filesep + "xmi" + filesep + "supportFiles.zip", pwd);

% Use 2018 version of SysML by default unless one is provided by
% additional URI or the model is using 2024.
if (isempty(additionalURIs) || ~any(additionalURIs(:,1) == "SysML.xmi")) ...
        && ~isempty(sysmlTok) && contains(sysmlTok, "2024")
    movefile("SysML.xmi.2024", "SysML.xmi");
else
    movefile("SysML.xmi.2018", "SysML.xmi");
end

%% Load XMI to UML model
log = M3I.Logger;
if verboseImport
    M3IUserMessages.show;
    log.instance.setTestMode;
    log.instance.Level='All';
else
    M3IUserMessages.hide;
    log.instance.resetTestMode;
    log.instance.Level='Fatal';
end

f = M3I.XmiReaderFactory();
s = M3I.XmiReaderSettings;
s.InputFormat = "MagicDraw";
s.InLineProfiles = true;
s.ProcessTopLevelSettings=true;
s.UseCurrentXMIUri = true;

s.FlattenProfiles = true;
s.ProfileURIPrefix = "http://www.magicdraw.com/schemas/";

% If undefined and not provided externally, add one.
if isempty(primTok) && (isempty(additionalURIs) || ~any(contains(additionalURIs(:,1), "PrimitiveTypes.xmi")))
    primTok = '20110701';
end

if ~isempty(primTok)
    extraURIs = {};
    if strcmp(primTok, '20131001')
        % Add this as an additional URI but revert to 2011.
        extraURIs = [extraURIs "http://www.omg.org/spec/UML/" + primTok + "/PrimitiveTypes.xmi"];

        primTok = '20110701';
    end

    primURI = "http://www.omg.org/spec/UML/" + primTok + "/PrimitiveTypes.xmi";

    s.addRemoteUri(primURI, "PrimitiveTypes.xmi", extraURIs);
    if verboseImport || tryOnly
        fprintf("Adding URI: %s\n", primURI);
        arrayfun(@(uri) fprintf("Adding Extra URI: %s\n", uri), extraURIs);
    end
end

% If undefined and not provided externally, add one.
if isempty(umlTok) && (isempty(additionalURIs) || ~any(contains(additionalURIs(:,1), "UML.xmi")))
    umlTok = '20110701';
end

if ~isempty(umlTok)
    extraURIs = {};

    if strcmp(umlTok, '20131001')
        % Add this as an additional URI but revert to 2011.
        extraURIs = [extraURIs "http://www.omg.org/spec/UML/" + umlTok + "/UML.xmi"];
        umlTok = '20110701';
    end

    umlURI = "http://www.omg.org/spec/UML/" + umlTok + "/UML.xmi";
    extraURIs = [extraURIs "http://www.omg.org/spec/uml/" + umlTok + "/uml.xml"];
    s.addRemoteUri(umlURI,"UML.xmi", extraURIs);

    if verboseImport || tryOnly
        fprintf("Adding URI: %s\n", umlURI);
        arrayfun(@(uri) fprintf("Adding Extra URI: %s\n", uri), extraURIs);
    end
end

% If undefined and not provided externally, add one.
if isempty(sysmlTok) && (isempty(additionalURIs) || ~any(contains(additionalURIs(:,1), "SysML.xmi")))
    sysmlTok = '20181001';
end

if ~isempty(sysmlTok) && (isempty(additionalURIs) || ~any(contains(additionalURIs(:,1), "SysML.xmi")))
    sysmlURI = "http://www.omg.org/spec/SysML/" + sysmlTok + "/SysML.xmi";
    s.addRemoteUri(sysmlURI,"SysML.xmi",{});
    if verboseImport || tryOnly
        fprintf("Adding URI: %s\n", sysmlURI);
    end
end

mTmp = height(additionalURIs);
for k = 1:mTmp
    if ~strcmp(additionalURIs(k, 3), "")
        copyfile(additionalURIs(k,3), string(pwd) + filesep + additionalURIs(k,2));
    end

    s.addRemoteUri(additionalURIs(k,1), additionalURIs(k,2), {});

    if verboseImport || tryOnly
        fprintf("Adding URI: %s\n", additionalURIs(k,1));
    end
end

if strcmp(sourceTool, 'EA')
    % If the file is from EA, pre-process it for import.
    if isempty(primTok)
        primTok=umlTok;
    end

    SysMLConnector.internal.StatusMonitor.publishEvent('PreProcessEAModel', xmiTmpFname, 'Pre-Processing EA Model');
    SysMLConnector.internal.utils.processEAXMI(xmiTmpFname, sysMLTag, sysmlTok, primTok);
    if ~isempty(additionalURIs)
        numExternalURIs = sum(strcmp(additionalURIs(:, 3), ""));
    end

    for k = 1:mTmp
        if ~strcmp(additionalURIs(k, 3), "")
            additionalURIPath = string(pwd) + filesep + additionalURIs(k,2);
            SysMLConnector.internal.StatusMonitor.publishEvent('PreProcessEAAdditionalURI', additionalURIPath, 'Pre-Processing Additional URI from EA %s (%i of %i)', additionalURIs(k,2), k, numExternalURIs);
            SysMLConnector.internal.utils.processEAXMI(additionalURIPath, sysMLTag, sysmlTok, umlTok);
        end
    end
end

% Load the XMI file
rdr = f.createXmiReader(s);
rdrCleanup = onCleanup(@() rdr.unloadProfiles);
m3imod = rdr.read(xmiTmpFname);

disp("backupGraph");
% Create a back-up graph.
SysMLConnector.internal.XMIGraph.Graph.getGraph(m3imod.uri, Refresh=true);

%% Survey the model and build up a projection into ZC

disp("UMLVisitor");
% Process the UML Model
umlmmV = SysMLConnector.internal.UMLVisitor();
umlmmV.PackagesToIgnore = string(pkgsToIgnore);

for contentIdx = 1:m3imod.content.size
    nextItem = m3imod.content.at(contentIdx);
    umlmmV.apply(nextItem);
end

% Extract profiles and stereotypes
m3iProfs = [];
candProfiles = [];

if ~isempty(umlmmV.ProfilesFound)
    m3iProfs = umlmmV.ProfilesFound.values;
else
    SysMLConnector.internal.StatusMonitor.publishEvent('ParsingProfiles', '', 'No profiles found.');
end

numProfiles = length(m3iProfs);
for k = 1:numProfiles
    m3iProf = m3iProfs(k);

    profileName = string(m3iProf.name);
    SysMLConnector.internal.StatusMonitor.publishEvent('ParsingProfile', profileName, 'Parsing profile %s (%i of %i).', profileName, k, numProfiles);

    profileExtID = SysMLConnector.internal.utils.getExtID(m3iProf);

    newProf = SysMLConnector.internal.CandidateProfile(profileExtID, profileName);

    if ~isempty(m3iProf.owner)
        newProf.OwnerExtElementID = SysMLConnector.internal.utils.getExtID(m3iProf.owner);
    end

    candProfiles = [candProfiles newProf]; %#ok<AGROW>

    numProfTypes = m3iProf.ownedType.size;

    stereotypeIndices = double.empty(0, numProfTypes);
    stereotypeCount = 0;

    for m = 1:numProfTypes
        pType = m3iProf.ownedType.at(m);
        if isa(pType, 'M3I.ImmutableCustomStereotype')
            stereotypeCount = stereotypeCount + 1;
            stereotypeIndices(stereotypeCount) = m;
        end
    end

    if stereotypeCount == 0
        SysMLConnector.internal.StatusMonitor.publishEvent('ParsingStereotypes', profileName, 'No stereotypes found.');
    else
        idx = 0;
        for m = stereotypeIndices
            idx = idx + 1;

            pType = m3iProf.ownedType.at(m);
            stereotypeName = string(pType.name);

            SysMLConnector.internal.StatusMonitor.publishEvent('ParsingStereotype', stereotypeName, 'Parsing stereotype %s (%i of %i).', profileName + "." + stereotypeName, idx, stereotypeCount);

            % Get stereotype superclass ID
            scExtID = "";
            if pType.superClass.size > 0
                sc = pType.superClass.at(1);
                if ~strncmp(sc.qualifiedName, 'SysML.', 6)
                    scExtID = SysMLConnector.internal.utils.getExtID(sc);
                end
            end

            newStype = SysMLConnector.internal.CandidateStereotype(...
                string(pType.toString()), stereotypeName, ...
                newProf, string(pType.qualifiedName), scExtID);
            newProf.addStereotype(newStype);

            % Get stereotype properties
            for p = 1:pType.ownedAttribute.size
                pElem = pType.ownedAttribute.at(p);
                if ~strncmp(pElem.name, 'base_', 5)
                    elTypeName = "";
                    elType = "";
                    pElemType = pElem.type;

                    if isempty(pElemType)
                        % Try to resolve one more time using regex
                        typeID = SysMLConnector.internal.utils.getBlockPropertyType(pElem);
                        if ~isempty(typeID)
                            elType = SysMLConnector.internal.CandidateElement.idMap("lookup", typeID);
                        end
                    else
                        if isa(pElemType, 'umlmm.Enumeration')
                            elType = umlmmV.visitEnumeration(pElemType);
                        elseif isa(pElemType, 'umlmm.DataType') || ...
                                isa(pElemType,'M3I.ImmutablePrimitiveType')
                            elTypeName = "Dtype:" + string(pElemType.name);
                        end
                    end

                    if isa(elType, 'SysMLConnector.internal.CandidateEnum')
                        % Stereotype properties do not support
                        % dictionary enumerations so mark this one
                        % to generate as a MATLAB class instead.
                        elType.Internal = false;
                        elTypeName = "Enumeration";
                    end

                    newStype.addProperty(string(pElem.name), elTypeName, elType);
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
cd(xmiStartDir);

disp("Clear temp");

if ~options.DebugMode
    delete(cleanupTempDir);
end

% Start building the report.
report.NotImported = umlmmV.NotImported;

% Fetch lists of elements
candArchs = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateArchitecture.CandidateArchitecture");
candComps = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateArchitecture.CandidateComponent");
candActivities = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateAD.Model");
candInteractions = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateInteraction.Interaction");
candPkgs = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidatePackage");
candidateValueTypes = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateValueType");
candIntfs = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateInterface");
candAllocs = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateAllocation.Allocation");
candReqs = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateRequirement");
candReqLinks = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateReqLink");
candStateMachines = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateStateMachine.StateMachine");
candComments = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems","SysMLConnector.internal.CandidateComment.Comment");

% Find all components with deferred architectures (were unable to be
% built at the time they were discovered.
deferredCompIndices = arrayfun(@(candComp) isempty(candComp{1}.Owner), candComps);
deferredComponents = candComps(deferredCompIndices);
deferredComponents = [deferredComponents{:}];
% Merge in generalizations and add deferred components.
numCandidateArchitectures = length(candArchs);
for k = 1:numCandidateArchitectures
    thisArch = candArchs{k};

    if ~isempty(deferredComponents)
        childIndices = strcmp(thisArch.ExtElementID, [deferredComponents.DeferredParentArchitecture]);

        if any(childIndices)
            SysMLConnector.internal.StatusMonitor.publishEvent('AddingDeferredComponents', thisArch.Name, 'Adding deferred components for %s (%i of %i).', thisArch.Name, k, numCandidateArchitectures);

            applicableComponents = deferredComponents(childIndices);

            thisArch.addDeferredChildComponents(applicableComponents);

            deferredComponents(childIndices) = [];
        end
    end

    SysMLConnector.internal.StatusMonitor.publishEvent('MergingGeneralizations', thisArch.Name, 'Merging generalizations for %s (%i of %i).', thisArch.Name, k, numCandidateArchitectures);
    notImported = thisArch.mergeGeneralizations();
    report.NotImported = [report.NotImported notImported];
end

SysMLConnector.internal.StatusMonitor.publishEvent('LinkingPackageChildren', 'Packages', 'Linking packages and children.');

% Link packages in parent-child relationships
rootPackages  = SysMLConnector.internal.CandidatePackage.empty(0, length(candPkgs));
rootPackageIdx = 0;
for k = 1:length(candPkgs)
    % Link pkg to owner
    thisPkg = candPkgs{k};

    thisPkg.link();

    if thisPkg.OwnerExtElementID == ""
        rootPackageIdx = rootPackageIdx + 1;
        rootPackages(rootPackageIdx) = thisPkg;
    end
end

if rootPackageIdx > 1
    % There were multiple packages at the root so create a new package
    % to contain them.
    rootModel = SysMLConnector.internal.CandidatePackage(outputProjName, outputProjName, "");

    for rootPackage = rootPackages
        rootPackage.OwnerExtElementID = rootModel.ExtElementID;
        link(rootPackage);
    end
else
    rootModel = rootPackages;
end

% Link Activities to Packages
for k = 1:length(candActivities)
    thisActivity = candActivities{k};
    thisActivity.linkPackage();
end

% Link Interactions to Packages
for k = 1:length(candInteractions)
    thisInteraction = candInteractions{k};
    thisInteraction.linkPackage();
end

% Link Components to Architectures and Ports to Interfaces
for k = 1:length(candArchs)
    thisArch = candArchs{k};
    thisArch.linkComponentsPortsPackage();
end

% Check for reference cycles (Component referring to ancestor Architecture)
SysMLConnector.internal.StatusMonitor.publishEvent('ReferenceCycles', 'ReferenceCycles', 'Checking architectures for reference cycles.');
for k = 1:length(candArchs)
    thisArch = candArchs{k};
    thisArch.Visited = false;
end
for k = 1:length(candArchs)
    thisArch = candArchs{k};
    notImported = thisArch.checkArchReferenceCycles();

    report.NotImported = [report.NotImported notImported];
end

SysMLConnector.internal.StatusMonitor.publishEvent('ArchitectureCleanup', 'ArchitectureCleanup', 'Cleaning up ports/interfaces/connectors.');
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
    notImported = thisArch.linkAndExpandConnectors();

    report.NotImported = [report.NotImported notImported];
end

% Limitation: Disallow multiple Connectors coming to an Input port.
% Support using Adapters?
for k = 1:length(candArchs)
    thisArch = candArchs{k};
    thisArch.fixFanInConnectors();
end

% Link State Machines to their owning packages
cellfun(@(sm) sm.linkPackage(), candStateMachines);

%% Link requirements to each other and model elements
SysMLConnector.internal.StatusMonitor.publishEvent('LinkRequirements', 'Requirements', 'Creating requirements link candidates.');
for k = 1:length(candReqs)
    thisReq = candReqs{k};
    thisReq.link();
end

for k = 1:length(candReqLinks)
    thisLink = candReqLinks{k};
    thisLink.link();
end

% Refresh to get new links that may have been added
candReqLinks = SysMLConnector.internal.CandidateElement.idMap(...
    "getElems", "SysMLConnector.internal.CandidateReqLink");

if ~isempty(rootModel)
    SysMLConnector.internal.StatusMonitor.publishEvent('RemoveUnusedElements', '', 'Removing unused elements from build tree.');

    %% Prune pkg tree
    buildRootModel = rootModel.visitAndPrunePackageBuildTree(...
        inlineSingleUseArchsAcrossPackages, ...
        pruneEmptyArchsWithNoRefAndNoChildren, ...
        simulinkLeaf);
else
    buildRootModel = [];
    SysMLConnector.internal.StatusMonitor.publishEvent('NoSuitableModel', '', 'No suitable model found in XMI.');
    warning('No suitable model found in XMI');
end

%% Build model
repFileName = "";
if ~tryOnly
    buildDirectory = outputDirectory + filesep + outputProjName;
    assert(~isfolder(buildDirectory),'SysMLConnector:internal:import:OutputProjectAlreadyExists', 'Output project ''%s'' already exists. Cannot overwrite.', buildDirectory);
    repFileName = buildDirectory + "_report.txt";
end

if ~tryOnly && (~isempty(buildRootModel) || ~isempty(candReqs))
    builder = SysMLConnector.internal.Builder(...
        outputDirectory, outputProjName, dtypeMapping, validNameStyle);
    builder.DebugMode = options.DebugMode;

    numArchitectures = sum(arrayfun(@(candidateArchitecture) candidateArchitecture{:}.Build==true, candArchs), 'all');
    numPackages      = sum(arrayfun(@(candidatePackage)      candidatePackage{:}.Build==true, candPkgs), 'all');

    builder.updateBuildCounts(numel(candActivities), numel(candAllocs),       ...
        numArchitectures,      numel(candInteractions), ...
        numPackages,           numel(candProfiles),     ...
        numel(candReqs),       numel(candReqLinks),     ...
        numel(candStateMachines), ...
        numel(candComments));

    builder.createProfiles(candProfiles);

    if ~isempty(buildRootModel)
        buildRootModel.BuiltElement = "";
        buildRootModel.prelimBuild(builder);
        buildRootModel.finishBuild(builder);
    end

    if ~isempty(candAllocs)
        builder.createAllocationFiles(candAllocs);
    end

    if ~isempty(candReqs)
        builder.createRequirementsFile(candReqs);
    end

    if ~isempty(candReqLinks)
        builder.createReqLinks(candReqLinks);
    end

    if ~isempty(candComments)
        cellfun(@(cc) builder.createComment(cc),candComments);
    end

    report.NotImported = [report.NotImported builder.NotImported];
    report.ImportedTotals = builder.Stats;

    builder.BuildComplete = true;

    %% add elements to report
    % start with one type and build up from there
    % right now just including the ones to import
    % need to add a mechanism for not imported
    % impReport.imported = SysMLConnector.internal.CandidateElement.idMap("getAll");
    report.imported = [candPkgs, candArchs, candActivities, ...
        candInteractions, candidateValueTypes, candIntfs, candAllocs,...
        candReqs, candStateMachines];

    %% Print for reporting
    if ~strcmp(repFileName, "")
        SysMLConnector.internal.StatusMonitor.publishEvent('GeneratingReport', '', 'Generating import report.');
        printer = SysMLConnector.internal.Printer(repFileName, verboseImport, tryOnly);

        printer.startSection('NOT IMPORTED FROM XML');
        for k = 1:length(report.NotImported)
            printString = sprintf('%s\t%s\t%s\t%s\t%s',             ...
                report.NotImported(k).Type,    ...
                report.NotImported(k).Element, ...
                report.NotImported(k).Reason,  ...
                report.NotImported(k).Stereotype, ...
                report.NotImported(k).ElementID);
            printer.print(printString);
        end
        printer.endSection('NOT IMPORTED FROM XML');

        printer.startSection('MODEL STRUCTURE');
        if ~isempty(buildRootModel)
            buildRootModel.print(printer);
        end
        printer.endSection('MODEL STRUCTURE');

        printer.startSection('REQUIREMENTS');
        for k = 1:length(candReqs)
            if isempty(candReqs{k}.Owner)
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

    %% delete builder and close everything
    delete(builder);

end

SysMLConnector.internal.StatusMonitor.publishEvent('ImportComplete', originalModelFilename, 'Import of %s complete.', originalModelFilename);

% <ProductSupportPackage><Protect/></ProductSupportPackage>
end
