classdef OwnedBehavior < matlab.mixin.Heterogeneous & handle
    %OWNEDBEHAVIOR Interface for anything that is an owned behavior

    properties (SetAccess=protected)
        BehaviorComponent systemcomposer.arch.Component
    end

    properties (Abstract)
        Name
    end

    methods
        function setBehaviorComponent(this,Component)
            arguments
                this SysMLConnector.internal.OwnedBehavior
                Component systemcomposer.arch.Component
            end
            this.BehaviorComponent = Component;
        end
    end
end