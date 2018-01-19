function [ coordout ] = cone_add_remove(im,coords, outputtype)
    
    imagesize = size(im);
    cellimage=im;
    coordout =0;
    
    zoomlevel=7;
    zoomnum=[50 100 150 200 300 400 800 1000 1300 1600];
    
    linImgs = cell(length(zoomnum),1); % Preallocate interp'd image sequence
    interpType = 'bilinear';
    
    linlog = true; % true if linear viewing, false if log viewing
    logImgs = linImgs; % Preallocate log versions of interp'd images
    origImgs = linImgs; % log versions should only be made from unadjusted imgs

    xcoords = -1;
    ycoords = -1;
    relcoords = coords; % Get relative positions for use after interp    
    
    % Set up function handles
    fh_cb = @removepress; % Create function handle for remove press detection
    fh_ac = @addpress; % Create function for cell addition
    button_detect = @keypress;
    x_out_detect = @xoff;
    
    % Set up imscrollpane parameters, spawn imscrollpane
    fig_hand=figure('name','Press Enter When Finished, (Use +/- to zoom, v to switch views)','MenuBar','none','Toolbar','none');
    im_hand = imshow(cellimage);
    hold on; % Plot the data from the coord list
%         linkdata(plot_hand,'on');

    fig_hand_scrl = imscrollpanel(fig_hand, im_hand);
    imcontrast(fig_hand_scrl);

    % Grab the pointer to the frame we spawned, store its location
    top_pane=get(fig_hand_scrl,'Parent');
    main_im=findall(fig_hand_scrl,'type','image');
    set(main_im,'ButtonDownFcn',fh_ac); % Set the image to being button sensitive
    iptPointerManager(top_pane,'disable'); % MUST do this, or the contrast cursor will not go away...
    
    % Set figure parameters
    % Check to see if the image is bigger than the screen- if it is larger
    % than the screen, then shrink it by a zoomsize factor until it fits-
    % then center it in the middle of the screen, and display.
    screensize = get(0,'ScreenSize');
    screensize = [screensize(4) screensize(3)]; % rearrange so it is row/col
    
    difference = 0;

    while any(difference < 100)
        difference = round(screensize/(zoomnum(zoomlevel)/100)) - imagesize;
        zoomlevel = zoomlevel-1;
    end
    
    zoomlevel = zoomlevel+1;
    scaledimsize = round(imagesize*(zoomnum(zoomlevel)/100));
    
    set(top_pane,'Position',[round(difference(2)/2) round((screensize(1)-scaledimsize(1))/2) scaledimsize(2) scaledimsize(1)]);
    set(top_pane,'Pointer','crosshair');
    set(top_pane,'KeyPressFcn',button_detect);
    set(top_pane,'CloseRequestFcn',x_out_detect);
    clear tmp;
    
    im_hand_api=iptgetapi(fig_hand_scrl); % Grab an api so we can modify the scrollpane
    defMag = 100; % Set default api magnification to 100%
    
    % Create first interpolated image
    newZoom = zoomnum(zoomlevel);
    scale = newZoom/defMag;
    if isempty(linImgs{zoomlevel})
        linImgs{zoomlevel} = imresize(cellimage,scale,'method',interpType);
        origImgs{zoomlevel} = linImgs{zoomlevel};
    end
    im_hand_api.replaceImage(linImgs{zoomlevel})

    % Plot points
    if ~isempty(coords)
        xcoords = coords(:,1).*scale;
        ycoords = coords(:,2).*scale;
        plot_hand=plot(xcoords,ycoords,'.','Color','r');
        title('Press Enter When Finished, (Use +/- to zoom, v to switch views)');
    else
        plot_hand=plot(-1,-1,'.','Color','r');
        title('Press Enter When Finished, (Use +/- to zoom, v to switch views)');
    end
    
    set(plot_hand,'XDataSource','xcoords');
    set(plot_hand,'YDataSource','ycoords');
    set(plot_hand,'ButtonDownFcn',fh_cb);
    hold off;    
%     im_hand_api.setMagnification(zoomnum(zoomlevel)/defMag);
    
        
    figure(top_pane);
      
    %repaint();
    % Wait until the user presses enter (killing the figure) before continuing
    waitfor(gcf);

    function removepress(src,evnt)
              
       if strcmp(get(gcf,'SelectionType'),'alt')
            point=get(gca,'CurrentPoint');
            
            scale = zoomnum(zoomlevel)/defMag;
            relcoords = coords.*scale;
            pointScaled = point./scale;
            
            disp(['Right clicked at: (' num2str(pointScaled(1)) ',' num2str(pointScaled(3)) ')' ]);
            coords=delete_single_cone( scale, coords, [pointScaled(1) pointScaled(3)]);
            
            relcoords = coords.*scale;
            xcoords = relcoords(:,1);
            ycoords = relcoords(:,2);
            % Refresh image and coordinates
%             repaint();
            refreshdata(plot_hand,'caller');
            drawnow;
       else

       end
    end

    function addpress(src,evnt)
              
       if strcmp(get(gcf,'SelectionType'),'normal')
           point=get(gca,'CurrentPoint');
           
           scale = zoomnum(zoomlevel)/defMag;
           relcoords = coords.*scale;
           pointScaled = point./scale;
           disp(['Left clicked at: (' num2str(pointScaled(1)) ',' num2str(pointScaled(3)) ')']);
                
           coords=[coords;[(pointScaled(1)) (pointScaled(3))]];
           relcoords=[relcoords;[(point(1)) (point(3))]];
            
           xcoords = relcoords(:,1);
           ycoords = relcoords(:,2);
           % Refresh image and coordinates
%             repaint();
           refreshdata(plot_hand,'caller');
           drawnow;
           
       end
    end

    function keypress(src,evnt)

        % Character 13 is the enter character...
        if strcmp(get(gcf,'CurrentCharacter'),char(13))
            if strcmp(outputtype,'file')
                [fname, pname]=uiputfile('*.csv');

                if fname ~= 0
                    dlmwrite(fullfile(pname,fname),coords,',');
                end
                [fname, pname]=uiputfile('*.eps');

                figure(2); imagesc(im); colormap gray; axis image; axis off;
                hold on; plot(coords(:,1),coords(:,2),'.');

                saveas(gcf,fullfile(pname,[fname(1:end-4) '.eps']),'epsc');

%             elseif strcmp(outputtype,'var');
%                 coordout=coords;
            end
            coordout=coords;
            close(gcf);
        elseif strcmp(get(gcf,'CurrentCharacter'),'-') % 
            
            % Save contrast adjustment
            temImg = getimage(gcf);
            if linlog
                linImgs{zoomlevel} = temImg;
            else
                logImgs{zoomlevel} = temImg;
            end
            
            % Adjust zoom
            if zoomlevel>1
                zoomlevel=zoomlevel-1;
                dzoom = true;
            else
                zoomlevel=1;
                dzoom = false;
            end
            
            % Resize and get linear/log versions
            scale = zoomnum(zoomlevel)/defMag;
            if isempty(linImgs{zoomlevel})
                linImgs{zoomlevel} = ...
                    imresize(cellimage,scale,'method',interpType);  
                origImgs{zoomlevel} = linImgs{zoomlevel};
            end
            if isempty(logImgs{zoomlevel})
                img = origImgs{zoomlevel};
                logImgs{zoomlevel} = uint8(255*(mat2gray(log(double(img)+1))));
            end
            
            % Check intensity distributions
            if dzoom
                if linlog
                    linImgs = checkImhist(linImgs, zoomlevel, '-');
                else
                    logImgs = checkImhist(logImgs, zoomlevel, '-');
                end
            end
            
            disp(['Zooming to:' num2str(zoomnum(zoomlevel))]);
            
            % Display image
            if linlog
                im_hand_api.replaceImage(linImgs{zoomlevel});
            else
                im_hand_api.replaceImage(logImgs{zoomlevel});
            end
            
            % Display points
            relcoords = coords.*scale;
            xcoords = relcoords(:,1);
            ycoords = relcoords(:,2);
            refreshdata(plot_hand,'caller');
%             im_hand_api.setMagnification(zoomnum(zoomlevel)/defMag);
            
        elseif strcmp(get(gcf,'CurrentCharacter'),'+') % 
            
            % Save contrast adjustment
            temImg = getimage(gcf);
            if linlog
                linImgs{zoomlevel} = temImg;
            else
                logImgs{zoomlevel} = temImg;
            end
            
            % Adjust zoom
            if zoomlevel<length(zoomnum)
                zoomlevel=zoomlevel+1;
                dzoom = true;
            else
                zoomlevel=length(zoomnum);
                dzoom = false;
            end
            
            % Resize and get linear/log versions
            scale = zoomnum(zoomlevel)/defMag;
            if isempty(linImgs{zoomlevel})
                linImgs{zoomlevel} = ...
                    imresize(cellimage,scale,'method',interpType);
                origImgs{zoomlevel} = linImgs{zoomlevel};
            end
            if isempty(logImgs{zoomlevel})
                img = origImgs{zoomlevel};
                logImgs{zoomlevel} = uint8(255*(mat2gray(log(double(img)+1))));
            end
            
            % Check intensity distributions
            if dzoom
                if linlog
                    linImgs = checkImhist(linImgs, zoomlevel, '+');
                else
                    logImgs = checkImhist(logImgs, zoomlevel, '+');
                end
            end
            
            disp(['Zooming to:' num2str(zoomnum(zoomlevel))]);
            
            % Display image
            if linlog
                im_hand_api.replaceImage(linImgs{zoomlevel});
            else
                im_hand_api.replaceImage(logImgs{zoomlevel});
            end
            
            % Display points
            relcoords = coords.*scale;
            xcoords = relcoords(:,1);
            ycoords = relcoords(:,2);
            refreshdata(plot_hand,'caller');
%             im_hand_api.setMagnification(zoomnum(zoomlevel)/defMag);
            
        elseif strcmp(get(gcf,'CurrentCharacter'),'v') %
            
            % Save contrast adjustment
            temImg = getimage(gcf);
            if linlog
                linImgs{zoomlevel} = temImg;
            else
                logImgs{zoomlevel} = temImg;
            end
            
            linlog = ~linlog;
            if linlog
                im_hand_api.replaceImage(linImgs{zoomlevel});
                disp('Now viewing with a linear scale');
            else
                if isempty(logImgs{zoomlevel})
                    % get log img, convert back to uint8, offset by 1 to avoid 0's
                    img = origImgs{zoomlevel};
                    logImgs{zoomlevel} = uint8(255*(mat2gray(log(double(img)+1))));
                end
                im_hand_api.replaceImage(logImgs{zoomlevel});
                disp('Now viewing with a log scale');
            end
        end
    end

    % @Override: This function is designed to run if someone clicks off the window
    % instead of pressing enter.
    function xoff(src,evnt)
        %% My Handling code here...
       % disp('Exiting cell coordinate modification.');
        if coordout~=0  % If it wasn't an exit condition, fill in the coordinates
            
            if strcmp(outputtype,'file')
                [fname pname]=uiputfile('*.csv');

                dlmwrite(fullfile(pname,fname),coords,',');
                coordout=1;
            elseif strcmp(outputtype,'var');
                coordout=coords;
            end    
        end
        
%         close all;
        
        %% Matlab default code
        if isempty(gcbf)
           if length(dbstack) == 1
              warning(['MATLAB:closereq'...
              'Calling closereq from the command line is now obsolete.'...
                     'use close instead']);
           end
           close force
        else
           delete(gcbf);
        end
        
    end


end