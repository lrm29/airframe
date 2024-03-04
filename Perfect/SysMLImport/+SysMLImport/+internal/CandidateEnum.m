classdef CandidateEnum < SysMLImport.internal.CandidateElement
% CANDIDATEENUM Helper class for SysMLImport.internal.import that holds candidate enumerations.
    properties
        Name
        EnumStrs = []

        Internal = true % If false then this will be a MATLAB class instead of a dictionary entry.
        ParentPackageExtElementID = ''
        ParentPackage = [];

        BuildName = ""
        BuildEnumStrs = []
        BuildFileContent = ""
    end

    properties (Dependent)
        BuildFileName
    end
    
    methods
        function this = CandidateEnum(extElemID, eName, eStrs)
            this@SysMLImport.internal.CandidateElement(extElemID);

            this.Name = eName;
            this.EnumStrs = eStrs;
        end

        function fileName = get.BuildFileName(this)
            fileName = this.BuildName + ".m";
        end

        function linkComponentsPortsPackage(this)
            if this.Internal
                % Do not build internally-stored enumerations. They will be
                % added to the data dictionary instead.
                return;
            end
            
            parentPackage = SysMLImport.internal.CandidateElement.idMap(...
                "lookup", this.ParentPackageExtElementID);
            parentPackage.addEnumeration(this);
            this.ParentPackage = parentPackage;
        end

        function prelimBuild(this, builder)
            this.BuildName = builder.makeValidName(this.Name);
            builder.AllEnumNames = [builder.AllEnumNames string(this.BuildName)];

            this.BuildEnumStrs = arrayfun(@builder.makeValidName, this.EnumStrs); 
            
            if this.Internal
                prelimBuildInternal(this, builder);
            else
                prelimBuildExternal(this, builder);
            end
        end

        function prelimBuildInternal(this, builder)
            % Only build dictionary enums. External (MATLAB class) will be
            % built during package construction.

            ddHdl = Simulink.data.dictionary.open(builder.ProjectSLDDName);
            
            evalin('base', ...
                   [char(this.BuildName), ...
                    '=Simulink.data.dictionary.EnumTypeDefinition;']);
            
            for p = 1:length(this.BuildEnumStrs)
                evalin('base', ...
                       ['appendEnumeral(' char(this.BuildName) ','''         ...
                                          char(this.BuildEnumStrs(p)) ''',', ...
                                          int2str(p) ')']);
            end

            evalin('base', ...
                   ['removeEnumeral(' char(this.BuildName) ', 1)']);

            importFromBaseWorkspace(ddHdl, 'varList', {char(this.BuildName)});

            evalin('base', ['clear ' char(this.BuildName)]);
        end

        function prelimBuildExternal(this, builder)
            fileHeader = sprintf('classdef %s\n   properties\n      ExternalUID="%s"\n   end\n\n   enumeration\n', this.BuildName, this.ExtElementID);

            enumContent = '';
            for enumIdx = 1:length(this.BuildEnumStrs)
                enumContent = sprintf('%s      %s\n', enumContent, this.BuildEnumStrs(enumIdx));
            end

            fileFooter = sprintf('   end\nend\n');

            this.BuildFileContent = sprintf('%s%s%s', fileHeader, enumContent, fileFooter);

            builder.createPackagedFile(this);
        end

        function finishBuild(~, ~)
        end

        function prePrint(this, printer)
            printer.openScope("Enumeration: " + this.Name);
        end

        function doPrint(this, printer)
            for k = 1:length(this.EnumStrs)
                printer.print("Enum: [" + this.EnumStrs(k) + " + ]");
            end
        end

        function postPrint(this, printer)
            printer.openScope("Enumeration: " + this.Name);
        end
    end
end
