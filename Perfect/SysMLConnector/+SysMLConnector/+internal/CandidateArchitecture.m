classdef CandidateArchitecture < SysMLConnector.internal.CandidateElement
% CANDIDATEARCHITECTURE Helper class for SysMLConnector.internal.import that
% holds candidate Architecture models
    properties
        Name = "";
        
        ParentPackageExtElementID;
        GeneralizationExtElementIDs;

        CompMapFromExtElementID;
        PortMapFromExtElementID;
        
        ReferencingComps = [];
        ChildComponents = [];
        ChildConnectors = [];

        Redefined = "";

        DeferredConnectors = [];

        Parameters = [];
        
        ParentPackage = [];        
       
        GenMerged = false;
        Build = true;
        
        ZCElement = []
        SystemComposerUUID = ''
        
        IsInlined = false;
        Visited = false;
        Derived = false;
        BuildAsSimulink = false;
        SimulinkModelName = "";
        
        NonSiblingDelegatesAdded = [];
        
        PortNameGeneratedIdx = 1;
        
        DerivedConnectorIdx = 1;
        DerivedPortIdx = 1;
        DerivedArchIdx = 1;
        DerivedCompIdx = 1;
        
        DefaultWidthOfReferencingComp = -1; 
    end

    methods
        function set.ZCElement(this, value)
            this.ZCElement = value;

            if ~isempty(value) && isvalid(value)
                this.SystemComposerUUID = value.UUID; %#ok<MCSUP>
            end
        end
    end
    
    methods (Static, Access = private)
        
        function [reached,pArchs1,pComps1] = recMarkHier(arch, endArch, pArchs, pComps)
            pArchs1 = pArchs;
            pComps1 = pComps;
            reached = false;
            if arch == endArch
                reached = true;
            else
                rComps = arch.ReferencingComps;
                for k = 1:length(rComps)
                    [reached,pArchs1,pComps1] = ...
                        SysMLConnector.internal.CandidateArchitecture.recMarkHier(...
                            rComps(k).ParentArchitecture, endArch, pArchs, pComps);
                    if reached
                        pArchs1 = [pArchs1 arch]; %#ok<AGROW>
                        pComps1 = [pComps1 rComps(k)]; %#ok<AGROW>
                        break;
                    end
                end
            end
        end
        
        function [pArchs,pComps] = findArchHierPath(comp, endArch)

            [~, pArchs, pComps] = SysMLConnector.internal.CandidateArchitecture.recMarkHier(...
                comp.ParentArchitecture, endArch, [], []);

            pArchs = fliplr(pArchs);
            pComps = fliplr(pComps);
        end
        
        
        function [pArchs, notUnique] = findUniqueParentArchHier(comp, endArch)
            notUnique = false; % assume
            pArchs = [];
            pArch = comp.ParentArchitecture;
            while pArch ~= endArch                    
                pArchs = [pArchs pArch]; %#ok<AGROW>
                rComps = pArch.ReferencingComps;
                if length(rComps) > 1
                    notUnique = true;
                    pArchs = [];
                    return;
                elseif isempty(rComps)
                    break;
                else
                    pArch = rComps.ParentArchitecture;
                end
            end
            if pArch ~= endArch
                notUnique = true;
                pArchs = [];
            end
        end
        
        function newConn = addDerivedConnector(thisArch, comp1, aPort1, ...
                                                         comp2, aPort2, connID)
            
            comp1ID = "";
            if ~isempty(comp1)
                comp1ID = comp1.ExtElementID;
            end
            
            comp2ID = "";
            if ~isempty(comp2)
                comp2ID = comp2.ExtElementID;
            end
            
            newConn = thisArch.addChildConnector(...
                connID + "DerivedConn" + thisArch.DerivedConnectorIdx, ...
                comp1ID, aPort1.ExtElementID, ...
                aPort1.ParentArch.ExtElementID, ...
                comp2ID, aPort2.ExtElementID, ...
                aPort2.ParentArch.ExtElementID, true);
            thisArch.DerivedConnectorIdx = thisArch.DerivedConnectorIdx + 1;

            if isempty(comp1)
                aPort1.addConnector(newConn);
            else
                comp1.addConnector(aPort1, newConn);
            end
            if isempty(comp2)
                aPort2.addConnector(newConn);
            else
                comp2.addConnector(aPort2, newConn);
            end
            
            newConn.setEndComps(aPort1, comp1, aPort1.ParentArch, ...
                                aPort2, comp2, aPort2.ParentArch);
            
            % Set that the ends are already checked and set to avoid rechecking
            newConn.EndsChecked = true;
        end
        
    end
        
    methods (Access = private)
        
        function mergeInGeneralization(this, otherArch)
        % Copy over all parameters, components, ports, and connectors of 
        % the 'general' Architecture.            
            otherArchComps = otherArch.CompMapFromExtElementID.values;
            for k = 1:length(otherArchComps)
                if ~ismember(otherArchComps{k}.ExtElementID, this.Redefined)
                    this.addChildComponent(...
                        otherArchComps{k}.Name, ...
                        otherArchComps{k}.ExtElementID, ...
                        otherArchComps{k}.ReferenceArchExtElementID);
                end
            end
            
            otherArchPorts = otherArch.PortMapFromExtElementID.values;
            for k = 1:length(otherArchPorts)
                otherPort = otherArchPorts{k};
                if ~ismember(otherPort.ExtElementID, this.Redefined)
                    this.addPort(...
                        otherPort.Name, otherPort.IsConjugated, ...
                        otherPort.ExtElementID, otherPort.InterfaceExtElementID, ...
                        otherPort.Interface, true);
                end
            end

            otherArchParameters = otherArch.Parameters;
            for k = 1:length(otherArchParameters)
                otherParameter = otherArchParameters(k);
                if ~ismember(otherParameter.ExtElementID, this.Redefined)
                    cloneParameter(otherParameter, this);
                end
            end
            
            this.copyChildConnectors(otherArch.ChildConnectors);
            
            this.Generalizations = [this.Generalizations otherArch];
            otherArch.Specializations = ...
                [otherArch.Specializations, this];
        end
        
        function [endComp, endAPort, nonSibling] = ...
                checkConnectorEnd(this, thisConn, ...
                                       endCompID, endPortID, endArchID)
            
            endComp = [];
            nonSibling = false; % assume
            endAPort = [];

            if endCompID == ""
                % Architecture port connector or unresolved deferred
                % connector. First, assume architecture port.
                archPort = this.getCachedPortFromExtElementID(endPortID);
    
                if ~isempty(archPort)
                    archPort.addConnector(thisConn);
                    endAPort = archPort;
                end
            else
                endComp = this.findChildComponent(endCompID);
            end

            % Second try to resolved connector based on EA diagram information.
            if endCompID == ""  && ...
                    isempty(endAPort) && ...                    
                    strcmp(SysMLConnector.internal.StatusMonitor.getSourceTool, 'EA') && ...
                    ~isempty(this.ChildComponents)

                childCompArchIdx = strcmp(endArchID, [this.ChildComponents.ReferenceArchExtElementID]);
                if any(childCompArchIdx)
                    endComp = this.ChildComponents(childCompArchIdx);

                    if sum(childCompArchIdx) > 1
                        endComp = endComps(1);
                        message = sprintf('Duplicate ends were detected for connector ''%s'' in architecture ''%s''. It is recommended that you manually review the import result.', thisConn.ExtElementID, this.Name);
                        SysMLConnector.internal.StatusMonitor.publishEvent('DuplicateConnectorEnds', 'Connectors', message);
                    end
                end
            end

            if ~isempty(endComp)
                endAPort = ...
                    endComp.ReferenceArch.getCachedPortFromExtElementID(endPortID);
                if endComp.ParentArchitecture ~= this
                    % Handle connection of non sibling Components
                    nonSibling = true;
                elseif ~isempty(endAPort)
                    endComp.addConnector(endAPort, thisConn);
                end
            end
        end

        function port = getCachedPortFromExtElementID(this, portExtElementID)
            port = [];

            if isKey(this.PortMapFromExtElementID, portExtElementID)
                port = this.PortMapFromExtElementID(portExtElementID);
            end
        end
    
        function handleNonSiblingConnector(this, thisConn)
        % Handle deep nested connectors
            end1APort = thisConn.End1APort;
            end1Comp = thisConn.End1Comp;
            end2APort = thisConn.End2APort;
            end2Comp = thisConn.End2Comp;
            
            end1Archs = [];
            end1Comps = [];
            if ~isempty(end1Comp)
                [end1Archs,end1Comps] = this.findArchHierPath(end1Comp, this);
            end
            end2Archs = [];
            end2Comps = [];
            if ~isempty(end2Comp)
                [end2Archs,end2Comps] = this.findArchHierPath(end2Comp, this);
            end
            
            repConns = [];
            
            thisComp = end1Comp;
            thisAPort = end1APort;
            for k = 1:length(end1Archs)
                thisArch = end1Archs(k);
                
                pInfo = this.isPortAddedForNonSibling(thisComp, thisAPort);
                
                if isempty(pInfo)
                    % Add an architecture port and delegate connector
                    newPort =  thisArch.addPort(...
                        thisAPort.Name, ...
                        thisAPort.IsConjugated, ...
                        thisArch.ExtElementID + "NestedConnPort" + thisArch.DerivedPortIdx, ...
                        "", thisAPort.Interface, true);
                    newPort.setComputedDir();
                    thisArch.DerivedPortIdx = thisArch.DerivedPortIdx + 1;
                    
                    % Add connector
                    repConn = this.addDerivedConnector(...
                        thisArch, thisComp, thisAPort, ...
                        [], newPort, thisConn.ExtElementID);
                    repConns = [repConns repConn]; %#ok<AGROW>
                    
                    this.trackPortAddedForNonSibling(thisComp, thisAPort, newPort);
                else
                    newPort = pInfo.AddedPort;
                end
                
                % Reset vars
                thisComp = end1Comps(k);
                thisAPort = newPort;
            end
            finalEnd1Comp = thisComp;
            finalEnd1APort = thisAPort;
            
            thisComp = end2Comp;
            thisAPort = end2APort;
            for k = 1:length(end2Archs)
                thisArch = end2Archs(k);
                
                pInfo = this.isPortAddedForNonSibling(thisComp, thisAPort);
                
                if isempty(pInfo)
                    % Add an architecture port and delegate connector
                    newPort =  thisArch.addPort(...
                        thisAPort.Name, ...
                        thisAPort.IsConjugated, ...
                    thisArch.ExtElementID + "NestedConnPort" + thisArch.DerivedPortIdx, ...
                        "", thisAPort.Interface, true);
                    thisArch.DerivedPortIdx = thisArch.DerivedPortIdx + 1;
                    newPort.setComputedDir();
                    
                    % Add connector
                    repConn = this.addDerivedConnector(...
                        thisArch, thisComp, thisAPort, ...
                        [], newPort, thisConn.ExtElementID);
                    repConns = [repConns repConn]; %#ok<AGROW>
                    
                    this.trackPortAddedForNonSibling(thisComp, thisAPort, newPort);
                else
                    newPort = pInfo.AddedPort;
                end
                
                % Reset vars
                thisComp = end2Comps(k);
                thisAPort = newPort;
            end
            finalEnd2Comp = thisComp;
            finalEnd2APort = thisAPort;
            
            % Add final connector
            repConn = this.addDerivedConnector(...
                this, finalEnd1Comp, finalEnd1APort, ...
                finalEnd2Comp, finalEnd2APort, thisConn.ExtElementID);
            repConns = [repConns repConn];
            
            thisConn.setReplacements(repConns);
        end
    
        function cComp = findChildComponent(this, cID)
            if isKey(this.CompMapFromExtElementID, cID)
                cComp = this.CompMapFromExtElementID(cID);
            else
                for k = 1:length(this.ChildComponents)
                    gcComp = this.ChildComponents(k);
                    if gcComp.Valid % Prevents recursion due to Comp ref cycle
                        cComp = gcComp.ReferenceArch.findChildComponent(cID);
                        if ~isempty(cComp)
                            return;
                        end
                    end
                end
                cComp = [];
            end
        end
        
        function dWidth = getDefaultCompWidth(this)
            if this.DefaultWidthOfReferencingComp == -1
                if this.BuildAsSimulink
                    % Bug in ZC. Refresh Arch handle
                    set_param(this.SimulinkModelName, 'HasSystemComposerArchInfo', 'on');
                    this.ZCElement = get_param(this.SimulinkModelName, ...
                                              'SystemComposerArchitecture');
                    set_param(this.SimulinkModelName, 'HasSystemComposerArchInfo', 'off');
                end
                allPorts = this.ZCElement.Ports;
                maxPortNameLenIn = 0;
                maxPortNameLenOut = 0;
                
                for k = 1:length(allPorts)
                    thisPort = allPorts(k);
                    pNameLen = strlength(string(thisPort.Name));
                    if thisPort.Direction == systemcomposer.arch.PortDirection.Input
                        if pNameLen > maxPortNameLenIn
                            maxPortNameLenIn = pNameLen;
                        end
                    end
                    if thisPort.Direction == systemcomposer.arch.PortDirection.Output
                        if pNameLen > maxPortNameLenOut
                            maxPortNameLenOut = pNameLen;
                        end
                    end
                end
                this.DefaultWidthOfReferencingComp = ...
                    (maxPortNameLenIn + maxPortNameLenOut)*10 + 20;
            end

            dWidth = this.DefaultWidthOfReferencingComp;
        end
        
        function trackPortAddedForNonSibling(this, comp, aPort, newPort)
            pInfo.Component = comp;
            pInfo.ArchPort = aPort;
            pInfo.AddedPort = newPort;
            this.NonSiblingDelegatesAdded = [this.NonSiblingDelegatesAdded pInfo];
        end
        
        function fnd = isPortAddedForNonSibling(this, comp, aPort)
            fnd = [];
            pInfos = this.NonSiblingDelegatesAdded;

            for k = 1:length(pInfos)
                pInfo = pInfos(k);
                if isempty(comp)
                    if isempty(pInfo.Component)
                        if pInfo.ArchPort == aPort
                            fnd = pInfo;
                            break;
                        end
                    end
                elseif ~isempty(pInfo.Component)
                    if comp == pInfo.Component && aPort == pInfo.ArchPort
                        fnd = pInfo;
                        break;
                    end
                end
            end
        end
        
        function canInline = canBeInlined(this,checkedArchitectures)
            % checks to see if this candidate can be inlined 
            %
            % arguments:
            % this - this
            % checkedArchitectures - array of candidates to make sure this
            % does not get stuck in a loop
            %
            % return:
            % canInLine - true/false indicating if the architecture can be
            % inlined without orphaning elements
            arguments
                this SysMLConnector.internal.CandidateArchitecture  
                checkedArchitectures SysMLConnector.internal.CandidateArchitecture ...
                    = SysMLConnector.internal.CandidateArchitecture.empty
            end
            checkedArchitectures = [checkedArchitectures,this];
            % first check if this has a reference component
            if isempty(this.ReferencingComps) || ...
                    isempty(this.ReferencingComps.ParentArchitecture)
                % no reference means need to build the architecture
                canInline = false;
            elseif any(checkedArchitectures == ...
                    this.ReferencingComps.ParentArchitecture)
                % this means that we have hit a loop meaning we can't
                % inline this architecture
                canInline = false;
            elseif this.ReferencingComps.ParentArchitecture.Build
                % if the parent is being built the reference component will
                % be
                canInline = this.ReferencingComps.ParentArchitecture.Build;
            else
                % this means the the reference components parent is new and
                % not being built directly
                % need to get the answer from it
                canInline = this.ReferencingComps.ParentArchitecture.canBeInlined(checkedArchitectures);
            end
        end
    end
    
    methods
        function this = CandidateArchitecture(name, extID, ...
                                              parPackageExtID, genIDs)
            this@SysMLConnector.internal.CandidateElement(extID, ValidRequirementLinkTarget=true);

            this.Name = name;
            this.ParentPackageExtElementID = parPackageExtID;
            this.GeneralizationExtElementIDs = genIDs;
            
            this.PortMapFromExtElementID = containers.Map;
            this.CompMapFromExtElementID = containers.Map;
            
        end
        
        function newPort = addPort(this, portName, isConjugated, extID, ...
                                   intfID, intf, isDerived)
            if portName == ""
                portName = "APort" + this.PortNameGeneratedIdx;
                this.PortNameGeneratedIdx = this.PortNameGeneratedIdx + 1;
            end
            
            if ~isempty(intf)
                intfID = intf.ExtElementID;
            end
            
            newPort = SysMLConnector.internal.CandidatePort(...
                this, portName, extID, isConjugated, intfID, intf, isDerived);
            
            if ~isempty(intf)
                intf.addReferencingArchPort(newPort);
            end

            this.PortMapFromExtElementID(extID) = newPort;
        end
        
        function pDir = getComputedPortDir(this, portID)
            pDir = this.PortMapFromExtElementID(portID).ComputedDir;
        end
        
        function pName = getPortName(this, portID)
            pName = this.PortMapFromExtElementID(portID).Name;
        end

        function redefine(this, property, redefinitionID)
            property.Redefines = redefinitionID;
            this.Redefined = [this.Redefined string(redefinitionID)];
        end
        
        function cComp = addChildComponent(this, compName, extID, refCompID)
            cComp = SysMLConnector.internal.CandidateComponent(...
                compName, this, extID, refCompID);
    
            this.ChildComponents = [this.ChildComponents cComp];
    
            assert(~isKey(this.CompMapFromExtElementID, extID));
            this.CompMapFromExtElementID(extID) = cComp;
        end

        function addDeferredChildComponents(this, deferredChildComponents)
            for componentIndex = 1:numel(deferredChildComponents)
                deferredComponent = deferredChildComponents(componentIndex);
                deferredComponent.ParentArchitecture = this;

                this.ChildComponents = [this.ChildComponents deferredComponent];
    
                assert(~isKey(this.CompMapFromExtElementID, deferredComponent.ExtElementID));
                this.CompMapFromExtElementID(deferredComponent.ExtElementID) = deferredComponent;
            end
        end
        
        function cConn = addChildConnector(...
            this, extID, end1CompID, ...
            end1RefPortID, end1RefPortCompID, ...
            end2CompID, end2RefPortID, end2RefPortCompID, isDerived)
            cConn = SysMLConnector.internal.CandidateConnector(...
                this, extID,  end1CompID, end1RefPortID, end1RefPortCompID, ...
                end2CompID, end2RefPortID, end2RefPortCompID, isDerived);
            this.ChildConnectors = [this.ChildConnectors cConn];
        end

        function connectors = copyChildConnectors(this, childConnectors)
            % copy child connectors from another architecture to this one.
            connectors = SysMLConnector.internal.CandidateConnector.empty(0, length(childConnectors));

            for connectorIndex = 1:length(childConnectors)
                otherConnector = childConnectors(connectorIndex);
                connectors(connectorIndex) = this.addChildConnector(...
                    otherConnector.ExtElementID, ...
                    otherConnector.End1CompExtElementID, ...
                    otherConnector.End1RefPortExtElementID, ...
                    otherConnector.End1RefPortArchExtElementID, ...
                    otherConnector.End2CompExtElementID, ...
                    otherConnector.End2RefPortExtElementID, ...
                    otherConnector.End2RefPortArchExtElementID, true);
            end
        end
        
        function addReferencingComp(this, refComp)
            this.ReferencingComps = [this.ReferencingComps refComp];
        end

        function parameter = addParameter(this, extID, paramName, paramType, paramTypeName, paramDim, paramDefValue)

            parameter = SysMLConnector.internal.CandidateParameter(extID);
            parameter.ParentArch = this;

            parameter.Name = string(paramName);
            parameter.Type = paramType;
            parameter.TypeName = paramTypeName;
            parameter.Dim = string(paramDim);
            parameter.DefaultValue = string(paramDefValue);

            this.Parameters = [this.Parameters parameter]; 
        end
        
        function notImported = mergeGeneralizations(this)
            notImported = [];

            if ~this.GenMerged
                genIDs = this.GeneralizationExtElementIDs;
                for k = 1:length(genIDs)
                    genArch = SysMLConnector.internal.CandidateElement.idMap(...
                        "lookup", genIDs(k));

                    if isa(genArch, 'SysMLConnector.internal.CandidateArchitecture')
                        if ~genArch.GenMerged
                            notImportedArch = genArch.mergeGeneralizations();
                            notImported = [notImported notImportedArch]; %#ok<AGROW>
                        end
                        this.mergeInGeneralization(genArch);
                    end
                end

                if strcmp(SysMLConnector.internal.StatusMonitor.getSourceTool, 'EA')
                    % Check for deferred connectors from the diagrams that were not
                    % added
                    if ~isempty(this.DeferredConnectors)
                        message = sprintf('Merging deferred connectors into architecture ''%s''.', this.Name);
                        SysMLConnector.internal.StatusMonitor.publishEvent('AddDeferredConnectors', 'Connectors', message);

                        newConnectors = unique(this.DeferredConnectors);
                        if ~isempty(this.ChildConnectors)
                            childConnectorIDs = [this.ChildConnectors.ExtElementID];
                            newConnectors = setdiff(newConnectors, childConnectorIDs);
                        end

                        for deferredConnectorID = newConnectors
                            sourceConnector = SysMLConnector.internal.CandidateElement.idMap('lookup', deferredConnectorID);
                            
                            if isempty(sourceConnector)
                                notImportedConnector.Type = 'InheritedConnector';
                                notImportedConnector.Reason = 'Connector Not Found';
                                notImportedConnector.Stereotype = 'SysML.Connector';
                                notImportedConnector.ElementID = deferredConnectorID;
                                notImportedConnector.Element = getFullPath(this);
                                notImported = [notImported notImportedConnector]; %#ok<AGROW>

                                message = sprintf('Deferred connector source not found for ''%s''.', deferredConnectorID);
                                SysMLConnector.internal.StatusMonitor.publishEvent('DeferredConnectorNotFound', 'Connectors', message);
                            else
                                this.copyChildConnectors(sourceConnector);
                            end
                        end
                    end
                end
            end
                
            this.GenMerged = true;
        end
        
        function linkComponentsPortsPackage(this)
            cComps = this.ChildComponents;
            for k = 1:length(cComps)
                thisComp = cComps(k);
                if ~strcmp(thisComp.ReferenceArchExtElementID, "")
                    thisCompRefArch = ...
                        SysMLConnector.internal.CandidateElement.idMap(...
                        "lookup", thisComp.ReferenceArchExtElementID);
                    thisComp.ReferenceArch = thisCompRefArch;
                    thisCompRefArch.addReferencingComp(thisComp);
                end
            end
            
            cPorts = this.PortMapFromExtElementID.values;
            for k = 1:length(cPorts)
                thisPort = cPorts{k};
                if thisPort.InterfaceExtElementID ~= ""
                    thisPortIntf = ...
                        SysMLConnector.internal.CandidateElement.idMap(...
                            "lookup", thisPort.InterfaceExtElementID);
                    thisPortIntf.addReferencingArchPort(thisPort);
                    thisPort.Interface = thisPortIntf;
                end
            end
            
            compPkg = SysMLConnector.internal.CandidateElement.idMap(...
                "lookup", this.ParentPackageExtElementID);
            compPkg.addArchitecture(this);
            this.ParentPackage = compPkg;
        end
        
        function setPortDirection(this, splitBidirectional)
            allPorts = this.PortMapFromExtElementID.values;
            
            if splitBidirectional
                for k = 1:length(allPorts)
                    thisPort = allPorts{k};
                    if ~isempty(thisPort.Interface) && ...
                            ~isempty(thisPort.Interface.DerivedInInterface)

                        if thisPort.IsConjugated
                            iStr = "Out";
                            oStr = "In";
                        else
                            iStr = "In";
                            oStr = "Out";
                        end
                        
                        newPortI = this.addPort(...
                            thisPort.Name + iStr, ...
                            thisPort.IsConjugated, ...
                            this.ExtElementID + "BidirConnPort" + this.DerivedPortIdx, ...
                            "", thisPort.Interface.DerivedInInterface, true);
                        this.DerivedPortIdx = this.DerivedPortIdx + 1;

                        newPortO = this.addPort(...
                            thisPort.Name + oStr, ...
                            thisPort.IsConjugated, ...
                            thisPort.ExtElementID + "BidirConnPort" + this.DerivedPortIdx, ...
                            "", thisPort.Interface.DerivedOutInterface, true);
                        this.DerivedPortIdx = this.DerivedPortIdx + 1;
                
                        thisPort.setReplacements([newPortI newPortO]);
                    end
                end
            end
            
            % Set computed direction for ports
            allPorts = this.PortMapFromExtElementID.values;
            for k = 1:length(allPorts)
                thisPort = allPorts{k};
                thisPort.setComputedDir();
            end
        end
        
        function notImported = linkAndExpandConnectors(this)
            % Link connectors to comps and validate
            notImported = [];

            cConns = this.ChildConnectors;
            for c = 1:length(cConns)
                thisConn = cConns(c);
                
                if ~thisConn.EndsChecked
                    [end1Comp, end1APort, nonSibling1] = ...
                        this.checkConnectorEnd(...
                            thisConn, ...
                            thisConn.End1CompExtElementID, ...
                            thisConn.End1RefPortExtElementID, ...
                            thisConn.End1RefPortArchExtElementID);
                    [end2Comp, end2APort, nonSibling2] = ...
                        this.checkConnectorEnd(...
                            thisConn, ...
                            thisConn.End2CompExtElementID, ...
                            thisConn.End2RefPortExtElementID, ...
                            thisConn.End2RefPortArchExtElementID);

                    if ~isempty(end1APort) && ~isempty(end2APort)
                        thisConnNotImported = thisConn.setEndComps(...
                            end1APort, end1Comp, end1APort.ParentArch, ...
                            end2APort, end2Comp, end2APort.ParentArch);

                        notImported = [notImported thisConnNotImported]; %#ok<AGROW>
                    else
                        message = sprintf('The ends of connector ''%s'' could not be resolved.', thisConn.ExtElementID);
                        SysMLConnector.internal.StatusMonitor.publishEvent('LinkConnectors', 'Connectors', message);

                        notImported = [notImported thisConn.setInvalid(message)]; %#ok<AGROW>
                    end
                else
                    nonSibling1 = false;
                    if ~isempty(thisConn.End1Comp)
                        nonSibling1 = thisConn.End1Comp.ParentArchitecture ~= this;
                    end
                    nonSibling2 = false;
                    if ~isempty(thisConn.End2Comp)
                        nonSibling2 = thisConn.End2Comp.ParentArchitecture ~= this;
                    end
                end
                
                if thisConn.Valid
                    % Handle bidirectional connectors that need to be expanded
                    if thisConn.End1APort.Replaced || thisConn.End2APort.Replaced
                        if thisConn.End1APort.Replaced && thisConn.End2APort.Replaced
                            % Make sure the ports are complements of each
                            % other.
                            derivedConnectors = SysMLConnector.internal.CandidateConnector.empty(0, 2);
                            
                            if strcmp(thisConn.End1APort.Replacements(1).ComputedDir, "in")
                                conn(1).TargetPort      = thisConn.End1APort.Replacements(1);
                                conn(1).TargetComponent = thisConn.End1Comp;

                                conn(2).SourcePort      = thisConn.End1APort.Replacements(2);
                                conn(2).SourceComponent = thisConn.End1Comp;
                            else
                                conn(1).SourcePort      = thisConn.End1APort.Replacements(1);
                                conn(1).SourceComponent = thisConn.End1Comp;

                                conn(2).TargetPort      = thisConn.End1APort.Replacements(2);
                                conn(2).TargetComponent = thisConn.End1Comp;
                            end

                            if strcmp(thisConn.End2APort.Replacements(1).ComputedDir, "in")
                                conn(2).TargetPort      = thisConn.End2APort.Replacements(1);
                                conn(2).TargetComponent = thisConn.End2Comp;

                                conn(1).SourcePort      = thisConn.End2APort.Replacements(2);
                                conn(1).SourceComponent = thisConn.End2Comp;
                            else
                                conn(2).SourcePort      = thisConn.End2APort.Replacements(1);
                                conn(2).SourceComponent = thisConn.End2Comp;

                                conn(1).TargetPort      = thisConn.End2APort.Replacements(2);
                                conn(1).TargetComponent = thisConn.End2Comp;
                            end

                            for idx = 1:2
                                derivedConnectors(idx) = this.addDerivedConnector(...
                                        this, ...
                                        conn(idx).SourceComponent, ...
                                        conn(idx).SourcePort, ...
                                        conn(idx).TargetComponent, ...
                                        conn(idx).TargetPort, ...
                                        thisConn.ExtElementID);
                            end

                            thisConn.setReplacements(derivedConnectors);
                            
                            if derivedConnectors(1).Valid && (nonSibling1 || nonSibling2)
                                this.handleNonSiblingConnector(derivedConnectors(1));
                                this.handleNonSiblingConnector(derivedConnectors(2));
                            end
                        else
                            message = sprintf('Only one conn port was expanded to two for bidirectional interfaces for connector ''%s''.', thisConn.ExtElementID);

                            SysMLConnector.internal.StatusMonitor.publishEvent('LinkConnectors', 'Connectors', message);

                            notImported = [notImported thisConn.setInvalid('Connector', message)]; %#ok<AGROW>
                        end
                        
                    elseif (nonSibling1 || nonSibling2)
                        % Handle non-sibling
                        this.handleNonSiblingConnector(thisConn);
                    end
                end
            end

            % Validate connectors
            cConns = this.ChildConnectors;
            for c = 1:length(cConns)
                notImported = [notImported cConns(c).validate()]; %#ok<AGROW>
            end
        end
        
        function fixFanInConnectors(this)
        % Check Architecture output ports and Component input ports for fan-in
            
            ports = this.PortMapFromExtElementID.values;
            for k = 1:length(ports)
                thisPort = ports{k};
                thisPort.fixFanInConnectors();
            end
            
            cComps = this.ChildComponents;
            for p = 1:length(cComps)
                thisComp = cComps(p);
                thisComp.fixFanInConnectors();
            end            
        end
        
        function notImported = checkArchReferenceCycles(this)
            % Check for cycles (Components that have children referencing the parent)
            notImported = [];

            cComps = this.ChildComponents;
            for p = 1:length(cComps)
                thisComp = cComps(p);
                compArch = thisComp.ReferenceArch;
                
                archsToCheck = thisComp.ParentArchitecture;
                allArchsToCheck = archsToCheck;

                while ~isempty(archsToCheck)
                    archCheck = archsToCheck(1);
                    archCheck.Visited = true;
                    archsToCheck = archsToCheck(2:end);
                    
                    if archCheck == compArch
                        % Remove the circular reference.
                        thisComp.ReferenceArch = [];
                        thisComp.ReferenceArchExtElementID = [];

                        thisNotImported = thisComp.createNotImported('Architecture Reference', 'Circular behavioral references are not permitted so the component behavior was ignored.');
                        notImported = [notImported thisNotImported]; %#ok<AGROW>

                        break;
                    end
                    
                    for n = 1:length(archCheck.ReferencingComps)
                        parArch = archCheck.ReferencingComps(n).ParentArchitecture;
                        if ~parArch.Visited
                            archsToCheck = [archsToCheck, parArch]; %#ok<AGROW>
                            allArchsToCheck = [allArchsToCheck parArch]; %#ok<AGROW>
                        end
                    end
                end

                for n = 1:length(allArchsToCheck)
                    allArchsToCheck(n).Visited = false;
                end
            end
        end

        function fullPath = getFullPath(this)
            fullPath = this.getPostLinkFullPath;
        end
            
        function fPath = getPostLinkFullPath(this)
            fPath = this.Name;
            pOwn = this.ParentPackage;
            while ~isempty(pOwn)
                fPath = pOwn.Name + "/" + fPath;
                pOwn = pOwn.ParentPackage;
            end
        end
        
        function emp = isEmptyAndUnlinked(this)
            emp = false;
            if isempty(this.ChildComponents) && isempty(this.ReferencingComps) && ...
                    isempty(this.PortMapFromExtElementID.values)
                emp = true;
            end
        end
        
        function adComp = addAdapter(this, conns, dstComp, dstCompArchPort)
            adArch = SysMLConnector.internal.CandidateArchitecture(...
                "Adapter" + this.DerivedArchIdx, ...
                this.ExtElementID + "AdapterArch" + this.DerivedArchIdx, ...
                this.ParentPackageExtElementID, []);
            adArch.Derived = true;
            this.DerivedArchIdx = this.DerivedArchIdx + 1;
            
            othComps = cell(1, length(conns));
            othAPorts = [];
            for k = 1:length(conns)
                thisConn = conns(k);
                if thisConn.End1APort == dstCompArchPort
                    othComp = thisConn.End2Comp;
                    othAPort = thisConn.End2APort;
                else
                    othComp = thisConn.End1Comp;
                    othAPort = thisConn.End1APort;
                end
                othComps{k} = othComp;
                othAPorts = [othAPorts othAPort]; %#ok<AGROW>
            end
            
            adArchInports = [];
            for k = 1:length(conns)
                newPort = adArch.addPort(...
                    othAPorts(k).Name, ~othAPorts(k).IsConjugated, ...
                    adArch.ExtElementID + "AdapterPort" + adArch.DerivedPortIdx, ...
                    "", othAPorts(k).Interface, true);
                adArch.DerivedPortIdx = adArch.DerivedPortIdx + 1;
                newPort.ComputedDir = "in";
                adArchInports = [adArchInports newPort]; %#ok<AGROW>
            end
            
            adArchOutport = adArch.addPort(...
                dstCompArchPort.Name, ~dstCompArchPort.IsConjugated, ...
                adArch.ExtElementID + "AdapterPort" + adArch.DerivedPortIdx, ...
                "", dstCompArchPort.Interface, true);
            adArch.DerivedPortIdx = adArch.DerivedPortIdx + 1;
            adArchOutport.ComputedDir = "out";

            adComp = this.addChildComponent(...
                "Adapter" + this.DerivedCompIdx, ...
                this.ExtElementID + "AdapterComp" + this.DerivedCompIdx, ...
                adArch.ExtElementID);
            this.DerivedCompIdx = this.DerivedCompIdx + 1;

            adArch.linkComponentsPortsPackage();
            adComp.ReferenceArch = adArch;
            adArch.addReferencingComp(adComp);
                        
            for k = 1:length(conns)
                thisConn = conns(k);
                othComp = [];
                if ~isempty(othComps{k})
                    othComp = othComps{k};
                end
                repConn = this.addDerivedConnector(...
                    this, othComp, othAPorts(k), ...
                    adComp, adArchInports(k), thisConn.ExtElementID);
                thisConn.setReplacements(repConn);
            end
            this.addDerivedConnector(...
                this, dstComp, dstCompArchPort, ...
                adComp, adArchOutport, thisConn.ExtElementID);
        end
        
        function build = buildCheck(this, inlineSingleUseArchsAcrossPackages, ...
                                    pruneArchsWithNoRefAndNoChildren, ...
                                    simulinkLeaf)
            build = true; % assume
            if this.isEmptyAndUnlinked()
                % Prune empty architectures that have no references
                build = ~pruneArchsWithNoRefAndNoChildren;
            elseif isempty(this.ChildComponents) && simulinkLeaf
                % Build will happen
                this.BuildAsSimulink = true;
            elseif isscalar(this.ReferencingComps)
                % If a single reference, check if we should inline
                aPrj = this.ParentPackage;
                rcPrj = this.ReferencingComps.ParentArchitecture.ParentPackage;
                if (aPrj.ExtElementID == rcPrj.ExtElementID || ...
                        inlineSingleUseArchsAcrossPackages || ...
                        this.Derived) && this.canBeInlined()
                    this.IsInlined = true;
                    this.ReferencingComps.IsInliningItsArch = true;
                    this.ParentPackage = rcPrj; % Fixup parent pkg link for book keeping
                    build = false; % Will be built when building the Component instead of Prj
                    % need to check if the reference component is part of a
                    % loop
                    % any inlined architecture cannot be part of a loop
                    % since it will only be implemented as a single
                    % component in the parent architecture
                    % also, the loop detection will remove reference
                    % architecture from components in this architecture
                    % that from a loop
                    if isempty(this.ReferencingComps.ReferenceArch)
                        this.ReferencingComps.ReferenceArch = this;
                        this.ReferencingComps.ReferenceArchExtElementID = ...
                            this.ExtElementID;
                    end
                end
            end
            this.Build = build;
        end
        
        function print(this, printer)
            if ~this.IsInlined
                printer.openScope("Arch: " + this.Name);
            end
            allPorts = this.PortMapFromExtElementID.values;
            for k = 1:length(allPorts)
                allPorts{k}.print(printer);
                if ~isempty(allPorts{k}.Interface)
                    allPorts{k}.Interface.print(printer);
                end
            end
            for k = 1:length(this.ChildComponents)
                this.ChildComponents(k).print(printer);
            end
            for k = 1:length(this.ChildConnectors)
                this.ChildConnectors(k).print(printer);
            end
            for k = 1:length(this.Parameters)
                printer.print("Prm: [" + this.Parameters(k).Name + ",t:" + ...
                              this.Parameters(k).TypeName + ",d:" + ...
                              this.Parameters(k).Dim + ",v:" + this.Parameters(k).DefaultValue + "]");
            end
            if ~this.IsInlined
                printer.closeScope("Arch: " + this.Name);
            end
        end
        
        function prelimBuildArchBody(this, thisArch, builder)
            this.ZCElement = thisArch;
            thisArch.ExternalUID = this.ExtElementID;
            
            % Apply stereotypes
            builder.applyStereotypes(this);
            builder.createParameters(this);
            
            cComps = this.ChildComponents;
            % Add empty Components
            for p = 1:length(cComps)
                thisComp = cComps(p);
                if thisComp.Valid
                    c = builder.createComponent(thisArch, thisComp);
                    thisComp.ZCElement = c;
                    c.ExternalUID = thisComp.ExtElementID;
                end
            end
            
            % Add Arch ports
            prelimBuildPorts(this, thisArch, builder);
            
            % Do prelim build of inline Components
            for p = 1:length(cComps)
                thisComp = cComps(p);
                if thisComp.Valid && thisComp.IsInliningItsArch && ...
                        ~isempty(thisComp.ReferenceArch)
                    thisComp.ReferenceArch.prelimBuildArchBody(...
                        thisComp.ZCElement.Architecture, builder);
                end
            end
            
        end
        
        function prelimBuildPorts(this, thisArch, builder)
            allPorts = this.PortMapFromExtElementID.values;
            for k = 1:length(allPorts)
                thisPort = allPorts{k};
                if thisPort.Valid && ~thisPort.Replaced
                    aP = builder.createPort(thisArch, thisPort.Name, ...
                                            thisPort.ComputedDir);
                    thisPort.ZCElement = aP;
                    thisPort.BuildName = aP.Name;
                    aP.ExternalUID = thisPort.ExtElementID;
                    if ~isempty(thisPort.Interface)
                        intf = thisPort.Interface.ZCElement;
                        aP.setInterface(intf);
                    end
                end
            end
        end
        
        function prelimBuild(this, builder)
            SysMLConnector.internal.StatusMonitor.publishEvent('BuildArchitecture', this.ExtElementID, 'Building architecture %s (%i of %i).', this.Name, builder.getArchitectureIdx, builder.ArchitectureCount);

            if this.BuildAsSimulink
                builder.createSimulinkModel(this);
            else
                aMdl = builder.createArchitectureModel(this);
                this.prelimBuildArchBody(aMdl.Architecture, builder);
            end
        end
        
        function finishBuildLinkComps(this, builder)
            cComps = this.ChildComponents;
            cIdx = 1;
            for p = 1:length(cComps)
                thisComp = cComps(p);
                if thisComp.Valid
                    try
                        if ~isempty(thisComp.ReferenceArch)
                            if ~thisComp.IsInliningItsArch 
                                % Link to reference architecture model
                                refMdlName = builder.lookupModelNameFromExtID(...
                                    thisComp.ReferenceArchExtElementID);
                                    thisComp.ZCElement.linkToModel(refMdlName);
                            else
                                thisComp.ReferenceArch.finishBuildLinkComps(builder);
                            end
                    
                            defWidth = thisComp.ReferenceArch.getDefaultCompWidth();
                        else
                            defWidth = strlength(thisComp.Name)*10 + 20;
                        end

                        compPos = get_param(thisComp.ZCElement.SimulinkHandle,'Position');
                        offsetPos = 10 * (cIdx-1);
                        set_param(thisComp.ZCElement.SimulinkHandle,'Position',...
                                                [compPos(1), compPos(2), ...
                                            compPos(1)+defWidth, ...
                                            compPos(4)] + offsetPos);
                    catch ME
                        type   = 'Reference Component Link';
                        reason = sprintf('Unable to finish building component with error: %s', ME.identifier);
                        builder.addNotImported(thisComp, type, reason);

                        try %#ok<TRYNC>
                            % Try to position the component using basic heuristics but do not recover again.
                            defWidth = strlength(thisComp.Name)*10 + 20;
                            compPos = get_param(thisComp.ZCElement.SimulinkHandle,'Position');
                            offsetPos = 10 * (cIdx-1);
                            set_param(thisComp.ZCElement.SimulinkHandle,'Position',...
                                                    [compPos(1), compPos(2), ...
                                                compPos(1)+defWidth, ...
                                                compPos(4)] + offsetPos);
                        end
                    end

                    cIdx = cIdx + 1;
                end
            end
        end
        
        function finishBuildConnect(this, builder)
            cConns = this.ChildConnectors;
            for c = 1:length(cConns)
                thisConn = cConns(c);
                
                if thisConn.Valid && ~thisConn.Replaced
                    if isempty(thisConn.End1Comp)
                        % Arch port
                        port1 = this.getCachedPortFromExtElementID(thisConn.End1RefPortExtElementID);
                        port1Dir = port1.ComputedDir;
                        zcPort1 = port1.ZCElement;
                        port1Arch = true;
                    else
                        % Comp port
                        port1 = thisConn.End1RefArch.getCachedPortFromExtElementID(thisConn.End1RefPortExtElementID);
                        port1Name = port1.BuildName;
                        port1Dir = port1.ComputedDir;
                        zcPort1 = thisConn.End1Comp.ZCElement.getPort(char(port1Name));
                        port1Arch = false;
                    end
                    if isempty(thisConn.End2Comp)
                        % Arch port
                        port2 = this.getCachedPortFromExtElementID(thisConn.End2RefPortExtElementID);
                        zcPort2 = port2.ZCElement;
                    else
                        % Comp port
                        port2 = thisConn.End2RefArch.getCachedPortFromExtElementID(thisConn.End2RefPortExtElementID);
                        port2Name = port2.BuildName;
                        zcPort2 = thisConn.End2Comp.ZCElement.getPort(char(port2Name));
                    end
                    
                    if (port1Arch && port1Dir == "in") || (~port1Arch && port1Dir == "out")
                        connZC = builder.createConnector(zcPort1, zcPort2);
                    else
                        connZC = builder.createConnector(zcPort2, zcPort1);
                    end
                    connZC.ExternalUID = thisConn.ExtElementID;
                end
            end
            
            % Fix layout of Arch
            this.ZCElement.layout;
            set_param(this.ZCElement.SimulinkHandle, 'SystemRect', [0 0 0 0]);
            
            cComps = this.ChildComponents;
            for p = 1:length(cComps)
                thisComp = cComps(p);
                if thisComp.Valid && thisComp.IsInliningItsArch && ~isempty(thisComp.ReferenceArch)
                    thisComp.ReferenceArch.finishBuildConnect(builder);
                end
            end
            
            
        end
            
        function finishBuild(this, builder)
            SysMLConnector.internal.StatusMonitor.publishEvent('FinalizeArchitecture', this.ExtElementID, 'Finalizing architecture %s (%i of %i).', this.Name, builder.getArchitectureIdx-builder.ArchitectureCount, builder.ArchitectureCount);

            if ~this.BuildAsSimulink
                this.finishBuildLinkComps(builder);
                this.finishBuildConnect(builder);
            end
        end
        
    end
    
end