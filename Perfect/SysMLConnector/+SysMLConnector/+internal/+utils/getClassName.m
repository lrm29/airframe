function className = getClassName(obj)
    results = regexp(class(obj), '[.]?(?<className>\w+)$', 'names');
    className = results.className;
end