function example
%% example - Copy SysML example model to your current directory
%
%  Use SysMLConnector.example to copy a SysML example model into your
%  current directory. This example can be imported using the SysML
%  Connector.
    copyfile(fullfile(SysMLConnector.internal.toolboxRoot, 'Examples', 'SysMLExampleModel.mdzip'), pwd);
end