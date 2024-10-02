function processEAXMI(xmiTmpFname, sysMLTag, sysMLTok, primTok)
    % process the EA-generated XMI file and make it importable
    fileContents = fileread(xmiTmpFname);

    % The file will be saved as UTF-8 so update the encoding attribute if necessary.
    fileContents = regexprep(fileContents, '^(<\?xml[^>]*encoding=[''"])(?<Encoding>[^''"]*)([''"])', '$1UTF-8$3');
    
    % Sometimes the files have multiple SysML imports to make sure all the
    % tag names are consistent.
    fileContents = regexprep(fileContents, '<(?i)SysML:([^>]*)>', ['<' sysMLTag ':$1>']);

    % Fix the profile application
    if ~isempty(sysMLTag) && contains(sysMLTag, '2012')
        profileID = '_SysML__0';
    else
        profileID  = 'SysML';
    end

    fileContents = regexprep(fileContents, '<appliedProfile([^>]*)href="(http://www.omg.org/spec/SysML/[^"]*)"([^>*])>', ['<appliedProfile$1href="http:\/\/www.omg.org\/spec\/SysML\/' sysMLTok '\/SysML.xmi#' profileID '"$3>']);
    
    % Capitalize the SysML Stereotype Names (i.e. <SysML:block... to <SysML:Block...)
    fileContents = regexprep(fileContents, ['<' sysMLTag ':([a-zA-Z])'], ['<' sysMLTag ':${upper($1)}']);

    % Convert uml:Dependency to uml:Abstraction (requirement links)
    fileContents = strrep(fileContents, 'uml:Dependency', 'uml:Abstraction');
    fileContents = strrep(fileContents, 'base_Dependency=', 'base_Abstraction=');

    % Capitalize the requirement id attribute:
    capitalizeAttributes = @(tagText) regexprep(tagText, ' (?!base_Class)([a-z])([^=]*="[^"]*")', ' ${upper($1)}$2'); %#ok<NASGU> used by regex in next line
    fileContents = regexprep(fileContents, ['<' sysMLTag ':Requirement([^>]*)'], ['<' sysMLTag ':Requirement${capitalizeAttributes($1)}']);

    % Fix activity diagram output pins
    fileContents = regexprep(fileContents, '<output([^>]*xmi:type="uml:OutputPin".*?)<\/output>', '<result$1<\/result>');

    % The following checks have to be done line-by-line because of the
    % possibility of nested tags.
    fileLines = split(fileContents, newline);
    for lineIdx = 1:height(fileLines)
        line = fileLines{lineIdx};
        tag = regexp(line, '^(?<Tab>\t*)<(?<TagName>[^\s>]+)(?<TagHeader>\s(?!xmi:type).*?)?(?<XMIType>\sxmi:type="[^"]*")?(?<TagFooter>\s.*)?>[\r\n]?', 'names');

        if isempty(tag)
            continue;
        end

        if ~isempty(tag.XMIType)
            xmiType = char(extractBetween(line, 'xmi:type="', '"'));
        else
            xmiType = '';
        end
        
        switch xmiType
            case 'uml:Collaboration'
                % Comment out collaboration lines                
                fileLines{lineIdx} = [tag.Tab '<!--<' tag.TagName tag.TagHeader tag.XMIType tag.TagFooter '>-->'];
                
                if strcmp(tag.TagName, 'packagedElement')
                    inPackage=true;
                else
                    inPackage=false;
                end

                for nextLineIdx = lineIdx+1:height(fileLines)
                    nextLine = fileLines{nextLineIdx};
    
                    if startsWith(nextLine, [tag.Tab '</' tag.TagName '>'])
                        fileLines{nextLineIdx} = strrep(nextLine, ['</' tag.TagName '>'], ['<!--</' tag.TagName '>-->']);
                        break;
                    else
                        % Tab left since we are commenting out a line.
                        fileLines{nextLineIdx} = regexprep(nextLine, '^\t(\t*)', '$1');

                        if inPackage && startsWith(fileLines{nextLineIdx}, [tag.Tab '<'])
                            % Convert all the first level children to
                            % packaged elements.
                            fileLines{nextLineIdx} = regexprep(fileLines{nextLineIdx}, '^(\t*)<(?<TagName>[^\s>]+)(.*)', '$1<packagedElement$3');
                        end
                    end
                end
            case 'uml:Extension'
                for nextLineIdx = lineIdx+1:height(fileLines)
                    nextLine = fileLines{nextLineIdx};
                    
                    lineStart = sprintf('%s\t<ownedEnd', tag.Tab);
                    if startsWith(nextLine, lineStart) && ~contains(nextLine, 'xmi:type')
                        % Add the missing xmi:type and remove the memberEnd.
                        removedMemberEnd = regexprep(extractAfter(nextLine, lineStart), '\smemberEnd="[^"]*"', '');
                        fileLines{nextLineIdx} = [lineStart ' xmi:type="uml:ExtensionEnd"' removedMemberEnd];
                    elseif startsWith(nextLine, [tag.Tab '<'])
                        % If the indent level is the same as when we
                        % started, we have left the extension so stop.
                        break;
                    end
                end
            case 'uml:OccurrenceSpecification'
                if strcmp(tag.TagName, 'fragment')
                    % Convert to interaction message occurrence so that it
                    % gets parsed correctly.

                    match = regexp(line, 'xmi:id="(?<ID>[^"]*)".*', 'names');
                    if isempty(match)
                        % Nothing can be done to resolve this tag.
                        continue;
                    end

                    occurrenceID = match.ID;

                    for nextLineIdx = lineIdx+1:height(fileLines)
                        nextLine = fileLines{nextLineIdx};
                        
                        match = regexp(nextLine, '\t*<message xmi:type="uml:Message" xmi:id="(?<MessageID>[^"]*)".*sendEvent="(?<sendEvent>[^"]*)".*receiveEvent="(?<receiveEvent>[^"]*)".*/>', 'names');
    
                        if ~isempty(match) && (strcmp(match.sendEvent, occurrenceID) || strcmp(match.receiveEvent, occurrenceID))
                            tag.XMIType = ' xmi:type="uml:MessageOccurrenceSpecification"';
                            
                            fileLines{lineIdx} = [tag.Tab '<' tag.TagName tag.TagHeader tag.XMIType ' message="' match.MessageID '"' tag.TagFooter '>'];
                            break;
                        end
                    end
                end
        end
    end
    fileContents = char(join(fileLines, newline));

    % Fix property types
    fileContents = regexprep(fileContents, 'http:\/\/www.omg.org\/spec\/UML\/\d+\/UML.xmi#String', ['http:\/\/www.omg.org\/spec\/UML\/' primTok '\/PrimitiveTypes.xmi#String']);

    % Remove messageKind attribute, g3382238
    fileContents = regexprep(fileContents, '(<message[^>]*)( messageKind=[''"]\w*[''"])([^>]*>)', '$1$3');

    % Convert occurrence to message occurrence
    fileContents = strrep(fileContents, '<fragment xmi:type="uml:OccurrenceSpecification"', '<fragment xmi:type="uml:MessageOccurrenceSpecification"');

    % Find the port conjugation property in the XMI Extension data and
    % bubble it up to the port definition.
    portsMissingConjugationProperty = regexp(fileContents, "xmi:type=['""]uml:Port['""][^>]*xmi:id=['""](?![^>]*isConjugated)(?<PortID>[^'""]*)", 'names');
    for portIdx = 1:numel(portsMissingConjugationProperty)
        port = portsMissingConjugationProperty(portIdx).PortID;
        
        portXREF = regexp(fileContents, "<(?<TagName>[^>]*) [^>]*xmi:idref=['""]"+port+"['""][^>]*xmi:type=['""]uml:Port['""][^>]*>.*?<xrefs value=['""](?<XREF>[^'""]*).*?<\/\1>", 'names');
        
        if ~isempty(portXREF)
            isConjugated = extractBetween(portXREF.XREF, '$DES=@PROP=@NAME=isConjugated@ENDNAME;@TYPE=Boolean@ENDTYPE;@VALU=', '@ENDVALU;@PRMT=@ENDPRMT;@ENDPROP;$DES');

            if ~isempty(isConjugated) && strcmp(isConjugated, "-1")
                fileContents = regexprep(fileContents, "xmi:id=(['""])" + port + "\1", "xmi:id=$1" + port + "$1 isConjugated=$1true$1");
            end
        end
    end

    writelines(fileContents, xmiTmpFname, Encoding="UTF-8");
end