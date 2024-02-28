classdef Element < xmi.CandidateElement & matlab.mixin.SetGetExactNames
    properties
        Name (1,:) char
        Parent
        Model
    end

    properties
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
            elementObj@xmi.CandidateElement(NameValueArgs.ExternalID);

            elementObj.Name = NameValueArgs.Name;
            elementObj.Parent = NameValueArgs.Parent;

            setModel(elementObj);
        end

        function elementType = get.ElementType(this)
            elementType = xmi.CandidateAD.internal.getClassName(this);
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
    end
end