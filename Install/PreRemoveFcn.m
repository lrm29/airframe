function PreRemoveFcn(pspBuilder)
    generateDoc(pspBuilder);
end

function generateDoc(pspBuilder)
    startDir = pwd;
    docSrc = fullfile(pspBuilder.BuildDir, pspBuilder.Package, 'DocSrc');
    cleanup = onCleanup(@() cd(startDir));
    cd(docSrc);
    docFiles = dir('*.mlx')';
    for docFile = docFiles
        if strcmp(docFile.name, "UserGuide")
            continue;
        end
        htmlDocFile = export(docFile.name, Format='html');
        movefile(htmlDocFile, pspBuilder.DocDir);
    end

    % Navigate to the doc directory to continue updating the doc files.
    cd(pspBuilder.DocDir);

    % Remove the indexing file since it is no longer valid.
    if isfolder('helpsearch-v4_en')
        rmdir('helpsearch-v4_en', 's');
    end

    % Rebuild the table of contents to add the user guide sub pages.
    rebuildTableOfContents;
end

function rebuildTableOfContents
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Convert the user guide to a tree of pages and add the new pages.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tocStruct = readstruct('helptoc.xml');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Update the User Guide main sections
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    docFiles = dir('UserGuide_*.html')';
    docFiles = docFiles(~strcmp({docFiles.name},'UserGuide_Scr.html'));

    tocStructUGIndex = strcmp([tocStruct.tocitem.tocitem.Text], 'UserGuide');
    ugNode = tocStruct.tocitem.tocitem(tocStructUGIndex);
    newTocItem = struct('targetAttribute', '', 'Text', '', 'tocitem', missing);
    ugTocNodes = repmat(newTocItem, 1, numel(docFiles));
    for docFileNum = 1:numel(docFiles)
        ugTocNodes(docFileNum).targetAttribute = string(docFiles(docFileNum).name);         
        ugTocNodes(docFileNum).Text = string(getTitle(docFiles(docFileNum).name));  
    end    

    ugNode.tocitem = ugTocNodes;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Update the Import main sections
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    docFiles = dir('Importing_*.html')';
    ugNodeImportIndex = strcmp([ugNode.tocitem.Text], 'Importing SysML Models');
    newTocItem = struct('targetAttribute', '', 'Text', '', 'tocitem', missing);
    importTocNodes = repmat(newTocItem, 1, numel(docFiles));
    for docFileNum = 1:numel(docFiles)
        importTocNodes(docFileNum).targetAttribute = string(docFiles(docFileNum).name);         
        importTocNodes(docFileNum).Text = string(getTitle(docFiles(docFileNum).name));  
    end

    ugNode.tocitem(ugNodeImportIndex).tocitem = importTocNodes;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Update the struct with the new child nodes.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tocStruct.tocitem.tocitem(tocStructUGIndex) = ugNode;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Save the struct to the table of contents file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    writestruct(tocStruct, 'helptoc.xml', StructNodeName='toc');
    % Remove the <Text> and </Text> tags from the xml so that doc parses it
    % correctly.
    content = fileread('helptoc.xml');
    content = regexprep(content, '<[/]?[tT]ext>', '');
    content = regexprep(content, '(?<startTag><tocitem[^>]*>)\n[ ]*\n?[ ]*(?<text>[^<]*)[ ]*\n[ ]*</tocitem>', '$<startTag>$<text></tocitem>');
    writelines(content, 'helptoc.xml');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Helper functions to get page title from an html file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function title = getTitle(file)
        % Get the page title from an html file.
        fileContent = fileread(file);
        matchResults = regexp(fileContent, '<[tT]itle>(?<title>.*)</[tT]itle>', 'names');
        title = matchResults.title;
    end
end