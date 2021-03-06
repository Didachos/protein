function cvx_optval = log_sum_exp( x, dim )

%LOG_SUM_EXP   CVX internal version.

error( nargchk( 1, 2, nargin ) );
cvx_expert_check( 'log_sum_exp', x );

sx = size( x );
if nargin < 2 | isempty( dim ),
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim, true ),
    error( 'Second argument must be a valid dimension.' );
end

%
% Quick exits
%

sx( end + 1 : dim ) = 1;
nx = sx( dim );
sy = sx;
sy( dim ) = 1;
if nx == 0,
    sx( dim ) = 1;
    cvx_optval = -Inf * ones( sy );
    return
elseif nx == 1,
    cvx_optval = x;
    return;
elseif any( sx == 0 ),
    cvx_optval = zeros( sy );
    return
end

%
% Determine the expression types
%

persistent remap
if isempty( remap ),
    remap_2 = cvx_remap( 'real' );
    remap_1 = cvx_remap( 'convex' ) & ~remap_2;
    remap = remap_1 + 2 * remap_2;
end
v = reshape( remap( cvx_classify( x ) ), sx );
v = min( v, [], dim );

%
% Process each type of expression one piece at a time
%

vu = sort( v );
vu = vu([true,diff(vu)~=0]);
nv = length( vu );
if nv > 1,
    y = cvx( sy, [] );
    if prod(sx(1:dim+1))>1 & prod(sx(dim+1:end))>1,
        perm = [ dim, 1:dim-1, dim+1:length(sx) ];
        x  = permute( x, perm );
        v  = permute( v, perm );
        y  = permute( y, perm );
        dim = 1;
    end
end
for k = 1 : nv,

    %
    % Select the category of expression to compute
    %

    vk = vu( k );
    if nv == 1,
        xt = x;
        sz = sy;
    else
        t = v == vk;
        xt = cvx_subsref( x, cvx_expand_dim( t, dim, nx ) );
        sx = size( xt );
        sz = sx;
        sz( dim ) = 1;
    end

    %
    % Perform the computations
    %

    switch vk,
        case 0,
            % Invalid
            error( sprintf( 'Disciplined convex programming error:\n    Illegal operation: log_sum_exp( {%s} ).', cvx_class( xt ) ) );
        case 1,
            % Affine, convex
            cvx_begin
                variable w( sx )
                epigraph variable z( sz )
                { cvx_accept_convex( x ) - cvx_expand_dim( z, dim, nx ), 1, w } == exponential( sx );
                sum( w, dim ) == 1;
            cvx_end
        case 2,
            % Constant
            cvx_optval = cvx( log_sum_exp( cvx_constant( xt ) ) );
        otherwise,
            error( 'Shouldn''t be here.' );
    end

    %
    % Store the results
    %

    if nv == 1,
        y = cvx_optval;
    else
        y = cvx_subsasgn( y, t, cvx_optval );
    end

end

% Reshape again, just in case
y = reshape( y, sy );

% Copyright 2008 Michael C. Grant and Stephen P. Boyd. 
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
