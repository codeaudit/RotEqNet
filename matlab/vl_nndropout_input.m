function [y,mask] = vl_nndropout_input(x,varargin)
%VL_NNDROPOUT CNN dropout.
%   [Y,MASK] = VL_NNDROPOUT(X) applies dropout to the data X. MASK
%   is the randomly sampled dropout mask. Both Y and MASK have the
%   same size as X.
%
%   VL_NNDROPOUT(X, 'rate', R) sets the dropout rate to R. Rate is defined
%   as the probability that a variable will be zeroed (i.e. it is one 
%   minus the expected value of MASK).
%
%   [DZDX] = VL_NNDROPOUT(X, DZDY, 'mask', MASK) computes the
%   derivatives of the blocks projected onto DZDY. Note that MASK must
%   be specified in order to compute the derivative consistently with
%   the MASK randomly sampled in the forward pass. DZDX and DZDY have
%   the same dimesnions as X and Y respectivey.
%
%   Note that in the original paper on dropout, at test time the
%   network weights for the dropout layers are scaled down to
%   compensate for having all the neurons active. In this
%   implementation the dropout function itself already does this
%   compensation during training. So at test time no alterations are
%   required.

% Copyright (C) 2014-16 Andrea Vedaldi, Karel Lenc.
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

opts.groups = ones(1,size(x,3)) ;
opts.prob = 1;
opts.mask = [] ;

backMode = numel(varargin) > 0 && ~ischar(varargin{1}) ;
if backMode
  dzdy = varargin{1} ;
  opts = vl_argparse(opts, varargin(2:end)) ;
else
  opts = vl_argparse(opts, varargin) ;
end

% determine mask
%scale = 1 / (1 - opts.rate) ;
scale = 1;%bsxfun(@times,opts.groups,opts.prob(:)) / (numel(opts.groups)*sum(opts.prob));
if isa(x, 'gpuArray')
  dataType = classUnderlying(x) ;
else
  dataType = class(x) ;
end
switch dataType
  case 'single'
    scale = single(scale) ;
  case 'double'
    scale = double(scale) ;
end

if backMode && isempty(opts.mask)
  warning('vl_nndropout: when using in backward mode, the mask should be specified') ;
end
if isempty(opts.mask)
  % product determines data type
  if isa(x,'gpuArray')
    %opts.mask = scale * (gpuArray.rand(size(x(1,1,:,:,1)), 'single') >= opts.rate) ;
    opts.mask = gpuArray(permute(opts.groups(randi(size(opts.groups,1),1),:),[1 3 2]));
    opts.mask = opts.mask * gpuArray(numel(opts.mask) / sum(opts.mask(:)));
  else
    %opts.mask = scale * (rand(size(x(1,1,:,:,1)), 'single') >= opts.rate) ;
    opts.mask = scale*single(permute(opts.groups(randi(size(opts.groups,1),1),:),[1 3 2]));
    opts.mask = opts.mask * single(numel(opts.mask) / sum(opts.mask(:)));
  end
end

% Apply dropout mask. Note that mask is either `single` or `double`
% and a CPU or GPU array like the input argument `x`.
if ~backMode
  y = bsxfun(@times,x,opts.mask) ;
else
  y = bsxfun(@times,dzdy,opts.mask) ;
end
mask = opts.mask ;
