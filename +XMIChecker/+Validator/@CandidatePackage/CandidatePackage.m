classdef CandidatePackage < XMIChecker.Validator.Validator
    %PACKAGE validates a candidate pacakge

    methods
        function obj = CandidatePackage(candidate,~,~)
            %PACKAGE Construct an instance of this class
            arguments
                candidate SysMLConnector.internal.CandidatePackage
                ~
                ~
            end
            % store the candidate
            obj.candidate = candidate;
            % if build is set check for dir
            if candidate.Build
                project = currentProject();
                if exist(project.RootFolder+candidate.BuiltElement,"dir")
                    % build set and folder exists within the project
                    obj.pass = 1;
                else
                    % build was set but folder wasn't created
                    obj.fail = 1;
                end
            else
                % validate that dir is empty
                if strcmp(candidate.BuiltElement,"")
                    obj.pass = 1;
                else
                    obj.fail = 1;
                end
            end
        end
    end
end

