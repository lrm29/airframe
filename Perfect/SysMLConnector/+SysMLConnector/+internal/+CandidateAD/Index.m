classdef Index < handle
    properties
        DB
    end

    methods
        function idx = Index
            idx.DB = containers.Map;
        end

        function addElement(idx, id, element)
            assert(~isKey(idx.DB, id), 'element id must be unique')
            idx.DB(id) = element;
        end

        function updateElement(idx, id, element)
            assert(isKey(idx.DB, id), 'element id not found in db')
            idx.DB(id) = element;
        end

        function removeElement(idx, id)
            remove(idx.DB, id);
        end

        function element = getElement(idx, id)
            if isKey(idx.DB, id)
                element = idx.DB(id);
            else
                element = [];
            end
        end
    end
end