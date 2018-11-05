function [param]=extract_params(pp,draws)
% note since this is user customizable this does NOT do any input
% checking

% NOTE: We may want to make the parameters more flexible (time varying?). Then
% things will get a bit tricker. 

% All X's + price have rc. All X's + price interact with all H's

% param.betai = [];
param.betai = cell(1,draws.nMkt);
param.dbeta = cell(1,draws.nMkt);
for tx = 1:draws.nMkt
    for ix = 1:draws.dimX
        param.betai{tx} = [param.betai{tx} pp(ix)*draws.v{tx}(:,ix)];
    end

    for ix = 1:draws.dimH
    
        begindex = draws.dimX+1 + (ix-1)*draws.dimX;
        endindex = begindex+draws.dimX-1;
        param.betai{tx} = [param.betai{tx} repmat(pp(begindex:endindex)',draws.ns,1).*draws.H{tx}(:,ix)];
    
    end

    param.dbeta{tx} = [draws.v{tx}(:,1:draws.dimX) draws.H{tx}];

    
end

% The betamask is a matrix where each row corresponds to an element of
% betai and consists of two columns.
% column 1: the index of the corresponding column of x2
% column 2: the index of the corresponding column of dbeta
% the first column should never be greater than dim(x2)
% the second column should never be greater than dim(dbeta)

% In this example, we have 2 H's, and they are intereacted with each of the
% three [price x]. We set up the betai matrix so that the first 3 columns
% are the random coeffs, the next 3 are each of the [price x] intereacted
% with H1, and the final 3 are each of the [price x] interactes with H2.

% See RCBLP_Jacobian.m and the subfunction JacSigma for how this is used. 

param.betamask = [1 1; 
                 2 2; 
                 3 3;
                 1 4;
                 2 4;
                 1 4;
                 2 5;
                 1 5;
                 2 5];
                         
             
% Each entry in dbeta corresponds to the derivative of beta_i.
% It is possible to have fewer entries in dbeta than there are in
% betai.

% param.dbeta = [draws.v(:,1:draws.dimX) draws.H];

% These are upper and lower bounds on parameter values. Some parameters
% should only take on positive value (such as standard deviations).

param.lb = [0  0  0  -Inf -Inf -Inf -Inf -Inf -Inf];
param.ub = [Inf Inf Inf Inf Inf Inf Inf Inf Inf];




end