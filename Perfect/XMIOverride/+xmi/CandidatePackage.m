classdef CandidatePackage < systemcomposer.xmi.CandidateElement
% CANDIDATEPACKAGE Helper class to systemcomposer.xmi.import that holds a candidate list
%  of Architecture models that are to be packaged together in a project folder.
%    
   
    properties
        Name = "";
        BuildName = "";
        
        OwnerExtElementID = "";
        
        ParentPackage = [];
        ChildPackages = [];
        
        Architectures = [];  
        Activities = [];

        Build = false;
        BuildParentPackage = [];
        BuildChildPackages = [];
        BuildArchitectures = [];
        BuildActivities    = [];
        
        ZCProjectFolder = "";
    end
    
    methods
        function this = CandidatePackage(name, selfID, ownerID)
            this@systemcomposer.xmi.CandidateElement(selfID);
            this.Name = name;
            this.BuildName = name;
            this.OwnerExtElementID = ownerID;
        end
        
        function link(this)
            if this.OwnerExtElementID ~= ""
                oP = systemcomposer.xmi.CandidateElement.idMap(...
                    "lookup", this.OwnerExtElementID);
                this.setParentPackage(oP);
            end
        end
        
        function setParentPackage(this, oP)
            this.ParentPackage = oP;
            oP.ChildPackages = [oP.ChildPackages this];
        end
        
        function setBuildParentPackage(this, oP)
            this.BuildParentPackage = oP;
            oP.BuildChildPackages = [oP.BuildChildPackages this];
        end
        
        function addArchitecture(this, comp)
            this.Architectures = [this.Architectures comp];
        end

        function addActivity(this, activity)
            this.Activities = [this.Activities activity];
        end
        
        function print(this, printer)
            printer.openScope("Package: [Persist= " + ...
                              this.Build + "] " + this.Name);
            
            for k = 1:length(this.BuildArchitectures)
                this.BuildArchitectures(k).print(printer)
            end
            for k = 1:length(this.BuildActivities)
                this.BuildActivities(k).print(printer)
            end
            for k = 1:length(this.BuildChildPackages)
                this.BuildChildPackages(k).print(printer)
            end
            
            printer.closeScope("Package: " + this.Name);
        end
        
        function prelimBuild(this, builder)
            builder.createProjectFolder(this);
            for k = 1:length(this.BuildArchitectures)
                this.BuildArchitectures(k).prelimBuild(builder);
            end

            for k = 1:length(this.BuildActivities)
                this.BuildActivities(k).prelimBuild(builder);
            end
            
            % Unique child folder names
            if ~isempty(this.BuildChildPackages)
                cNames = [this.BuildChildPackages.BuildName];
                cNames = matlab.lang.makeUniqueStrings(cNames);
                for k = 1:length(this.BuildChildPackages)
                    this.BuildChildPackages(k).BuildName = cNames(k);
                end            
                
                for k = 1:length(this.BuildChildPackages)
                    this.BuildChildPackages(k).prelimBuild(builder)
                end
            end
        end

        function finishBuild(this, builder)
            for k = 1:length(this.BuildArchitectures)
                this.BuildArchitectures(k).finishBuild(builder);
            end
            for k = 1:length(this.BuildActivities)
                this.BuildActivities(k).finishBuild(builder);
            end
            for k = 1:length(this.BuildChildPackages)
                this.BuildChildPackages(k).finishBuild(builder)
            end               
        end

        function buildChildRet = recVisitForPrune(this)
            this.Build = ~isempty(this.BuildArchitectures) || ~isempty(this.BuildActivities);
            
            buildChildren = [];
            for k = 1:length(this.ChildPackages)
                bc = this.ChildPackages(k).recVisitForPrune();
                buildChildren = [buildChildren bc]; %#ok
            end
            
            if this.Build || length(buildChildren) > 1
                buildChildRet = this;
                this.Build = true;
                for k = 1:length(buildChildren)
                    buildChildren(k).setBuildParentPackage(this);
                end
            else
                % Append name of this package to children since it will be dissolved
                for k = 1:length(buildChildren)
                    buildChildren.BuildName = this.BuildName + "_" + buildChildren.BuildName;
                end
                buildChildRet = buildChildren;
            end
            
        end
        
        function recVisitForArchPrune(this, inlineSingleUseArchsAcrossPackages, ...
                                      pruneArchsWithNoRefAndNoChildren, ...
                                      simulinkLeaf)
            for k = 1:length(this.Architectures)
                % Check if Architecture needs to be built
                build = this.Architectures(k).buildCheck(...
                    inlineSingleUseArchsAcrossPackages, ...
                    pruneArchsWithNoRefAndNoChildren, ...
                    simulinkLeaf);
                if build
                    this.BuildArchitectures = [this.BuildArchitectures, this.Architectures(k)];
                end
            end

            % Build all activity diagrams
            this.BuildActivities = this.Activities;
            
            for k = 1:length(this.ChildPackages)
                this.ChildPackages(k).recVisitForArchPrune(...
                    inlineSingleUseArchsAcrossPackages, ...
                    pruneArchsWithNoRefAndNoChildren, simulinkLeaf);
            end
        end
        
        function rootProj = visitAndPrunePackageBuildTree(...
            this, ...
            inlineSingleUseArchsAcrossPackages, ...
            pruneArchsWithNoRefAndNoChildren, ...
            simulinkLeaf)
            % Visit to prune out empty and inlined Architectures
            this.recVisitForArchPrune(inlineSingleUseArchsAcrossPackages, ...
                                      pruneArchsWithNoRefAndNoChildren,...
                                      simulinkLeaf);
            
            % Visit to prune out empty Packages
            rootProj = this.recVisitForPrune();
        end
        
    end
end