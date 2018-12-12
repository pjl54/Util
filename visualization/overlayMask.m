function overlayMask(img,varargin)

imshow(img); hold on

transImg = repmat(ones(size(varargin{1})),[1,1,3]);

colors = linspecer(4);
colors = [0,1,0;0,0,1];

for(k = 1:length(varargin))
    mask = varargin{k};

    green = transImg .* reshape(colors(k,:),[1,1,3]);
    hold on
    h = imshow(green);
    hold off
    set(h, 'AlphaData',mask .* .3)
end