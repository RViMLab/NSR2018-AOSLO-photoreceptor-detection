function [ output_args ] = coord_stats(pname, fname,lut,micronboxsize, imsize, imfname )

        % Determine username from filename
        % NOTE: This section only really works on post- Neitz subjects...
        [idpiece1 remain]=strtok(fname,'_'); %Take Referrer
        [idpiece2 remain]=strtok(remain,'_'); %Take ID #
        subID=[idpiece1 '_' idpiece2]; 
        clear remain idpiece1 idpiece2;

        LUTindex=find(strcmp(lut{1},subID));

        axiallength = lut{2}(LUTindex);
        pixelsperdegree = lut{3}(LUTindex);
        
        micronsperdegree = (291*axiallength)/24;
        micronsperpixel = 1 / (pixelsperdegree / micronsperdegree);
        
        if strcmp(fname(end-8:end),'cones.txt')
            coords=dlmread(fullfile(pname,fname),'\t');
            coords=coords*[0 1;1 0];
        else   
            coords=dlmread(fullfile(pname,fname),'\t');
        end
        
        
        [pix_crop_row pix_crop_col]=calc_pixel_cutoff(micronsperpixel,micronboxsize,imsize);
        
%         fid=fopen('pixcropnew.csv','a');
%         fprintf(fid,'%s,%f,%f\n',fname,pix_crop_row,pix_crop_col);
%         fclose(fid);
        
        clipped_coords=coordclip_npoly(coords,[pix_crop_row imsize(1)-pix_crop_row],...
                                              [pix_crop_col imsize(2)-pix_crop_col]);

                                          
                                          
%         dlmwrite([imfname(1:end-10) '_80um_manualcoord.csv'],(clipped_coords-repmat(min(clipped_coords,[],1),length(clipped_coords),1) +3))

        clipped_box_row_size = imsize(1)-(2*pix_crop_row);
        clipped_box_col_size = imsize(2)-(2*pix_crop_col);
        
        
%         im = imread(imfname);
%         imwrite( im(pix_crop_row:imsize(1)-pix_crop_row, pix_crop_col:imsize(2)-pix_crop_col), [imfname(1:end-9) '80um.tif'] );
        

        determine_coord_stats(fname, fullfile(pname,[getparent(pname,0,'short') '_coordstats_' num2str(micronboxsize) 'um_box.csv']),...
                              clipped_coords, micronsperpixel,[pix_crop_row imsize(1)-pix_crop_row; pix_crop_col imsize(2)-pix_crop_col],...
                              [clipped_box_row_size clipped_box_col_size]);
                          
end
        

