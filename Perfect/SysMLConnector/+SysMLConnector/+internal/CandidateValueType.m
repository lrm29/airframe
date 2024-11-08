classdef CandidateValueType < SysMLConnector.internal.CandidateElement
% CANDIDATEVALUETYPE Helper class for SysMLConnector.internal.import that holds candidate interface objects.
    properties
        TypeName = '';
        Type;
        Dim;

        Valid = true
        InvalidReason = "";
    end
    
    methods
        function this = CandidateValueType(name, extID)
            this@SysMLConnector.internal.CandidateElement(extID);
            this.Name = name;
            this.ValidRequirementLinkTarget = true;
        end

        function linkTarget = getLinkTarget(this)
            linkTarget = SysMLConnector.internal.utils.getInterfaceLinkTarget(this.Interface);            
        end

        function tf = doBuild(this)
            tf = true;

            if contains(this.TypeName, "Bus:")
                % Value types do not support nested types.
                tf = false;
                this.InvalidReason = 'Value Types do not support nested data types.';
            end

            this.Valid = tf;
        end

        function buildZCInterface(this, builder)
            if isempty(this.BuiltElement)
                intf = builder.createValueType(this.ExtElementID, this.BuildName);

                this.BuiltElement = intf;
                intf.ExternalUID = this.ExtElementID;

                builder.setDataType(this);
            end
        end
        
        function print(this, printer)
            pStr = this.Name + ": ";
            pStr = pStr + ...
                   "[" + this.Direction + "]" + ...
                   "[" + this.TypeName + "]";
            printer.print("   ValueType =  " + pStr);
        end
    end
end
