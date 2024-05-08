classdef UMLVisitor < m3i.Visitor
%UMLVisitor Helper Visitor class for SysMLConnector.internal.import that scans UML model loaded from XMI file
    
    properties
        PackagesToIgnore = [];

        ProfilesFound = [];
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
                            
                        % Cache profile
                        thisProf = st.package;
                        pFound = false;
                        for pIdx = 1:length(this.ProfilesFound)
                            if this.ProfilesFound(pIdx) == thisProf
                                pFound = true;
                                break;
                            end
                        end
                        if ~pFound
                            this.ProfilesFound = [this.ProfilesFound thisProf];
                        end
                        
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
                if ~isa(property, 'umlmm.Port') && ...
                        ~isempty(property.type) && ...
                        this.isBlock(this.getSysMLStereotype(property.type))
                    cID = this.getExtID(property);
                    thisArch.addChildComponent(...
                        string(property.name), ...
                        cID, this.getExtID(property.type));
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
                    
                    thisArch.addParameter(property.name, elType, elTypeName, elDim, elValue);
                end
            end
            
            % Process child connectors
            visitChildren(this, element.ownedConnector, thisArch);    
            
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

            additionalProperties = properties(cStype)';
            additionalProperties = string(setdiff(additionalProperties, {'base_Class', 'base_ClassObject', 'Id', 'Text', 'propertyName', 'propertyValue'}));
            
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
            if ismember('propertyName', additionalProperties) && ismember('propertyValue', additionalProperties)
                for stereotypePropertyIdx = 1:cStype.propertyName.size
                    propertyName = cStype.propertyName.at(stereotypePropertyIdx);
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
                    
                    intf.addElement(string(pA.name), this.getExtID(pA), ...
                                    "unset", elTypeName, elType, elDim);
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
                            else
                                addNotImported(this, prop.type, "UnsupportedFlowType", ...
                                               "Interface flow property is not a primitive type or signal");
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
        
        function visitInterface(this, element)
            intf = SysMLConnector.internal.CandidateInterface(...
                string(element.name), this.getExtID(element), ...
                "INTERFACEBLOCK");
            %debugPrintInterface(this, element);
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
        end
         
        function ret = visitumlmmPort(this,element,thisArch)

            ret = [];
            
            % Process port type
            pType = element.type;
            pTypeStype = "";
            pTypeID = "";
            if ~isempty(pType)
                pTypeStype = this.getSysMLStereotype(pType);
                pTypeID = this.getExtID(pType);                
            end

            % Ensure port is a supported port type explicitly or implied
            pStrName = this.getSysMLStereotype(element);
            if pStrName ~= "SysML.ProxyPort" && pStrName ~= "SysML.FullPort" ...
                    && pStrName ~= "SysML.FlowPort"

                if this.isBlock(pTypeStype)
                    % Assume port is a Full Port when typed by a SysML
                    % Block
                    pStrName = "SysML.FullPort";
                elseif pTypeStype == "SysML.InterfaceBlock"
                    % Assume port is a Full Port when typed by a SysML
                    % Block
                    pStrName = "SysML.ProxyPort";
                else
                    % Unable to infer port type.
                    addNotImported(this, element, "Port", "Not a proxy port or full port");
                    return;
                end
            end
            
            if (pStrName == "SysML.FullPort") && (pTypeStype ~= "SysML.InterfaceBlock")
                % Create child component for Full Port
                cID = this.getExtID(element);
                thisArch.addChildComponent(...
                    string(element.name), ...
                    cID, pTypeID);
            else
                % Full Port typed by interface, Proxy Port, Flow Port
                isConj = false;
                if pStrName == "SysML.FlowPort"
                    [~,sType] = this.getSysMLStereotype(element);
                    sDir = sType.getOne('direction');
                    sDir = string(sDir.toString);
                    if strcmp(sDir, "out")
                        isConj = true;
                    end
                else
                    isConj = element.isConjugated;                    
                end

                if (pTypeStype ~= "SysML.InterfaceBlock")
                    % Incompatible port interface type.
                    pTypeID = "";
                end

                thisArch.addPort(string(element.name), isConj, ...
                                 this.getExtID(element), pTypeID, [], false);
            end
        end
        
        function ret = visitumlmmConnector(this,element,thisArch)
            
            cEnd1 = element.end.at(1);
            cEnd2 = element.end.at(2);
        
            cEnd1PID = "";
            cEnd2PID = "";
            if ~isempty(cEnd1.partWithPort)
                cEnd1PID = this.getExtID(cEnd1.partWithPort);
            end
            if ~isempty(cEnd2.partWithPort)
                cEnd2PID = this.getExtID(cEnd2.partWithPort);
            end
            
            p1Valid = true; % assume
            if isa(cEnd1.role, 'umlmm.Port') 
                pStrName = this.getSysMLStereotype(cEnd1.role);
                if pStrName ~= "SysML.ProxyPort" && pStrName ~= "SysML.FlowPort"
                    p1Valid = false;
                end
            else
                p1Valid = false;
            end
            p2Valid = true; % assume
            if isa(cEnd2.role, 'umlmm.Port') 
                pStrName = this.getSysMLStereotype(cEnd2.role);
                if pStrName ~= "SysML.ProxyPort" && pStrName ~= "SysML.FlowPort"
                    p2Valid = false;
                end
            else
                p2Valid = false;
            end
           
            if p1Valid && p2Valid && ...
                    this.isBlock(this.getSysMLStereotype(cEnd1.role.owner)) && ...
                    this.isBlock(this.getSysMLStereotype(cEnd2.role.owner))
                thisArch.addChildConnector(this.getExtID(element), ...
                                           cEnd1PID, this.getExtID(cEnd1.role), ...
                                           this.getExtID(cEnd1.role.owner), ...
                                           cEnd2PID, this.getExtID(cEnd2.role), ...
                                           this.getExtID(cEnd2.role.owner), false);
            
            else
                addNotImported(this, element, "Connector", ...
                               "Not connecting flow ports");        
            end
            ret = [];
        end

        function ret = visitumlmmActivity(this, element)
            ret = [];
            %fprintf('visited activity: %s\n', element.name);

            % uml:Activity -- Create candidate activity diagram
            ppID = SysMLConnector.internal.utils.getUMLPackageParentID(element);

            [CandidateAD, notImported] = SysMLConnector.internal.CandidateAD.buildCandidateAD(element);
            CandidateAD.ParentPackageExtElementID = ppID;
            this.NotImported = [this.NotImported notImported];

            visitChildren(this, element.ownedBehavior);
        end

        function newEnum = visitumlmmEnumeration(this, element)
            newEnum = visitEnumeration(this, element);
        end

        function ret = visitumlmmInteraction(this, element)
            % Import any behaviors but still log the sequence diagram
            % itself as not imported.
            ret = [];
            
            ppID = SysMLConnector.internal.utils.getUMLPackageParentID(element);

            [candidateInteraction, notImported] = SysMLConnector.internal.CandidateInteraction.buildCandidateInteraction(element);
            candidateInteraction.ParentPackageExtElementID = ppID;
            this.NotImported = [this.NotImported notImported];

            visitChildren(this, element.ownedBehavior);
        end

        function ret = visitumlmmUseCase(this, element)
            % Import any behaviors but still log the use case itself as not
            % imported.
            ret = [];

            visitChildren(this, element.ownedBehavior);

            addNotImported(this, element, "Use Case", ...
                               "Use Case import not supported.");
        end
    end    

end