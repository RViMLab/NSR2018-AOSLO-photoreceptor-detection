function [ pix_cutoff_row pix_cutoff_col  ] = calc_pixel_cutoff( micronsperpixel,micronboxsize,imsize )


    adjusted_box_size = micronboxsize/micronsperpixel; % The box size we need for the correct micron amount
    
    total_clip_size_row = imsize(1)-adjusted_box_size;
    
    total_clip_size_col = imsize(2)-adjusted_box_size;
    
    pix_cutoff_row = total_clip_size_row/2;
    pix_cutoff_col = total_clip_size_col/2;
end

