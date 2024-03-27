classdef CandidateRequirement < XMIChecker.Validator.Validator
    %CANDIDATEREQUIREMENT validates candidate requirements

    methods
        function obj = CandidateRequirement(candidate,~,~)
            %CANDIDATEREQUIREMENT Construct an instance of this class
            % process requirement on arrival
            arguments
                candidate (1,1) SysMLImport.internal.CandidateRequirement
                ~
                ~
            end
            % store the candidate
            obj.candidate = candidate;
            % assume we are in the project being processed
            project = currentProject();
            %% find requirement files
            requirementFiles = project.Files( ...
                endsWith([project.Files.Path],"slreqx"));
            %% load each file and check if success
            for requirementFile = requirementFiles
                requirementSet = slreq.load(requirementFile.Path);
                requirements = requirementSet.find("Id",candidate.ReqID);
                if ~isempty(requirements)
                    for requirement = requirements
                        if strcmp(requirement.Description,candidate.Text) && ...
                                strcmp(requirement.Summary,candidate.Name)
                            % going to assume ID + Text is unique
                            obj.pass = 1;
                            % passed so we are done
                            return;
                        end
                    end
                end
            end
            %% TODO: check XMI database
            % nothing is found fail
            obj.fail = 1;
        end
    end
end