function [ ] = show_2Demojis( eids_plot, emojis )
% 2014/03/29: display the all emojis 
    
    unicodes = {emojis.col_2};
    unicodes = unicodes(eids_plot(:,1));
    N_PLOT = size(eids_plot,1);
    basepath = 'emojiPic/';
    imgWidth = 0.005;
    
    figure;
    
    for n = 1:N_PLOT,
        
        unicode = unicodes{n};
        filename = lower(unicode(3:end));
        filepath = [basepath, filename,'.png'];
        
        plot_config;
        img = imread(filepath);
        %uniquebgcolor = [0 0 0]; % <- select a color that does not exist in your image!!!
        %img = imread(filepath,'BackgroundColor',uniquebgcolor);
        %mask = bsxfun(@eq,img,reshape(uniquebgcolor,1,1,3));
        
        hold on;   %# Add to the plot        
        %image([eids_plot(n,2)-imgWidth eids_plot(n,2)+imgWidth],[eids_plot(n,3)+imgWidth eids_plot(n,3)-imgWidth],img,'alphadata',1-double(all(mask,3)));
        image([eids_plot(n,2)-imgWidth eids_plot(n,2)+imgWidth],[eids_plot(n,3)+imgWidth eids_plot(n,3)-imgWidth],img);
    end  
hold on;
%plot(0);
xlabel('First principle component');
ylabel('Second principle component');
%xlim([-0.05, 0.07]);
%ylim([-0.1 0.02]);
saveas(gcf, 'poster_pca.pdf');
end

