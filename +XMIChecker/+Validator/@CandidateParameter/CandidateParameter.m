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

            % assume fail
            obj.fail = true;

            % load the model, lookup the parameter parent architecture by
            % UUID, match the external UID of the parent architecture,
            % match the build name of the parameter.
            zcMdl = systemcomposer.loadModel(candidate.ParentArch.SimulinkModelName);
            cleanupModel = onCleanup(@() close(zcMdl));
            
            [~, archElement] = zcMdl.lookup(UUID=candidate.ParentArch.SystemComposerUUID);            

            if ~isempty(archElement.Parameters)
                paramLogIdx = strcmp(candidate.SystemComposerUUID, {archElement.Parameters.UUID});

                if any(paramLogIdx)
                    param = archElement.Parameters(paramLogIdx);

                    if strcmp(param.Owner.ExternalUID, candidate.ParentArch.ExternalUID) ...
                           && strcmp(param.Name, candidate.BuildName)
                        obj.fail = false;
                    end
                end
            end
        end
    end
end

