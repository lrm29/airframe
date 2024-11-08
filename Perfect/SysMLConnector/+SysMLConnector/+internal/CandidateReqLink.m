classdef CandidateReqLink < SysMLConnector.internal.CandidateElement
% CANDIDATEREQLINK Helper class for SysMLConnector.internal.import that holds candidate Requirement links.
    properties
        LinkType
        SupplierExtElementID
        ClientExtElementID

        SupplierMetaClass
        ClientMetaClass
        
        SupplierStereotype
        ClientStereotype
       
        Supplier = []
        Client = []
        
        Build = true; % assume it will be built by default.
        Valid = true;
        InvalidReason = "";
        
        DerivedID = 1;

        FullPath = "" % Cached XMI path for error reporting.
    end
    
    methods
        function this = CandidateReqLink(extElemID, lType, ...
                                         suppID, clientID, ...
                                         suppMclass, clientMclass, ...
                                         suppStype, clientStype, ...
                                         fullPath)
            this@SysMLConnector.internal.CandidateElement(extElemID);
            this.LinkType = lType;
            this.SupplierExtElementID = suppID;
            this.ClientExtElementID = clientID;
        
            this.SupplierMetaClass = suppMclass;
            this.ClientMetaClass = clientMclass;
            
            this.SupplierStereotype = suppStype;
            this.ClientStereotype = clientStype;

            this.FullPath = fullPath;
        end

        function newLink = addDerivedLink(this, supplierID, clientID)
            % Create a link for the specialization and increment the
            % derived counter.
            newLink = SysMLConnector.internal.CandidateReqLink(...
                this.ExtElementID + "_derived" + this.DerivedID, ...
                this.LinkType, ...                            
                supplierID, ...
                clientID, ...
                this.SupplierMetaClass, this.ClientMetaClass, ...
                this.SupplierStereotype, this.ClientStereotype, ...
                this.FullPath);
            newLink.link();
            this.DerivedID = this.DerivedID + 1;
        end

        function fullPath = getFullPath(this)
            if strcmp(this.FullPath, "")
                fullPath = this.ExtElementID;
            else
                fullPath = this.FullPath;
            end
        end

        function resolvedElement = resolveMultipleElements(~, elementID)
            resolvedElement = SysMLConnector.internal.CandidateElement.idMap(...
                "lookup", elementID);   

            % Add heuristic to figure out the correct link target since the
            % map look-up can return multiple elements after
            % generalizations have been merged in.
            if numel(resolvedElement) > 1
                if isa(resolvedElement, 'SysMLConnector.internal.CandidateArchitecture.CandidateComponent') && isscalar(unique([resolvedElement.ReferenceArchExtElementID]))
                    % If it resolves to an array of components and they all
                    % reference the same architecture, then return the
                    % architecture as the resolved element.
                    resolvedElement = resolvedElement(1).ReferenceArch;
                else
                    error('SysMLConnector:internal:CandidateReqLink:UnableToResolveElement', 'Unable to resolve element ''%s'' of type ''%s''.', elementID, class(resolvedElement));
                end
            end
        end
        
        function link(this)
            this.Valid = false; 

            try
                this.Supplier = resolveMultipleElements(this, this.SupplierExtElementID);         
            catch 
                warning('SysMLConnector:internal:CandidateReqLink:UnableToResolveSupplier', 'Unable to resolve supplier ''%s'' for link ''%s''.', this.SupplierExtElementID, this.ExtElementID);
            end

            try
                this.Client   = resolveMultipleElements(this, this.ClientExtElementID);         
            catch 
                warning('SysMLConnector:internal:CandidateReqLink:UnableToResolveClient', 'Unable to resolve client ''%s'' for link ''%s''.', this.ClientExtElementID, this.ExtElementID);
            end          

            try
                this.Valid = ~isempty(this.Client) && ~isempty(this.Supplier) && this.Client.ValidRequirementLinkTarget && this.Supplier.ValidRequirementLinkTarget;
            catch ME
                warning('SysMLConnector:internal:CandidateReqLink:ValidityError', '%s:%s\n%s', this.ExtElementID, ME.identifier, getReport(ME));
            end

            if this.Valid
                try
                    % Link to specializations
                    for k = 1:length(this.Client.Specializations)
                        addDerivedLink(this.SupplierExtElementID, this.Client.Specializations(k).ExtElementID);
                    end
                catch ME
                    warning('SysMLConnector:internal:CandidateReqLink:ClientSpecializationLinkError', '%s:%s\n%s', this.ExtElementID, ME.identifier, getReport(ME));
                end

                try
                    for k = 1:length(this.Supplier.Specializations)
                        addDerivedLink(this.Supplier.Specializations(k).ExtElementID, this.ClientExtElementID);
                    end
                catch ME
                    warning('SysMLConnector:internal:CandidateReqLink:SupplierSpecializationLinkError', '%s:%s\n%s', this.ExtElementID, ME.identifier, getReport(ME));
                end
            else
                this.InvalidReason = ...
                    "Link between elements that are not in model or are unlinkable";
            end
        end

                
        function print(this, printer)
            sName = ""; 
            cName = ""; 
            
            if ~isempty(this.Supplier)
                try
                    sName = this.Supplier.Name;
                catch
                    sName = '';
                end
            end
            
            if ~isempty(this.Client)
                try 
                    cName = this.Client.Name;
                catch
                    cName = '';
                end
            end

            printer.print("ReqLink: " + this.LinkType + "[Valid=" + ...
                          this.Valid + "," + this.InvalidReason + ...
                          "] [supp: " + this.SupplierStereotype + ":" + sName + "]" + ...
                          " [client: " + this.ClientStereotype + ":" + cName + "]");
        end
    end
end
