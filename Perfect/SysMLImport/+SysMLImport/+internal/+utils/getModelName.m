function modelName = getModelName(element)
    % Get model name for various element types (needed mostly because
    % lifeline is missing Model property, g3243131).
    if isa(element, 'systemcomposer.interaction.Lifeline')
        modelName = element.RelatedElements(1).Model.Name;
    elseif startsWith(class(element), 'systemcomposer.activitydiagram.')
        modelName = element.p_TraitParent.cachedWrapper.Model.Name;
    elseif isa(element, 'systemcomposer.arch.Model')
        modelName = element.Name;
    else
        modelName = element.Model.Name;
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end