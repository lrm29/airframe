function export(inpModelSet, outXMIFileName, varargin)
% EXPORT Export a System Composer model into a XMI file
%     systemcomposer.SysMLImport.internal.export(INPMODELSET, OUTXMIFILENAME) creates an XMI
%     export for a set of System Composer input models. Only "root" architecture
%     models need to be specified and any associated referenced models are also
%     automatically exported. Associated interfaces are also exported into a 
%     separate package in the same XMI file.
%
%     Optional input parameters that may be specified as comma separated 
%     name-value pairs are:  
%
%     - 'UseExternalIDs': {false} | true
%       false - Do not use the ExternalUID property of the elements being exported
%       true  - Export the ExternalUID property of elements being exported as the
%               XMI ID of the corresponding object in the XMI file. This option
%               attempts to recreate the IDs of objects that were imported from
%               another tool using XMI import into System Composer.     
%
%     - 'MakeNestedInterfacesSignals': {false} | true
%       false - Keep nested interfaces as Interface Blocks
%       true  - Export nested interfaces as UML signals     
%
%     Current limitations:
%     - Profiles and stereotypes are not exported
%     - Views are not exported
%

    %% Parse input args
    defFeatureLevel = "";
    defUseExternalIDs = false;
    defMakeNestedSignals = false;
    ip = inputParser;
    addOptional(ip, 'UseExternalIDs', ...
                defUseExternalIDs, ...
                @islogical);
    
    addOptional(ip, 'FeatureLevel', ...
                defFeatureLevel, ...
                @(x) isstring(x) || ischar(x));

    addOptional(ip, 'MakeNestedInterfacesSignals', ...
                defMakeNestedSignals, ...
                @islogical);

    parse(ip, varargin{:});
    featureLevel = ip.Results.FeatureLevel;
    useExternalIDs = ip.Results.UseExternalIDs;
    makeNestedSignals = ip.Results.MakeNestedInterfacesSignals;
    
    %% Check feature control
    if ~(strcmp(featureLevel, "R2021a") || ...
         strcmp(featureLevel, "R2021b") || ...
         strcmp(featureLevel, "InternalTesting"))
        error(['This functionality is not available for general use. ', ...
               'Please contact MathWorks for access to this trial functionality.']);
    end

    if ~isa(inpModelSet, 'systemcomposer.arch.Model')
        error('Input must be a vector System Composer model handles.')
    end
    
    %% Create catalogs
    archToBlockMap = containers.Map;
    archToArchHdlMap = containers.Map;
    intfToIntfBlockMap = containers.Map;
    portToProxyPortMap = containers.Map;
    
    %% Read SysML profile
    f = M3I.XmiReaderFactory();
    s = M3I.XmiReaderSettings;
    s.ProcessTopLevelSettings=true;
    s.InputFormat = "MagicDraw";
    s.UseCurrentXMIUri = true;
    reader = f.createXmiReader(s);
    
    tmpDname = tempname;
    mkdir(tmpDname);
    startDir = cd(tmpDname);
    
    xmiLoc = string(fileparts(which('systemcomposer.SysMLImport.internal.import')));
    unzip(xmiLoc + filesep + "xmi" + filesep + "supportFiles.zip", tmpDname);
    sysmlMod = reader.read("SysML.xmi");
    sysmlprofile=sysmlMod.content.at(1);
    cd(startDir);
    rmdir(tmpDname, 's');
    
    %% Create base model
    m3im = umlmm.Factory.createNewModel();
    tr = M3I.Transaction(m3im);

    umlMdl = umlmm.Model(m3im);
    umlMdl.name = outXMIFileName;
    pf=umlmm.ProfileApplication(m3im);
    umlMdl.profileApplication.append(pf);
    pf.appliedProfile=sysmlprofile;
    
    m3im.content.append(umlMdl);
    
    umlBlkPkg = umlmm.Package(m3im);
    umlBlkPkg.name = 'Models';
    umlMdl.nestedPackage.push_back(umlBlkPkg);
    
    umlIntfPkg = umlmm.Package(m3im);
    umlIntfPkg.name = 'Interfaces';
    umlMdl.nestedPackage.push_back(umlIntfPkg);
    
    
    %% Cycle through all models
    % Visit Architectures and create Blocks. Add flow ports to Blocks and interface blocks to ports
    
    allArchMdlsToVisit = inpModelSet;
    allArchMdlsVisited = containers.Map;
    m3iIDtoExtIDMap = containers.Map;
    
    nVisited = 1;
    while nVisited <= length(allArchMdlsToVisit)
        if ~isKey(allArchMdlsVisited, allArchMdlsToVisit(nVisited).Name)
            [childArchMdls, archToBlockMap, archToArchHdlMap, portToProxyPortMap, ...
             intfToIntfBlockMap, m3iIDtoExtIDMap] = ...
                visitArchForBuild(allArchMdlsToVisit(nVisited).Architecture, [], ...
                                  archToBlockMap, archToArchHdlMap, portToProxyPortMap, ...
                                  intfToIntfBlockMap, ...
                                  m3im, umlBlkPkg, umlIntfPkg, m3iIDtoExtIDMap, useExternalIDs, makeNestedSignals);
            allArchMdlsVisited(allArchMdlsToVisit(nVisited).Name) = true;
            
            allArchMdlsToVisit = [allArchMdlsToVisit childArchMdls]; %#ok<AGROW>
        end
        
        nVisited = nVisited + 1;
    end
    
    
    %% Visit Components/Connectors in Architectures and create 
    %% attributes/connectors on corresponding classes
    allArchs = archToBlockMap.keys;
    for k = 1:length(allArchs)
        m3iIDtoExtIDMap = finalizeArch(archToArchHdlMap(allArchs{k}), archToBlockMap, ...
                                       portToProxyPortMap, m3im, m3iIDtoExtIDMap, ...
                                       useExternalIDs);
    end
        
    %% End build
    tr.commit;
    
    %% Write file
    
    % Setup writer settings
    s = M3I.XmiWriterSettings();
    s.MultiPackageMetaModel = false;
    s.UseURI = true;
    if useExternalIDs
        s.UseExternalId = true;
        s.OutputFormat = 'MagicDraw';
    end
    
    %  Write to file
    outXMIFileNameC = string(outXMIFileName);

    f = M3I.XmiWriterFactory();
    w = f.createXmiWriter(s);
    w.setPreferredUriForPrefix('sysml',"http://www.omg.org/spec/SysML/20150709/SysML")
    w.write(outXMIFileNameC + ".xml", m3im);
    
end

function m3iIDtoExtIDMap = cacheExtID(elem, m3iElem, m3iIDtoExtIDMap, useExternalIDs)
    if useExternalIDs && ~isempty(elem.ExternalUID)
        m3iElem.setExternalToolInfo(M3I.ExternalToolInfo('MagicDraw',elem.ExternalUID));
        m3iElem.externalId = char(elem.UUID);
    end
    
    if ~isempty(elem.ExternalUID)
        m3id = m3iElem.toString;
        m3id = m3id(2:end); m3id = m3id(1:end-1);
        elID = "_m3i_" + string(m3id);
        m3iIDtoExtIDMap(elID) = string(elem.ExternalUID);
    end
end

function [childArchMdls, archToBlockMap, archToArchHdlMap, portToProxyPortMap, ...
          intfToIntfBlockMap,m3iIDtoExtIDMap] = visitArchForBuild(...
    arch, childArchMdls, ...
    archToBlockMap, archToArchHdlMap, ...
    portToProxyPortMap, intfToIntfBlockMap, ...
    m3im, umlBlkPkg, umlIntfPkg, m3iIDtoExtIDMap, ...
    useExternalIDs, origProcessAsSignal)
    
% Visit Architecture to build for first time

    %% Create class for Architecture
    umlClass = umlmm.Class(m3im);
    umlClass.name = arch.Name;
    blkST = SysML.Block(m3im);
    umlClass.appliedStereotypeInstance.push_back(blkST);

    m3iIDtoExtIDMap = cacheExtID(arch, umlClass, m3iIDtoExtIDMap, useExternalIDs);

    umlBlkPkg.packagedElement.push_back(umlClass);
    
    archPorts = arch.Ports;
    for k = 1:length(archPorts)
        umlPort = umlmm.Port(m3im);
        umlPort.name = archPorts(k).Name;
        m3iIDtoExtIDMap = cacheExtID(archPorts(k), umlPort, m3iIDtoExtIDMap, useExternalIDs);
        
        portST = SysML.ProxyPort(m3im);
        umlPort.appliedStereotypeInstance.push_back(portST);

        if archPorts(k).Direction == systemcomposer.arch.PortDirection.Output
            umlPort.isConjugated = true;
        end
        
        intf = archPorts(k).Interface;
        if ~isempty(intf)
            [umlIntf, umlIntfPkg, intfToIntfBlockMap, m3iIDtoExtIDMap, m3im] = ...
                ProcessInterface(intf, m3im, umlIntfPkg, intfToIntfBlockMap, m3iIDtoExtIDMap, useExternalIDs, false, origProcessAsSignal);
            umlPort.type = umlIntf;
        end
        umlClass.ownedPort.push_back(umlPort);
        assert(~isKey(portToProxyPortMap, getUUID(archPorts(k))));
        portToProxyPortMap(getUUID(archPorts(k))) = umlPort;
    end
    
    assert(~isKey(archToBlockMap, getUUID(arch)));
    archToBlockMap(getUUID(arch)) = umlClass;
    archToArchHdlMap(getUUID(arch)) = arch;

    %% Visit child components
    cComps = arch.Components;
    for k = 1:length(cComps)
        comp = cComps(k);
        compArch = comp.Architecture;
        if ~comp.isReference() || ...
                compArch.Definition == systemcomposer.arch.ArchitectureDefinition.Behavior
            [childArchMdls, archToBlockMap, archToArchHdlMap, portToProxyPortMap, ...
             intfToIntfBlockMap, m3iIDtoExtIDMap] = ...
                visitArchForBuild(compArch, childArchMdls, ...
                                  archToBlockMap, archToArchHdlMap, ...
                                  portToProxyPortMap, intfToIntfBlockMap, m3im, ...
                                  umlBlkPkg, umlIntfPkg, m3iIDtoExtIDMap, ...
                                  useExternalIDs, origProcessAsSignal);
        else
            childArchMdls = [childArchMdls, compArch.Model]; %#ok<AGROW>
        end
    end
    
end

function uid = getUUID(element)
% UUIDs are not unique across models and need to be uniquified with
% model name.
    if isa(element, 'systemcomposer.arch.Architecture') || ...
            isa(element, 'systemcomposer.arch.BasePort') || ...
            isa(element, 'systemcomposer.arch.Connector')
        uid = string(element.Model.Name) + "_" + string(element.UUID);
    elseif isa(element, 'systemcomposer.interface.DataInterface')
        uid = string(element.Owner.UUID) + "_" + string(element.UUID);        
    elseif isa(element, 'systemcomposer.ValueType')
        uid = string(element.Owner.UUID) + "_" + string(element.UUID);        
    else
        error("Unhandled model element for export of type: " + class(element));
    end
end


function [umlIntf, umlIntfPkg, intfToIntfBlockMap, m3iIDtoExtIDMap, m3im] = ...
    ProcessInterface(intf, m3im, umlIntfPkg, intfToIntfBlockMap, m3iIDtoExtIDMap, useExternalIDs, processAsSignal, origProcessAsSignal)

    if isKey(intfToIntfBlockMap, getUUID(intf))
        umlIntf = intfToIntfBlockMap(getUUID(intf));
    else
        createdSignal = false;
        if isa(intf, 'systemcomposer.ValueType') || processAsSignal
            umlIntf = umlmm.Signal(m3im);
            umlIntf.name = intf.Name;
            createdSignal = true;
        else
            umlIntf = umlmm.Class(m3im);
            umlIntf.name = intf.Name;
            intfST = SysML.InterfaceBlock(m3im);
            umlIntf.appliedStereotypeInstance.push_back(intfST);
        end
        m3iIDtoExtIDMap = cacheExtID(intf, umlIntf, m3iIDtoExtIDMap, useExternalIDs);
        
        if ~isa(intf, 'systemcomposer.interface.DataInterface') || isempty(intf.Elements)
            % For empty and non-data interfaces insert one element to anchor direction
            umlProp = umlmm.Property(m3im);
            umlProp.name = 'elem0';                    
            umlProp.visibility = umlmm.VisibilityKind.Public;
            umlProp.aggregation = umlmm.AggregationKind.Composite;

            if ~createdSignal
                propST = SysML.FlowProperty(m3im);
                propST.direction = SysML.FlowDirection.In;
                umlProp.appliedStereotypeInstance.push_back(propST);
            end
            umlIntf.ownedAttribute.push_back(umlProp);
        else
            intfEl = intf.Elements;
            for m = 1:length(intfEl)
                umlProp = umlmm.Property(m3im);
                umlProp.name = intfEl(m).Name;
                m3iIDtoExtIDMap = cacheExtID(...
                    intfEl(m), umlProp, m3iIDtoExtIDMap, useExternalIDs);
                umlProp.visibility = umlmm.VisibilityKind.Public;
                umlProp.aggregation = umlmm.AggregationKind.Composite;
        
                if ~processAsSignal
                    propST = SysML.FlowProperty(m3im);
                    propST.direction = SysML.FlowDirection.In;
                    umlProp.appliedStereotypeInstance.push_back(propST);
                end
                
                if isa(intfEl(m).Type, 'systemcomposer.interface.DataInterface')
                    [umlElIntf, umlIntfPkg, intfToIntfBlockMap, m3iIDtoExtIDMap, m3im] = ...
                        ProcessInterface(intfEl(m).Type, m3im, umlIntfPkg, intfToIntfBlockMap, m3iIDtoExtIDMap, useExternalIDs, origProcessAsSignal, origProcessAsSignal);
                    umlProp.type = umlElIntf;
                elseif isa(intfEl(m).Type, 'systemcomposer.ValueType')
                    dt = umlmm.DataType(m3im);
                    dt.name = intfEl(m).Type.DataType;
                    umlIntfPkg.packagedElement.push_back(dt);
                    umlProp.type = dt;
                else
                    warning(['Type of interface element ''' intfEl(m).Name ''' in interface ''' intf.Name ''' being ignored.']);
                end
                
                umlIntf.ownedAttribute.push_back(umlProp);
            end

        end
        umlIntfPkg.packagedElement.push_back(umlIntf);
        intfToIntfBlockMap(getUUID(intf)) = umlIntf;
    end
end

function m3iIDtoExtIDMap = finalizeArch(arch, archToBlockMap, portToProxyPortMap, ...
                                        m3im, m3iIDtoExtIDMap, useExternalIDs)
    umlClass = archToBlockMap(getUUID(arch));
    
    compNameToPropMap = containers.Map;
    
    %% Visit child components
    cComps = arch.Components;
    for k = 1:length(cComps)
        comp = cComps(k);
        compArch = comp.Architecture;
        compArchUmlClass = archToBlockMap(getUUID(compArch));
        
        umlProp = umlmm.Property(m3im);
        umlProp.name = comp.Name;
        umlProp.type = compArchUmlClass;
        umlProp.visibility = umlmm.VisibilityKind.Public;
        umlProp.aggregation = umlmm.AggregationKind.Composite;
        
        umlClass.ownedAttribute.push_back(umlProp);
        compNameToPropMap(comp.Name) = umlProp;
        m3iIDtoExtIDMap = cacheExtID(comp, umlProp, m3iIDtoExtIDMap, useExternalIDs);
    end

    %% Visit connectors
    cConns = arch.Connectors;
    for k = 1:length(cConns)
        thisConn = cConns(k);
        srcPort = thisConn.SourcePort;
        dstPort = thisConn.DestinationPort;
        
        umlConn = umlmm.Connector(m3im);
        m3iIDtoExtIDMap = cacheExtID(thisConn, umlConn, m3iIDtoExtIDMap, useExternalIDs);

        umlConnEnd1 = umlmm.ConnectorEnd(m3im);
        
        umlConnEnd2 = umlmm.ConnectorEnd(m3im);
        
        if isa(srcPort, 'systemcomposer.arch.ComponentPort')
            umlConnEnd1.partWithPort = compNameToPropMap(...
                srcPort.Parent.Name);
            srcRole = srcPort.ArchitecturePort;
        else
            srcRole = srcPort;
        end
        
        if isa(dstPort, 'systemcomposer.arch.ComponentPort')
            umlConnEnd2.partWithPort = compNameToPropMap(...
                dstPort.Parent.Name);
            dstRole = dstPort.ArchitecturePort;
        else
            dstRole = dstPort;
        end
        
        umlConnEnd1.role = portToProxyPortMap(getUUID(srcRole));
        umlConnEnd2.role = portToProxyPortMap(getUUID(dstRole));
        
        endST = SysML.NestedConnectorEnd(m3im);
        if ~isempty(umlConnEnd1.partWithPort)
            endST.propertyPath.push_back(umlConnEnd1.partWithPort);
        end
        umlConnEnd1.appliedStereotypeInstance.push_back(endST);
        endST = SysML.NestedConnectorEnd(m3im);
        if ~isempty(umlConnEnd2.partWithPort)
            endST.propertyPath.push_back(umlConnEnd2.partWithPort);
        end
        umlConnEnd2.appliedStereotypeInstance.push_back(endST);

        umlConn.end.push_back(umlConnEnd1);
        umlConn.end.push_back(umlConnEnd2);
        umlClass.ownedConnector.push_back(umlConn);
    end
    
end
