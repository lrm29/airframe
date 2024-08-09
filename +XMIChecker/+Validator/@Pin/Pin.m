classdef Pin < XMIChecker.Validator.CandidateAD.Element
    %PIN validator for Pins
    
    methods
        function obj = Pin(candidate,xmidb,foundElements)
            %PIN Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.Pin
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            obj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
            % check token type
            if candidate.TokenType == ...
                    systemcomposer.activitydiagram.model.TokenType.CONTROL ...
                    && candidate.Built
                % if control expect it not to be built so invert result
                temp.fail = obj.fail;
                temp.pass = obj.pass;
                obj.fail = temp.pass;
                obj.pass = temp.fail;
            end
            % else use default result
        end

    end
end

