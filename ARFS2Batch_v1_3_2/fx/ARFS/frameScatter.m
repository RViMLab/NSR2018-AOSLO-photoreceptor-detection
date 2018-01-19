function [] = frameScatter( xy, dim, cluster )
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
        patch(xx,yy,'k','FaceColor','none')
    end
else
    for i=1:nrf
        xx = [x(i), x(i)+wd, x(i)+wd, x(i)];
        yy = [y(i), y(i), y(i)-ht, y(i)-ht];
        patch(xx, yy, 'r','FaceColor','none','EdgeColor',colors(cluster(i),:))
    end
end
% for i=1:nrf-1
%     xx = [x(i), x(i+1)]; yy = [y(i) y(i+1)];
%     if isempty(cluster)
%         plot(xx,yy,'r');
%     else
%         plot(xx,yy,'k');
%     end
% end
hold off;
axis equal;

end

