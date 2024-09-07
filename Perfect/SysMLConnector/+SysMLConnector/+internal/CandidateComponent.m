classdef CandidateComponent < SysMLConnector.internal.CandidateElement
    properties
        Name = "";
        ParentArchitecture;
        
        DeferredParentArchitecture;

        ReferenceArchExtElementID = ""
        
        ReferenceArch = [];
        
        PortMapFromArchElementID = [];
        
        IsInliningItsArch = false;
        
        Valid = true;
        InvalidReason = "";
        Build = true;
        
        ZCElement = [];
    end

    properties (Dependent)
        BuildName
    end
    
    methods
        function this = CandidateComponent(name, parArch, extID, refCompID)
            this@SysMLConnector.internal.CandidateElement(extID);
            this.Name = name;
            this.ReferenceArchExtElementID = refCompID;
            this.ParentArchitecture = parArch;
            this.ValidRequirementLinkTarget = true;
        end

        function name = get.BuildName(this)
            % No restrictions on component names so it is used directly.
            name = this.Name;
        end
        
        function addConnector(this, refArchPort, conn)
            refArchPortID = refArchPort.ExtElementID;
            if isempty(this.PortMapFromArchElementID)
                this.PortMapFromArchElementID = containers.Map;
            end
            
            % Port map is stored indexed by the underlying Arch port's ID because
            % the component port themselves have no external ID
            if ~isKey(this.PortMapFromArchElementID, refArchPortID)
                thisPortInfo.RefArchPort = refArchPort;
                thisPortInfo.Connectors = conn;
                this.PortMapFromArchElementID(refArchPortID) = thisPortInfo;
            else
                thisPortInfo = this.PortMapFromArchElementID(refArchPortID);
                thisPortInfo.Connectors = [thisPortInfo.Connectors conn];
                this.PortMapFromArchElementID(refArchPortID) = thisPortInfo;
            end
        end
        
        function fixFanInConnectors(this)
            if ~isempty(this.PortMapFromArchElementID)
                pInfo = this.PortMapFromArchElementID.values;
                for k = 1:length(pInfo)
                    thisInfo = pInfo{k};
                    if thisInfo.RefArchPort.ComputedDir == "in" && ...
                            length(thisInfo.Connectors) > 1
                        conn = thisInfo.Connectors;
                        validConn = [];
                        for m = 1:length(conn)
                            if conn(m).Valid && ~conn(m).Replaced
                                validConn = [validConn conn(m)]; %#ok<AGROW>
                            end
                        end
                        
                        % Multiple fan in connectors
                        if length(validConn) > 1
                            % Synthesize an Adapter Component
                            this.ParentArchitecture.addAdapter(...
                                validConn, this, thisInfo.RefArchPort);
                        end
                    end
                end
            end
        end

        function fullPath = getFullPath(this)
            fullPath = this.ParentArchitecture.getPostLinkFullPath() + "/" + this.Name;
        end
        
        function setInvalid(this, reason)
            this.Valid = false;
            this.Build = false;
            this.InvalidReason = reason;
        end
        
        
        function print(this, printer)
            if this.Name == ""
                cName = "<None>";
            else
                cName = this.Name;
            end

            if ~isempty(this.ReferenceArch)
                referenceArchPath = this.ReferenceArch.getPostLinkFullPath();
            else
                referenceArchPath = "";
            end
            
            printer.print("Component: " + cName + ...
                          " [Valid = " + this.Valid + "] [" + ...
                          referenceArchPath + "]");

            if ~isempty(this.ReferenceArch) && this.IsInliningItsArch
                printer.openScope("");
                printer.openScope("InlineArch: " + this.ReferenceArch.Name);
                this.ReferenceArch.print(printer);
                printer.closeScope("InlineArch: " + this.ReferenceArch.Name);
                printer.closeScope("");
            end
        end
    end
end
