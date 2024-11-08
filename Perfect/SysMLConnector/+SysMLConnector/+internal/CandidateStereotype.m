classdef CandidateStereotype < SysMLConnector.internal.CandidateElement
% CANDIDATEREQUIREMENT Helper class for SysMLConnector.internal.import that holds candidate Stereotypes.
    properties
        PackagePath
        
        SuperClassExtElementID = ""
        
        SuperClass = [];
        
        Properties = [];
        NumProps = 0;
        Uniqued = false;
        PropNamesInScope = [];
        
        AppliedElements = [];
    end
    
    methods
        function this = CandidateStereotype(extElemID, sName, prof, pPath, scExtID)
            this@SysMLConnector.internal.CandidateElement(extElemID);

            this.Name = sName;
            this.PackagePath = pPath;
            this.Owner = prof;
            this.SuperClassExtElementID = scExtID;
        end
        
        function addProperty(this, pName, pDtypeName, eType)
            this.NumProps = this.NumProps + 1;
            newProp = SysMLConnector.internal.CandidateStereotypeProp(...
                this.ExtElementID + "Prop" + this.NumProps, ...
                pName, pDtypeName, eType, this);
            this.Properties = [this.Properties newProp];
        end

        function prop = findProperty(this, pName)
            prop = [];
            for k = 1:length(this.Properties)
                if strcmp(this.Properties(k).Name, pName)
                    prop = this.Properties(k);
                    break;
                end
            end
            if isempty(prop) && ~isempty(this.SuperClass)
                prop = findProperty(this.SuperClass, pName);
            end
        end
        
        function link(this)
            if this.SuperClassExtElementID ~= ""
                sClass = SysMLConnector.internal.CandidateElement.idMap(...
                    "lookup", this.SuperClassExtElementID);
                this.SuperClass = sClass;
            end
        end

        function trackAppliedElement(this, elem)
            this.AppliedElements = [this.AppliedElements elem];
        end
        
        function uniquePropNames(this, builder)
            sClassPropNames = [];
            if ~isempty(this.SuperClass)
                % There can be multiple superclasses after generalizations
                % have been merged in.
                sClassPropNameCells = cell(0, numel(this.SuperClass));
                for superClassIdx = 1:numel(this.SuperClass)
                    superClass = this.SuperClass(superClassIdx);

                    if ~superClass.Uniqued
                        superClass.uniquePropNames(builder);
                    end

                    sClassPropNameCells{superClassIdx} = superClass.PropNamesInScope;
                end
                sClassPropNames = [sClassPropNameCells{:}];
            end

            propNames = [];
            for k = 1:length(this.Properties)
                thisName = builder.makeValidName(this.Properties(k).Name);
                thisName = matlab.lang.makeUniqueStrings(...
                    [sClassPropNames, thisName], ...
                    [false(1, length(sClassPropNames)) true]);
                thisName = thisName(end);
                this.Properties(k).BuildName = thisName;
                propNames = [propNames thisName]; %#ok<AGROW>
            end
            
            this.PropNamesInScope = [sClassPropNames propNames];
            this.Uniqued = true;
        end
        
        function print(this, printer)
            printer.openScope("Stereotype: " + this.Name);
            
            for k = 1:length(this.Properties)
                this.Properties(k).print(printer);
            end
            
            printer.closeScope("Stereotype: " + this.Name);
        end
    end
end