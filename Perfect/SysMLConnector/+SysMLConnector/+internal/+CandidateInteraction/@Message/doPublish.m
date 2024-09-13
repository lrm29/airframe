function doPublish(this, varargin)
%DOPUBLISH publish the message
arguments
    this SysMLConnector.internal.CandidateInteraction.Message
end
arguments (Repeating)
    varargin
end
if this.Built || isMATLABReleaseOlderThan("R2024b")
    % before R2024b the API needed does not exist
    % otherwise if this is built no work to do
    return;
else
    %% first need create ports for the connection
    fromPort = createPort(this.From,"out");
    toPort = createPort(this.To,"in");
    %% connect those ports
    % this is optional but I think it is valuable
    fromPort.connect(toPort);
    %% add the message to the sequence diagram
    operand = this.Parent.getOperand();
    if isempty(operand)
        warning("SysMLConnector:internal:CandidateInteraction:Message",...
            "Message with ExtID %s could not find a valid operand.",...
            this.ExtElementID);
        this.Invalid = true;
    else
        try
            this.ZCElement = operand.addMessage( ...
                this.From.ZCElement,fromPort.Name, ...
                this.To.ZCElement,toPort.Name, ...
                this.Name);
        catch 
            warning("SysMLConnector:internal:CandidateInteraction:Message",...
                "Message %s from %s to %s was not able to be created.",...
                this.Name,this.From.Name,this.To.Name);
            this.Invalid = true;
        end
    end
end
end

function port = createPort(endPoint,direction)
arguments
    endPoint {SysMLConnector.internal.CandidateInteraction.Message.validateEndPoint}
    direction string {mustBeMember(direction,["in","out"])}
end
if isa(endPoint,"SysMLConnector.internal.CandidateInteraction.Interaction")
    % since this means the port is on the port level architecture
    % need to reverse the port direction
    if strcmp(direction,"in")
        direction = "out";
    else
        direction = "in";
    end
    port = endPoint.ModelZCElement.Architecture.addPort( ...
        getNextPortNumber(endPoint.ModelZCElement.Architecture), ...
        direction);
elseif isa(endPoint,"SysMLConnector.internal.CandidateInteraction.Lifeline")
    port = endPoint.ZCElement.RelatedElements.Architecture.addPort(...
        getNextPortNumber(endPoint.ZCElement.RelatedElements.Architecture),...
        direction);
    % need the parents parents ports actually
    port = port.Parent.Parent.Ports( ...
        ismember({port.Parent.Parent.Ports.Name}, ...
        port.Name));
end
end

function portNumber = getNextPortNumber(element)
portNumber = num2str(numel(element.Ports));
end