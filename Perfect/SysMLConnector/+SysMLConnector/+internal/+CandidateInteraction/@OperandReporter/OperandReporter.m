classdef (Abstract) OperandReporter < handle
    %OPERANDREPORTER Abstract class to define interface to get operand
    %during publishing
    methods
        operand = getOperand(this);
    end
end

