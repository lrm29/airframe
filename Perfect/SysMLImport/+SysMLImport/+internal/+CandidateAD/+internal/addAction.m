function actionNode = addAction(target, nodeName)
        % Add an action node to an activity diagram and resolve any naming
        % conflicts.
        if isa(target.ZCElement, 'systemcomposer.activitydiagram.model.Action')
            % Get the child activity of the action to continue the
            % build.
            targetElement = target.ZCElement.ChildActivity;
        else
            targetElement = target.ZCElement;
        end

        existingComponents = targetElement.Nodes;
        
        actionName = SysMLImport.internal.CandidateAD.internal.nextNameProperty(existingComponents, nodeName);

        targetPath = SysMLImport.internal.CandidateAD.internal.getQualifiedName(target);

        adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

        % creating with a placeholder name is a work-around for internal
        % API issues related to names with special characters.
        actionNode = adCommands.addAction(targetPath, 'tempName'); 
        archElement = SysMLImport.internal.CandidateAD.internal.getArchitecturePeer(actionNode);
        archElement.Name = actionName;
end