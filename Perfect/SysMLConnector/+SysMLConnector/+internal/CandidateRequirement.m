classdef CandidateRequirement < SysMLConnector.internal.CandidateElement
% CANDIDATEREQUIREMENT Helper class for SysMLConnector.internal.import that holds candidate Requirements.
    properties
        Name
        ReqID
        Text
        
        ReqOwnerExtElementID
        
        ChildRequirements
        ParentRequirement
        
        Type % SysML requirement type (Requirement, FunctionalRequirement, etc).
        ZCElement = [];
        AdditionalProperties = [];
    end
    
    methods
        function this = CandidateRequirement(extElemID, reqName, reqID, txt, ownID, type)
            this@SysMLConnector.internal.CandidateElement(extElemID);
            this.Name = reqName;
            this.ReqID = reqID;
            this.Text = txt;
            this.Type = type;
            
            this.ReqOwnerExtElementID = ownID;
            this.ValidRequirementLinkTarget = true;
        end

        function addAdditionalProperty(this, propName, propVal)
            if isempty(propVal)
                propVal = "";
            elseif ~ischar(propVal)
                propVal = propVal.toString;
            end
            
            propName = regexprep(propName, '[^0-9a-zA-Z]', '_');
            propStruct = this.AdditionalProperties;
            
            if ~isempty(propStruct)
                % Ensure unique property name in struct.
                propName = SysMLConnector.internal.utils.nextName(fieldnames(propStruct), propName);
            end

            propStruct.(propName) = propVal;
            this.AdditionalProperties = propStruct;
        end
        
        function link(this)
            if this.ReqOwnerExtElementID ~= ""
                parReq = SysMLConnector.internal.CandidateElement.idMap(...
                    "lookup", this.ReqOwnerExtElementID);
                parReq.ChildRequirements = [parReq.ChildRequirements this];
                this.ParentRequirement = parReq;
            end
        end
                
        function print(this, printer)
            printer.openScope("Req: " + this.ReqID  + " -- " + ...
                              this.Name);
            
            for k = 1:length(this.ChildRequirements)
                this.ChildRequirements(k).print(printer);
            end
            
            printer.closeScope("Req: " + this.ReqID);
        end
    end
end
