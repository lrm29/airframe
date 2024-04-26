function [C, iA, iC] = unique(A, varargin)
    if iscell(A)
        arrStrings = arrayfun(@(element) element{1}.toString, A, UniformOutput=false);
    else
        arrStrings = arrayfun(@(element) element.toString, A, UniformOutput=false);
    end
    [~, iA, iC] = unique(arrStrings, varargin{:});
    C = A(iA);
end