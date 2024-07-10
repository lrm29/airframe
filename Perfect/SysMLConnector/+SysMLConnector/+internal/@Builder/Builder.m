classdef Builder < handle
% BUILDER Helper class for SysMLConnector.internal.import that helps build model.
    properties
        BuildDir = ""
        BuildProject = ""

        ValidNameStyle = "Default"
        
        DatatypeMapping = strings(0);
        
        ArchModelExtIDMap
        
        ProjectPath
        RootProject
        
        IntfExtIDMap
        
        ProjectSLDDPath
        ProjectSLDD
        ProjectSLDDName
        
        AllModelNames string = strings(1,0)
        AllModelPaths = []
        AllInterfaceNames = []
        AllEnumNames = []

        ReqFileName = ""

        ReqFile = []
        AllocationSets = []
        AllLinkSets = []
        
        Profiles = []

        NotImported = []; % Stuff that failed to build should get added here.
        BuildComplete = false; % if false, then delete method knows the import did not exit cleanly.
        Stats 
    end

    properties (SetAccess=private)
        % These are set by the importer before building for the status
        % monitor.
        ActivityCount
        AllocationCount
        ArchitectureCount
        EnumerationCount
        InteractionCount
        InterfaceCount
        PackageCount
        ProfileCount
        RequirementCount
        RequirementLinkCount
    end
    
    properties (Access=private)
        % These are incremented when they are retrieved for the status monitor.
        ActivityIdx        = 0
        AllocationIdx      = 0
        ArchitectureIdx    = 0
        EnumerationIdx     = 0
        InteractionIdx     = 0
        InterfaceIdx       = 0
        PackageIdx         = 0
        ProfileIdx         = 0
        RequirementIdx     = 0
        RequirementLinkIdx = 0
    end
 
    methods
        function vName = makeValidName(this, name)
            if strcmpi(this.ValidNameStyle, "underscore")
                name = strrep(name, " ", "_");
                name = regexprep(name, '(_)\1+', '');
            end
            
            vName = matlab.lang.makeValidName(name);
            eN = exist(vName); %#ok<EXIST>
            if eN > 0 && eN ~= 7
                vName = vName + "_1";
            end
        end
    
        function this = Builder(buildDir, buildProj, dtypeMapping, vNameStyle)
            this.BuildDir = buildDir;
            this.BuildProject = buildProj;
            
            this.DatatypeMapping = containers.Map;
            this.ValidNameStyle = vNameStyle;

            for k = 1:size(dtypeMapping, 1)
                this.DatatypeMapping(dtypeMapping(k,1)) = ...
                    dtypeMapping(k,2);
            end
            
            SysMLConnector.internal.StatusMonitor.publishEvent('BuilderCreateProject', buildProj, 'Creating project %s.', buildProj);

            pPath = buildDir + filesep + buildProj;
            this.RootProject = matlab.project.createProject(...
                'Name', buildProj, 'Folder', pPath);
            this.ProjectPath = this.RootProject.RootFolder;
            this.RootProject.Name = buildProj;
            
            this.ArchModelExtIDMap = containers.Map;
            this.IntfExtIDMap = containers.Map;
        
            this.ProjectSLDDName = this.makeValidName(buildProj) + "_DD.sldd";
            ddFile = this.ProjectPath + filesep + this.ProjectSLDDName;

            SysMLConnector.internal.StatusMonitor.publishEvent('BuilderCreateDataDictionary', this.ProjectSLDDName, 'Creating data dictionary.');
            try
                this.ProjectSLDD = systemcomposer.createDictionary(ddFile);
            catch ME
                if ~ismember(ME.identifier, {'mf0:messages:UniquenessConstraint', 'SLDD:sldd:SlddFileWithSameNameAlreadyOpen'})
                    rethrow(ME);
                end
                [~, ddName] = fileparts(ddFile);

                try
                    close(systemcomposer.openDictionary(ddName + ".sldd"));
                catch
                    Simulink.data.dictionary.closeAll(ddName + ".sldd")
                end

                this.ProjectSLDD = systemcomposer.createDictionary(ddFile);
            end

            this.ProjectSLDDPath = ddFile;
            this.RootProject.addFile(ddFile);
            this.RootProject.addPath(this.ProjectPath);
        
            this.Stats.NumProjectFolders = 0;

            this.Stats.NumArchitectureModels = 0;
            this.Stats.NumArchitecturePorts = 0;
            this.Stats.NumComponents = 0;
            this.Stats.NumConnectors = 0;
            this.Stats.NumInterfaces = 0;  

            this.Stats.NumActivityDiagrams = 0;
            this.Stats.NumInteractions = 0;

            this.Stats.NumRequirements = 0;
            this.Stats.NumReqLinks = 0;

            this.Stats.NumProfiles = 0;
            this.Stats.NumStereotypes = 0;
            this.Stats.NumStereotypeProps = 0;
            this.Stats.NumStereotypesApplied = 0;
            this.Stats.NumStereotypePropsSet = 0;
            this.Stats.NumStateMachines = 0;
            
            populateEnumerations(this);
            populateInterfaces(this);
        end
        
        function delete(this)
            % Check to see if the import was successful
            if ~this.BuildComplete
                warning('SysMLConnector:import:CancelBuild', 'Import aborted. Performing clean up. It is recommended that you let the clean up complete on its own.');
            end

            % The builder needs to exit cleanly so do not allow the status
            % monitor to abort the build during builder delete.
            SysMLConnector.internal.StatusMonitor.inhibitCancelRequest;
            cleanup = onCleanup(@SysMLConnector.internal.StatusMonitor.uninhibitCancelRequest);

            SysMLConnector.internal.StatusMonitor.publishEvent('FinalizingBuild', '', 'Finalizing build.');

            allMdls = this.ArchModelExtIDMap.values;
            
            numProfiles = length(this.Profiles);
            for k = 1:numProfiles
                SysMLConnector.internal.StatusMonitor.publishEvent('SavingProfiles', this.Profiles(k).Name, 'Saving profiles (%i of %i).', k, numProfiles);
                this.Profiles(k).save;
            end
            
            SysMLConnector.internal.StatusMonitor.publishEvent('AddingShutdownFileToProject', '', 'Adding shutdown file to project.');
            % Create a shutdown file to ensure all Profiles close
            sdownFile = this.ProjectPath + filesep + "projectShutdown.m";
            fid = fopen(sdownFile, 'w');
            sdownFileCleanup = onCleanup(@()fclose(fid));
            for k = 1:length(this.Profiles)
                fprintf(fid, ['profTmp = systemcomposer.profile.Profile.find(''', ...
                              this.Profiles(k).Name, ''');\n']);
                fprintf(fid, 'if ~isempty(profTmp); profTmp.close(true); end; clear(''profTmp'');\n');
            end
            delete(sdownFileCleanup);
            this.RootProject.addFile(sdownFile);
            this.RootProject.addShutdownFile(sdownFile);
            
            numModels = length(allMdls);
            for k = 1:numModels
                modelHandle = allMdls{k};
                modelName = get_param(modelHandle, 'Name');
                SysMLConnector.internal.StatusMonitor.publishEvent('SavingAndClosingModels', modelName, 'Saving and closing models, %s (%i of %i).', modelName, k, numModels);
                save_system(modelHandle, '', ...
                            'SaveDirtyReferencedModels', 'on');
                close_system(modelHandle);
            end

            numAllocationSets = length(this.AllocationSets);
            for k = 1:numAllocationSets
                allocationSet = this.AllocationSets(k);
                SysMLConnector.internal.StatusMonitor.publishEvent('SavingAndClosingAllocationSets', allocationSet.Name, 'Saving and closing allocation sets (%i of %i).', k, numAllocationSets);
                save(allocationSet);
                close(allocationSet);
            end
            
            if ~isempty(this.ReqFile)
                SysMLConnector.internal.StatusMonitor.publishEvent('SavingAndClosingRequirementSet', this.ReqFile.Name, 'Saving and closing requirement set.');
                this.ReqFile.save;
                this.ReqFile.close;
            end
            
            numLinkSets = length(this.AllLinkSets);
            for k = 1:numLinkSets
                SysMLConnector.internal.StatusMonitor.publishEvent('AddingLinksetsToProject', this.AllLinkSets(k), 'Adding requirement link sets to project (%i of %i).', k, numLinkSets);
                this.RootProject.addFile(this.AllLinkSets(k));
            end
            
            numProfiles = length(this.Profiles);
            for k = 1:numProfiles
                SysMLConnector.internal.StatusMonitor.publishEvent('ClosingProfiles', this.Profiles(k).Name, 'Closing profiles (%i of %i).', k, numProfiles);
                this.Profiles(k).close;
            end

            if ~isempty(this.ProjectSLDD) && isvalid(this.ProjectSLDD) && isOpen(this.ProjectSLDD) 
                SysMLConnector.internal.StatusMonitor.publishEvent('SavingDataDictionary', this.ProjectSLDDName, 'Saving data dictionary.');
                this.ProjectSLDD.save;
            end

            SysMLConnector.internal.StatusMonitor.publishEvent('ClosingProject', this.RootProject.Name, 'Closing imported project.');
            this.RootProject.close;
        end

        function addNotImported(this, element, type, reason)
            % This function is intentionally written to be fault-tolerant.
            notImp = element.createNotImported(type, reason);
            
            this.NotImported = [this.NotImported notImp];

            try 
                % Try to let the checker know this was not built
                element.Build = false;
            catch ME
                % do not break the build, just warn to let us know we
                % missed a property assignment.
                warning(ME.identifier, '%s', getReport(ME));
            end
        end
        
        function populateEnumerations(this)
            enumTypes = SysMLConnector.internal.CandidateElement.idMap(...
                "getElems", "SysMLConnector.internal.CandidateEnum");

            this.EnumerationCount = numel(enumTypes);

            arrayfun(@(enumType) prelimBuild(enumType, this), [enumTypes{:}]);
        end
        
        function populateInterfaces(this)
            valueTypes = SysMLConnector.internal.CandidateElement.idMap(...
                "getElems", "SysMLConnector.internal.CandidateValueType"); 

            intfTypes =  SysMLConnector.internal.CandidateElement.idMap(...
                "getElems", "SysMLConnector.internal.CandidateInterface");

            % Build value types first in case the interfaces use them.
            intfTypes = [valueTypes intfTypes];

            allIntfNames = [];
            this.InterfaceCount = length(intfTypes);
            for k = 1:this.InterfaceCount
                thisIntf = intfTypes{k};
                if thisIntf.doBuild()
                    allIntfNames = [allIntfNames this.makeValidName(thisIntf.Name)]; %#ok<AGROW>
                end
            end

            if ~isempty(allIntfNames)
                allNamesMerged = [this.AllEnumNames allIntfNames];
                allNamesMerged1 = matlab.lang.makeUniqueStrings(...
                    allNamesMerged, [false(1, length(this.AllEnumNames)) true(1, length(allIntfNames))], namelengthmax);
                allIntfNames = allNamesMerged1(length(this.AllEnumNames)+1:end);
                
                intfIdx = 1;
                for k = 1:length(intfTypes)
                    thisIntf = intfTypes{k};
                    if thisIntf.doBuild()
                        thisIntf.BuildName = allIntfNames(intfIdx);
                        intfIdx = intfIdx + 1;
                    end
                end
                
                for k = 1:length(intfTypes)
                    thisIntf = intfTypes{k};
                    if thisIntf.doBuild()
                        thisIntf.buildZCInterface(this);
                    end
                end
            end
        end
        
        function mn = getModelName(this, mName)
            if mName == ""
                mName = "Architecture";
            end
            
            mn = this.makeValidName(mName);

            this.AllModelNames = matlab.lang.makeUniqueStrings(...
                [this.AllModelNames, mn], [false(1, length(this.AllModelNames)) true], namelengthmax);

            mn = this.AllModelNames(end);
        end
        
        function projFolderPath = createProjectFolder(this, candProj)
            projFolderPath = this.ProjectPath;

            if ~isempty(candProj) && ~isempty(candProj.BuildParentPackage)
                candProjName = candProj.BuildName;
                
                candProj.ZCProjectFolder = ...
                    candProj.BuildParentPackage.ZCProjectFolder + filesep + candProjName;
                projFolderPath = projFolderPath + filesep + candProj.ZCProjectFolder;
                mkdir(projFolderPath);
                
                this.RootProject.addPath(projFolderPath);
                
                this.Stats.NumProjectFolders = this.Stats.NumProjectFolders + 1;
            end
        end

        function createPackagedFile(this, element)
            candProj = element.ParentPackage;
            
            folderPath = this.createProjectFolder(candProj);
            filePath = folderPath + filesep + element.BuildFileName;

            fid = fopen(filePath, 'w');
            cleanup = onCleanup(@()fclose(fid));
            fprintf(fid, element.BuildFileContent);
        end
        
        function slMdlHdl = createSimulinkModel(this, candArch)
            tempMdlName = this.BuildProject + "_tmp";
            tempMdlZCM = systemcomposer.createModel(tempMdlName);
            tempMdlZCM.linkDictionary(this.ProjectSLDDPath);
            for k = 1:length(this.Profiles)
                tempMdlZCM.applyProfile(this.Profiles(k).Name)
            end
            
            candArchName = this.getModelName(candArch.Name);
            tmpComp = tempMdlZCM.Architecture.addComponent(char(candArchName));
            candArch.prelimBuildPorts(tmpComp.Architecture, this);
            
            candArch.ZCElement = tmpComp.Architecture;
            
            this.applyStereotypes(candArch);
            this.createParameters(candArch);
            
            candProj = candArch.ParentPackage;
            slMdlPath = this.ProjectPath + ...
                candProj.ZCProjectFolder + filesep + candArchName + ".slx";
            
            this.AllModelPaths = [this.AllModelPaths slMdlPath];
            tmpComp.createSimulinkBehavior(char(slMdlPath));
            this.RootProject.addFile(slMdlPath);
            candArch.SimulinkModelName = candArchName;

            close_system(tempMdlName, 0);
            slMdlHdl = load_system(candArchName);
            this.ArchModelExtIDMap(candArch.ExtElementID) = slMdlHdl;
            
            set_param(slMdlHdl, 'HasSystemComposerArchInfo', 'on');
            candArch.ZCElement = get_param(slMdlHdl, 'SystemComposerArchitecture');
            set_param(slMdlHdl, 'HasSystemComposerArchInfo', 'off');
            candArch.ZCElement.ExternalUID = candArch.ExtElementID;

            this.Stats.NumArchitectureModels = this.Stats.NumArchitectureModels + 1;
        end

        function archMdl = createActivityDiagram(this, candAct)
            SysMLConnector.internal.StatusMonitor.publishEvent('BuildActivity', candAct.ExtElementID, 'Building activity %s (%i of %i).', candAct.Name, this.getActivityIdx, this.ActivityCount);

            archMdlName = this.getModelName(candAct.Name);
            candAct.BuildName = archMdlName;

            try
                publish(candAct);
            catch ME
                SysMLConnector.internal.StatusMonitor.publishEvent('BuildActivityFailed', candAct.ExtElementID, 'Build of activity %s did not exit cleanly.', candAct.Name);
                warning('SysMLConnector:internal:Builder:FailedToBuildActivityDiagram', 'Unable to complete build of activity diagram ''%s'' with ID ''%s''. Error: %s (%i).', candAct.Name, candAct.ExtElementID, ME.identifier, ME.stack(1).line);
            end

            if ~isempty(candAct.ZCElement)
                actArch  = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(candAct.ZCElement);
                archMdl  = actArch.Model;
                slHandle = archMdl.SimulinkHandle;
                
                candProj = candAct.ParentPackage;
                archMdlPath = this.ProjectPath + ...
                    candProj.ZCProjectFolder + filesep + archMdlName + ".slx";
                this.AllModelPaths = [this.AllModelPaths archMdlPath];
    
                save_system(slHandle, archMdlPath);
    
                this.RootProject.addFile(archMdlPath);
    
                this.ArchModelExtIDMap(candAct.ExtElementID) = slHandle;
            
                this.Stats.NumActivityDiagrams = this.Stats.NumActivityDiagrams + 1;
            end
        end

        function interactionMdl = createInteraction(this, candInteraction)
            SysMLConnector.internal.StatusMonitor.publishEvent('BuildInteraction', candInteraction.ExtElementID, 'Building interaction %s (%i of %i).', candInteraction.Name, this.getInteractionIdx, this.InteractionCount);

            archMdlName = this.getModelName(candInteraction.Name);
            candInteraction.BuildName = archMdlName;
            publish(candInteraction);
            interactionMdl  = candInteraction.ZCElement.Model;
            slHandle = interactionMdl.SimulinkHandle;
            
            candProj = candInteraction.ParentPackage;
            archMdlPath = this.ProjectPath + ...
                candProj.ZCProjectFolder + filesep + archMdlName + ".slx";
            this.AllModelPaths = [this.AllModelPaths archMdlPath];

            save_system(slHandle, archMdlPath);

            this.RootProject.addFile(archMdlPath);

            this.ArchModelExtIDMap(candInteraction.ExtElementID) = slHandle;
        
            this.Stats.NumInteractions = this.Stats.NumInteractions + 1;
        end

        stateMachineMdl = createStateMachine(this,candStateMachine);
        
        function archMdl = createArchitectureModel(this, candArch)
            archMdlName = this.getModelName(candArch.Name);
            
            archMdl = systemcomposer.createModel(archMdlName);
            archMdl.linkDictionary(this.ProjectSLDDPath);
            for k = 1:length(this.Profiles)
                archMdl.applyProfile(this.Profiles(k).Name)
            end
            
            candProj = candArch.ParentPackage;
            archMdlPath = this.ProjectPath + ...
                candProj.ZCProjectFolder + filesep + archMdlName + ".slx";
            this.AllModelPaths = [this.AllModelPaths archMdlPath];
            save_system(archMdl.SimulinkHandle, archMdlPath);
            this.RootProject.addFile(archMdlPath);

            this.ArchModelExtIDMap(candArch.ExtElementID) = archMdl.SimulinkHandle;
        
            this.Stats.NumArchitectureModels = this.Stats.NumArchitectureModels + 1;
        end
        
        function comp = createComponent(this, archHdl, comp)
            compName = comp.Name;
            if compName == "" && ~isempty(comp.ReferenceArch)
                % Inherit name from architecture
                compName = comp.ReferenceArch.Name;
            end
            if compName == ""
                % Default name
                compName = "Component";
            end
            
            compName = char(compName);
            % Remove slashes
            compName = strrep(compName, '/', '_');
            
            cComps = archHdl.Components;

            % Unique component names
            otherNames = [];
            for k = 1:length(cComps)
                otherNames = [otherNames string(cComps(k).Name)]; %#ok<AGROW>
            end
            
            cn = matlab.lang.makeUniqueStrings(...
                [otherNames ,string(compName)], ...
                [false(1, length(otherNames)) true]);
            compName = cn(end);
            
            comp = archHdl.addComponent(char(compName));
            this.Stats.NumComponents = this.Stats.NumComponents + 1;
        end
        
        function aP = createPort(this, archHdl, portName, portDir)
            aP = archHdl.addPort(char(portName), char(portDir));
            this.Stats.NumArchitecturePorts = this.Stats.NumArchitecturePorts + 1;
        end
        
        function conn = createConnector(this, srcPort, dstPort)
            conn = srcPort.connect(dstPort);
            this.Stats.NumConnectors = this.Stats.NumConnectors + 1;            
        end
        
        function intf = createInterface(this, intfExtID, intfName)
            SysMLConnector.internal.StatusMonitor.publishEvent('BuildInterface', intfExtID, 'Building interface %s (%i of %i).', intfName, this.getInterfaceIdx, this.InterfaceCount);

            assert(~this.IntfExtIDMap.isKey(intfExtID));
            intf = this.ProjectSLDD.addInterface(char(intfName));
            this.IntfExtIDMap(intfExtID) = intf;
            this.Stats.NumInterfaces = this.Stats.NumInterfaces + 1;            
        end

        function valueType = createValueType(this, intfExtID, intfName)
            SysMLConnector.internal.StatusMonitor.publishEvent('BuildInterface', intfExtID, 'Building interface %s (%i of %i).', intfName, this.getInterfaceIdx, this.InterfaceCount);
            assert(~this.IntfExtIDMap.isKey(intfExtID));
            valueType = this.ProjectSLDD.addValueType(char(intfName));
            this.IntfExtIDMap(intfExtID) = valueType;
            this.Stats.NumInterfaces = this.Stats.NumInterfaces + 1;            
        end

        function valueType = setDataType(builder, valueType, interface)
            arguments
                builder
                valueType
                interface = []
            end
            
            baseType = valueType;

            if isempty(interface) 
                % Value Types cannot be typed by other value types so they
                % must be boiled down to their base types.
                recursionIdx = 1;
                recursionLimit = 30;
                while isa(baseType.Type, 'SysMLConnector.internal.CandidateValueType') || recursionIdx > recursionLimit
                    baseType = baseType.Type;
                    recursionIdx = recursionIdx + 1;
                end
            end

            tName = 'double'; % assume

            isBus = false;
            if contains(valueType.TypeName, "Bus:") 
                tName = char("Bus: " + valueType.Type.BuildName);
                isBus = true;
            elseif contains(valueType.TypeName, "Enumeration")
                tName = ['Enum:' char(valueType.Type.BuildName)]; 
            elseif isa(baseType.Type, "SysMLConnector.internal.CandidateValueType")
                % Assume it is a value type name
                tName = baseType.Type.BuildName;
            elseif contains(baseType.TypeName, "Dtype:")
                dtypeName = extractAfter(baseType.TypeName, "Dtype:");
                if isKey(builder.DatatypeMapping, dtypeName)
                    tName = char(builder.DatatypeMapping(dtypeName));
                else
                    if contains(dtypeName, 'Bool', 'IgnoreCase', true)
                        tName = 'boolean';
                    elseif contains(dtypeName, 'Int', 'IgnoreCase', true) || ...
                            contains(dtypeName, 'Natural', 'IgnoreCase', true)
                        tName = 'int32';
                    elseif contains(dtypeName, 'Real', 'IgnoreCase', true)
                        tName = 'double';
                    elseif contains(dtypeName, 'string', 'IgnoreCase', true)
                        tName = 'string';
                    end
                end
            end

            if isBus
                % Interface Element with a Bus Data Type
                zcElem = interface.addElement(...
                    char(builder.makeValidName(valueType.Name)), ...
                    'Type', tName);
            else
                dVal = 1; % assume
                if ~isempty(valueType.Dim) && ~isinf(valueType.Dim) && valueType.Dim > 0
                    dVal = valueType.Dim;
                end
                dimensions = int2str(dVal);

                if ~isempty(interface)
                    % Interface Element without a Bus Data Type
                    zcElem = interface.addElement(...
                        char(builder.makeValidName(valueType.Name)), ...
                        'Type', tName, 'Dimensions', dimensions);
                else
                    % Standalone Value Type Interface
                    zcElem = valueType.ZCElement;
                    setDataType(zcElem, tName);
                    setDimensions(zcElem, dimensions);
                end
            end

            zcElem.ExternalUID = valueType.ExtElementID;
        end
        
        function intf = lookupInterfaceFromExtID(this, intfExtID)
            intf = [];
            if this.IntfExtIDMap.isKey(intfExtID)
                intf = this.IntfExtIDMap(intfExtID);
            end
        end
        
        function archMdlName = lookupModelNameFromExtID(this, candArchExtID)
            archMdl = this.ArchModelExtIDMap(candArchExtID);
            archMdlName = get_param(archMdl, 'Name');
        end
        
        function recAddRequirementToSet(this, req, reqParent)
            req.ReqID = strrep(req.ReqID, '#', '');
            req.Name  = strrep(slreq.cpputils.htmlToText(req.Name), newline, ' ');
            req.Text  = strrep(slreq.cpputils.htmlToText(req.Text), newline, ' ');
            
            thisReq = reqParent.add(Id=req.ReqID, ...
                                    Summary=req.Name, ...
                                    Description=req.Text);
            req.ZCElement = thisReq;

            setAttribute(thisReq, 'ExternalUID',   req.ExtElementID);
            setAttribute(thisReq, 'ExternalType', req.Type);

            % Check for additional properties on the requirement
            if ~isempty(req.AdditionalProperties)
                additionalProperties = fieldnames(req.AdditionalProperties);
                newProperties = setdiff(additionalProperties, this.ReqFile.CustomAttributeNames);
                arrayfun(@(propName) addAttribute(this.ReqFile, string(propName), 'Edit'), newProperties);
                arrayfun(@(propName) setAttribute(thisReq, string(propName), req.AdditionalProperties.(string(propName))), additionalProperties);
            end

            this.Stats.NumRequirements = this.Stats.NumRequirements + 1;
            for k = 1:length(req.ChildRequirements)
                recAddRequirementToSet(...
                    this, req.ChildRequirements(k), thisReq);
            end
        end
        
        function createProfiles(this, candProfiles)
            numProfiles = length(candProfiles);
            for k = 1:numProfiles
                thisProf = candProfiles(k);

                SysMLConnector.internal.StatusMonitor.publishEvent('BuildingProfile', thisProf.Name, 'Building profile %s (%i of %i).', thisProf.Name, this.getProfileIdx, this.ProfileCount);
                if ~isempty(thisProf.Stereotypes)
                    % Fixup names of stereotypes to be unique. This happens
                    % because stereotypes in different packages in the same profile
                    % can end up with the same name
                    thisProf.fixupStereotypeNames(this);
                    
                    % Make stereotype prop names unique across inheritance
                    % System Composer requires this while UML does not
                    for p = 1:length(thisProf.Stereotypes)
                        thisProf.Stereotypes(p).uniquePropNames(this);
                    end
                    
                    % Create profile
                    newProfName = this.makeValidName(char(thisProf.Name));
                    newProf = systemcomposer.profile.Profile.createProfile(newProfName);
                    this.Profiles = [this.Profiles newProf];
                    profFile = save(newProf, char(this.ProjectPath));
                    this.RootProject.addFile(profFile);
                    thisProf.FinalName = newProfName;
                    
                    this.Stats.NumProfiles = this.Stats.NumProfiles + 1;
                    
                    % Add stereotypes 
                    numStereotypes = length(thisProf.Stereotypes);
                    for p = 1:numStereotypes
                        st = thisProf.Stereotypes(p);
                        SysMLConnector.internal.StatusMonitor.publishEvent('BuildingStereotype', st.ExtElementID, 'Building stereotype %s (%i of %i).', st.Name, p, numStereotypes);

                        st.ZCElement = newProf.addStereotype(st.Name);
                        props = st.Properties;
                        this.Stats.NumStereotypes = this.Stats.NumStereotypes + 1;
                        
                        for m = 1:length(props)
                            tName = 'string';
                            ptName = props(m).DatatypeName;
                            if contains(ptName, "Enumeration")
                                 tName = char(props(m).Enumtype.BuildName);
                            elseif contains(ptName, "Dtype:")
                                dtypeName = extractAfter(ptName, "Dtype:");
                                if isKey(this.DatatypeMapping, dtypeName)
                                    tName = char(builder.DatatypeMapping(dtypeName));
                                else
                                    if contains(dtypeName, 'Bool', 'IgnoreCase', true)
                                        tName = 'boolean';
                                    elseif contains(dtypeName, 'Int', 'IgnoreCase', true) || ...
                                            contains(dtypeName, 'Natural', 'IgnoreCase', true)
                                        tName = 'int32';
                                    elseif contains(dtypeName, 'Real', 'IgnoreCase', true)
                                        tName = 'double';
                                    elseif contains(dtypeName, 'string', 'IgnoreCase', true)
                                        tName = 'string';
                                    end
                                end
                            end

                            props(m).Datatype = tName;
                            props(m).ZCElement = st.ZCElement.addProperty(...
                                char(props(m).FinalName),'Type', tName);
                            
                            this.Stats.NumStereotypeProps = this.Stats.NumStereotypeProps+1;
                        end
                    end
                    
                    % Add superclasses
                    for p = 1:length(thisProf.Stereotypes)
                        st = thisProf.Stereotypes(p);
                        if ~isempty(st.SuperClass) && ~isempty(st.SuperClass(1).ZCElement)
                            st.ZCElement.Parent = st.SuperClass.ZCElement;
                        end

                        if numel(st.SuperClass) > 1
                            warning('xmi:Builder:createProfiles:UnresolvedMultipleInheritance', 'Stereotype ''%s'' in profile ''%s'' has multiple parents. Only the first was linked.\nParents:\n%s', st.Name, thisProf.Name, formattedDisplayText([st.SuperClass.Name]'));
                        end
                    end
                end
            end
        end
        
        function applyStereotypes(this, elem)
            zcElem = elem.ZCElement;
            
            for k = 1:length(elem.StereotypesExtIDs)
                candidateStereotypes = SysMLConnector.internal.CandidateElement.idMap(...
                    "lookup", elem.StereotypesExtIDs(k));
                if ~isempty(candidateStereotypes) 
                    for candidateStereotype = candidateStereotypes
                        zcElem.applyStereotype(...
                            char(candidateStereotype.Profile.FinalName + "." + candidateStereotype.Name));
                        candidateStereotype.trackAppliedElement(zcElem)
                        this.Stats.NumStereotypesApplied = ...
                            this.Stats.NumStereotypesApplied+1;
                    end
                end
            end
            props = elem.StereotypePropVals;
            for p = 1:length(props)
                propST = SysMLConnector.internal.CandidateElement.idMap(...
                    "lookup", props(p).Stereotype);
                if ~isempty(propST)
                    prop = propST.findProperty(props(p).PropertyName);
                    if ~isempty(prop)
                        propName = propST.Profile.FinalName + "." + propST.Name + "." + prop.FinalName;

                        if ismember(prop.Datatype, {'boolean', 'uint8', 'uint16', 'uint32', 'uint64', 'int8', 'int16', 'int32', 'int64', 'single', 'double'})
                            propValueString = props(p).Value;
                        else
                            if strcmp(prop.DatatypeName, 'Enumeration')
                                props(p).Value = this.makeValidName(props(p).Value);
                            end
                            propValueString = ['''' char(props(p).Value)  ''''];
                        end

                        try
                            zcElem.setProperty(char(propName), propValueString);

                            this.Stats.NumStereotypePropsSet = ...
                            this.Stats.NumStereotypePropsSet + 1;
                        catch ME
                            warning('SysMLConnector:internal:Builder:ErrorSettingStereotypePropertyValue', 'Unable to set property ''%s'' on element ''%s'' due to the following error:\n%s\n', propName, zcElem.getQualifiedName, getReport(ME));
                        end
                    end
                end
            end
        end

        function createParameters(this, candArch)
            if isempty(candArch.Parameters)
                return;
            end

            arch = candArch.ZCElement;

            % Start with built-ins
            allPrmNames = string(fieldnames(get_param(arch.SimulinkHandle, 'ObjectParameters')))';

            newPrmNames = arrayfun(@this.makeValidName, [candArch.Parameters.Name]);

            [allPrmNames, modified] = matlab.lang.makeUniqueStrings(...
                    lower([allPrmNames, newPrmNames]), ...
                    [false(1, length(allPrmNames)) true(1, length(newPrmNames))], namelengthmax);

            % Remove built-ins
            modified = modified(end-length(newPrmNames)+1:end);
            allPrmNames = allPrmNames(end-length(newPrmNames)+1:end);

            for k = 1:length(candArch.Parameters)
                thisPrm = candArch.Parameters(k);
                prmName = allPrmNames(k);

                if modified(k)
                    % The parameter name was modified so honor the original
                    % case.
                    originalPrmName = char(thisPrm.Name);
                    newPrmName = char(prmName);

                    finalLength = length(newPrmName);
                    startLength = length(originalPrmName);

                    left  = repmat(' ', [max(finalLength, startLength) 1]);
                    right = left;

                    left(1:startLength) = originalPrmName';
                    right(1:finalLength) = newPrmName';

                    diffIdx = find(left~=right, 1);

                    prmName = string([originalPrmName(1:diffIdx-1) newPrmName(diffIdx:finalLength)]);
                end

                options = [];

                multiDimensional = false;
                paramValueArray = "NaN";

                dimensions = thisPrm.Dim;
                
                if strcmp(dimensions, "0")
                    dimensions = "1";
                end

                if ~strcmp(dimensions, "1")
                    options.Dimensions = dimensions;
                    multiDimensional = true;
                    try %#ok<TRYNC> Basic Heuristic with no recovery
                        % Try creating an array to hold the values based on
                        % the dimensions.
                        paramValueArray(1:eval(dimensions)) = "NaN";
                    end
                end

                
                tName = "string";
                if thisPrm.TypeName ~= ""
                    ptName = thisPrm.TypeName;
                    if contains(ptName, "Enumeration")
                        tName = ['Enum:' char(thisPrm.Type.BuildName)]; 
                    elseif contains(ptName, "Dtype:")
                        dtypeName = extractAfter(ptName, "Dtype:");
                        if isKey(this.DatatypeMapping, dtypeName)
                            tName = char(builder.DatatypeMapping(dtypeName));
                        else
                            if contains(dtypeName, 'Bool', 'IgnoreCase', true)
                                tName = 'boolean';
                            elseif contains(dtypeName, 'Int', 'IgnoreCase', true) || ...
                                    contains(dtypeName, 'Natural', 'IgnoreCase', true)
                                tName = 'int32';
                            elseif contains(dtypeName, 'Real', 'IgnoreCase', true)
                                tName = 'double';
                            elseif contains(dtypeName, 'string', 'IgnoreCase', true)
                                tName = 'string';
                            end
                        end
                    end
                end

                if thisPrm.DefaultValue ~= ""
                    paramValue = string(thisPrm.DefaultValue);

                    if string(tName) ~= "string"
                        % Needs to be evaluatable
                        try
                            if multiDimensional
                                paramValues = split(paramValue, ',');

                                for valueIdx = 1:numel(paramValues)
                                    paramValue = paramValues(valueIdx);
                                    if isempty(paramValue) || strcmp(paramValue, '')
                                        paramValue = "NaN";
                                    end
                                    paramValueArray(valueIdx) = paramValue;
                                end

                                paramValue = "[" + strjoin(paramValueArray, ",") + "]";
                            end

                            evalc(paramValue);
                        catch
                            warning('xmi:Builder:createParameters:InvalidValue', 'Unable to evaluate value ''%s'' for parameter ''%s'' in architecture ''%s''. Setting type to string to preserve value.', paramValue, prmName, getQualifiedName(arch));
                            tName = "string";
                            paramValue = string(thisPrm.DefaultValue);
                        end
                    end

                    if strcmpi(tName, "string")
                        options.Value = sprintf('"%s"', paramValue);
                    else
                        options.Value = paramValue;
                    end
                end

                options.Type = string(tName);

                if ~isempty(options)
                    try
                        optionArgs = namedargs2cell(options);
                        arch.addParameter(prmName,optionArgs{:});
                    catch ME
                        arch.addParameter(prmName);
                        warning('xmi:Builder:createParameters:InvalidOptions', 'Unable to add options for parameter ''%s'' in architecture ''%s''.\nOptions:\n%s', prmName, getQualifiedName(arch), formattedDisplayText(options));
                    end
                end
            end
        end

        function createAllocationFiles(this, candidateAllocations)
            if iscell(candidateAllocations)
                % Homogenize the array
                candidateAllocations = [candidateAllocations{:}];
            end
            
            % Set the build flag to false for the checker.
            arrayfun(@(invalidAllocation) set(invalidAllocation, "Build", false), candidateAllocations(~[candidateAllocations.IsValid]));
            % At this point, the source and target should be valid. If
            % they are not, nothing can be done to fix it.
            candidateAllocations = candidateAllocations([candidateAllocations.IsValid]);
            
            if isempty(candidateAllocations)
                % Nothing to do.
                return;
            end

            % Update the allocation count to the valid ones.
            this.AllocationCount = numel(candidateAllocations);

            % Populate the allocation sets and scenarios.
            for allocationIdx = 1:this.AllocationCount
                candidateAllocation = candidateAllocations(allocationIdx);

                SysMLConnector.internal.StatusMonitor.publishEvent('BuildAllocations', candidateAllocation.ExtElementID, 'Building allocations (%i of %i).', this.getAllocationIdx, this.AllocationCount);

                allocSetName = candidateAllocation.AllocationSetName;
                if isempty(candidateAllocation.Model)
                    allocationSet = SysMLConnector.internal.CandidateElement.idMap(...
                                    "lookup", allocSetName);
                    
                    if isempty(allocationSet)
                        allocationSet = SysMLConnector.internal.CandidateAllocation.AllocationSet(Name=allocSetName, ExternalID=allocSetName);
                    end

                    allocationSet.BuildSource = SysMLConnector.internal.utils.getModelName(candidateAllocation.Source.ZCElement);
                    allocationSet.BuildTarget = SysMLConnector.internal.utils.getModelName(candidateAllocation.Target.ZCElement);

                    candidateAllocation.Model = allocationSet;
                end

                % Populate the default scenario if does not exist
                if isempty(candidateAllocation.Parent)
                    scenarioName = 'Allocations';
                    scenarioID   = sprintf('%s_%s', allocSetName, scenarioName);

                    allocationScenario = SysMLConnector.internal.CandidateElement.idMap(...
                                    "lookup", scenarioID);

                    if isempty(allocationScenario)
                        allocationScenario = allocationSet.addScenario(scenarioName, scenarioID);
                    end

                    candidateAllocation.Parent = allocationScenario;
                    allocationScenario.Allocations = [allocationScenario.Allocations candidateAllocation];
                end
            end

            candidateAllocationSets = SysMLConnector.internal.CandidateElement.idMap(...
                                    "getElems", "SysMLConnector.internal.CandidateAllocation.AllocationSet");

            for k = 1:length(candidateAllocationSets)
                candidateAllocationSet = candidateAllocationSets{k};

                linkPackage(candidateAllocationSet);
                
                candidateAllocationSet.Builder = this;
                candidateAllocationSet.BuildName = candidateAllocationSet.Name;
            
                publish(candidateAllocationSet);

                if ~isempty(candidateAllocationSet.ParentPackage)
                    directoryPath = this.ProjectPath + ...
                                candidateAllocationSet.ParentPackage.ZCProjectFolder;
                else
                    directoryPath = pwd;
                end

                this.saveFileToPath(candidateAllocationSet.ZCElement, directoryPath);
                
                allocationSetName  = [candidateAllocationSet.ZCElement.Name '.mldatx'];
                allocationFilepath = which(allocationSetName);
                this.RootProject.addFile(allocationFilepath);
            end
        end

        function saveFileToPath(~, fileObject, filePath)
            % Workaround for allocation sets not accepting a file path as
            % an input.
            startDir = pwd;
            cleanup = onCleanup(@() cd(startDir));
            cd(filePath);
            save(fileObject);
        end
        
        function createRequirementsFile(this, candReqs)
            reqFileName = this.ProjectPath + filesep + ...
                this.makeValidName(this.BuildProject) + "_REQ.slreqx";
            this.ReqFileName = reqFileName;
            
            SysMLConnector.internal.StatusMonitor.publishEvent('BuilderCreateRequirementSet', reqFileName, 'Creating requirement set ''%s''.', reqFileName);
            try
                this.ReqFile = slreq.new(reqFileName);
            catch ME
                if ~strcmp(ME.identifier, 'Slvnv:slreq:RequirementSetAlreadyLoaded')
                    rethrow(ME);
                end

                arrayfun(@close, slreq.find('Type', 'ReqSet', 'Filename', reqFileName));
                this.ReqFile = slreq.new(reqFileName);
            end

            addAttribute(this.ReqFile, 'ExternalType', 'Edit');
            addAttribute(this.ReqFile, 'ExternalUID', 'Edit');

            this.RootProject.addFile(reqFileName);

            for k = 1:length(candReqs)
                thisReq = candReqs{k};
                
                SysMLConnector.internal.StatusMonitor.publishEvent('BuilderRequirements', thisReq.ExtElementID, 'Building requirements (%i of %i).', this.getRequirementIdx, this.RequirementCount);
                                
                if isempty(thisReq.ParentRequirement)
                    this.recAddRequirementToSet(thisReq, ...
                                                this.ReqFile);
                end
            end
        end
        
        function createReqLinks(this, candReqLinks)
            
            allMdls = this.ArchModelExtIDMap.values;
            originalWarnState = warning('off', 'Slvnv:oslc:LinkExists');
            cleanup = onCleanup(@() warning(originalWarnState));
            
            numModels = length(allMdls);
            for k = 1:numModels
                modelHandle = allMdls{k};
                modelName = get_param(modelHandle, 'Name');
                SysMLConnector.internal.StatusMonitor.publishEvent('BuilderSaveModelsBeforeLinking', modelName, 'Saving all models before adding requirement links, %s (%i of %i).', modelName, k, numModels);
                save_system(modelHandle, '', ...
                            'SaveDirtyReferencedModels', 'on');
            end
            
            for k = 1:length(candReqLinks)
                thisLink = candReqLinks{k};

                reqIndex = this.getRequirementLinkIdx;
                SysMLConnector.internal.StatusMonitor.publishEvent('BuilderRequirementLink', thisLink.ExtElementID, 'Building requirement link (%i of %i).', reqIndex, this.RequirementLinkCount);
                
                if ~thisLink.Valid || isempty(thisLink.Client.LinkTarget) || isempty(thisLink.Supplier.LinkTarget)
                    SysMLConnector.internal.StatusMonitor.publishEvent('BuilderRequirementLinkNotValid', thisLink.ExtElementID, 'Requirement link %i of %i not valid.', reqIndex, this.RequirementLinkCount);
                    addNotImported(this, thisLink, 'Requirement Link', 'Link not valid during build. Probably due to a missing link end or a link between elements that are not linkable.');
                    continue;
                end
                    
                supp = thisLink.Supplier;
                client = thisLink.Client;
                
                link = [];
                try
                    if isa(supp,'SysMLConnector.internal.CandidateRequirement') ...
                       && isa(client,'SysMLConnector.internal.CandidateRequirement')  
    
                        link = slreq.createLink(supp.LinkTarget, client.LinkTarget);
    
                        if thisLink.LinkType == "SysML.DeriveReqt"
                            link.Type = 'Derive';
                        end
                    elseif isa(supp,'SysMLConnector.internal.CandidateRequirement')
                        link = slreq.createLink(client.LinkTarget, supp.LinkTarget);
    
                        link.Type = 'Implement';
                    elseif isa(client,'SysMLConnector.internal.CandidateRequirement')
                        link = slreq.createLink(supp.LinkTarget, client.LinkTarget);
    
                        link.Type = 'Implement';
                    elseif ~isempty(client.LinkTarget) && ~isempty(supp.LinkTarget)
                        link = slreq.createLink(supp.LinkTarget, client.LinkTarget);
                    end
    
                    if ~isempty(link)
                        % try catch is faster than checking the attribute
                        % list every time.
                        linkID   = thisLink.ExtElementID;
                        linkType = extractAfter(thisLink.LinkType, 'SysML.');
                        try
                            setAttribute(link, 'ExternalUID',   linkID);
                            setAttribute(link, 'ExternalType', linkType);
                        catch ME
                            if strcmp(ME.identifier, 'Slvnv:slreq:NoSuchAttribute')
                                addAttribute(link.linkSet, 'ExternalUID',   'Edit');
                                addAttribute(link.linkSet, 'ExternalType', 'Edit');

                                setAttribute(link, 'ExternalUID',   linkID);
                                setAttribute(link, 'ExternalType', linkType);
                            else
                                rethrow(ME)
                            end
                        end
                        thisLink.ZCElement = link;
                        this.Stats.NumReqLinks = this.Stats.NumReqLinks + 1;
                    end
                catch ME
                    warning('SysMLConnector:internal:Builder:ErrorCreatingLink', 'Unable to create link from ''%s'' of type ''%s'' to ''%s'' of type ''%s''. Error: %s', supp.ExtElementID, class(supp), client.ExtElementID, class(client), ME.identifier);
                    addNotImported(this, thisLink, 'Requirement Link', 'Build error.');
                end
            end

            % Get all of the link sets
            this.AllLinkSets = [];
            
            ls = slreq.find('Type', 'LinkSet', 'Artifact', this.ReqFileName);
            if ~isempty(ls)
                this.AllLinkSets = string(ls.Filename);
                ls.save;
            end
            
            for k = 1:length(this.AllModelPaths)
                ls = slreq.find('Type', 'LinkSet', 'Artifact', this.AllModelPaths(k));
                if ~isempty(ls)
                    this.AllLinkSets = [this.AllLinkSets string(ls.Filename)];
                    ls.save;
                end
            end

            ls = slreq.find('Type', 'LinkSet', 'Artifact', this.ProjectSLDDPath);
            if ~isempty(ls)
                this.AllLinkSets = [this.AllLinkSets string(ls.Filename)];
                ls.save;
            end
        end


        function updateBuildCounts(builder, activityCount, allocationCount, architectureCount, interactionCount, packageCount, profileCount, requirementCount, requirementLinkCount)
            % This is set by the import function and used by the status monitor.
            builder.ActivityCount        = activityCount;
            builder.AllocationCount      = allocationCount;
            builder.ArchitectureCount    = architectureCount;
            builder.InteractionCount     = interactionCount;
            builder.PackageCount         = packageCount;
            builder.ProfileCount         = profileCount;
            builder.RequirementCount     = requirementCount;
            builder.RequirementLinkCount = requirementLinkCount;
        end

        function index = getActivityIdx(this)
            this.ActivityIdx = this.ActivityIdx + 1;
            index = this.ActivityIdx;
        end

        function index = getAllocationIdx(this)
            this.AllocationIdx = this.AllocationIdx + 1;
            index = this.AllocationIdx;
        end

        function index = getArchitectureIdx(this)
            this.ArchitectureIdx = this.ArchitectureIdx + 1;
            index = this.ArchitectureIdx;
        end

        function index = getEnumerationIdx(this)
            this.EnumerationIdx = this.EnumerationIdx + 1;
            index = this.EnumerationIdx;
        end

        function index = getInteractionIdx(this)
            this.InteractionIdx = this.InteractionIdx + 1;
            index = this.InteractionIdx;
        end

        function index = getInterfaceIdx(this)
            this.InterfaceIdx = this.InterfaceIdx + 1;
            index = this.InterfaceIdx;
        end

        function index = getPackageIdx(this)
            this.PackageIdx = this.PackageIdx + 1;
            index = this.PackageIdx;
        end

        function index = getProfileIdx(this)
            this.ProfileIdx = this.ProfileIdx + 1;
            index = this.ProfileIdx;
        end

        function index = getRequirementIdx(this)
            this.RequirementIdx = this.RequirementIdx + 1;
            index = this.RequirementIdx;
        end

        function index = getRequirementLinkIdx(this)
            this.RequirementLinkIdx = this.RequirementLinkIdx + 1;
            index = this.RequirementLinkIdx;
        end
    end
end