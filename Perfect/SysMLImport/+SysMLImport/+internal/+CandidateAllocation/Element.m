classdef Element < SysMLImport.internal.CandidateElement & matlab.mixin.SetGetExactNames
    properties
        Name (1,:) char
        Parent
        Model
    end

    properties
        Build (1,1) logical = true % build all allocations unless the build of it fails.
        ZCElement
    end

    properties (Dependent)
        ElementType
    end
    
    methods
        function elementObj = Element(NameValueArgs)
            arguments
                NameValueArgs.Name
                NameValueArgs.ExternalID
                NameValueArgs.Parent = [];
            end
            elementObj@SysMLImport.internal.CandidateElement(NameValueArgs.ExternalID);

            elementObj.Name = NameValueArgs.Name;
            elementObj.Parent = NameValueArgs.Parent;

            setModel(elementObj);
        end

        function elementType = get.ElementType(this)
            elementType = SysMLImport.internal.utils.getClassName(this);
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
            if ~isempty(this.Parent)
                this.Model = this.Parent.Model;
            end
        end

        function applyExternalUID(~)
            % Do nothing (g3245146)
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
                if ~isempty(this.Name)
                    fullPath = this.Name;
                else
                    fullPath = this.ExtElementID;
                end
            else
                fullPath = [getFullPath(this.Parent) '<:>' this.Name];
            end
        end
    end
end