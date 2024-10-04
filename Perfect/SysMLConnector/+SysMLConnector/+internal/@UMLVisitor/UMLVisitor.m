classdef UMLVisitor < m3i.Visitor
%UMLVisitor Helper Visitor class for SysMLConnector.internal.import that scans UML model loaded from XMI file
    
    properties
        PackagesToIgnore = [];

        ProfilesFound = []
        ArchNameGeneratedIdx = 1;        
        NotImported = [];
    end
    
    methods (Static)
        
        function path = getFullPath(part)
            path = part.name;
            owner = part.owner;
            while ~isempty(owner)
                path = owner.name + "/" + path;
                owner = owner.owner;
            end
        end
        
        function stype = findSysMLSuperType(st)
             if strncmp(st.qualifiedName, 'SysML.', length('SysML.'))
                 stype = st;
             else
                 for si = 1:st.superClass.size
                     stype = SysMLConnector.internal.UMLVisitor.findSysMLSuperType(st.superClass.at(si));
                     if ~isempty(stype)
                         return;
                     end
                 end
                 stype = [];
             end
        end

        function [className,stypeInst] = getSysMLStereotype(element)
            className = "";
            stypeInst = [];
            stypes = element.appliedStereotypeInstance;
            for k = 1:stypes.size
                stypeIn = stypes.at(k);
                st = SysMLConnector.internal.UMLVisitor.findSysMLSuperType(stypeIn.getMetaStereotype);
                if ~isempty(st)
                    className = string(st.qualifiedName);
                    stypeInst = stypeIn;
                    break;
                end
            end
        end
        
        function extID = getExtID(element)
            extIDInfo = element.getExternalToolInfo("MagicDraw");
            extID = "";
            if ~isempty(extIDInfo)
                extID = string(extIDInfo.externalId);
            end
            if extID == ""
                extID = string(element.toString());
            end
        end
        
    end
    
    methods (Access = private)
        
        function addStereotypes(this, element, candElem)
            stypes = element.appliedStereotypeInstance;
            for k = 1:stypes.size
                stypeIn = stypes.at(k);
                st = stypeIn.getMetaStereotype;
                stExtID = SysMLConnector.internal.UMLVisitor.getExtID(st);
                leafClass = true;
                while 1
                    if isempty(st) || strncmp(st.qualifiedName, 'SysML.', length('SysML.'))
                        break;
                    else
                        if leafClass
                            candElem.addStereotype(stExtID);
                            leafClass = false;
                        end

                        visitumlmmProfile(this, st.package);
                        
                        % Get stereotype properties
                        for p = 1:st.ownedAttribute.size
                            pElem = st.ownedAttribute.at(p);
                            if ~strncmp(pElem.name, 'base_', 5)
                                tName = "";
                                propVal = [];
                                if ~isempty(pElem.type)
                                    tName = string(pElem.type.name);
                                end

                                try %#ok<TRYNC> (getOne may error)
                                    pVal = stypeIn.getOne(pElem.name);
                                    if ~isempty(pVal)
                                        propVal = candElem.addStereotypePropVal(...
                                            stExtID, string(pElem.name), tName, pVal.toString());
                                    end
                                end

                                if isempty(propVal)
                                    % Try to recover using regex
                                    pVal = SysMLConnector.internal.utils.getStereotypePropertyValue(element, pElem.qualifiedName);
                                    if ~isempty(pVal)
                                        propVal = candElem.addStereotypePropVal(...
                                            stExtID, string(pElem.name), tName, pVal); %#ok<NASGU>
                                    end
                                end
                            end
                        end
                        
                    end
                    if st.superClass.size > 0
                        st = st.superClass.at(1);
                    else
                        st = [];
                    end
                end
            end
        end

        function addNotImported(this, element, type, reason)
            notImp.Type = type;

            if ~isstring(element)
                notImp.Element = this.getFullPath(element);
                notImp.ElementID = SysMLConnector.internal.utils.getExtID(element);
                scName = this.getSysMLStereotype(element);
                notImp.Stereotype = scName;
            else
                notImp.Element = element;
                notImp.ElementID = element;
                notImp.Stereotype = type;
            end

            notImp.Reason = reason;

            this.NotImported = [this.NotImported notImp];
        end

        function ret = isBlock(~, sType)
            ret = (sType == "SysML.Block") || ...
                  (sType == "SysML.System") || ...
                  (sType == "SysML.Subsystem");
        end
        
        function visitBlock(this, element)            
            % SysML:Block -- Create candidate architecture
            ppID = SysMLConnector.internal.utils.getUMLPackageParentID(element);
            
            cID =  this.getExtID(element);

            aName = string(element.name);
            if aName == ""
                % If architecture has no name, create a default name
                aName = "Architecture" + this.ArchNameGeneratedIdx;
                this.ArchNameGeneratedIdx = this.ArchNameGeneratedIdx + 1;
            end
            
            genIDs = [];
            for g=1:element.generalization.size()
                gen = element.generalization.at(g);
                if ~isempty(gen) && ~isempty(gen.general)
                    genID = this.getExtID(gen.general);
                    genIDs = [genIDs genID]; %#ok<AGROW>
                end
            end
            
            thisArch = SysMLConnector.internal.CandidateArchitecture(...
                aName, cID, ppID, genIDs);
            this.addStereotypes(element, thisArch);
            
            % Process ports
            visitChildren(this, element.ownedPort, thisArch);   
            
            % Process child components
            for p=1:element.ownedAttribute.size
                property = element.ownedAttribute.at(p);
                propertyName = string(property.name);

                try
                    if (isempty(propertyName) || strcmp(propertyName, "")) && ~isempty(property.type)
                        propertyName = string(property.type.name);
                    end
                catch ME
                    warning('SysMLConnector:internal:UMLVisitor:FailedToResolvePropertyName', 'Failed to resolve name of property ''%s'' with error:\n%s', this.getExtID(property), getReport(ME));
                end

                if ~isa(property, 'umlmm.Port') && ...
                        ~isempty(property.type) && ...
                        this.isBlock(this.getSysMLStereotype(property.type))
                    if strcmpi(property.aggregation.toString, 'composite')
                        cID = this.getExtID(property);
                        childComp = thisArch.addChildComponent(...
                            propertyName, ...
                            cID, this.getExtID(property.type));
                        if property.redefinedElement.size > 0
                            thisArch.redefine(childComp, this.getExtID(property.redefinedElement.at(1)));
                        end
                        visitChildren(this,property.ownedComment);
                    else
                        addNotImported(this, property, "BlockProperty", ...
                                               sprintf("The aggregation type of '%s' is not supported. Part properties must have an aggregation type of 'composite'.", property.aggregation.toString));
                    end
                elseif ~isa(property, 'umlmm.Port')
                    elTypeName = "";
                    elType = "";
                    if ~isempty(property.type)
                        if isa(property.type, 'umlmm.Enumeration')
                            elType = this.visitEnumeration(property.type);
                            elTypeName = "Enumeration";
                        elseif isa(property.type, 'umlmm.DataType')
                            elType = this.visitValueType(property.type);
                            elTypeName = "Dtype:" + string(property.type.name);
                        end
                    else
                        [elType, elTypeName] = SysMLConnector.internal.utils.getBlockPropertyType(property);
                    end

                    elDim = inf;
                    if ~isempty(property.upperValue)
                        [pD, isOk] = str2num(property.upperValue.value);
                        if isOk
                            elDim = floor(pD);
                        end
                    end
                    if isinf(elDim), elDim = 1; end

                    elValue = '';
                    if ~isempty(property.defaultValue)
                        if isa(property.defaultValue, 'umlmm.OpaqueExpression')
                            val = property.defaultValue.body;
                            if val.size > 0
                                elValue = val.at(1);
                            end
                        elseif isa(property.defaultValue, 'umlmm.InstanceValue')
                            val = property.defaultValue.instance;
                            if isa(val, 'umlmm.EnumerationLiteral')
                                elValue = val.name;
                            end
                        else
                            vClass = class(property.defaultValue);
                            if strncmpi(vClass, 'umlmm.Literal', length('umlmm.Literal'))
                                elValue = property.defaultValue.value;
                            else
                                addNotImported(this, property.defaultValue, "UnsupportedDefaultValueType", ...
                                               "Unsupported default value type.");
                            end
                        end
                    end
                    
                    parameter = thisArch.addParameter(this.getExtID(property), propertyName, elType, elTypeName, elDim, elValue);
                    if property.redefinedElement.size > 0
                        thisArch.redefine(parameter, this.getExtID(property.redefinedElement.at(1)));
                    end
                end
            end
            
            % Process child connectors
            visitChildren(this, element.ownedConnector, thisArch);    

            if strcmp(SysMLConnector.internal.StatusMonitor.getSourceTool, 'EA')
                % EA sometimes stores connector information in the diagram
                % section instead, so go check that.
                xmiNode = SysMLConnector.internal.utils.getNode(element);
                
                structureDiagrams = xmiNode.Graph.getElementsByType('umldi:UMLCompositeStructureDiagram');
                structureDiagramIndices = arrayfun(@(diagram) strcmp(diagram.getProperty('modelElementAttribute'), thisArch.ExtElementID), structureDiagrams);
                if any(structureDiagramIndices)
                    if ~isempty(thisArch.ChildConnectors)
                        existingConnectorIDs = [thisArch.ChildConnectors.ExtElementID];
                    else
                        existingConnectorIDs = "";
                    end

                    structureDiagrams = structureDiagrams(structureDiagramIndices);
                    for structureDiagram = structureDiagrams
                        if hasProperty(structureDiagram, 'ownedElement')
                            for ownedElement = structureDiagram.getProperty('ownedElement')
                                if hasProperty(ownedElement, 'modelElementAttribute')
                                    modelElements = structureDiagram.Graph.lookup(ownedElement.getProperty('modelElementAttribute'));
                                    % Only use the first if there are
                                    % duplicates.
                                    modelElement = modelElements(1);
                                    if strcmp(modelElement.Type, 'uml:Connector') && ~ismember(modelElement.ID, existingConnectorIDs)
                                        existingConnectorIDs = [existingConnectorIDs modelElement.ID]; %#ok<AGROW>
                                        % Cache it for now and add it later if it does not show up during generalization merging.
                                        thisArch.DeferredConnectors = [thisArch.DeferredConnectors modelElement.ID];
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            % Process nested classes
            visitChildren(this, element.nestedClassifier);

            % Process nested behaviors
            visitChildren(this, element.ownedBehavior);
        end
        
        function visitRequirement(this, element)
            
            elemOwner = element.owner;
            reqOwner = "";

            if isa(elemOwner, 'umlmm.Class')
                oStypeStr = this.getSysMLStereotype(elemOwner);
                if contains(oStypeStr, "Requirement")
                    reqOwner = this.getExtID(elemOwner);
                end
            end
            
            [~,cStype] = this.getSysMLStereotype(element);
            reqXMIID = this.getExtID(element);
            
            reqID = cStype.getOne('Id');
            if ~isempty(reqID)
               reqIDString = string(reqID.toString); 
            else
               reqIDString = "";
            end

            reqText = cStype.getOne('Text');
            if ~isempty(reqText)
               reqTextString = string(reqText.toString); 
            else
               reqTextString = "";
            end

            reqType = extractAfter(class(cStype), "SysML.");

            req = SysMLConnector.internal.CandidateRequirement(...
                reqXMIID, string(element.name), reqIDString, ...
                reqTextString, reqOwner, reqType);

            reqProperties = properties(cStype)';
            additionalProperties = string(setdiff(reqProperties, {'base_Class', 'base_ClassObject', 'Id', 'Text', 'propertyName', 'propertyValue'}));
            
            elementPath = this.getFullPath(element);
            for additionalProperty = additionalProperties
                try
                    addAdditionalProperty(req, additionalProperty, cStype.(additionalProperty));
                catch ME
                    addNotImported(this, elementPath + ":" + additionalProperty, ...
                                         "RequirementProperty", ...
                                         "Error:" + string(ME.identifier));
                end
            end

            % Check for stereotype properties
            if ismember('propertyName', reqProperties) && ismember('propertyValue', reqProperties)
                for stereotypePropertyIdx = 1:cStype.propertyName.size
                    propertyName = cStype.propertyName.at(stereotypePropertyIdx);
                    
                    if startsWith(propertyName, 'SysML.Requirement.')
                        continue;
                    end

                    try
                        addAdditionalProperty(req, propertyName, cStype.propertyValue.at(stereotypePropertyIdx));
                    catch ME
                        addNotImported(this, elementPath + ":" + propertyName, ...
                                             "RequirementStereotypeProperty", ...
                                             "Error:" + string(ME.identifier));
                    end
                end
            end
            
            % Process nested classes (requirements)
            for i=1:element.nestedClassifier.size
                this.apply(element.nestedClassifier.at(i));
            end
        end
        
        function debugPrintSignal(this, prop, idt, dispStr)
            idt = idt + "  ";
            fprintf('%s %s: %s\n', idt, dispStr, prop.name);
            for oa = 1:prop.ownedAttribute.size
                attr = prop.ownedAttribute.at(oa);
                attrType = "";
                if ~isempty(attr.type)
                    if isa(attr.type, 'umlmm.Enumeration')
                        attrType = "Enum: <" + attr.type.name + ">";
                    elseif isa(attr.type, 'umlmm.DataType')
                        attrType = attr.type.name;
                    end
                end
                
                attName = "<noName>"; %assume
                if ~isempty(attr.name)
                    attName = string(attr.name);
                end
                
                if attr.redefinedProperty.size > 0
                    rp = attr.redefinedProperty.at(1);
                    rpO = rp.owner;
                    fprintf('%s     .%s [%s] REDEFINES: %s.%s\n', ...
                            idt, attName, attrType, rpO.name, rp.name);
                else
                    fprintf('%s     .%s [%s]\n', idt, attName, attrType);
                end
            end
            if prop.generalization.size > 0
                this.debugPrintSignal(prop.generalization.at(1).general, ...
                                      idt, "INH-FROM-SIGNAL");
            end
        end
            
        
        function debugPrintInterface(this, element)
            fprintf('INTERFACE: %s -----------------------------------\n', element.name);
            for p = 1:element.ownedAttribute.size
                prop = element.ownedAttribute.at(p);
                fpn = this.getSysMLStereotype(prop);
                if fpn == "SysML.FlowProperty"
                    fprintf('->FLOWPROP: %s\n', prop.name);
                    if ~isempty(prop.type)
                        if isa(prop.type, 'umlmm.Signal')
                            this.debugPrintSignal(prop.type, "", "SIGNAL");
                         elseif isa(prop.type, 'umlmm.Enumeration')
                             fprintf(' ENUM: %s\n', prop.type.name);
                         elseif isa(prop.type, 'umlmm.DataType')
                             fprintf(' DATA-TYPE: %s\n', prop.type.name);
                         else
                             fprintf(' TYPE: %s\n', class(prop.type));
                         end
                    end
                end
            end
        end
        
        function recVisitSignalSuperClass(this, element, intf, redefProps)
            for oa = 1:element.ownedAttribute.size
                pA = element.ownedAttribute.at(oa);
                
                if ~any(redefProps == this.getExtID(pA))
                    elTypeName = "";
                    elType = [];
                    if ~isempty(pA.type)
                        if isa(pA.type, 'umlmm.Enumeration')
                            elType = this.visitEnumeration(pA.type);
                            elTypeName = "Enumeration";
                        elseif isa(pA.type, 'umlmm.DataType')
                            elType = this.visitValueType(pA.type);
                            elTypeName = "Dtype:" + string(pA.type.name);
                        end
                    else
                        [elType, elTypeName] = SysMLConnector.internal.utils.getBlockPropertyType(pA);
                    end

                    if pA.redefinedProperty.size > 0
                        rdP = pA.redefinedProperty.at(1);
                        redefProps = [redefProps this.getExtID(rdP)]; %#ok<AGROW>
                    end
                    elDim = inf;
                    if ~isempty(pA.upperValue)
                        [pD, isOk] = str2num(pA.upperValue.value);
                        if isOk
                            elDim = floor(pD);
                        end
                    end
                    
                    if isa(intf, 'SysMLConnector.internal.CandidateValueType')
                        addNotImported(this, pA, "ValueTypeElementsUnsupported", ...
                                               "ValueTypes do not support elements. If needed, use interfaces with flow properties instead.");
                    else
                        intf.addElement(string(pA.name), this.getExtID(pA), ...
                                        "unset", elTypeName, elType, elDim);
                    end
                end
            end
            
            if element.generalization.size > 0
                gen = element.generalization.at(1);
                if ~isempty(gen) && ~isempty(gen.general)
                    recVisitSignalSuperClass(this, gen.general, intf, redefProps);
                end
            end
        end
        
        function [propType, propTypeName] = visitValueType(this, element)
            if isa(element, 'umlmm.PrimitiveType')
                propType = element;
                propTypeName = ['Dtype:' lower(element.name)];

                return
            end

            valueTypeID = this.getExtID(element);
            propType = SysMLConnector.internal.CandidateElement.idMap(...
                "lookup", valueTypeID);
            if isempty(propType)
                propType = SysMLConnector.internal.CandidateValueType(...
                    string(element.name), valueTypeID);
                recVisitSignalSuperClass(this, element, propType, strings(0));
            end
            propTypeName = "ValueType:" + propType.Name;

            % Check to see if the value type has a general type
            if element.generalization.size > 0
                generalization = element.generalization.at(1);

                if isempty(generalization.general)
                    [baseValueType, baseValueTypeName] = SysMLConnector.internal.utils.getBlockPropertyType(generalization, AttributeName='general');
                else
                    [baseValueType, baseValueTypeName] = visitValueType(this, generalization.general);
                end

                if ~isempty(baseValueType)
                    propType.Type = baseValueType;
                    propType.TypeName = baseValueTypeName;
                end
            end
        end

        function [propType, propTypeName] = visitSignal(this, element)
            
            sigID = this.getExtID(element);
            propType = SysMLConnector.internal.CandidateElement.idMap(...
                "lookup", sigID);
            if isempty(propType)
                propType = SysMLConnector.internal.CandidateInterface(...
                    string(element.name), sigID, "SIGNAL");
                recVisitSignalSuperClass(this, element, propType, strings(0));
            end
            propTypeName = "Bus:" + propType.Name;
        end
        
        function newEnum = visitEnumeration(this, element)
            enumID = this.getExtID(element);
            newEnum = SysMLConnector.internal.CandidateElement.idMap(...
                "lookup", enumID);
            if isempty(newEnum)
                enumStrs = [];
                for ol = 1:element.ownedLiteral.size
                    enumStrs = [enumStrs string(element.ownedLiteral.at(ol).name)]; %#ok<AGROW>
                end
                newEnum = SysMLConnector.internal.CandidateEnum(...
                    enumID, string(element.name), ...
                    enumStrs);

                % Set the package parent in case this becomes an external enumeration.
                ppID = SysMLConnector.internal.utils.getUMLPackageParentID(element);
                newEnum.ParentPackageExtElementID = ppID;
            end
        end
        
        function recVisitInterfaceSuperClass(this, element, intf, redefProps)
            for p = 1:element.ownedAttribute.size
                prop = element.ownedAttribute.at(p);
                if ~any(redefProps == this.getExtID(prop))
                    [fpn,fp] = this.getSysMLStereotype(prop);
                    if fpn == "SysML.FlowProperty"
                        propType = [];
                        propTypeName = "";
                        if ~isempty(prop.type)
                            if isa(prop.type, 'umlmm.Signal')
                                [propType, propTypeName] = this.visitSignal(prop.type);
                            elseif isa(prop.type, 'umlmm.Enumeration')
                                propType = this.visitEnumeration(prop.type);
                                propTypeName = "Enumeration";
                            elseif isa(prop.type, 'umlmm.DataType')
                                propType = this.visitValueType(prop.type);
                                propTypeName = "Dtype:" + string(prop.type.name);
                            elseif isa(prop.type, 'umlmm.Class') && strcmp(this.getSysMLStereotype(prop.type), 'SysML.InterfaceBlock')
                                propTypeName = string(prop.type.name);
                            else
                                addNotImported(this, prop.type, "UnsupportedFlowType", ...
                                               "Interface flow property is not a primitive type, interface block, value type, or signal");
                            end
                        else
                            [propType, propTypeName] = SysMLConnector.internal.utils.getBlockPropertyType(prop);
                        end

                        % Instead of getting 'direction' directly we get the property
                        % indirectly to workaround an issue with inheritance from
                        % SysML stereotypes.
                        portDir = fp.getOne('direction');
                        portDir = string(portDir.toString);

                        assert(strcmp(portDir, "in") || strcmp(portDir, "out") || ...
                               strcmp(portDir, "inout"));
                        
                        if prop.redefinedProperty.size > 0
                            rdP = prop.redefinedProperty.at(1);
                            redefProps = [redefProps this.getExtID(rdP)]; %#ok<AGROW>
                        end
                        propDim = inf;
                        if ~isempty(prop.upperValue)
                            [pD, isOk] = str2num(prop.upperValue.value);
                            if isOk
                                propDim = floor(pD);
                            end
                        end
                        
                        intf.addElement(string(prop.name), this.getExtID(prop), ...
                                        portDir, propTypeName, propType, propDim);
                    else
                        % [Limitation]: We could potentially remove 
                        % this restriction in the future
                        addNotImported(this, prop, "NestedPortType", ...
                                       "Nested ports not supported");
                    end
                end
            end
            if element.generalization.size > 0
                gen = element.generalization.at(1);
                if ~isempty(gen) && ~isempty(gen.general)
                    recVisitInterfaceSuperClass(this, gen.general, intf, redefProps);
                end
            end
            
        end
        
        function intf = visitInterface(this, element)
            intf = SysMLConnector.internal.CandidateInterface(...
                string(element.name), this.getExtID(element), ...
                "INTERFACEBLOCK");
            recVisitInterfaceSuperClass(this, element, intf, strings(0));
        end

        function visitChildren(this, children, varargin)
            % Visit package elements
            switch (nargin - 2)
                case 0
                    applyFcn = @(elem) this.apply(elem);
                case 1
                    applyFcn = @(elem) this.apply1(elem, varargin{1});
                case 2
                    applyFcn = @(elem) this.apply2(elem, varargin{1}, varargin{2});
                case 3
                    applyFcn = @(elem) this.apply3(elem, varargin{1}, varargin{2}, varargin{3});
                otherwise
                    error('unsupported argument count, %i', nargin);
            end
            
            children = SysMLConnector.internal.utils.toArray(children);
            children = SysMLConnector.internal.utils.unique(children);
            
            if iscell(children)
                arrayfun(@(elem) applyFcn(elem{1}), children, UniformOutput=false);
            else
                arrayfun(applyFcn, children, UniformOutput=false);
            end
        end

        function ret = visitViewpoint(this, element)
            % Treat a viewpoint as a package for now but log it as not
            % imported.
            ret = this.visitumlmmPackage(element);

            addNotImported(this, element, "Viewpoint", ...
                               "Viewpoint import not supported.");
        end
    end
    
    methods (Access = public)
        
        function ret = visitumlmmModel(this,element)
            
            % A model is a package. Treat as the same
            ret = visitumlmmPackage(this, element); 
        end
        
        function ret = visitumlmmPackage(this,package)
            
            ret = [];
            if any(this.PackagesToIgnore == string(package.name))
                return;
            end
            
            pID = this.getExtID(package);
            
            % Create candidate package
            oID = "";
            if ~isempty(package.owner)
                oID = this.getExtID(package.owner);
            end
            SysMLConnector.internal.CandidatePackage(...
                string(package.name), pID, oID);
            
            % Visit package elements
            visitChildren(this, package.ownedMember)
        end

        function ret = visitumlmmDataType(this, element)
            this.visitValueType(element);
            ret = [];
        end

        function ret = visitumlmmSignal(this, element)
            this.visitSignal(element);
            ret = [];
        end

        function ret = visitumlmmProfile(this, profile)
            if isempty(this.ProfilesFound)
                this.ProfilesFound = dictionary;
            end

            if isequal(this.ProfilesFound.numEntries, 0) || ~this.ProfilesFound.isKey(profile.toString)
                this.ProfilesFound(profile.toString) = profile;
            end
            
            ret = [];
        end

        function ret = visitumlmmAbstraction(this, element)
            className = this.getSysMLStereotype(element);
            if className == "SysML.DeriveReqt" || ...
                          className == "SysML.Trace" || ...
                          className == "SysML.Allocate" || ...
                          className == "SysML.Satisfy"
                supplierID = "";
                clientID = "";
                supplierStype = "";
                clientStype = "";
                supplierMclass = "";
                clientMclass = "";
                if element.supplier.size ~= 0
                    supp = element.supplier.at(1);
                    supplierID = this.getExtID(supp);
                    supplierMclass = supp.MetaClass.qualifiedName;
                    supplierStype = this.getSysMLStereotype(supp);
                end
                if element.client.size ~= 0
                    client = element.client.at(1);
                    clientID = this.getExtID(client);
                    clientMclass = client.MetaClass.qualifiedName;
                    clientStype = this.getSysMLStereotype(client);
                end
                
                rLinkID = this.getExtID(element);

                if className == "SysML.Allocate"
                    SysMLConnector.internal.CandidateAllocation.Allocation(supplierID, clientID, Name='', ExternalID=rLinkID);
                else
                    % Requirement Link
                    try
                        classParts = split(className, '.');
                        fullPath = this.getFullPath(element) + string(classParts(end));
                    catch
                        fullPath = "";
                    end

                    SysMLConnector.internal.CandidateReqLink(...
                        rLinkID, className, supplierID, clientID, ...
                        supplierMclass, clientMclass, ...
                        supplierStype, clientStype, fullPath);
                end
            else
                notImportedReason = sprintf('Import not supported for UML %s element, ''%s'', of SysML type ''%s''. Supported types: SysML.DeriveReqt, SysML.Trace, SysML.Allocate, or SysML.Satisfy', ...
                                           SysMLConnector.internal.utils.getClassName(element), ...
                                           SysMLConnector.internal.utils.getExtID(element), ...
                                           className);
                addNotImported(this, element, "Abstraction", notImportedReason);  
            end
            
            ret = [];
        end

        function ret = visitumlmmAssociation(this, element)
            ret = [];

            try
                if element.ownedEnd.size == 2
                    associationSource = element.ownedEnd.at(1);
                    associationTarget = element.ownedEnd.at(2);
    
                    if isa(associationSource, 'umlmm.Property') ...
                          && isa(associationTarget, 'umlmm.Property') ...
                          && strcmp(associationSource.aggregation.toString, 'composite')
                        % source is a reference part property of target
                        part = associationSource;
                        partStereotype = this.getSysMLStereotype(part.type);
                        partParent = associationTarget.type;
                        partParentStereotype = this.getSysMLStereotype(partParent);
    
                        if this.isBlock(partStereotype) && this.isBlock(partParentStereotype)
                            candidateComponent = SysMLConnector.internal.CandidateComponent(part.name, [], this.getExtID(part), this.getExtID(part.type));
                            candidateComponent.DeferredParentArchitecture = this.getExtID(partParent);

                            return;
                        end
                    end
                end

                % Else not imported.
                addNotImported(this, element, "Association", sprintf("Unsupported association type."));  

            catch ME
                addNotImported(this, element, "Association", sprintf("Unexpected error: %s", ME.identifier));  
            end
        end
        
        function ret = visitumlmmClass(this,element)
            cStypeStr = this.getSysMLStereotype(element);
            if cStypeStr == "SysML.InterfaceBlock"
                this.visitInterface(element);
            elseif contains(cStypeStr, "Requirement")
                this.visitRequirement(element);
            elseif this.isBlock(cStypeStr)
                this.visitBlock(element);
            elseif cStypeStr == "SysML.Viewpoint"
                this.visitViewpoint(element);
            else
                addNotImported(this, element, "Class", ...
                               "Not a Block, InterfaceBlock, or Requirement");
            end
            ret = [];            
            visitChildren(this,element.ownedComment);
        end

        function portType = getSupportedPortType(this, portElement)
            % This heuristic tries to figure out the port type for
            % specified or under-specified ports. It will return empty if
            % the port type is not supported.

            portType = this.getSysMLStereotype(portElement);

            if any(strcmpi(portType, ["SysML.ProxyPort" "SysML.FullPort" "SysML.FlowPort"]))
                % Port is fully specified and supported so check is
                % complete.
                return;
            end

            % Port is unspecified so try to figure out the type using
            % heuristics.
            portDataType = portElement.type;
            portDataTypeStereotype = "";
            
            if ~isempty(portDataType)
                portDataTypeStereotype = this.getSysMLStereotype(portDataType);              
            end

            if this.isBlock(portDataTypeStereotype)
                % Assume port is a Full Port when typed by a SysML
                % Block
                portType = "SysML.FullPort";
            elseif portDataTypeStereotype == "SysML.InterfaceBlock"
                % Assume port is a Full Port when typed by a SysML
                % Block
                portType = "SysML.ProxyPort";
            else
                % Unable to infer port type or port is of unsupported type.
                portType = string.empty;
            end
        end
         
        function ret = visitumlmmPort(this,element,thisArch)

            ret = false;

			portName = string(element.name);
            
            % Process port type
            portDataType = element.type;
            portDataTypeStereotype = "";
            portDataTypeExtID = "";
            if ~isempty(portDataType)
                portDataTypeStereotype = this.getSysMLStereotype(portDataType);
                portDataTypeExtID = this.getExtID(portDataType);       
				
				if isempty(portName) || strcmp(portName, "")
					portName = string(portDataType.name);
				end         
            end

            % Ensure port is a supported port type explicitly or implied
            portStereotype = getSupportedPortType(this, element);
            if isempty(portStereotype)
                % Unable to infer port type.
                addNotImported(this, element, "Port", "Not a proxy port or full port");
                return;
            end
            
            % The port has passed the import checks so this function will return true.
            ret = true;

            if (portStereotype == "SysML.FullPort") && (portDataTypeStereotype ~= "SysML.InterfaceBlock")
                % Create child component for Full Port
                cID = this.getExtID(element);
                port = thisArch.addChildComponent(...
                    portName, ...
                    cID, portDataTypeExtID);
            else
                % Full Port typed by interface, Proxy Port, Flow Port
                isConj = false;
                if portStereotype == "SysML.FlowPort"
                    [~,sType] = this.getSysMLStereotype(element);
                    sDir = sType.getOne('direction');
                    sDir = string(sDir.toString);
                    if strcmp(sDir, "out")
                        isConj = true;
                    end
                else
                    isConj = element.isConjugated;                    
                end

                if (portDataTypeStereotype ~= "SysML.InterfaceBlock")
                    % Incompatible port interface type.
                    portDataTypeExtID = "";
                end
                port = thisArch.addPort(portName, isConj, ...
                                 this.getExtID(element), portDataTypeExtID, [], false);
            end

            if element.redefinedElement.size > 0
                thisArch.redefine(port, this.getExtID(element.redefinedElement.at(1)));
            end
        end

        function ret = visitumlmmConnector(this,element,thisArch)
            connectorEnds = [element.end.at(1) element.end.at(2)];
        
            cEndPIDs   = ["" ""];
            connectorComponents = {[], []};
            connectorPorts = {[], []};
            portsValid = false([1 2]);
            xmiNode    = [];
            propNames  = ["startAttribute" "endAttribute"];

            try
                for cEndIdx = 1:2
                    if ~isempty(connectorEnds(cEndIdx).partWithPort)
                        cEndPIDs(cEndIdx) = this.getExtID(connectorEnds(cEndIdx).partWithPort);
                    end
    
                    if strcmp(cEndPIDs(cEndIdx), "") && strcmp(SysMLConnector.internal.StatusMonitor.getSourceTool, 'EA')
                        % Recovery heuristic for EA which stores connector
                        % information in the UML Diagram section of the XMI.
    
                        if isempty(xmiNode)
                            xmiNode = SysMLConnector.internal.utils.getNode(element);
                        end
        
                        try %#ok<TRYNC> Do not try to reconcile failed heuristics.
                            if ~isempty(xmiNode) 
                                if hasProperty(xmiNode, propNames(cEndIdx))
                                    componentPortID = getProperty(xmiNode, propNames(cEndIdx));
                                    componentPortNode = xmiNode.Graph.lookup(componentPortID);
        
                                    if ~isempty(componentPortNode)
                                        cEndPIDs(cEndIdx) = componentPortNode.Owner.ID;
                                    end
                                end
                            end
                        end
                    end
    
                    connectorPorts{cEndIdx} = connectorEnds(cEndIdx).role;
                    connectorComponents{cEndIdx} = connectorEnds(cEndIdx).role.owner;
                    
                    if ~isa(connectorPorts{cEndIdx}, 'umlmm.Port') ...
                            || ~this.isBlock(this.getSysMLStereotype(connectorComponents{cEndIdx}))
                        % This is a heuristic to try to resolve the
                        % connector a different way using the propertyPath
                        % attribute.
                        [stereotypeName, stereotype] = this.getSysMLStereotype(connectorEnds(cEndIdx));
                        if strcmp(stereotypeName, 'SysML.NestedConnectorEnd')
                            % Walk the property path looking for the
                            % first block.
                            for pathIdx = 1:stereotype.propertyPath.size
                                pathObject = stereotype.propertyPath.at(pathIdx);
                                
                                if ~isempty(getSupportedPortType(this, pathObject)) ...
                                        && this.isBlock(this.getSysMLStereotype(pathObject.owner))
                                    connectorPorts{cEndIdx} = pathObject;
                                    connectorComponents{cEndIdx} = pathObject.owner;
                                    break;
                                end
                            end
                        end
                    end

                    if isa(connectorPorts{cEndIdx}, 'umlmm.Port') ...
                        && this.isBlock(this.getSysMLStereotype(connectorComponents{cEndIdx}))
                        % Check if the port is valid                        
                        portType = getSupportedPortType(this, connectorPorts{cEndIdx});
    
                        if ~isempty(portType)
                            portsValid(cEndIdx) = true;
                        end
                    end
                end
               
                if all(portsValid)    
                    thisArch.addChildConnector(this.getExtID(element), ...
                                               cEndPIDs(1), this.getExtID(connectorPorts{1}), this.getExtID(connectorComponents{1}), ...
                                               cEndPIDs(2), this.getExtID(connectorPorts{2}), this.getExtID(connectorComponents{2}), ...
                                               false);
                
                else
                    addNotImported(this, element, "Connector", ...
                                   "Not connecting flow ports");        
                end
            catch ME
                addNotImported(this, element, "Connector", ...
                                   sprintf("Connector visit failed with error %s(%s:%i)", ME.identifier, ME.stack(1).name, ME.stack(1).line)); 
            end

            ret = [];
        end

        function ret = visitumlmmActivity(this, element)
            ret = [];

            % uml:Activity -- Create candidate activity diagram
            ppID = SysMLConnector.internal.utils.getUMLPackageParentID(element);

            [CandidateAD, notImported] = SysMLConnector.internal.CandidateAD.buildCandidateAD(element);
            CandidateAD.ParentPackageExtElementID = ppID;
            this.NotImported = [this.NotImported notImported];

            visitChildren(this, element.ownedBehavior);
        end

        function ret = visitumlmmClassifier(this, element)
            ret = [];
            addNotImported(this, element, "UML Classifier", ...
                               "Unsupported type for import.");
        end

        function newEnum = visitumlmmEnumeration(this, element)
            newEnum = visitEnumeration(this, element);
        end

        function ret = visitumlmmInteraction(this, element)
            ret = [];
            
            ppID = SysMLConnector.internal.utils.getUMLPackageParentID(element);

            [candidateInteraction, notImported] = SysMLConnector.internal.CandidateInteraction.buildCandidateInteraction(element);
            candidateInteraction.ParentPackageExtElementID = ppID;
            this.NotImported = [this.NotImported notImported];

            visitChildren(this, element.ownedBehavior);
        end

        function ret = visitumlmmStateMachine(~, element)
            % Import State Machine
            ret = [];
            try
                SysMLConnector.internal.CandidateStateMachine.StateMachine(element,...
                    SysMLConnector.internal.utils.getUMLPackageParentID(element));
            catch ME
                warning("SysMLConnector:internal:UMLVisitor", ...
                    "Error %s(%s:%i) occured while importing a state machine named %s.",...
                    ME.identifier, ME.stack(1).name, ME.stack(1).line, element.name);
            end
        end

        function ret = visitumlmmUseCase(this, element)
            % Import any behaviors but still log the use case itself as not
            % imported.
            ret = [];

            visitChildren(this, element.ownedBehavior);

            addNotImported(this, element, "Use Case", ...
                               "Use Case import not supported.");
        end

        ret = visitumlmmComment(~,element);
    end    

end