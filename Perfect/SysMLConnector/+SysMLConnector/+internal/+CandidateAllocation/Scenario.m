classdef Scenario < SysMLConnector.internal.CandidateAllocation.Element
    properties
        Builder
        Allocations
    end

    methods
        function scenarioObj = Scenario(varargin)
            scenarioObj@SysMLConnector.internal.CandidateAllocation.Element(varargin{:});
        end

        function prePublish(this, varargin)
            % propagate downward for build.
            this.Builder = this.Owner.Builder;
        end

        function doPublish(this, varargin)
            this.BuiltElement = this.Owner.BuiltElement.createScenario(this.Name);
        end

        function postPublish(this, varargin)
            arrayfun(@publish, this.Allocations);
        end
        
        function prePrint(this, printer)
            printer.openScope("Scenario: " + this.Name);
        end

        function doPrint(this, printer)
            printer.openScope("Allocations");
            arrayfun(@(elem) print(elem, printer), this.Allocations);
            printer.closeScope("Allocations");
        end
        
        function postPrint(this, printer)
            printer.closeScope("Scenario: " + this.Name);
        end
    end
end