function L = evaluate_log_posterior(this, op)
%EVALUATE_LOG_POSTERIOR computes the log-posterior (negative energy) of the
%   flow fields UV 
%   Actually only proportional to the log posterior since the variance of neither the
%   spatial nor the data terms is considered
%
% This is a member function of the class 'classic_nl_optical_flow'. 
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

% Spatial term
S = this.spatial_filters;
p = 0;

for i = 1:length(S)

    o_ = convn(op(:,:,:,:,1), S{i}, 'valid');
    p_ = convn(op(:,:,:,:,2), S{i}, 'valid');

    if isa(this.rho_spatial_u{i}, 'robust_function')
        
        p = p - this.lambda*sum(evaluate(this.rho_spatial_u{i}, o_(:)))...
            - this.lambda*sum(evaluate(this.rho_spatial_v{i}, p_(:)));
        
    elseif isa(this.rho_spatial_u{i}, 'gsm_density')
        
        p   = p + this.lambda*sum(evaluate_log(this.rho_spatial_u{i}, o_(:)'))...
                    + this.lambda*sum(evaluate_log(this.rho_spatial_v{i}, p_(:)'));
                
    else
        error('evaluate_log_posterior: unknown rho function!');
    end;
end;

% likelihood
op_pad = cat(5,op,zeros(size(op,1),size(op,2),size(op,3),size(op,4)));
It = partial_deriv(this.images, this.intr, op_pad, this.interpolation_method,...
        [],[],[],[],...
        0.6, this.mask);
    
if isa(this.rho_data, 'robust_function')

    l   = -sum(evaluate(this.rho_data, It(:)));
    
elseif isa(this.rho_data, 'gsm_density')
    
    l   = sum(evaluate_log(this.rho_data, It(:)'));
    
else
    error('evaluate_log_posterior: unknown rho function!');
end;

L = p + l;

if this.display
    fprintf('spatial\t%3.2e\tdata\t%3.2e\n', p, l);
end;
