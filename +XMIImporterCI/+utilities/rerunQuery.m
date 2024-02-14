function artifactToUse = rerunQuery(query,artifact)
%RERUNQUERY re-runs the query and matches results with end of file address
%from the artifact
arguments
    query padv.Query
    artifact padv.Artifact
end
newArtifacts = query.run();
reportedPath = artifact.ArtifactAddress.getFileAddress();
reportedPath = strrep(reportedPath,"/",filesep);
artifactToUse = [];
for newArtifact = newArtifacts
    if endsWith(newArtifact.ArtifactAddress.getFileAddress, reportedPath)
        % found the real artifact
        artifactToUse = newArtifact;
        break;
    end
end
end

