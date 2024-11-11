classdef CandidateParameter < XMIChecker.Validator.Validator
    %CANDIDATEPARAMETER validates candidate architecture parameters
    
    methods
        function obj = CandidateParameter(candidate,~,~)
            %CANDIDATEPARAMETER Construct an instance of this class
            arguments
                candidate SysMLConnector.internal.CandidateArchitecture.CandidateParameter
                ~
                ~
            end
            % call the super constructor
            obj@XMIChecker.Validator.Validator(candidate);

            % load the model, lookup the parameter parent architecture by
            % UUID, match the external UID of the parent architecture,
            % match the build name of the parameter.

            try
                result = obj.checkParameter(candidate);
            catch ME
                fprintf('Failed to check parameter ''%s'' with parent architecture ''%s'' in model ''%s'' with error:\n%s\n', ...
                    candidate.Name, candidate.Owner.Name, candidate.Owner.SimulinkModelName, getReport(ME));

                result = false;
            end

            if result
                obj.pass = 1;
                obj.warn = 0;
                obj.fail = 0;
            else
                obj.pass = 0;
                obj.warn = 0;
                obj.fail = 1;
            end
        end
    end

    methods (Static)
        function tf = checkParameter(candidateParameter)
            arguments
                candidateParameter SysMLConnector.internal.CandidateArchitecture.CandidateParameter
            end

            tf = false; 

            zcMdl = systemcomposer.loadModel(candidateParameter.Owner.ModelName);

            cleanupModel = onCleanup(@() close(zcMdl));
            
            archElement = zcMdl.lookup(UUID=candidateParameter.Owner.SystemComposerUUID);            

            if ~isempty(archElement.Parameters)
                paramLogIdx = strcmp(candidateParameter.BuildName, [archElement.Parameters.Name]);

                if any(paramLogIdx)
                    param = archElement.Parameters(paramLogIdx);

                    if strcmp(param.Owner.ExternalUID, candidateParameter.Owner.ExtElementID) ...
                           && strcmp(param.Name, candidateParameter.BuildName)
                        tf = true;
                    end
                end
            end

            if isempty(candidateParameter.BuildName)
                % this means it was not built
                %invert the result reported
                tf = ~tf;
            end
        end
    end
end

