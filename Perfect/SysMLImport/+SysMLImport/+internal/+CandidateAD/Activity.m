classdef Activity < SysMLImport.internal.CandidateAD.Node   
    properties
        ActionBehavior = systemcomposer.activitydiagram.model.BehaviorLanguage.MATLAB;
        ReferenceID
    end

    properties (Dependent)
        Reference
    end

    methods
        function activityObj = Activity(varargin)
            activityObj@SysMLImport.internal.CandidateAD.Node(varargin{:});
            
            if isempty(activityObj.Name)
                activityObj.Name = SysMLImport.internal.utils.nextNameProperty(activityObj.Parent.Nodes, 'Activity');
            end
        end

        function reference = get.Reference(this)
            reference = [];

            if ~isempty(this.ReferenceID)
                reference = this.Model.lookup(this.ReferenceID);
            end
        end

        function doPublish(this, target)
            doPublish@SysMLImport.internal.CandidateAD.Node(this, target);

            this.ZCElement.PinNamesVisible = true;
            
            this.ZCElement.ActionBehavior  = this.ActionBehavior;
        end

        function postPublish(this, target)
            if isempty(this.ReferenceID)
                postPublish@SysMLImport.internal.CandidateAD.Node(this, target);
            else
                % Tag the child architecture with the reference id:
                childActivity = this.ZCElement.ChildActivity;
                archElement = SysMLImport.internal.CandidateAD.internal.getArchitecturePeer(childActivity);
                archElement.ExternalUID = this.ReferenceID;

                % Publish pins
                arrayfun(@(pin)  publish(pin,  this), this.Pins);
                arrayfun(@(parameter)  publish(parameter,  this), this.Reference.Parameters);
                
                if ~SysMLImport.internal.CandidateAD.internal.isRecursive(this)
                    arrayfun(@(node) publish(node, this), this.Reference.Nodes);
                    arrayfun(@(flow) publish(flow, this), this.Reference.Flows);
                    
                    warnState = warning('off', 'diagram_autolayout:autolayout:layoutRejectedCommandLine');
                    systemPath = SysMLImport.internal.CandidateAD.internal.getArchitecturePeer(this.ZCElement).getQualifiedName;
                    Simulink.BlockDiagram.arrangeSystem(systemPath);
                    warning(warnState);
                end
            end
        end
    end
end