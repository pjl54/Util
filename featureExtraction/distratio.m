%Program for new distance ratio
% December 10 2018 - Changed from a bunch of if statemetns to 1% of points
% - Patrick Leo
function dratio= distratio(xy)
%xy being the matrix containin x and y coordinates
n=size(xy,1); %assuming 2 column vectors

points = round(linspace(1,length(xy(:,1)),max(length(xy(:,1))*.01,3)));

lx = xy(points,1);
ly = xy(points,2);
lxy = [lx,ly];
% 
% if n >=800
%     k=n/200;
%     j=floor(k)*200;
%     if abs(n-j) ==  0;
%          j=j-199;
%     else
%         j=j+1;
%     end
%     
%     s=(j-1)/200;
%     lx = zeros(1,s+1);
%     ly = zeros(1,s+1);
%     for i=1:s+1;
%         lx(i)=xy(1+(i-1)*200,1);
%         ly(i)=xy(1+(i-1)*200,2);
%     end
%     lxy=[lx;ly];
% end
% 
% if n > 400 & n < 800
%     k=n/100;
%     j=floor(k)*100;
%     if abs(n-j) == 0;
%        j=j-99;
%     else
%         j=j+1;
%     end
%     s=(j-1)/100;
%     lx = zeros(1,s+1);
%     ly = zeros(1,s+1);
%     for i=1:s+1;
%         lx(i)=xy(1+(i-1)*100,1);
%         ly(i)=xy(1+(i-1)*100,2);
%     end
%     lxy=[lx,ly];
% end
% 
% if n <= 400 && n > 10
%     k=n/10;
%     j=floor(k)*5;
%     if abs(n-j) >= 51;
%        j=j+51;
%     else
%         j=j+1;
%     end
%     s=(j-1)/5;
%     lx = zeros(1,s+1);
%     ly = zeros(1,s+1);
%     for i=1:s+1;
%         lx(i)=xy(1+(i-1)*5,1);
%         ly(i)=xy(1+(i-1)*5,2);
%     end
%     lxy=[lx,ly];
% end
% 
% if n <= 10
%     k=n/4;
%     j=floor(k)*4;
%     if abs(n-j) >= 21;
%        j=j+21;
%     else
%         j=j+1;
%     end
%     s=(j-1)/2;
%     lx = zeros(1,s+1);
%     ly = zeros(1,s+1);
%     for i=1:s+1;
%         lx(i)=xy(1+(i-1)*3,1);
%         ly(i)=xy(1+(i-1)*3,2);
%     end
%     lxy=[lx,ly];
% end


%for long distances
dislong = zeros(1,length(lxy)-1);
for a=1:length(lxy)-1;
    dislong(a)=sqrt((lx(a)-lx(a+1)).^2+(ly(a)-ly(a+1)).^2);
end
dislong=dislong';

%for smaller distances
disshort = zeros(1,length(xy)-1);
for b=1:length(xy)-1;
    disshort(b)=sqrt((xy(b,1)-xy(b+1,1)).^2+(xy(b,2)-xy(b+1,2)).^2);
end
disshort=disshort';
dl=sum(dislong);
ds=sum(disshort);
dratio=dl/ds;