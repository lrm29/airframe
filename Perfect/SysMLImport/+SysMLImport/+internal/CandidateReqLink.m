classdef CandidateReqLink < SysMLImport.internal.CandidateElement
% CANDIDATEREQLINK Helper class for SysMLImport.internal.import that holds candidate Requirement links.
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
        
        Valid = true;
        InvalidReason = "";
        
        ZCElement = [];
        
        DerivedID = 1;
    end
    
    methods
        function this = CandidateReqLink(extElemID, lType, ...
                                         suppID, clientID, ...
                                         suppMclass, clientMclass, ...
                                         suppStype, clientStype)
            this@SysMLImport.internal.CandidateElement(extElemID);
            this.LinkType = lType;
            this.SupplierExtElementID = suppID;
            this.ClientExtElementID = clientID;
        
            this.SupplierMetaClass = suppMclass;
            this.ClientMetaClass = clientMclass;
            
            this.SupplierStereotype = suppStype;
            this.ClientStereotype = clientStype;
        end
        
        function link(this)
            this.Supplier = SysMLImport.internal.CandidateElement.idMap(...
                "lookup", this.SupplierExtElementID);
            this.Client = SysMLImport.internal.CandidateElement.idMap(...
                "lookup", this.ClientExtElementID);
            
            this.Valid = false;

            

            try
                this.Valid = this.Client.ValidRequirementLinkTarget && this.Supplier.ValidRequirementLinkTarget;
            catch ME
                warning('SysMLImport:internal:CandidateReqLink:ValidityError', '%s:%s\n%s', this.ExtElementID, ME.identifier, getReport(ME));
            end

            if this.Valid
                try
                    % Link to specializations
                    for k = 1:length(this.Client.Specializations)
                        addDerivedLink(this.SupplierExtElementID, this.Client.Specializations(k).ExtElementID);
                    end
                catch ME
                    warning('SysMLImport:internal:CandidateReqLink:ClientSpecializationLinkError', '%s:%s\n%s', this.ExtElementID, ME.identifier, getReport(ME));
                end

                try
                    for k = 1:length(this.Supplier.Specializations)
                        addDerivedLink(this.Supplier.Specializations(k).ExtElementID, this.ClientExtElementID);
                    end
                catch ME
                    warning('SysMLImport:internal:CandidateReqLink:SupplierSpecializationLinkError', '%s:%s\n%s', this.ExtElementID, ME.identifier, getReport(ME));
                end
            else
                this.InvalidReason = ...
                    "Link between elements that are not in model or are unlinkable";
            end
        end

        function newLink = addDerivedLink(this, supplierID, clientID)
            % Create a link for the specialization and increment the
            % derived counter.
            newLink = SysMLImport.internal.CandidateReqLink(...
                this.ExtElementID + this.DerivedID, ...
                this.LinkType, ...                            
                supplierID, ...
                clientID, ...
                this.SupplierMetaClass, this.ClientMetaClass, ...
                this.SupplierStereotype, this.ClientStereotype);
            newLink.link();
            this.DerivedID = this.DerivedID + 1;
        end
                
        function print(this, printer)
            sName = ""; 
            cName = ""; 
            
            if ~isempty(this.Supplier)
                sName = this.Supplier.Name;
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
