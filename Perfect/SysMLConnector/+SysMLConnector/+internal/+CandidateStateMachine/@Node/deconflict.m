function deconflict(this)
    %DECONFLICT moves the element until it no longer glows red!
    arguments
        this SysMLConnector.internal.CandidateStateMachine.Node
    end
    if ~isempty(this.StateflowObj)
        styler = diagram.style.getStyler('GlowStyler');
        while(styler.hasClass(this.StateflowObj.Id,'Red'))
            this.moveCenterTo(this.Center+[this.DefaultOffset,0]);
        end
    end
end