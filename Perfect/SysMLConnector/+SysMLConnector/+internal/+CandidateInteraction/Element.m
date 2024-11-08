classdef Element < SysMLConnector.internal.CandidateElement & ...
        matlab.mixin.SetGetExactNames & ...
        SysMLConnector.internal.utils.Printable
   
    properties
        Model
        ReferenceElementID
    end

    properties (Dependent)
        QualifiedName
        ElementType
        ReferenceElement
    end
    
    methods
        function elementObj = Element(NameValueArgs)
            arguments
                NameValueArgs.Name
                NameValueArgs.ExternalID
                NameValueArgs.Owner = [];
            end
            elementObj@SysMLConnector.internal.CandidateElement(NameValueArgs.ExternalID);

            elementObj.Name = NameValueArgs.Name;
            elementObj.Owner = NameValueArgs.Owner;
            elementObj.ValidRequirementLinkTarget = true;

            setModel(elementObj);

            % update print exclusions
            elementObj.ExcludedProperties = [elementObj.ExcludedProperties,...
                "Model"];
        end

        function referenceElement = get.ReferenceElement(this)
            referenceElement = [];
            if ~isempty(this.ReferenceElementID)
                referenceElement = SysMLConnector.internal.CandidateElement.idMap(...
                                "lookup", this.ReferenceElementID);
            end
        end

        function elementType = get.ElementType(this)
            elementType = SysMLConnector.internal.utils.getClassName(this);
        end

        function qualifiedName = get.QualifiedName(this)
            if ~isempty(this.Owner)
                qualifiedName = [get(this.Owner, 'QualifiedName') '/' this.BuiltElement.Name];
            else
                qualifiedName = this.BuiltElement.Name;
            end
        end

        function doPublish(this, target) %#ok<INUSD>

        end

        function prePublish(this, target) %#ok<INUSD>

        end

        function postPublish(this, target) %#ok<INUSD>

        end

        function prePrint(this, printer)
            printer.openScope(string(this.ElementType) + ": " + this.Name);
        end

        function doPrint(this, printer) %#ok<INUSD>
        end

        function postPrint(this, printer)
            printer.closeScope(string(this.ElementType) + ": " + this.Name);
        end

        function setModel(this)
            % Can be overridden during element construction.
            this.Model = this.Owner.Model;
        end

        function setZCName(this, newName)
            SysMLConnector.internal.CandidateAD.internal.setName(this.BuiltElement, newName);
        end

        function applyExternalUID(this)
            if ~isempty(this.BuiltElement)
                this.BuiltElement.ExternalUID = this.ExtElementID;
            end
        end
    end
    methods (Sealed)
        function publish(this, target)
            %fprintf('publishing: \n  %s\n  %s\n\n', class(this), this.getFullPath);

            if nargin < 2
                target = this.Owner;
            end

            this.BuiltElement = [];
            
            prePublish(this, target);

            doPublish(this, target);

            % Tag the element with the xmi id:
            applyExternalUID(this);

            postPublish(this, target);
        end

        function fullPath = getFullPath(this)
            if isempty(this.Owner)
                fullPath = this.Name;
            else
                fullPath = [getFullPath(this.Owner) '<:>' this.Name];
            end
        end
    end
end