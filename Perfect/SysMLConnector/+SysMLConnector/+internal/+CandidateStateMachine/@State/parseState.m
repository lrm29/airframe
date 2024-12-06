function parseState(this,element)
%PARSESTATE parses UML state
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
    element umlmm.State
end
this.Name = element.name;
%% parse connection points
this.ConnectionPoints = ...
    SysMLConnector.internal.CandidateStateMachine.Port.empty(element.connectionPoint.size,0);
for i = 1:element.connectionPoint.size
    this.ConnectionPoints(i) = ...
        SysMLConnector.internal.CandidateStateMachine.Port(...
        element.connectionPoint.at(i),this,i);
end
% report the connection points to the parent
this.Owner.addConnectionPoint(this.ConnectionPoints);
%% parse regions
% expect this to be 1
this.Regions = ...
    SysMLConnector.internal.CandidateStateMachine.Region.empty(element.region.size,0);
if isempty(this.ConnectionPoints)
    portJunctions = SysMLConnector.internal.CandidateStateMachine.PortJunction.empty();
else
    portJunctions = [this.ConnectionPoints.Junction];
end
for i = 1:element.region.size
    this.Regions(i) = ...
        SysMLConnector.internal.CandidateStateMachine.Region(...
        element.region.at(i),this,...
        portJunctions);
end
if ~isempty(element.submachine)
    if isempty(this.Regions)
        this.Regions = ...
            SysMLConnector.internal.CandidateStateMachine.Region.empty( ...
            element.submachine.region.size,0);
        for i = 1:element.submachine.region.size
            this.Regions(i) = ...
                SysMLConnector.internal.CandidateStateMachine.Region(...
                element.submachine.region.at(i),this,portJunctions);
        end
    else
        warning("SysMLConnector:internal:CandidateStateMachine:State:parseState",...
        "State %s with ID %s contained %d regions and a submachine. The submachine will be ignored. This is not valid please contact MathWorks.",...
        this.Name,this.ExtElementID,element.region.size);
    end
end
if element.region.size > 1
    warning("SysMLConnector:internal:CandidateStateMachine:State:parseState",...
        "State %s with ID %s contained %d regions, this is not expected please contact MathWorks.",...
        this.Name,this.ExtElementID,element.region.size);
end
%% parse the content of the state
if ~isempty(element.entry)
    parseString = parseBehavior(element.entry);
    if ~isempty(parseString)
        this.LabelString = this.LabelString + "en: "+parseString;
    end
end
if ~isempty(element.doActivity)
    parseString = parseBehavior(element.doActivity);
    if ~isempty(parseString)
        this.LabelString = this.LabelString + "du: "+parseString;
    end
end
if ~isempty(element.exit)
    parseString = parseBehavior(element.exit);
    if ~isempty(parseString)
        this.LabelString = this.LabelString + "ex: "+parseString;
    end
end
end

function labelString = parseBehavior(element)
arguments
    element
end
labelString = strings(0);
switch class(element)
    case "umlmm.OpaqueBehavior"
        if element.body.size > 0
            labelString = string(element.body.at(1)) + newline;
        end
    case "umlmm.Activity"
        labelString = string(element.name) + newline;
    otherwise
        warning("SysMLConnector:internal:CandidateStateMachine:State:parseState",...
            "A state was found with an unsupported behavior type of %s, please contact MathWorks.",...
            class(element));
end
end