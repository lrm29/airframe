classdef Element < xmi.CandidateElement & matlab.mixin.SetGetExactNames
    properties
        Name (1,:) char
        Parent
        Model
        ReferenceElementID
    end

    properties
        ZCElement
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
                NameValueArgs.Parent = [];
            end
            elementObj@xmi.CandidateElement(NameValueArgs.ExternalID);

            elementObj.Name = NameValueArgs.Name;
            elementObj.Parent = NameValueArgs.Parent;

            setModel(elementObj);
        end

        function referenceElement = get.ReferenceElement(this)
            referenceElement = [];
            if ~isempty(this.ReferenceElementID)
                referenceElement = xmi.CandidateElement.idMap(...
                                "lookup", this.ReferenceElementID);
            end
        end

        function elementType = get.ElementType(this)
            elementType = xmi.CandidateAD.internal.getClassName(this);
        end

        function qualifiedName = get.QualifiedName(this)
            if ~isempty(this.Parent)
                qualifiedName = [get(this.Parent, 'QualifiedName') '/' this.ZCElement.Name];
            else
                qualifiedName = this.ZCElement.Name;
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
            % Can be overriden during element construction.
            this.Model = this.Parent.Model;
        end

        function setZCName(this, newName)
            xmi.CandidateAD.internal.setName(this.ZCElement, newName);
        end

        function applyExternalUID(this)
            if ~isempty(this.ZCElement)
                this.ZCElement.ExternalUID = this.ExtElementID;
            end
        end
    end
    methods (Sealed)
        function print(this, printer)           
            prePrint(this, printer);

            doPrint(this, printer);

            postPrint(this, printer);
        end

        function publish(this, target)
            %fprintf('publishing: \n  %s\n  %s\n\n', class(this), this.getFullPath);

            if nargin < 2
                target = this.Parent;
            end

            this.ZCElement = [];
            
            prePublish(this, target);

            doPublish(this, target);

            % Tag the element with the xmi id:
            applyExternalUID(this);

            postPublish(this, target);
        end

        function fullPath = getFullPath(this)
            if isempty(this.Parent)
                fullPath = this.Name;
            else
                fullPath = [getFullPath(this.Parent) '<:>' this.Name];
            end
        end
    end
end