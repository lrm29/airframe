classdef Scenario < SysMLImport.internal.CandidateAllocation.Element
    properties
        Allocations
    end

    methods
        function scenarioObj = Scenario(varargin)
            scenarioObj@SysMLImport.internal.CandidateAllocation.Element(varargin{:});
        end

        function doPublish(this, varargin)
            this.ZCElement = this.Parent.ZCElement.createScenario(this.Name);
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