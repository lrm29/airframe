function array = toArray(seq)
    array = [];
    seqSize = seq.size;

    if seqSize > 0
        array = cell(0, seqSize);
        for i = 1:seqSize
            array{i} = seq.at(i);
        end

        try %#ok<TRYNC>, Might not be homogeneous
            % Try to homogenize the array if possible.
            array = [array{:}];
        end
    end
end