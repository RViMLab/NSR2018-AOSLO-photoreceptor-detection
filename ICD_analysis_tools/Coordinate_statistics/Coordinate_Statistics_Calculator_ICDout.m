% Robert Cooper
% 9-24-2014
%
% This script calculates the coordinate statistics from a folder.
clear
close all

windowsize = [  ];
%% Crop the coordinates to this size in microns, and calculate the area from it.
% usewindowsize = 1;
%% Use the window size instead of the size from the image for area calculations

[basepath] = uigetdir(pwd);

[fnamelist, isdir ] = read_folder_contents(basepath,'csv');

[tmp, lutData] = load_scaling_file(fullfile(basepath,'LUT.csv'));
clear tmp

first = true;

proghand = waitbar(0,'Processing...');

for i=1:size(fnamelist,1)

    if ~isdir{i} && ~strcmp(fnamelist{i},'LUT.csv')
        
        waitbar(i/size(fnamelist,1), proghand, strrep(fnamelist{i},'_','\_') );
        
        [idpiece1 remain]=strtok(fnamelist{i},'_'); %Take Referrer
        [idpiece2 remain]=strtok(remain,'_'); %Take ID #
        subID=[idpiece1 '_' idpiece2]; 
        clear remain idpiece1 idpiece2;

        % Calculate the scale for this ID
        LUTindex=find(strcmp(lutData{1},subID));

        axiallength = lutData{2}(LUTindex);
        pixelsperdegree = lutData{3}(LUTindex);

        micronsperdegree = (291*axiallength)/24;
        micronsperpixel = 1 / (pixelsperdegree / micronsperdegree);


        %Read in coordinates - assumes x,y
        coords=dlmread(fullfile(basepath,fnamelist{i}));

        
        if exist(fullfile(basepath, [fnamelist{i}(1:end-length('_coords.csv')) '.tif']), 'file')
            
            im = imread( fullfile(basepath, [fnamelist{i}(1:end-length('_coords.csv')) '.tif']));
            
            width = size(im,2);
            height = size(im,1);
            
            if ~isempty(windowsize)
                pixelwindowsize = windowsize/micronsperpixel;

                diffwidth  = (width-pixelwindowsize)/2;
                diffheight = (height-pixelwindowsize)/2;
            else

                pixelwindowsize = [height width]./micronsperpixel;
                diffwidth=0;
                diffheight=0;
            end
            
            clipped_coords =coordclip(coords,[diffwidth  width-diffwidth],...
                                             [diffheight height-diffheight],'i');
                                         
            clip_start_end = [diffheight height-diffheight diffwidth  width-diffwidth];
        else

            width  = max(coords(:,1)) - min(coords(:,1));
            height = max(coords(:,2)) - min(coords(:,2));
            
            if ~isempty(windowsize)
                pixelwindowsize = windowsize/micronsperpixel;

                diffwidth  = (width-pixelwindowsize)/2;
                diffheight = (height-pixelwindowsize)/2;
            else

                pixelwindowsize = [height width]./micronsperpixel;
                diffwidth=0;
                diffheight=0;
            end
            
            clipped_coords =coordclip(coords,[min(coords(:,1))+diffwidth  max(coords(:,1))-diffwidth],...
                                             [min(coords(:,2))+diffheight max(coords(:,2))-diffheight],'i');

            clip_start_end = [min(coords(:,2))+diffheight max(coords(:,2))-diffheight min(coords(:,1))+diffwidth  max(coords(:,1))-diffwidth];
        end

        

           
        warning off;
        [ success ] = mkdir(basepath,'Results');
        warning on;
                      

        statistics = determine_mosaic_stats_ICDout( clipped_coords, micronsperpixel, clip_start_end ,[pixelwindowsize pixelwindowsize], 2,[basepath,'\Results'], subID );
        
      
      
        if success
            
            if first
                fid= fopen(fullfile(basepath,'Results',[getparent(basepath,'short') '_coordstats.csv'] ),'w');

                % If it is the first time writing the file, then write the
                % header
                fprintf(fid,'Filename');

                % Grab the names of the fields we're working with
                datafields = fieldnames(statistics);
                
                numfields = size(datafields,1);                
                
                k=1;
                
                while k <= numfields

                    val = statistics.(datafields{k});
                    
                    % If it is a multi-dimensional field, remove it
                    % from our csv, and write it separately.
                    if size(val,1) ~= 1 || size(val,2) ~= 1   
                        disp([datafields{k} ' removed!']);
                        datafields = datafields([1:k-1 k+1:end]);                        
                        numfields = numfields-1;                        
                    else
%                         disp([fields{k} ' added!']);
                        fprintf(fid,',%s',datafields{k});
                        k = k+1;
                    end 

                    
                end  
                fprintf(fid,'\n');

                first = false;
                
            else % If it isn't the first entry, then append.
                fid= fopen(fullfile(basepath,'Results',[getparent(basepath,'short') '_coordstats.csv'] ),'a');
            end

            % Write the file we've worked on as the first column
            fprintf(fid,'%s', fnamelist{i});

            for k=1:size(datafields,1)
%                 fields{k}
                if size(val,1) == 1 || size(val,2) == 1
                    val = statistics.(datafields{k});

                    fprintf(fid,',%1.2f',val);
                end
            end

            fprintf(fid,'\n');
            fclose(fid);
        else
            error('Failed to make results folder! Exiting...');
        end

    end
    

end


close(proghand);