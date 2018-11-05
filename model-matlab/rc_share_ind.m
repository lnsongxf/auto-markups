function [pjt,pijt]=rc_share_ind(delta, params,draws,mkt)
% This gives the RC choice probabilities after integration (pjt)
% Also gives the individual choice probabilities (pijt) for derivatives
%
% This function should be re-written in mex/C++ for improved speed
    [ns k] = size(draws.v);
    u1 = repmat(delta,[1 ns]) + [mkt.price mkt.x2]*params.betai(:,1:draws.dimX)' ...
        + [mkt.price mkt.x2]*params.betai(:,draws.dimX+1:draws.dimX+draws.dimX)' ...
        + [mkt.price mkt.x2]*params.betai(:,2*draws.dimX+1:2*draws.dimX+draws.dimX)';
    m = max(u1,[],1);
    utils = exp(bsxfun(@minus,u1,m));
    share_weight = exp(-m) + sum(utils);
    pijt = bsxfun(@rdivide,utils,share_weight);
    pjt=pijt*draws.w;
    
% under/overflow safety
% should write an under/overflow safe version of this function
%    m = max(u1); 
%    utils = exp(bsxfun(@minus,u1,m));
%    pijt = bsxfun(@rdivide,utils,exp(-m)+sum(utils));

end