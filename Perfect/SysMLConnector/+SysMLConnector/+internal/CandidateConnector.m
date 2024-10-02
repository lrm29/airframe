classdef CandidateConnector < SysMLConnector.internal.CandidateElement
% CANDIDATECONNECTOR Helper class for SysMLConnector.internal.import that holds candidate Connector objects.
    properties
        ParentComp
        
        End1CompExtElementID
        End1RefPortExtElementID
        End1RefPortArchExtElementID
        
        End2CompExtElementID
        End2RefPortArchExtElementID
        End2RefPortExtElementID
        
        End1Comp = []
        End2Comp = []
        
        End1APort = []
        End2APort = []
        
        End1RefArch = []
        End2RefArch = []
        
        Valid = true;
        InvalidReason = "";

        EndsChecked = false;
        Replaced = false;
        Replacements = [];
        
        Derived = false;
    end

    properties (Dependent)
        ParentPackageExtElementID
    end
    
    methods
        function this = CandidateConnector(parComp, extID, end1CompID, end1RefPortID, ...
                                           end1RefPortArchID, ...
                                           end2CompID, end2RefPortID, end2RefPortArchID, isDerived)
            this@SysMLConnector.internal.CandidateElement(extID);
            this.ParentComp   = parComp;
            
            this.End1CompExtElementID = end1CompID;
            this.End1RefPortExtElementID = end1RefPortID;
            this.End1RefPortArchExtElementID = end1RefPortArchID;
            
            this.End2CompExtElementID = end2CompID;
            this.End2RefPortExtElementID = end2RefPortID;
            this.End2RefPortArchExtElementID = end2RefPortArchID;
            
            this.Derived = isDerived;
        end

        function elementID = get.ParentPackageExtElementID(this)
            try
                elementID = this.ParentComp.ParentPackageExtElementID;
            catch
                elementID = [];
            end
        end

        function fullPath = getFullPath(this)
            fullPath = this.ParentComp.getFullPath + "/";
        end
        
        function notImported = setEndComps(this, end1P, end1C, end1RC, end2P, end2C, end2RC)
            notImported = [];

            this.End1APort = end1P;
            this.End1Comp = end1C;
            this.End1RefArch = end1RC;

            this.End2APort = end2P;
            this.End2Comp = end2C;
            this.End2RefArch = end2RC;
            
            if ~this.End1APort.Valid || ~this.End2APort.Valid
                notImported = this.setInvalid("End port(s) not valid");
            end

            if (~isempty(this.End1Comp) && ~this.End1Comp.Valid) || ...
                    (~isempty(this.End2Comp) && ~this.End2Comp.Valid)
                notImported = this.setInvalid("End components not valid");
            end

            if ~isempty(notImported)
                message = sprintf('%s for connector ''%s''.', notImported.Reason, this.ExtElementID);
                SysMLConnector.internal.StatusMonitor.publishEvent('setEndComps', 'Connectors', message);
            end
        end
        
        
        function thisNotImported = setInvalid(this, invalidReason)
            thisNotImported = this.createNotImported('Connector', invalidReason);

            this.Valid = false;
            this.InvalidReason = invalidReason;
        end
        
        function setReplacements(this, replacements)
            this.Replaced = true;
            this.Replacements = replacements;            
        end
        
        function validate(this)
            if this.Valid && ~this.Replaced
                end1TypeIsArchPort = isempty(this.End1Comp);
                end2TypeIsArchPort = isempty(this.End2Comp);
                end1Dir = this.End1APort.ComputedDir;
                end2Dir = this.End2APort.ComputedDir;
                
                % Must be called only after all other validation done
                assert(end1Dir == "in" || end1Dir == "out");
                assert(end2Dir == "in" || end2Dir == "out");
                inv = false; % assume
                if end1TypeIsArchPort && end1Dir == "in"
                    if end2TypeIsArchPort
                        if end2Dir ~= "out"
                            inv = true;
                        end
                    elseif end2Dir ~= "in"
                        inv = true;                        
                    end
                elseif end1TypeIsArchPort && end1Dir == "out" 
                    if end2TypeIsArchPort
                        if end2Dir ~= "in"
                            inv = true;
                        end
                    elseif end2Dir ~= "out"
                        inv = true;                        
                    end
                elseif end1Dir == "in"
                    if end2TypeIsArchPort
                        if end2Dir ~= "in"
                            inv = true;
                        end
                    elseif end2Dir ~= "out"
                        inv = true;                        
                    end
                else
                    assert(end1Dir == "out");
                    if end2TypeIsArchPort
                        if end2Dir ~= "out"
                            inv = true;
                        end
                    elseif end2Dir ~= "in"
                        inv = true;                        
                    end
                end
                if inv
                    notImported = this.setInvalid("Ports not complements");
                    message = sprintf('%s for connector ''%s''.', notImported.Reason, this.ExtElementID);
                    SysMLConnector.internal.StatusMonitor.publishEvent('ValidateConnector', 'Connectors', message);
                end
            end
        end
        
        
        function print(this, printer)
            if isempty(this.End1Comp)
                if ~isempty(this.End1RefArch)
                    e1Pname = "[Aport]." + this.End1RefArch.getPortName(this.End1RefPortExtElementID);
                else
                    % The ports cannot be connected, probably because of
                    % incompatible directions.
                    port = SysMLConnector.internal.CandidateElement.idMap("lookup", this.End1RefPortExtElementID);
                    e1Pname = "[Aport]." + port.BuildName;
                end
            else
                if ~isempty(this.End1Comp.ReferenceArch)
                    refArchName = this.End1Comp.ReferenceArch.Name;
                else
                    refArchName = "";
                end

                e1Pname = "[" + this.End1Comp.Name + "]" + "<" + ...
                          refArchName + ">." + ...
                          this.End1RefArch.getPortName(this.End1RefPortExtElementID);
            end

            if isempty(this.End2Comp)
                if ~isempty(this.End2RefArch)
                    e2Pname = "[Aport]." + this.End2RefArch.getPortName(this.End2RefPortExtElementID);
                else
                    % The ports cannot be connected, probably because of
                    % incompatible directions.
                    port = SysMLConnector.internal.CandidateElement.idMap("lookup", this.End2RefPortExtElementID);
                    e2Pname = sprintf("[Aport].%s ", port.BuildName);
                end
            else
                if ~isempty(this.End2Comp.ReferenceArch)
                    refArchName = this.End2Comp.ReferenceArch.Name;
                else
                    refArchName = "";
                end

                e2Pname = "[" + this.End2Comp.Name + "]" + "<" + ...
                          refArchName + ">." + ...
                          this.End2RefArch.getPortName(this.End2RefPortExtElementID);
            end
            
            printer.print("Connector: [Valid=" + this.Valid + " " + ... 
                          this.InvalidReason + "] " + ...
                          "[Replaced=" + this.Replaced + "]" + ...
                          "[Derived=" + this.Derived + "]" + ...
                          e1Pname + " <-> " + e2Pname);
        end
    end
end
