function [ ] = show_emojis( eids_plot, emojis )
% 2014/03/29: display the all emojis 
    N_COLS = 8;
    N_ROWS = 8;

    N_PLOT = length(eids_plot);
    
    unicodes = {emojis.col_2};
    unicodes = unicodes(eids_plot);
    
    figure;
    basepath = 'emojiPic/';
    
    plot_offset = 0;
    for n = 1:N_PLOT,
        
        
        unicode = unicodes{n};
        filename = lower(unicode(3:end));
        filepath = [basepath, filename,'.png'];
        
        subplot(N_ROWS,N_COLS,n+plot_offset);
        %subaxis(N_ROWS,N_COLS,n+plot_offset,'Spacing', 0, 'Padding', 0, 'Margin', 0);
        %axis off
        %imshow(filepath,'Border','tight')
        pic  = imread(filepath);
        imagesc(pic);
        set(gca,'xtick',[],'ytick',[])
        title(sprintf('%d',eids_plot(n)), 'color',[0,0,0]);
        %xlabel(sprintf('%d',eids_plot(n)), 'color',[0,1,0])
        %[X1,map1]=imread(filepath);
        %subimage(X1,map1)
        
        % update after first round
        %plot_offset = N_COLS-1;
    end
    
    %ax = subplot(N_ROWS,N_COLS,N_PLOT+plot_offset+1);
    %text(0.5,0.5,mytext);
    %set (ax,'visible','off','fontSize',14,'fontWeight','bold');
    
 
end

