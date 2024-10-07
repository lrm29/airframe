classdef CandidateParameter < XMIChecker.Validator.Default
    %CANDIDATEPARAMETER validates candidate architecture parameters
    
    methods
        function obj = CandidateParameter(candidate,xmidb,foundElements)
            %CANDIDATEPARAMETER Construct an instance of this class
            arguments
                candidate SysMLConnector.internal.CandidateParameter
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call the super constructor
            obj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);

            % load the model, lookup the parameter parent architecture by
            % UUID, match the external UID of the parent architecture,
            % match the build name of the parameter.

            try
                zcMdl = systemcomposer.loadModel(candidate.ParentArch.ModelName);

                cleanupModel = onCleanup(@() close(zcMdl));
                
                archElement = zcMdl.lookup(UUID=candidate.ParentArch.SystemComposerUUID);            
    
                if ~isempty(archElement.Parameters)
                    paramLogIdx = strcmp(candidate.Name, {archElement.Parameters.Name});
    
                    if any(paramLogIdx)
                        param = archElement.Parameters(paramLogIdx);
    
                        if strcmp(param.Owner.ExternalUID, candidate.ParentArch.ExternalUID) ...
                               && strcmp(param.Name, candidate.BuildName)
                            obj.pass = 1;

                            return;
                        end
                    end
                end

            catch ME
                fprintf('Failed to check parameter ''%s'' with parent architecture ''%s'' in model ''%s'' with error:\n%s\n', ...
                    candidate.Name, candidate.ParentArch.Name, candidate.ParentArch.SimulinkModelName, getReport(ME));
            end

            % If we got to the bottom of the script, the validation failed.
            obj.fail = 1;            
        end
    end
end

