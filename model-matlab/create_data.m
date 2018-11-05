%% Script to import data

% use "table" fnc

% For now, modify dtable to have ind. chars. 

clear
load sample.mat

draws.dimX = size(dtable.x2,2)+1; % X's + price, no constant

dtable = dtable(1:3000,:);
draws.nMkt = max(dtable.mktid);

% Redraw -- MC antitehtic draws 
% (to do: quasi-MC -- too many dims for quad. -- sparse grids?)
%----- User Input ------%
draws.ns = 500;
%-----------------------%
rng(381)
draws.v = cell(1,draws.nMkt);
for tx = 1:draws.nMkt
    draws.v{tx} = randn(draws.ns/2,draws.dimX);
    draws.v{tx} = [draws.v{tx};-draws.v{tx}];
end

draws.w = (1/draws.ns)*ones(size(draws.v{1},1),1);

% Make fake ind. chars. 
rng(420)
draws.H = cell(1,draws.nMkt);

for tx = 1:draws.nMkt

    H1 = log(exp(10 + .2*randn(draws.ns,1)));
    H1 = (H1 - mean(H1))/std(H1);

    H2 = randi(6,[draws.ns,1]);
    H2 = H2 - mean(H2);

    draws.H{tx} = [H1 H2];
end

% draws.H = [log(exp(10 + .2*randn(draws.ns,1))) randi(6,[draws.ns,1])];
draws.dimH = size(draws.H{1},2);



save sampleInd.mat

%% Macro Data

%% Beta_i Draws
% ns = 1000;


%% Ind Characteristics draws (H_i = inc, family size, etc.)

%% Number of parameters
% Think about model here...each x fully interacted with H? That might be
% the easiest thing to do given we have limited x and H_i.





