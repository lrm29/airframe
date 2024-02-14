classdef CandidateReqLink < xmi.CandidateElement
% CANDIDATEREQLINK Helper class for xmi.import that holds candidate Requirement links.
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
        
        ZCHandle = [];
        
        DerivedID = 1;
    end
    
    methods
        function this = CandidateReqLink(extElemID, lType, ...
                                         suppID, clientID, ...
                                         suppMclass, clientMclass, ...
                                         suppStype, clientStype)
            this@xmi.CandidateElement(extElemID);
            this.LinkType = lType;
            this.SupplierExtElementID = suppID;
            this.ClientExtElementID = clientID;
        
            this.SupplierMetaClass = suppMclass;
            this.ClientMetaClass = clientMclass;
            
            this.SupplierStereotype = suppStype;
            this.ClientStereotype = clientStype;
        end
        
        function link(this)
            this.Supplier = xmi.CandidateElement.idMap(...
                "lookup", this.SupplierExtElementID);
            this.Client = xmi.CandidateElement.idMap(...
                "lookup", this.ClientExtElementID);
            
            isValid = true; % assume
            
            if isa(this.Supplier, "xmi.CandidateArchitecture")
                % If client is a requirement, make sure links to specializations
                if isa(this.Client, "xmi.CandidateRequirement")
                    for k = 1:length(this.Supplier.Specializations)
                        newLink = xmi.CandidateReqLink(...
                            this.ExtElementID + this.DerivedID, ...
                            this.LinkType, ...                            
                            this.Supplier.Specializations(k).ExtElementID, ...
                            this.ClientExtElementID, ...
                            this.SupplierMetaClass, this.ClientMetaClass, ...
                            this.SupplierStereotype, this.ClientStereotype);
                        newLink.link();
                        this.DerivedID = this.DerivedID + 1;
                    end
                end
            elseif ~isa(this.Supplier, "xmi.CandidateRequirement")
                isValid = false;
            end
            
            if isa(this.Client, "xmi.CandidateArchitecture")
                % If supp is a requirement, make sure links to specializations
                if isa(this.Supplier, "xmi.CandidateRequirement")
                    for k = 1:length(this.Client.Specializations)
                        newLink = xmi.CandidateReqLink(...
                            this.ExtElementID + this.DerivedID, ...
                            this.LinkType, ...
                            this.SupplierExtElementID, ...
                            this.Client.Specializations(k).ExtElementID, ...
                            this.SupplierMetaClass, this.ClientMetaClass, ...
                            this.SupplierStereotype, this.ClientStereotype);
                        newLink.link();
                        this.DerivedID = this.DerivedID + 1;
                    end
                end
                
                
            elseif ~isa(this.Client, "xmi.CandidateRequirement")
                isValid = false;
            end
            
            if ~isValid
                this.Valid = false;
                this.InvalidReason = ...
                    "Link between elements that are not in model or are unlinkable";
            else
                this.Valid = true;
            end
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
