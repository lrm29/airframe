classdef Element < SysMLConnector.internal.CandidateElement & ...
        matlab.mixin.SetGetExactNames & ...
        SysMLConnector.internal.CandidateComment.Commentable
    properties
        Model
        ExternalID (1,:) char
    end

    properties (Dependent)
        QualifiedName
        ElementType
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
            elementObj.ExternalID = NameValueArgs.ExternalID;
            elementObj.Owner = NameValueArgs.Owner;

            setModel(elementObj);
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

        function linkTarget = getLinkTarget(this)
            linkTarget = SysMLConnector.internal.CandidateAD.internal.getSimulinkPeer(this.BuiltElement);
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

        appendComment(this,comment);
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
                target = this.Owner;
            end

            this.BuiltElement = [];
            
            prePublish(this, target);

            doPublish(this, target);

            % Tag the element with the xmi id:
            if ~isempty(this.BuiltElement)
                archElement = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(this.BuiltElement);
                archElement.ExternalUID = this.ExternalID;
            end

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