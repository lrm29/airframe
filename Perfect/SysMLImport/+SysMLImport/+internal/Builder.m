classdef Builder < handle
% BUILDER Helper class for SysMLImport.internal.import that helps build model.
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
        
        NotImported = []
        Stats 
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

        function addNotImported(this, element, type, reason)
            notImp.Type = type;
            notImp.Element = element.ExtElementID;
            notImp.Reason = reason;
            classParts = strsplit(class(element), '.');
            notImp.Stereotype = classParts{end};
            
            this.NotImported = [this.NotImported notImp];
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
            
            pPath = buildDir + filesep + buildProj;
            this.RootProject = matlab.project.createProject(...
                'Name', buildProj, 'Folder', pPath);
            this.ProjectPath = this.RootProject.RootFolder;
            this.RootProject.Name = buildProj;
            
            this.ArchModelExtIDMap = containers.Map;
            this.IntfExtIDMap = containers.Map;
        
            this.ProjectSLDDName = this.makeValidName(buildProj) + "_DD.sldd";
            ddFile = this.ProjectPath + filesep + this.ProjectSLDDName;

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
            
            populateEnumerations(this);
            populateInterfaces(this);
        end
        
        function delete(this)
            allMdls = this.ArchModelExtIDMap.values;
            
            for k = 1:length(this.Profiles)
                this.Profiles(k).save;
            end
            
            % Create a shutdown file to ensure all Profiles close
            sdownFile = this.ProjectPath + filesep + "projectShutdown.m";
            fid = fopen(sdownFile, 'w');
            for k = 1:length(this.Profiles)
                fprintf(fid, ['profTmp = systemcomposer.profile.Profile.find(''', ...
                              this.Profiles(k).Name, ''');\n']);
                fprintf(fid, 'if ~isempty(profTmp); profTmp.close(true); end; clear(''profTmp'');\n');
            end
            fclose(fid);
            this.RootProject.addFile(sdownFile);
            this.RootProject.addShutdownFile(sdownFile);
            
            for k = 1:length(allMdls)
                save_system(allMdls{k}, '', ...
                            'SaveDirtyReferencedModels', 'on');
                close_system(allMdls{k});
            end

            for k = 1:length(this.AllocationSets)
                allocationSet = this.AllocationSets(k);
                save(allocationSet);
                close(allocationSet);
            end
            
            if ~isempty(this.ReqFile)
                this.ReqFile.save;
                this.ReqFile.close;
            end
            
            for k = 1:length(this.AllLinkSets)
                this.RootProject.addFile(this.AllLinkSets(k));
            end
            
            for k = 1:length(this.Profiles)
                this.Profiles(k).close;
            end

            this.ProjectSLDD.save;
            this.RootProject.close;
        end

        function addNotImported(this, element, type, reason)
            % This function is intentionally written to be fault-tolerant.
            
            notImp.Type = type;
            notImp.Reason = reason;
            notImp.Stereotype = SysMLImport.internal.utils.getClassName(element);

            try
                % Try to let the get the path
                notImp.Element = getFullPath(element);
            catch ME
                % do not break the build, just warn to let us know we
                % missed a property assignment.
                warning(ME.identifier, '%s', getReport(ME));

                try
                    % Every element should have this property
                    notImp.Element = element.ExtElementID; 
                catch ME
                    % do not break the build, just warn to let us know we
                    % missed a property assignment.
                    warning(ME.identifier, '%s', getReport(ME));
                    
                    % Give up and just use the class name.
                    notImp.Element = notImp.Stereotype; 
                end
                
            end
            
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
            enumTypes = SysMLImport.internal.CandidateElement.idMap(...
                "getElems", "SysMLImport.internal.CandidateEnum");

            arrayfun(@(enumType) prelimBuild(enumType, this), [enumTypes{:}]);
        end
        
        function populateInterfaces(this)
            intfTypes = SysMLImport.internal.CandidateElement.idMap(...
                "getElems", "SysMLImport.internal.CandidateInterface");
            allIntfNames = [];
            for k = 1:length(intfTypes)
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
            new_system(tempMdlName, "Architecture");
            tempMdlZCM = get_param(tempMdlName, 'SystemComposerModel');
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
            archMdlName = this.getModelName(candAct.Name);
            candAct.BuildName = archMdlName;
            publish(candAct);
            actArch  = SysMLImport.internal.CandidateAD.internal.getArchitecturePeer(candAct.ZCElement);
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

        function interactionMdl = createInteraction(this, candInteraction)
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
            if compName == ""
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
            assert(~this.IntfExtIDMap.isKey(intfExtID));
            intf = this.ProjectSLDD.addInterface(char(intfName));
            this.IntfExtIDMap(intfExtID) = intf;
            this.Stats.NumInterfaces = this.Stats.NumInterfaces + 1;            
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
            this.Stats.NumRequirements = this.Stats.NumRequirements + 1;
            for k = 1:length(req.ChildRequirements)
                recAddRequirementToSet(...
                    this, req.ChildRequirements(k), thisReq);
            end
        end
        
        function createProfiles(this, candProfiles)
            for k = 1:length(candProfiles)
                thisProf = candProfiles(k);
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
                    for p = 1:length(thisProf.Stereotypes)
                        st = thisProf.Stereotypes(p);
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
                candidateStereotypes = SysMLImport.internal.CandidateElement.idMap(...
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
                propST = SysMLImport.internal.CandidateElement.idMap(...
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
                            propValueString = ['''' props(p).Value  ''''];
                        end

                        try
                            zcElem.setProperty(char(propName), propValueString);

                            this.Stats.NumStereotypePropsSet = ...
                            this.Stats.NumStereotypePropsSet + 1;
                        catch ME
                            warning('SysMLImport:internal:Builder:ErrorSettingStereotypePropertyValue', 'Unable to set property ''%s'' on element ''%s'' due to the following error:\n%s\n', propName, zcElem.getQualifiedName, getReport(ME));
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

                options = {};
                if ~strcmp(thisPrm.Dim, "1")
                    options{end+1} = "Dimensions"; %#ok<AGROW>
                    options{end+1} = thisPrm.Dim; %#ok<AGROW>
                end
                tName = 'double';
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
                    options{end+1} = "Type"; %#ok<AGROW>
                    options{end+1} = string(tName); %#ok<AGROW>
                end
                if thisPrm.DefaultValue ~= ""
                    if string(tName) ~= "string"
                        % Needs to be evaluatable
                        try %#ok<TRYNC>
                            eval(string(thisPrm.DefaultValue) + ";");
                            options{end+1} = "Value"; %#ok<AGROW>
                            options{end+1} = thisPrm.DefaultValue; %#ok<AGROW>
                        end
                    else
                        options{end+1} = "Value"; %#ok<AGROW>
                        options{end+1} = thisPrm.DefaultValue; %#ok<AGROW>
                    end
                end

                if ~isempty(options)
                    try
                        arch.addParameter(prmName,options{:});
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
            
            % At this point, the source and target should be valid. If
            % they are not, nothing can be done to fix it.
            candidateAllocations = candidateAllocations([candidateAllocations.IsValid]);
            % Set the build flag to false for the checker.
            arrayfun(@(invalidAllocation) set(invalidAllocation.Build, false), candidateAllocations(~[candidateAllocations.IsValid]));
            
            if isempty(candidateAllocations)
                % Nothing to do.
                return;
            end

            % Populate the allocation sets and scenarios.
            for allocationIdx = 1:numel(candidateAllocations)
                candidateAllocation = candidateAllocations(allocationIdx);

                allocSetName = candidateAllocation.AllocationSetName;
                if isempty(candidateAllocation.Model)
                    allocationSet = SysMLImport.internal.CandidateElement.idMap(...
                                    "lookup", allocSetName);
                    
                    if isempty(allocationSet)
                        allocationSet = SysMLImport.internal.CandidateAllocation.AllocationSet(Name=allocSetName, ExternalID=allocSetName);
                    end

                    allocationSet.BuildSource = SysMLImport.internal.utils.getModelName(candidateAllocation.Source.ZCElement);
                    allocationSet.BuildTarget = SysMLImport.internal.utils.getModelName(candidateAllocation.Target.ZCElement);

                    candidateAllocation.Model = allocationSet;
                end

                % Populate the default scenario if does not exist
                if isempty(candidateAllocation.Parent)
                    scenarioName = 'Allocations';
                    scenarioID   = sprintf('%s_%s', allocSetName, scenarioName);

                    allocationScenario = SysMLImport.internal.CandidateElement.idMap(...
                                    "lookup", scenarioID);

                    if isempty(allocationScenario)
                        allocationScenario = allocationSet.addScenario(scenarioName, scenarioID);
                    end

                    candidateAllocation.Parent = allocationScenario;
                    allocationScenario.Allocations = [allocationScenario.Allocations candidateAllocation];
                end
            end

            candidateAllocationSets = SysMLImport.internal.CandidateElement.idMap(...
                                    "getElems", "SysMLImport.internal.CandidateAllocation.AllocationSet");

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
            
            try
                this.ReqFile = slreq.new(reqFileName);
            catch ME
                if ~strcmp(ME.identifier, 'Slvnv:slreq:RequirementSetAlreadyLoaded')
                    rethrow(ME);
                end

                arrayfun(@close, slreq.find('Type', 'ReqSet', 'Filename', reqFileName));
                this.ReqFile = slreq.new(reqFileName);
            end

            this.RootProject.addFile(reqFileName);
            
            for k = 1:length(candReqs)
                thisReq = candReqs{k};
                if isempty(thisReq.ParentRequirement)
                    this.recAddRequirementToSet(thisReq, ...
                                                this.ReqFile);
                end
            end
        end
        
        function createReqLinks(this, candReqLinks)
            
            allMdls = this.ArchModelExtIDMap.values;
            
            for k = 1:length(allMdls)
                save_system(allMdls{k}, '', ...
                            'SaveDirtyReferencedModels', 'on');
            end
            
            
            for k = 1:length(candReqLinks)
                thisLink = candReqLinks{k};
                
                if ~thisLink.Valid
                    addNotImported(this, thisLink, 'Requirement Link', 'Link not valid during build.');
                    continue;
                end
                    
                supp = thisLink.Supplier;
                client = thisLink.Client;
                
                lnk = [];
                try
                    if isa(supp,'SysMLImport.internal.CandidateRequirement') ...
                       && isa(client,'SysMLImport.internal.CandidateRequirement')  
    
                        lnk = slreq.createLink(supp.LinkTarget, client.LinkTarget);
    
                        if thisLink.LinkType == "SysML.DeriveReqt"
                            lnk.Type = 'Derive';
                        end
                    elseif isa(supp,'SysMLImport.internal.CandidateRequirement')
                        lnk = slreq.createLink(client.LinkTarget, supp.LinkTarget);
    
                        lnk.Type = 'Implement';
                    elseif isa(client,'SysMLImport.internal.CandidateRequirement')
                        lnk = slreq.createLink(supp.LinkTarget, client.LinkTarget);
    
                        lnk.Type = 'Implement';
                    elseif ~isempty(client.LinkTarget) && ~isempty(supp.LinkTarget)
                        lnk = slreq.createLink(supp.LinkTarget, client.LinkTarget);
                    end
    
                    if ~isempty(lnk)
                        thisLink.ZCElement = lnk;
                        this.Stats.NumReqLinks = this.Stats.NumReqLinks + 1;
                    end
                catch ME
                    warning('SysMLImport:internal:Builder:ErrorCreatingLink', 'Unable to create link from ''%s'' of type ''%s'' to ''%s'' of type ''%s''. Error: %s', supp.ExtElementID, class(supp), client.ExtElementID, class(client), ME.identifier);
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
        end
        
    end
end