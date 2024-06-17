classdef CandidateRequirement < XMIChecker.Validator.Validator
    %CANDIDATEREQUIREMENT validates candidate requirements

    methods
        function obj = CandidateRequirement(candidate,xmidb,~)
            %CANDIDATEREQUIREMENT Construct an instance of this class
            % process requirement on arrival
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateRequirement
                xmidb (1,1) SysMLConnector.internal.CandidateAD.internal.XMIDatabase
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
                            if ismember("ExternalUID", ...
                                    requirementSet.CustomAttributeNames)
                                % the XMIDB can be checked so check
                                if ismember( ...
                                        requirement.getAttribute("ExternalUID"), ...
                                        xmidb.LookupTable.keys)
                                    % found it 
                                    obj.pass = 1;
                                else
                                    % did not find this in the XMIDB 
                                    % failure
                                    obj.fail = obj.fail + 1;
                                end
                            else
                                % unable to confirm requirement in XMIDB
                                % add a warning
                                obj.warn = obj.warn + 1;
                                % mark the result as a failure
                                obj.fail = obj.fail + 1;
                            end
                            % passed so we are done
                            close(requirementSet);
                            return;
                        end
                    end
                end
                % close the requirement set before going on
                close(requirementSet);
            end
            % nothing is found fail
            obj.fail = 1;
        end
    end
end