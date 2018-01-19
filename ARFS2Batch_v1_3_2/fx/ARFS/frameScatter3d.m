function [] = frameScatter3d( xy, dim, cluster )
%frameScatter Displays a more understandable representation of the motion trace

ht=dim(1);
wd=dim(2);
x = xy(:,1);
y = xy(:,2);
nrf = length(x);

if ~isempty(cluster)
    colors = [
        1.000, 0.000, 0.000;
        0.000, 1.000, 0.000;
        0.000, 0.000, 1.000;
        0.000, 0.000, 0.000;
        0.000, 1.000, 1.000;
        0.486, 0.988, 0.000;
        0.000, 0.980, 0.604;
        0.000, 0.749, 1.000;
        0.098, 0.098, 0.439;
        0.580, 0.000, 0.827;
        0.545, 0.271, 0.075;
        0.502, 0.000, 0.000;
        0.643, 0.165, 0.165;
        ];
    while length(colors(:,1)) < length(unique(cluster))
        colors(end+1,:) = rand(1,3); %#ok<AGROW>
    end
end

% figure;
title('Motion Trace','FontName','Arial','FontSize',16);
xlabel('x (px)','FontName','Arial','FontSize',14);
ylabel('y (px)','FontName','Arial','FontSize',14);
hold on;
if isempty(cluster)
    for i=1:nrf
        xx = [x(i), x(i)+wd, x(i)+wd, x(i)];
        yy = [y(i), y(i), y(i)-ht, y(i)-ht];
        fill3(xx,yy,i.*ones(numel(xx),1),'k','FaceColor','none')
    end
else
    for i=1:nrf
        xx = [x(i), x(i)+wd, x(i)+wd, x(i)];
        yy = [y(i), y(i), y(i)-ht, y(i)-ht];
        fill3(xx, yy,i.*ones(numel(xx),1),'r','FaceColor','none','EdgeColor',colors(cluster(i),:))
    end
end
view([90 90 90])

minx = max(x); % counterintuitive i know, but it's for the common area
miny = max(y)-ht+1;
maxx = min(x)+wd;
maxy = min(y);

% xxx = [max(x),min(x)+wd-1,min(x)+wd-1,max(x),max(x),min(x)+wd-1,min(x)+wd-1,max(x)];
% yyy = [min(y),min(y),max(y)-ht+1,max(y)-ht+1,min(y),min(y),max(y)-ht+1,max(y)-ht+1];
zzz = [1,1,nrf,nrf];

%top wall
fill3([minx,maxx,maxx,minx],...
    maxy.*ones(1,4),...
    zzz,'r','facecolor','none','edgecolor',[1 140/255 0],'linestyle','--','linewidth',2);
%right wall
fill3(maxx.*ones(1,4),...
    [maxy,miny,miny,maxy],...
    zzz,'r','facecolor','none','edgecolor',[1 140/255 0],'linestyle','--','linewidth',2);
%lower wall
fill3([minx,maxx,maxx,minx],...
    miny.*ones(1,4),...
    zzz,'r','facecolor','none','edgecolor',[1 140/255 0],'linestyle','--','linewidth',2);
%left wall
fill3(minx.*ones(1,4),...
    [maxy,miny,miny,maxy],...
    zzz,'r','facecolor','none','edgecolor',[1 140/255 0],'linestyle','--','linewidth',2);
hold off;
axis tight equal off;

% for i=1:nrf-1
%     xx = [x(i), x(i+1)]; yy = [y(i) y(i+1)];
%     if isempty(cluster)
%         plot(xx,yy,'r');
%     else
%         plot(xx,yy,'k');
%     end
% end

end

