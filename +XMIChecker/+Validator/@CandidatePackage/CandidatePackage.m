classdef CandidatePackage < XMIChecker.Validator.Validator
    %PACKAGE validates a candidate pacakge

    properties (SetAccess=protected)
        implentedDirectory string = string.empty
    end

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
                % record directory if filled in
                if candidate.ZCProjectFolder ~= ""
                    obj.implentedDirectory = candidate.ZCProjectFolder;
                end
                % if build is set have to check that all items under it are
                % built
                explorer = XMIChecker.CandidateExplorer(...
                    @(fieldname) startsWith(fieldname,"Build") ...
                    && ~contains(fieldname,"Parent"));
                % explore
                explorer.explore(candidate);
                % make a copy of the values
                children = explorer.dictionary.values;
                % remove the candidate as property filter
                children = children(~strcmp(explorer.dictionary.keys, ...
                    candidate.ExtElementID));
                % that gives me the direct children based on "Build"
                % attributes, but I need all the children
                childExplorer = XMIChecker.CandidateExplorer(...
                    @(fieldname) ~contains(fieldname,"Parent"));
                % explore again
                childExplorer.explore(children);
                % get the full set of candidates
                children = childExplorer.dictionary.values;
                validators = XMIChecker.Validator.build( ...
                    children,xmidb,foundElements);
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

