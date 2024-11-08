classdef Element < SysMLConnector.internal.CandidateElement & matlab.mixin.SetGetExactNames
    properties
        Model
    end

    properties
        Build (1,1) logical = true % build all allocations unless the build of it fails.
    end

    properties (Dependent)
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
            elementObj.Owner = NameValueArgs.Owner;

            setModel(elementObj);
        end

        function elementType = get.ElementType(this)
            elementType = SysMLConnector.internal.utils.getClassName(this);
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
            if ~isempty(this.Owner)
                this.Model = this.Owner.Model;
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
                if ~isempty(this.Name)
                    fullPath = this.Name;
                else
                    fullPath = this.ExtElementID;
                end
            else
                fullPath = [getFullPath(this.Owner) '<:>' this.Name];
            end
        end
    end
end