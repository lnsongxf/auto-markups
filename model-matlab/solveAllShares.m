function [ delta,Jac ] = solveAllShares(dtable,draws,params,method)
%solveAllShares: Solve shares for delta market by market
%   Can also return the Jacobian (d delta/ d theta)
% 
% Everything in this routine should be re-written in mex/C++ for speed

% newton's method or fixed-point iteration
if(strcmp(method,'newton'))    
    for i =1:max(dtable.mktid) % parfor here
        mkt_i    = dtable(dtable.mktid==i,:);
        dhat=solveNewton(mkt_i.delta,params,draws,mkt_i);
        % this returns the Jacobian once after convergence (for the
        % gradient computation)
        deltahat{i}=dhat;
        Jacpart{i}=RCBLP_Jacobian(params,draws,mkt_i,'sterr');
    end

elseif(strcmp(method,'fixed-point'))
    for i =1:max(dtable.mktid) % parfor here
        mkt_i    = dtable(dtable.mktid==i,:);
        
        % Clone draws, but for this particular mkt
        [drawstmp, paramstmp] = get_mkt(draws,params,i);                
        
        % don't start with bad values!
        if sum(~isfinite(mkt_i.delta)) > 0
            mkt_i.delta = log(mkt_i.sjt)-log(mkt_i.s0t);
        end
        % This is the BLP fixed point relation as a function handle
        f=@(x)(x + log(mkt_i.sjt) - log(rc_share_ind(x,paramstmp,drawstmp,mkt_i)));
        % Call the SQUAREM routine of (Raeynerts, Varadayan and Nash)
        [dhat]=fp_squarem(f,mkt_i.delta,'algorithm','contraction','con_tol',2e-12);
        deltahat{i}=dhat;
        % this returns the Jacobian once after convergence (for the
        % gradient computation)
        Jacpart{i}=RCBLP_Jacobian(paramstmp,drawstmp,mkt_i,'sterr'); %!! I will have to change this for ind. chars. !!
    end
end
% pull deltas and jacobian out of market by market cell arrays
% This way we dont need fixed # of products per market
delta=real(cat(1,deltahat{:}));
Jac=real(cat(1,Jacpart{:}));
    
end

function [drawstmp, paramstmp] = get_mkt(draws,params,i_mkt)
    
    drawstmp = draws;
    drawstmp.v = draws.v{i_mkt};
    drawstmp.H = draws.v{i_mkt};

    paramstmp = params;
    paramstmp.betai = params.betai{i_mkt};
    paramstmp.dbeta = params.dbeta{i_mkt};
    
end
