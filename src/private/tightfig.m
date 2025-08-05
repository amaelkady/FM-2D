function hfig = tightfig(hfig)
% tightfig: Alters a figure so that it has the minimum size necessary to
% enclose all axes in the figure without excess space around them.
% 
% Note that tightfig will expand the figure to completely encompass all
% axes if necessary. If any 3D axes are present which have been zoomed,
% tightfig will produce an error, as these cannot easily be dealt with.
% 
% Input
%
% hfig - handle to figure, if not supplied, the current figure will be used
%   instead.
%
%

    if nargin == 0
        hfig = gcf;
    end

    % There can be an issue with tightfig when the user has been modifying
    % the contnts manually, the code below is an attempt to resolve this,
    % but it has not yet been satisfactorily fixed
%     origwindowstyle = get(hfig, 'WindowStyle');
    set(hfig, 'WindowStyle', 'normal');
    
    % 1 point is 0.3528 mm for future use

    % get all the axes handles note this will also fetch legends and
    % colorbars as well
    hax = findall(hfig, 'type', 'axes');
    % TODO: fix for modern matlab, colorbars and legends are no longer axes
    hcbar = findall(hfig, 'type', 'colorbar');
    hleg = findall(hfig, 'type', 'legend');
    
    % get the original axes units, so we can change and reset these again
    % later
    origaxunits = get(hax, 'Units');
    
    % change the axes units to cm
    set(hax, 'Units', 'centimeters');
    
    pos = [];
    ti = [];
    
    % get various position parameters of the axes
    if numel(hax) > 1
%         fsize = cell2mat(get(hax, 'FontSize'));
        ti = cell2mat(get(hax,'TightInset'));
        pos = [pos; cell2mat(get(hax, 'Position')) ];
    else
%         fsize = get(hax, 'FontSize');
        ti = get(hax,'TightInset');
        pos = [pos; get(hax, 'Position') ];
    end
    
    if ~isempty (hcbar)
        
        set(hcbar, 'Units', 'centimeters');
        
        % colorbars do not have tightinset property
        for cbind = 1:numel(hcbar)
            %         fsize = cell2mat(get(hax, 'FontSize'));
            [cbarpos, cbarti] = colorbarpos (hcbar);

            pos = [pos; cbarpos];
            ti = [ti; cbarti];
        end
    end
    
    if ~isempty (hleg)
        
        set(hleg, 'Units', 'centimeters');
        
        % legends do not have tightinset property
        if numel(hleg) > 1
            %         fsize = cell2mat(get(hax, 'FontSize'));
            pos = [pos; cell2mat(get(hleg, 'Position')) ];
        else
            %         fsize = get(hax, 'FontSize');
            pos = [pos; get(hleg, 'Position') ];
        end
        ti = [ti; repmat([0,0,0,0], numel(hleg), 1); ];
    end
    
    % ensure very tiny border so outer box always appears
    ti(ti < 0.1) = 0.15;
    
    % we will check if any 3d axes are zoomed, to do this we will check if
    % they are not being viewed in any of the 2d directions
    views2d = [0,90; 0,0; 90,0];
    
    for i = 1:numel(hax)
        
        set(hax(i), 'LooseInset', ti(i,:));
%         set(hax(i), 'LooseInset', [0,0,0,0]);
        
        % get the current viewing angle of the axes
        [az,el] = view(hax(i));
        
        % determine if the axes are zoomed
        iszoomed = strcmp(get(hax(i), 'CameraViewAngleMode'), 'manual');
        
        % test if we are viewing in 2d mode or a 3d view
        is2d = all(bsxfun(@eq, [az,el], views2d), 2);
               
        if iszoomed && ~any(is2d)
           error('TIGHTFIG:haszoomed3d', 'Cannot make figures containing zoomed 3D axes tight.') 
        end
        
    end
    
    % we will move all the axes down and to the left by the amount
    % necessary to just show the bottom and leftmost axes and labels etc.
    moveleft = min(pos(:,1) - ti(:,1));
    
    movedown = min(pos(:,2) - ti(:,2));
    
    % we will also alter the height and width of the figure to just
    % encompass the topmost and rightmost axes and lables
    figwidth = max(pos(:,1) + pos(:,3) + ti(:,3) - moveleft);
    
    figheight = max(pos(:,2) + pos(:,4) + ti(:,4) - movedown);
    
    % move all the axes
    for i = 1:numel(hax)
        
        set(hax(i), 'Position', [pos(i,1:2) - [moveleft,movedown], pos(i,3:4)]);
        
    end
    
    for i = 1:numel(hcbar)
        
        set(hcbar(i), 'Position', [pos(i+numel(hax),1:2) - [moveleft,movedown], pos(i+numel(hax),3:4)]);
        
    end
    
    for i = 1:numel(hleg)
        
        set(hleg(i), 'Position', [pos(i+numel(hax)+numel(hcbar),1:2) - [moveleft,movedown], pos(i+numel(hax)+numel(hcbar),3:4)]);
        
    end
    
    origfigunits = get(hfig, 'Units');
    
    set(hfig, 'Units', 'centimeters');
    
    % change the size of the figure
    figpos = get(hfig, 'Position');
    
    set(hfig, 'Position', [figpos(1), figpos(2), figwidth, figheight]);
    
    % change the size of the paper
    set(hfig, 'PaperUnits','centimeters');
    set(hfig, 'PaperSize', [figwidth, figheight]);
    set(hfig, 'PaperPositionMode', 'manual');
    set(hfig, 'PaperPosition',[0 0 figwidth figheight]);    
    
    % reset to original units for axes and figure 
    if ~iscell(origaxunits)
        origaxunits = {origaxunits};
    end

    for i = 1:numel(hax)
        set(hax(i), 'Units', origaxunits{i});
    end

    set(hfig, 'Units', origfigunits);
    
%      set(hfig, 'WindowStyle', origwindowstyle);
     
end


function [pos, ti] = colorbarpos (hcbar)

    % 1 point is 0.3528 mm
    
    pos = hcbar.Position;
    ti = [0,0,0,0];
    
    if ~isempty (strfind (hcbar.Location, 'outside'))

        if strcmp (hcbar.AxisLocation, 'out')
            
            tlabels = hcbar.TickLabels;
            
            fsize = hcbar.FontSize;
            
            switch hcbar.Location
                
                case 'northoutside'
                    
                    % make exta space a little more than the font size/height
                    ticklablespace_cm = 1.1 * (0.3528/10) * fsize;
                    
                    ti(4) = ti(4) + ticklablespace_cm;
                    
                case 'eastoutside'
                    
                    maxlabellen = max ( cellfun (@numel, tlabels, 'UniformOutput', true) );
            
                    % 0.62 factor is arbitrary and added because we don't
                    % know the width of every character in the label, the
                    % fsize refers to the height of the font
                    ticklablespace_cm = (0.3528/10) * fsize * maxlabellen * 0.62;

                    ti(3) = ti(3) + ticklablespace_cm;
                    
                case 'southoutside'
                    
                    % make exta space a little more than the font size/height
                    ticklablespace_cm = 1.1 * (0.3528/10) * fsize;

                    ti(2) = ti(2) + ticklablespace_cm;
                    
                case 'westoutside'
                    
                    maxlabellen = max ( cellfun (@numel, tlabels, 'UniformOutput', true) );
            
                    % 0.62 factor is arbitrary and added because we don't
                    % know the width of every character in the label, the
                    % fsize refers to the height of the font
                    ticklablespace_cm = (0.3528/10) * fsize * maxlabellen * 0.62;

                    ti(1) = ti(1) + ticklablespace_cm;
                    
            end
            
        end
        
    end

end