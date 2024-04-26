classdef CandidateElement < handle
% CANDIDATEELEMENT Base class of all candidate model elements
    properties
        ExtElementID

        Generalizations = [];
        Specializations = [];

        StereotypesExtIDs = [];
        StereotypePropVals = [];

        ValidRequirementLinkTarget = false; % This should be set to true by any constructs that support requirement linking.
    end
    
    properties (Dependent)
        LinkTarget
    end
    
    methods (Static)
        function varargout = idMap(idFun, varargin)
            persistent idMap
            if isempty(idMap)
                idMap = containers.Map;
            end
            if idFun == "add"
                elID = varargin{1};
                elem = varargin{2};

                if ~isKey(idMap, elID)
                    idMap(elID) = elem;
                else
                    % Can happen when generalizations are merged
                    cVal = idMap(elID);
                    cVal = [cVal, elem];
                    idMap(elID) = cVal;
                end
                
                varargout = {};
            elseif idFun == "lookup"
                elem = [];
                elID = varargin{1};
                
                if isKey(idMap, elID)
                    elem = idMap(elID);
                end
                
                varargout = {elem};
            elseif idFun == "reset"
                idMap = containers.Map;
                varargout = {};
            elseif idFun == "getElems"
                cls = varargin{1};
                elems = idMap.values;
                elems = elems(cellfun(@(x) isa(x, cls), elems));
                varargout = {elems};
            elseif idFun == "getAll"
                varargout = {idMap};
            else
                error("Unknown option to idMap");
            end
        end
        
    end
    
    methods
        function this = CandidateElement(extElemID, options)
            arguments
                extElemID
                options.ValidRequirementLinkTarget = false
            end

            this.ExtElementID = extElemID;
            this.ValidRequirementLinkTarget = options.ValidRequirementLinkTarget;
            SysMLConnector.internal.CandidateElement.idMap(...
                "add", extElemID, this);
        end

        function linkTarget = get.LinkTarget(this)
            linkTarget = getLinkTarget(this);
        end
        
        function linkTarget = getLinkTarget(this)
            % Stub to be populated by the candidates for their own link
            % targets.
            try
                linkTarget = this.ZCElement.SimulinkHandle; %#ok<MCNPN>
            catch
                try
                    linkTarget = this.ZCElement; %#ok<MCNPN>
                catch
                    error('SysMLConnector:internal:CandidateElement:InvalidLinkTarget', 'Missing link target for ''%s'' with ID ''%s''.', class(this), this.ExtElementID);
                end
            end
        end

        function st = addStereotype(this, st)
            this.StereotypesExtIDs = [this.StereotypesExtIDs st];
        end

        function pVal = addStereotypePropVal(this, stype, prop, propType, val)
            pVal.Stereotype = stype;
            pVal.PropertyName = prop;
            pVal.Type = propType;
            pVal.Value = val;
            this.StereotypePropVals = [this.StereotypePropVals pVal];
        end
    end
end
