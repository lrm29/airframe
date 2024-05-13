function toFront(app)
    % Bring the app to the foreground (UI workaround).
    warning('off', 'MATLAB:callback:error') % Nuisance message
    drawnow;
    figure(app.UIFigure)
    warning('on', 'MATLAB:callback:error')
end