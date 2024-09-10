classdef Fragment < SysMLConnector.internal.CandidateInteraction.Element & ...
        SysMLConnector.internal.CandidateInteraction.OperandReporter
    properties (SetAccess=protected)
        Message = []
        Interaction
        Type = []
        Operands = []
        DefaultGuard = missing % used to inform operands of default Guard value in some cases
        Lifeline = []
        NotImported = []
    end

    methods 
        function fragmentObj = Fragment(parent,interaction,element)
            %FRAGMENT Construct an instance of this class
            arguments
                parent SysMLConnector.internal.CandidateInteraction.OperandReporter
                interaction SysMLConnector.internal.CandidateInteraction.Interaction
                element 
            end
            fragmentObj@SysMLConnector.internal.CandidateInteraction.Element( ...
                Name="", ...
                ExternalID=SysMLConnector.internal.utils.getExtID(element), ...
                Parent=parent);
            fragmentObj.Interaction = interaction;
            if isMATLABReleaseOlderThan("R2024b")
                warning("SysMLConnector:internal:CandidateInteraction:Fragment",...
                    "Fragments are not supported before R2024b.");
                return;
            end            
            %% update print settings
            fragmentObj.ExcludedProperties = ...
                [fragmentObj.ExcludedProperties,"Interaction"];
            %% Parse the content of the fragment
            if isa(element,"umlmm.MessageOccurrenceSpecification")
                % means this gives order to a message
                messageExtID = SysMLConnector.internal.utils.getExtID(element.message);
                if interaction.MessageMap.isConfigured && ismember( ...
                        messageExtID, [interaction.MessageMap.keys])
                    % the message this fragment relates to has been created
                    % link it to make sure the graph makes sense
                    fragmentObj.Message = interaction.MessageMap(messageExtID);
                else
                    % new message, add it
                    fragmentObj.Message = interaction.addMessage(...
                        fragmentObj,element.message);
                end
                % need the lifeline to register with the message
                fragmentObj.Lifeline = SysMLConnector.internal.CandidateInteraction.Message.getEndPoint(interaction,element);
                % now register
                fragmentObj.Message.registerFragment(fragmentObj);
            elseif isa(element,"umlmm.CombinedFragment")
                % Combined Fragments have interaction constraints
                fragmentObj.Type = systemcomposer.interaction.internal.fragmentTypeStrToEnum(...
                    element.interactionOperator.toString());
                if fragmentObj.Type == -1
                    warning("SysMLConnector:internal:CandidateInteraction:Fragment", ...
                        "Unsupported fragment type %s.", ...
                        element.interactionOperator.toString());
                else
                    % check for Alt fragment
                    if fragmentObj.Type == sequencediagram.lang.syntax.CompositeFragmentOpType.Alt
                        % in the Alt fragment the else operand does not get
                        % a guard in the XMI
                        fragmentObj.DefaultGuard = "Else";
                    end
                    % need to create a operand
                    for i = 1:element.operand.size
                        fragmentObj.Operands = [fragmentObj.Operands, ...
                            SysMLConnector.internal.CandidateInteraction.Operand(...
                            fragmentObj,element.operand.at(i))];
                    end
                end
            else
                warning("SysMLConnector:internal:CandidateInteraction:Fragment", ...
                    "Unsupported fragment type %s",class(element));
                fragmentObj.NotImported = fragmentObj.createNotImported( ...
                    "Sequence Diagram Fragment",...
                    sprintf("Unsupported fragment type %s.",class(element)));
            end
        end

        doPublish(this, varargin);
        print(this,printer);
    end

    methods (Access=protected)
        infoString = getInfoString(this);
    end
end