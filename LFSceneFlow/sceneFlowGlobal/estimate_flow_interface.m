function uvo = estimate_flow_interface(im1, im2, intr, method, params, extra) 

%ESTIMATE_FLOW_INTERFACE  Optical flow estimation with various methods
%
% Demo program
%     [im1, im2, tu, tv] = read_flow_file('middle-other', 1);
%     uv = estimate_flow_interface(im1, im2, 'classic+nl-fast');
%     [aae stdae aepe] = flowAngErr(tu, tv, uv2(:,:,1), uv2(:,:,2), 0)
%
%
% Authors: Deqing Sun, Department of Computer Science, Brown University
% Contact: dqsun@cs.brown.edu
% $Date: $
% $Revision: $
%
% Copyright 2007-2010, Brown University, Providence, RI. USA
% 
%                          All Rights Reserved
% 
% All commercial use of this software, whether direct or indirect, is
% strictly prohibited including, without limitation, incorporation into in
% a commercial product, use in a commercial service, or production of other
% artifacts for commercial purposes.     
%
% Permission to use, copy, modify, and distribute this software and its
% documentation for research purposes is hereby granted without fee,
% provided that the above copyright notice appears in all copies and that
% both that copyright notice and this permission notice appear in
% supporting documentation, and that the name of the author and Brown
% University not be used in advertising or publicity pertaining to
% distribution of the software without specific, written prior permission.        
%
% For commercial uses contact the Technology Venture Office of Brown University
% 
% THE AUTHOR AND BROWN UNIVERSITY DISCLAIM ALL WARRANTIES WITH REGARD TO
% THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR ANY PARTICULAR PURPOSE.  IN NO EVENT SHALL THE AUTHOR OR
% BROWN UNIVERSITY BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL
% DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
% PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
% ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
% THIS SOFTWARE.        


% Read in arguments
if nargin < 3
    method = 'classic+nl-fast';
end;

if (~isdeployed)
    addpath(genpath('utils'));
end

% Load default parameters
ope = load_of_method(method);

if nargin > 3
    ope = parse_input_parameter(ope, params);    
end;

% Uncomment this line if Error using ==> \  Out of memory. Type HELP MEMORY for your option.
%ope.solver    = 'pcg';  

% Prefilter the image
im1 = gaussFilt4D(im1, ope.sigmaP);
im2 = gaussFilt4D(im2, ope.sigmaP);

if size(im1, 5) > 1
    tmp1 = LFRGB2Gray(im1);
    tmp2 = LFRGB2Gray(im2);
    ope.images  = cat(length(size(tmp1))+1, tmp1, tmp2);
else
    
%     if isinteger(im1);
%         im1 = single(im1);
%         im2 = single(im2);
%     end;
    ope.images  = cat(length(size(im1))+1, im1, im2);
end;
ope.intr = intr;

% Use color for weighted non-local term
if ~isempty(ope.color_images)    
    if size(im1, 5) > 1        
        % Convert to Lab space       
        im1 = LFRGB2Lab(im1);          
        for j = 1:size(im1, 5);
            im1(:,:,:,:,j) = scale_image(im1(:,:,:,:,j), 0, 255);
        end;        
    end;    
    ope.color_images   = im1;
end;

% Mask: only compute flow where mask = true
if nargin >= 6 && isfield(extra, 'mask');
    ope.mask = extra.mask;
end

% Initial xy flow used for flow segmentation
if nargin >= 6 && isfield(extra, 'xyflow');
    ope.xyflow = extra.xyflow;
end
if nargin >= 6 && isfield(extra, 'segMap');
    ope.segMap = extra.segMap;
end

% Alpha map used for clg2d
if nargin >= 6 && isfield(extra, 'alphaMap');
    ope.alphaMap = extra.alphaMap;
    ope.alphaCen = centralSub(extra.alphaMap);
end
if nargin >= 6 && isfield(extra, 'alphaCen');
    ope.alphaCen = extra.alphaCen;
end

% Compute flow field
if nargin >= 6 && isfield(extra, 'initFlow');
    uv  = compute_flow(ope, extra.initFlow);
else
    uv  = compute_flow(ope);
end

if nargout == 1
    uvo = uv;
end;
