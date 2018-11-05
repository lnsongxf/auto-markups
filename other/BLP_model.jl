function [share, x, demand] = BLP_model(dimension, seed)
%BLP_model Simulate the demand of BLP model
%
% -------------------------------------------------------------------------
% INPUT
%
% dimension   a structure which contains
%               n_simu    --- number of simulated samples
%               n_attr    --- number of product attributes
%               n_product --- number of products
%
% seed        random seed
%
% -------------------------------------------------------------------------
% OUTPUT
%
% share       simulated market share (not including outside option)
%
% x           mean utility used in the simulation
%
% demand      simulated demand function, whose interface is the following
%             [welfare, share, H] = demand(x),
%             where x is the mean utility
%                   welfare is the expected welfare of agents
%                   share is the market share
%                   H is the Hessian matrix of welfare as a function of x
%
% -------------------------------------------------------------------------
% Utility Model:
% u_ij = x_j + e_i                  %%%< x_j ---- mean utility of product j
%                                   %%%< e_i ---- latent taste shock
% where
%
% x_j = z_j * b                     %%%< z_j ---- product attributs of product j
%                                   %%%< b   ---- parameter
%
% e_i = epsilon_i + z_j * w_i       %%%< epsilon_i --- logistic shock
%                                   %%%< w_i       --- random coefficients
%

%% Prepareation
rng(seed, 'twister');  % fix random seed

n_simu = dimension.n_simu;
n_attr = dimension.n_attr;
n_product = dimension.n_product;

%% draw product attributs
z = randn(n_attr, n_product);
b = rand(n_attr, 1);
x = z' * b;

zw = z' * randn(n_attr, n_simu);


demand = @(x) BLP_demand(x, zw);
[~, share, ~] = demand(x);

end

function [welfare, share, H] = BLP_demand(x, zw)

    [n_product, n_simu] = size(zw);

    x_zw = x + zw;
    max_x_zw = max(x_zw, [], 1);
    share_weight = exp(-max_x_zw) + sum(exp(x_zw - max_x_zw), 1);

    welfare = sum(log(double(share_weight)) + max_x_zw) / n_simu;

    if (nargout > 1)
        share_ind = exp(x_zw - max_x_zw) ./ share_weight;
        share = mean(share_ind, 2);

        if (nargout > 2)
           H = zeros(n_product, n_product);
           for i = 1:n_simu
             share_i = share_ind(:, i);
             H = H + diag(share_i) - share_i * share_i';
           end
           H = H / n_simu;
        end
    end

end
