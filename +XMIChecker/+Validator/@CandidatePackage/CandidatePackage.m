classdef CandidatePackage < XMIChecker.Validator.Validator
    %PACKAGE validates a candidate pacakge

    methods
        function obj = CandidatePackage(candidate,xmidb,foundElements)
            %PACKAGE Construct an instance of this class
            arguments
                candidate SysMLImport.internal.CandidatePackage
                xmidb SysMLImport.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % store the candidate
            obj.candidate = candidate;
            % if build then something in the project should exist
            if candidate.Build
                % if build is set have to check that all items under it are
                % built
                explorer = XMIChecker.CandidateExplorer("ParentPackage");
                fields = fieldnames(candidate);
                childFields = fields(~contains(lower(fields),"parent"));
                for i = 1:numel(childFields)
                    if isobject(candidate.(childFields{i})) &&...
                            ~isstring(candidate.(childFields{i}))
                        % call the explore on child fields to avoid finding
                        % parent(s)
                        explorer.explore(candidate.(childFields{i}));
                    end
                end
                % need to validate all the elements found during
                % exploration
                validators = XMIChecker.Validator.build( ...
                    explorer.dictionary.values,xmidb,foundElements);
                % need to parse result for validators
                % priority is fail, then warn, finally pass
                % any of each sets the results
                if any(cellfun(@(v) v.fail,validators))
                    obj.fail = 1;
                elseif any(cellfun(@(v) v.warn,validators))
                    obj.warn = 1;
                elseif any(cellfun(@(v) v.pass,validators))
                    obj.pass = 1;
                else
                    % no result...
                    error("No result was reported %s",candidate.Name);
                end
            else
                % assume there will be no sign of this one
                % mark it passed
                obj.pass = 1;
            end
        end
    end
end

