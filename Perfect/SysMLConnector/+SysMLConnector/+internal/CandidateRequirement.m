classdef CandidateRequirement < SysMLConnector.internal.CandidateElement
% CANDIDATEREQUIREMENT Helper class for SysMLConnector.internal.import that holds candidate Requirements.
    properties
        ReqID
        Text
        Type % SysML requirement type (Requirement, FunctionalRequirement, etc).
        AdditionalProperties = [];
		ChildRequirements
    end
    
    methods
        function this = CandidateRequirement(extElemID, reqName, reqID, txt, ownID, type)
            this@SysMLConnector.internal.CandidateElement(extElemID);
            this.Name = reqName;
            this.ReqID = reqID;
            this.Text = txt;
            this.Type = type;
            
            this.OwnerExtElementID = ownID;
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
            if this.OwnerExtElementID ~= ""
                parReq = SysMLConnector.internal.CandidateElement.idMap(...
                    "lookup", this.OwnerExtElementID);
                parReq.ChildRequirements = [parReq.ChildRequirements this];
                this.Owner = parReq;
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
