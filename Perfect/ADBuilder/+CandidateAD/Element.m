classdef Element < handle & matlab.mixin.SetGetExactNames
    properties
        Name (1,:) char
        Parent
        Model
        ExternalID (1,:) char
    end

    properties
        ZCElement
    end

    properties (Dependent)
        QualifiedName
    end
    
    methods
        function elementObj = Element(NameValueArgs)
            arguments
                NameValueArgs.Name
                NameValueArgs.ExternalID
                NameValueArgs.Parent = [];
            end

            elementObj.Name = NameValueArgs.Name;
            elementObj.ExternalID = NameValueArgs.ExternalID;
            elementObj.Parent = NameValueArgs.Parent;

            setModel(elementObj);

            elementObj.Model.register(elementObj);
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

        function setModel(this)
            % Can be overriden during element construction.
            this.Model = this.Parent.Model;
        end

        function setZCName(this, newName)
            archElement = ADBuilder.internal.getArchitecturePeer(this.ZCElement);
            % Avoid dirtying the model if not necessary
            if ~strcmp(archElement.Name, newName)
                archElement.Name = newName;
            end
        end
    end
    methods (Sealed)
        function publish(this, target)
            %fprintf('publishing: \n  %s\n  %s\n\n', class(this), this.getFullPath);

            if nargin < 2
                target = this.Parent;
            end

            this.ZCElement = [];
            
            prePublish(this, target);

            doPublish(this, target);

            % Tag the element with the xmi id:
            if ~isempty(this.ZCElement)
                archElement = ADBuilder.internal.getArchitecturePeer(this.ZCElement);
                archElement.ExternalUID = this.ExternalID;
            end

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