function listing = getCellNames(varargin)


if nargin == 0
    name = '.';
elseif nargin == 1
    name = varargin{1};
else
    error('Too many input arguments.')
end

listing = dir(fullfile(name(),'**\*.*'));
listing = listing([listing.isdir]);

inds = [];


 for k = 1:length(listing)
    if any(strcmp(listing(k).name, {'.', '..', 'output'}))
        inds(end + 1) = k;
    end
 end

listing(inds) = [];   

end