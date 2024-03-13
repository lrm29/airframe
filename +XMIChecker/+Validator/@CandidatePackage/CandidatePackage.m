classdef CandidatePackage < handle
    %PACKAGE validates a candidate pacakge

    properties (SetAccess=protected)
        % the explorer has all the elements (mapped to IDs) that need to be
        % found in order to prove this package was imported
        explorer = XMIChecker.CandidateExplorer
        % skip means nothing to validate it was reported but not imported
        skip logical = false;
        % keep the candidate around
        candidate SysMLImport.internal.CandidatePackage
    end

    methods
        function obj = CandidatePackage(candidate)
            %PACKAGE Construct an instance of this class
            arguments
                candidate SysMLImport.internal.CandidatePackage
            end
            % store the candidate
            obj.candidate = candidate;
            % if build then something in the project should exist
            if candidate.Build
                % if build is set have to check that all items under it are
                % built
                obj.explorer = XMIChecker.CandidateExplorer("ParentPackage");
                fields = fieldnames(candidate);
                childFields = fields(~contains(lower(fields),"parent"));
                for i = 1:numel(childFields)
                    if isobject(candidate.(childFields{i})) &&...
                            ~isstring(candidate.(childFields{i}))
                        % call the explore on child fields to avoid finding
                        % parent(s)
                        obj.explorer.explore(candidate.(childFields{i}));
                    end
                end
            else
                % assume there will be no sign of this one
                % skip this one
                obj.skip = true;
            end
        end
    end
end

