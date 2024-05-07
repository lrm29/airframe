function export(models, xmiFilename, options)
%% export - Export a System Composer model into a XMI file
%     SysMLConnector.export(models, xmiFilename) creates an XMI
%     export for a set of System Composer input models. Only "root" architecture
%     models need to be specified and any associated referenced models are also
%     automatically exported. Associated interfaces are also exported into a 
%     separate package in the same XMI file.
%
%     Optional input parameters that may be specified as comma separated 
%     name-value pairs are:  
%
%     - 'UseExternalUIDs': false | {true}
%       false - Do not use the ExternalUID property of the elements being exported
%       true  - Export the ExternalUID property of elements being exported as the
%               XMI ID of the corresponding object in the XMI file. This option
%               attempts to recreate the IDs of objects that were imported from
%               another tool using XMI import into System Composer.     
%
%     - 'MakeNestedInterfacesSignals': {false} | true
%       false - Keep nested interfaces as Interface Blocks
%       true  - Export nested interfaces as UML signals     
%
%     Usage:
%     myModel = systemcomposer.loadModel('MyArchitectureModel');
%     SysMLConnector.export(myModel);
%
    arguments
        models (1,:) systemcomposer.arch.Model {mustBeNonempty}
        xmiFilename (1,:) char {mustBeNonempty} = models(1).Name
        options.UseExternalUIDs (1,1) logical = true
        options.MakeNestedInterfacesSignals (1,1) logical = true
    end

    optionArgs = namedargs2cell(options);

    SysMLConnector.internal.export(models, xmiFilename, optionArgs{:});
end