classdef Operand < SysMLConnector.internal.CandidateInteraction.AnnotatedCommentable & ...
        SysMLConnector.internal.CandidateInteraction.OperandReporter
    % OPERAND represents the XMI operand and translates to System Composer
    properties (SetAccess=protected)
        Guard = ""
        Fragments = []
    end

    methods
        function operandObj = Operand(parent,umlOperand)
            %OPERAND Construct an instance of this class
            arguments
                parent SysMLConnector.internal.CandidateInteraction.Fragment
                umlOperand umlmm.InteractionOperand
            end
            operandObj@SysMLConnector.internal.CandidateInteraction.AnnotatedCommentable(...
                parent,umlOperand);
            %% parse the element
            % get the guard
            if ~isempty(umlOperand.guard)
                guardSpecification = umlOperand.guard.specification;

                if isa(guardSpecification, 'umlmm.OpaqueExpression')
                    if ~ismissing(guardSpecification.body)
                        operandObj.Guard = guardSpecification.body.at(1);
                    end
                else
                     operandObj.Guard = umlOperand.guard.specification.value;
                end
            elseif ~ismissing(parent.DefaultGuard)
                operandObj.Guard = parent.DefaultGuard;
            end
            % need to build the fragments
            for i = 1:umlOperand.fragment.size
                operandObj.Fragments = [operandObj.Fragments,...
                    SysMLConnector.internal.CandidateInteraction.Fragment(...
                    operandObj,operandObj.Parent.Interaction,umlOperand.fragment.at(i))];
            end
        end
    end

    methods (Access=protected)
        infoString = getInfoString(this);
    end
end