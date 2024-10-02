function print(this,printer)
%PRINT prints transitions as always short
arguments
    this SysMLConnector.internal.CandidateStateMachine.Transition
    printer SysMLConnector.internal.Printer
end
this.shortPrint(printer);
end

