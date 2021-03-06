function net = cnn_mnist_init_size5(varargin)
% CNN_MNIST_LENET Initialize a CNN similar for MNIST
opts.batchNormalization = true ;
opts = vl_argparse(opts, varargin) ;

rng('default');
rng(0) ;

f=1/100 ;
net.layers = {} ;
angle_n = 17;
net.layers{end+1} = struct('type', 'convsteer', ...
                           'weights', {{f*randn(9,9,1,6, 'single'), zeros(6, 1, 'single')}}, ...
                           'angle_n',angle_n,...
                           'stride', 1, ...
                           'pad', 4) ;
net.layers{end+1} = struct('type', 'relu','leak',0.0) ;
%net.layers{end+1} = struct('type', 'dropout', 'rate', 0.3) ;
net.layers{end+1} = struct('type', 'poolangle','bins',0,'angle_n',angle_n) ;
net.layers{end+1} = struct('type', 'dropout', 'rate', 0.0) ;
% net.layers{end+1} = struct('type', 'pool', ...
%                            'method', 'max', ...
%                            'pool', [2 2], ...
%                            'stride', 2, ...
%                            'pad', 0) ;
net.layers{end+1} = struct('type', 'pool_ext', 'pool', [2 2]);
net.layers{end+1} = struct('type', 'convsteer', ...
                           'weights', {{f*randn(9,9,6,16,2, 'single'),zeros(16,1,'single')}}, ...
                           'angle_n',angle_n,...
                           'stride', 1, ...
                           'pad', 4,...
                            'learningRate', [1 0.1]) ;
net.layers{end+1} = struct('type', 'relu','leak',0.0) ;
net.layers{end+1} = struct('type', 'dropout', 'rate', 0.0) ;
net.layers{end+1} = struct('type', 'poolangle', ...
                            'bins',0,'angle_n',angle_n) ;
net.layers{end+1} = struct('type', 'pool_ext', 'pool', [2 2]);
net.layers{end+1} = struct('type', 'dropout', 'rate', 0.0) ;
%net.layers{end+1} = struct('type', 'pool_ext', 'pool', [2 2]);
net.layers{end+1} = struct('type', 'convsteer', ...
                           'weights', {{f*randn(9,9,16,32,2, 'single'), zeros(32,1,'single')}}, ...
                           'angle_n',angle_n,...
                           'stride', 1, ...
                           'pad', 1,...
                            'learningRate', [1 0.1]) ;
net.layers{end+1} = struct('type', 'relu','leak',0.0) ;
net.layers{end+1} = struct('type', 'poolangle', ...
                            'bins',1,'angle_n',angle_n) ;
net.layers{end+1} = struct('type', 'dropout', 'rate', 0.0) ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(1,1,32,128, 'single'), zeros(1,128,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0,...
                            'learningRate', [0.5 0.05]) ;
net.layers{end+1} = struct('type', 'relu','leak',0.1) ;
net.layers{end+1} = struct('type', 'dropout', 'rate', 0.7) ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(1,1,128,10, 'single'), zeros(1,10,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0,...
                            'learningRate', [0.5 0.05]) ;
net.layers{end+1} = struct('type', 'softmaxloss') ;

% optionally switch to batch normalization
if opts.batchNormalization
    i = 3;
    while 1
        if strcmp(net.layers{i}.type,'conv') || strcmp(net.layers{i}.type,'convsteer')
            net = insertBnorm(net, i) ;
            i = i + 1;
        end
        i = i + 1;
        if i >= numel(net.layers)
            break;
        end
    end
end

% Meta parameters
net.meta.inputSize = [28 28 1] ;
net.meta.trainOpts.learningRate = [0.1*ones(1,10) 0.03*ones(1,10) 0.01*ones(1,10) 0.003*ones(1,10) 0.001*ones(1,10)] ;
net.meta.trainOpts.weightDecay = 0.01 ;
net.meta.trainOpts.numEpochs = numel(net.meta.trainOpts.learningRate) ;
net.meta.trainOpts.batchSize = 600 ;

% Fill in defaul values
net = vl_simplenn_tidy(net) ;


% --------------------------------------------------------------------
function net = insertBnorm(net, l)
% --------------------------------------------------------------------

ndim = size(net.layers{l}.weights{1}, 3);


if size(net.layers{l}.weights{1},5) == 2
    layer = struct('type', 'bnormangle', ...
                   'weights', {{ones(ndim, 1, 'single'), zeros(ndim, 1, 'single')}}, ...
                   'learningRate', [1 1 0.05], ...
                   'weightDecay', [0 0 0]) ;
else
    layer = struct('type', 'bnorm', ...
               'weights', {{ones(ndim, 1, 'single'), zeros(ndim, 1, 'single')}}, ...
               'learningRate', [1 1 0.05], ...
               'weightDecay', [0 0 0]) ;
end
net.layers{l}.biases = [] ;
net.layers = horzcat(net.layers(1:l-1), layer, net.layers(l:end)) ;
