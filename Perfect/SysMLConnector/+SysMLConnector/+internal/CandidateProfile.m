classdef CandidateProfile < SysMLConnector.internal.CandidateElement
% CANDIDATEPROFILE Helper class for SysMLConnector.internal.import that holds candidate Profiles.
    properties
        Stereotypes = [];
    end
    
    methods
        function this = CandidateProfile(pExtID, pName)
            this@SysMLConnector.internal.CandidateElement(pExtID);
            this.Name = pName;
        end
        
        function addStereotype(this, stype)
            this.Stereotypes = [this.Stereotypes stype];
        end
        
        function fixupStereotypeNames(this, builder)
            sNames = [];
            for k = 1:length(this.Stereotypes)
                sNames = [sNames ...
                          builder.makeValidName(this.Stereotypes(k).Name)]; %#ok<AGROW>
            end
            if ~isempty(sNames)
                sNames = matlab.lang.makeUniqueStrings(sNames, 1:length(sNames), ...
                                                      namelengthmax);
                for k = 1:length(this.Stereotypes)
                    this.Stereotypes(k).Name = sNames(k);
                end
            end
        end
        
        function print(this, printer)
            printer.openScope("Profile: " + this.Name);
            
            for k = 1:length(this.Stereotypes)
                this.Stereotypes(k).print(printer);
            end
            
            printer.closeScope("Profile: " + this.Name);
        end
    end
end
