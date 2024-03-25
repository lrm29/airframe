function processRhapsodyXMI(xmiFileName)
    %% processRhapsodyXMI - Process an XMI file and make corrections to prepare it for import into System Composer
    % This script makes the following changes to the input XMI file:
    %   1. Adds a sysml:Block for RhapsodyProfile:TopLevelClass.
    %   2. Adds a sysml:Block for every HarmonySE:ActorBlock.
    %   3. Fix sysml:Requirement attribute name from “text” to “Text” and “id” to “Id”.
    %   4. Comment out defaultValue tags that have uml:EnumerationLiteral values.
    %
    % Input: XMI file name
    %
    % Output: Generates an XMI file in the same directory as the input file
    %         named [xmiFileName]_processed.SysMLImport.internal.
    % Usage:
    %   processRhapsodyXMI('MyXMIFile.xmi')
    % 

    [xmiPath, xmiName, xmiExt] = fileparts(xmiFileName);

    if isempty(xmiExt)
        xmiExt = '.xmi';
    end

    inputContents = fileread(fullfile(xmiPath, [xmiName xmiExt]));

    % Fix requirement attribute
    outputContents = regexprep(inputContents, '<sysml:Requirement xmi:id="([^"]*)" text="([^"]*)" id="([^"]*)" base_Class="([^"]*)"/>', '<sysml:Requirement xmi:id="$1" Text="$2" Id="$3" base_Class="$4"/>');

    % Comment out unsupported default values for enumerations.
    outputContents = regexprep(outputContents, '(<defaultValue[^>]*>\s*<instance xmi:type="uml:EnumerationLiteral"[^>]*>\s*<\/defaultValue>)', '<!-- Commented out during XMI preprocessing $1 -->');

    % Look for actor blocks that do not have corresponding SysML blocks
    actorBlocks = regexp(outputContents, '<HarmonySE:ActorBlock[^>]*base_Class="(?<xmiID>[^"]*)"\/>','names');
    sysMLBlocks = regexp(outputContents, '<sysml:Block[^>]*base_Class="(?<xmiID>[^"]*)"\/>','names');

    missingBlocks = setdiff({actorBlocks.xmiID}, {sysMLBlocks.xmiID});
    
    outputFID = fopen(fullfile(xmiPath, [xmiName '_processed' xmiExt]), 'w');
    outputCleanup = onCleanup(@() fclose(outputFID));

    % Remove the end delimiter to add more content
    outputContents = strrep(outputContents, '</xmi:XMI>', '');

    % Insert the processed contents into the file
    fprintf(outputFID, '%s', outputContents);

    % Add a SysML block for the top-level
    topLevelClass = regexp(outputContents, '<RhapsodyProfile:TopLevelClass xmi:id="[^"]*" base_Class="(?<xmiID>[^"]*)"/>','names');
    if ~isempty(topLevelClass)
        fprintf(outputFID, '  <sysml:Block xmi:id="%1$s_sysml_Block" base_Class="%1$s"/>\n', topLevelClass(1).xmiID);
    end

    % Add the missing actor SysML blocks
    if ~isempty(missingBlocks)
        for blockIdx = 1:numel(missingBlocks)
            fprintf(outputFID, '  <sysml:Block xmi:id="%1$s_sysml_Block" base_Class="%1$s"/>\n', missingBlocks{blockIdx});
        end
    end

    % Add the end delimiter
    fprintf(outputFID, '</xmi:XMI>\n');
end