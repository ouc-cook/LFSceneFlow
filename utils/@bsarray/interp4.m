function varargout = interp4(varargin)
% bsarray/interp4: 4-D interpolation (table lookup)
% usage: RI = interp4(B,XI,YI,UI,VI);
%    or: RI = interp4(B,XI,YI,UI,VI,EXTRAPVAL);
%
% arguments:
%   B - bsarray object having tensorOrder 2. The positions of the
%       x-coordinates of the underlying data array are assumed to be
%       X = s(2).*(1:Nx), where Nx is the number of data points in the X
%       dimension (i.e., second element of get(B,'dataSize')), and s
%       is the element spacing (i.e., get(B,'elementSpacing')). The
%       positions of the y-coordinates of the underlying data array are
%       assumed to be Y = s(1).*(1:Ny). The positions of the u-coordinates
%       of the underlying data array are assumed to be U = s(3).*(1:Nu).
%       The positions of the v-coordinates of the underlying data array are
%       assumed to be V = s(3).*(1:Nv).
%   XI - x-coordinates of points at which to interpolate B.
%   YI - y-coordinates of points at which to interpolate B. YI must be the
%       same size as XI.
%   UI - u-coordinates of points at which to interpolate B. UI must be the
%       same size as XI.
%   VI - v-coordinates of points at which to interpolate B. VI must be the
%       same size as VI.
%
%   EXTRAPVAL - value to return for points in XI, YI, UI, or VI that are
%       outside the ranges of X, Y, U, and V, respectively.
%       Default EXTRAPVAL = NaN.
%
%   RI - the values of the underlying bsarray B evaluated at the points in
%       the array XI.
%

% author: Sizhuo Ma

% parse input arguments
[b,xi,yi,ui,vi,extrapval] = parseInputs(varargin{:});

% get flag to determine if basis functions in each dimension are centred or
% shifted
m = double(get(b,'centred'));
mx = m(2); my = m(1); mu = m(4); mv = m(3);

% get number of data elements and coefficients, determine amount of padding
% that has been done to create coefficients
nData = get(b,'dataSize');
nDatax = nData(2); nDatay = nData(1); nDatau = nData(4); nDatav = nData(3);
n = get(b,'coeffsSize');
nx = n(2); ny = n(1); nu = n(4); nv = n(3);
padNum = (n-nData-1)/2;
padNumx = padNum(2); padNumy = padNum(1); padNumu = padNum(4); padNumv = padNum(3);

% get the spacing between elements, and then construct vectors of the
% locations of the data and of the BSpline coefficients
h = get(b,'elementSpacing');
hx = h(2); hy = h(1); hu = h(4); hv = h(3);
xCol = hx.*((1-padNumx):(nDatax+padNumx+1))';
xDataCol = xCol((1+padNumx):(end-padNumx));
yCol = hy.*((1-padNumy):(nDatay+padNumy+1))';
yDataCol = yCol((1+padNumy):(end-padNumy));
uCol = hu.*((1-padNumu):(nDatau+padNumu+1))';
uDataCol = uCol((1+padNumu):(end-padNumu));
vCol = hv.*((1-padNumv):(nDatav+padNumv+1))';
vDataCol = vCol((1+padNumv):(end-padNumv));

% turn evaluation points into a column vector, but retain original size so
% output can be returned in same size as input
siz_xi = size(xi);
siz_ri = siz_xi;

% grab the BSpline coefficients
cMat = get(b,'coeffs');

% initialize some variables for use in interpolation
numelXi = numel(xi);
riMat = zeros(numelXi,1);
p = 1:numelXi;

% Find indices of subintervals, x(k) <= u < x(k+1),
% or u < x(1) or u >= x(m-1).
kx = min(max(1+floor((xi(:)-xCol(1))/hx),1+padNumx),nx-padNumx) + 1-mx;
ky = min(max(1+floor((yi(:)-yCol(1))/hy),1+padNumy),ny-padNumy) + 1-my;
ku = min(max(1+floor((ui(:)-uCol(1))/hu),1+padNumu),nu-padNumu) + 1-mu;
kv = min(max(1+floor((vi(:)-vCol(1))/hv),1+padNumv),nv-padNumv) + 1-mv;
sx = (xi(:) - xCol(kx))/hx;
sy = (yi(:) - yCol(ky))/hy;
su = (ui(:) - uCol(ku))/hu;
sv = (vi(:) - vCol(kv))/hv;

% perform interpolation
d = get(b,'degree'); dx = d(2); dy = d(1); du = d(4); dv = d(3);
xflag = (~mx && mod(dx,2));
yflag = (~my && mod(dy,2));
uflag = (~mu && mod(du,2));
vflag = (~mv && mod(dv,2));

for l = 1:ceil((du+1)/2)
    Bu1 = evalBSpline(su+l-(1+mu)/2,du);
    Bu2 = evalBSpline(su-l+(1-mu)/2,du);
    for k = 1:ceil((dv+1)/2)
        Bv1 = evalBSpline(sv+k-(1+mv)/2,dv);
        Bv2 = evalBSpline(sv-k+(1-mv)/2,dv);
        for j=1:ceil((dx+1)/2) % loop over BSpline degree in x dimension
            Bx1 = evalBSpline(sx+j-(1+mx)/2,dx);
            Bx2 = evalBSpline(sx-j+(1-mx)/2,dx);
            for i=1:ceil((dy+1)/2) % loop over BSpline degree in y dimension
                By1 = evalBSpline(sy+i-(1+my)/2,dy);
                By2 = evalBSpline(sy-i+(1-my)/2,dy);
%                 fprintf('%d %d %d %d\n', l, k, j, i);
%                 for ind = 1:numelXi % loop over evaluation points, computing interpolated value
%                     riMat(ind) = riMat(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)-l+mu).*By1(ind).*Bx1(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)-l+mu).*By2(ind).*Bx1(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)-l+mu).*By1(ind).*Bx2(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)-l+mu).*By2(ind).*Bx2(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)-l+mu).*By1(ind).*Bx1(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)-l+mu).*By2(ind).*Bx1(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)-l+mu).*By1(ind).*Bx2(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)-l+mu).*By2(ind).*Bx2(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)+l-1+mu).*By1(ind).*Bx1(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)+l-1+mu).*By2(ind).*Bx1(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)+l-1+mu).*By1(ind).*Bx2(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)+l-1+mu).*By2(ind).*Bx2(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*By1(ind).*Bx1(ind).*Bv2(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*By2(ind).*Bx1(ind).*Bv2(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*By1(ind).*Bx2(ind).*Bv2(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*By2(ind).*Bx2(ind).*Bv2(ind).*Bu2(ind);
%                 end
                    riMat = riMat + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv-k+mv,ku-l+mu)).*By1.*Bx1.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv-k+mv,ku-l+mu)).*By2.*Bx1.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv-k+mv,ku-l+mu)).*By1.*Bx2.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv-k+mv,ku-l+mu)).*By2.*Bx2.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv+k-1+mv,ku-l+mu)).*By1.*Bx1.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv+k-1+mv,ku-l+mu)).*By2.*Bx1.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv+k-1+mv,ku-l+mu)).*By1.*Bx2.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv+k-1+mv,ku-l+mu)).*By2.*Bx2.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv-k+mv,ku+l-1+mu)).*By1.*Bx1.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv-k+mv,ku+l-1+mu)).*By2.*Bx1.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv-k+mv,ku+l-1+mu)).*By1.*Bx2.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv-k+mv,ku+l-1+mu)).*By2.*Bx2.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv+k-1+mv,ku+l-1+mu)).*By1.*Bx1.*Bv2.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv+k-1+mv,ku+l-1+mu)).*By2.*Bx1.*Bv2.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv+k-1+mv,ku+l-1+mu)).*By1.*Bx2.*Bv2.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv+k-1+mv,ku+l-1+mu)).*By2.*Bx2.*Bv2.*Bu2;
            end
            if yflag % add a correction factor if BSpline in y direction is shifted and of odd degree
                By1 = evalBSpline(sy+i+1/2,dy);
%                 for ind = 1:numelXi
%                     riMat(ind) = riMat(ind) + By1(ind).*...
%                         (cMat(ky(ind)-i-1,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)-l+mu).*Bx1(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i-1,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)-l+mu).*Bx2(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i-1,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)-l+mu).*Bx1(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i-1,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)-l+mu).*Bx2(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i-1,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)+l-1+mu).*Bx1(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i-1,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)+l-1+mu).*Bx2(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i-1,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*Bx1(ind).*Bv2(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i-1,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*Bx2(ind).*Bv2(ind).*Bu2(ind));
%                 end
                    riMat = riMat + By1.*...
                        (cMat(sub2ind(size(cMat),ky-i-1,kx-j+mx,kv-k+mv,ku-l+mu)).*Bx1.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i-1,kx+j-1+mx,kv-k+mv,ku-l+mu)).*Bx2.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i-1,kx-j+mx,kv+k-1+mv,ku-l+mu)).*Bx1.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i-1,kx+j-1+mx,kv+k-1+mv,ku-l+mu)).*Bx2.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i-1,kx-j+mx,kv-k+mv,ku+l-1+mu)).*Bx1.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i-1,kx+j-1+mx,kv-k+mv,ku+l-1+mu)).*Bx2.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i-1,kx-j+mx,kv+k-1+mv,ku+l-1+mu)).*Bx1.*Bv2.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i-1,kx+j-1+mx,kv+k-1+mv,ku+l-1+mu)).*Bx2.*Bv2.*Bu2);
            end
        end
        if xflag % add a correction factor if BSpline in x direction is shifted and of odd degree
            Bx1 = evalBSpline(sx+j+1/2,dx);
            for i=1:ceil((dy+1)/2)
                By1 = evalBSpline(sy+i-(1+my)/2,dy);
                By2 = evalBSpline(sy-i+(1-my)/2,dy);
%                 for ind = 1:numelXi
%                     riMat(ind) = riMat(ind) + Bx1(ind).*...
%                         (cMat(ky(ind)-i+my,kx(ind)-j-1,kv(ind)-k+mv,ku(ind)-l+mu).*By1(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j-1,kv(ind)-k+mv,ku(ind)-l+mu).*By2(ind).*Bv1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j-1,kv(ind)+k-1+mv,ku(ind)-l+mu).*By1(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j-1,kv(ind)+k-1+mv,ku(ind)-l+mu).*By2(ind).*Bv2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j-1,kv(ind)-k+mv,ku(ind)+l-1+mu).*By1(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j-1,kv(ind)-k+mv,ku(ind)+l-1+mu).*By2(ind).*Bv1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j-1,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*By1(ind).*Bv2(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j-1,kv(ind)+k-1+mv,ku(ind)+l-1+mu).*By2(ind).*Bv2(ind).*Bu2(ind));
%                 end
                    riMat = riMat + Bx1.*...
                        (cMat(sub2ind(size(cMat),ky-i+my,kx-j-1,kv-k+mv,ku-l+mu)).*By1.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j-1,kv-k+mv,ku-l+mu)).*By2.*Bv1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j-1,kv+k-1+mv,ku-l+mu)).*By1.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j-1,kv+k-1+mv,ku-l+mu)).*By2.*Bv2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j-1,kv-k+mv,ku+l-1+mu)).*By1.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j-1,kv-k+mv,ku+l-1+mu)).*By2.*Bv1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j-1,kv+k-1+mv,ku+l-1+mu)).*By1.*Bv2.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j-1,kv+k-1+mv,ku+l-1+mu)).*By2.*Bv2.*Bu2);
            end
        end
    end
    if vflag % add a correction factor if BSpline in v direction is shifted and of odd degree
        Bv1 = evalBSpline(sv+k+1/2,dv);
        for j=1:ceil((dx+1)/2)
            Bx1 = evalBSpline(sx+j-(1+mx)/2,dx);
            Bx2 = evalBSpline(sx-j+(1-mx)/2,dx);
            for i=1:ceil((dy+1)/2)
                By1 = evalBSpline(sy+i-(1+my)/2,dy);
                By2 = evalBSpline(sy-i+(1-my)/2,dy);
%                 for ind = 1:numelXi
%                     riMat(ind) = riMat(ind) + Bv1(ind).*...
%                         (cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)-k-1,ku(ind)-l+mu).*By1(ind).*Bx1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)-k-1,ku(ind)-l+mu).*By2(ind).*Bx1(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)-k-1,ku(ind)-l+mu).*By1(ind).*Bx2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)-k-1,ku(ind)-l+mu).*By2(ind).*Bx2(ind).*Bu1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)-k-1,ku(ind)+l-1+mu).*By1(ind).*Bx1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)-k-1,ku(ind)+l-1+mu).*By2(ind).*Bx1(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)-k-1,ku(ind)+l-1+mu).*By1(ind).*Bx2(ind).*Bu2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)-k-1,ku(ind)+l-1+mu).*By2(ind).*Bx2(ind).*Bu2(ind));
%                 end
                    riMat = riMat + Bv1.*...
                        (cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv-k-1,ku-l+mu)).*By1.*Bx1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv-k-1,ku-l+mu)).*By2.*Bx1.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv-k-1,ku-l+mu)).*By1.*Bx2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv-k-1,ku-l+mu)).*By2.*Bx2.*Bu1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv-k-1,ku+l-1+mu)).*By1.*Bx1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv-k-1,ku+l-1+mu)).*By2.*Bx1.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv-k-1,ku+l-1+mu)).*By1.*Bx2.*Bu2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv-k-1,ku+l-1+mu)).*By2.*Bx2.*Bu2);
            end
        end
    end
end
if uflag % add a correction factor if BSpline in z direction is shifted and of odd degree
    Bu1 = evalBSpline(su+l+1/2,du);
    for k=1:ceil((dv+1)/2)
        Bv1 = evalBSpline(sv+k-(1+mv)/2,dv);
        Bv2 = evalBSpline(sv-k+(1-mv)/2,dv);
        for j=1:ceil((dx+1)/2)
            Bx1 = evalBSpline(sx+j-(1+mx)/2,dx);
            Bx2 = evalBSpline(sx-j+(1-mx)/2,dx);
            for i=1:ceil((dy+1)/2)
                By1 = evalBSpline(sy+i-(1+my)/2,dy);
                By2 = evalBSpline(sy-i+(1-my)/2,dy);
%                 for ind = 1:numelXi
%                     riMat(ind) = riMat(ind) + Bu1(ind).*...
%                         (cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)-l-1).*By1(ind).*Bx1(ind).*Bv1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)-k+mv,ku(ind)-l-1).*By2(ind).*Bx1(ind).*Bv1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)-l-1).*By1(ind).*Bx2(ind).*Bv1(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)-k+mv,ku(ind)-l-1).*By2(ind).*Bx2(ind).*Bv1(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)-l-1).*By1(ind).*Bx1(ind).*Bv2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)-j+mx,kv(ind)+k-1+mv,ku(ind)-l-1).*By2(ind).*Bx1(ind).*Bv2(ind) + ...
%                         cMat(ky(ind)-i+my,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)-l-1).*By1(ind).*Bx2(ind).*Bv2(ind) + ...
%                         cMat(ky(ind)+i-1+my,kx(ind)+j-1+mx,kv(ind)+k-1+mv,ku(ind)-l-1).*By2(ind).*Bx2(ind).*Bv2(ind));
%                 end
                    riMat = riMat + Bu1.*...
                        (cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv-k+mv,ku-l-1)).*By1.*Bx1.*Bv1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv-k+mv,ku-l-1)).*By2.*Bx1.*Bv1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv-k+mv,ku-l-1)).*By1.*Bx2.*Bv1 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv-k+mv,ku-l-1)).*By2.*Bx2.*Bv1 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx-j+mx,kv+k-1+mv,ku-l-1)).*By1.*Bx1.*Bv2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx-j+mx,kv+k-1+mv,ku-l-1)).*By2.*Bx1.*Bv2 + ...
                        cMat(sub2ind(size(cMat),ky-i+my,kx+j-1+mx,kv+k-1+mv,ku-l-1)).*By1.*Bx2.*Bv2 + ...
                        cMat(sub2ind(size(cMat),ky+i-1+my,kx+j-1+mx,kv+k-1+mv,ku-l-1)).*By2.*Bx2.*Bv2);
            end
        end
    end
end

% perform extrapolation
outOfBounds = xi(:)<xDataCol(1) | xi(:)>xDataCol(nDatax) | yi(:)<yDataCol(1)...
    | yi(:)>yDataCol(nDatay) | ui(:)<uDataCol(1) | ui(:)>uDataCol(nDatau)...
    | vi(:)<vDataCol(1) | vi(:)>vDataCol(nDatav);
riMat(p(outOfBounds)) = extrapval;

% reshape result to have same size as input xi
ri = reshape(riMat,siz_ri);
varargout{1} = ri;


%% subfunction parseInputs
function [b,xi,yi,ui,vi,extrapval] = parseInputs(varargin)

nargs = length(varargin);
% error(nargchk(4,5,nargs));
narginchk(4,5);

% Process B
b = varargin{1};
if ~isequal(b.tensorOrder,4)
    error([mfilename,'parseInputs:WrongOrder'], ...
        'bsarray/interp4 can only be used with bsarray objects having tensor order 4.');
end

% Process XI
xi = varargin{2};
if ~isreal(xi)
    error([mfilename,'parseInputs:ComplexInterpPts'], ...
        'The interpolation points XI should be real.')
end

% Process YI
yi = varargin{3};
if ~isreal(yi)
    error([mfilename,'parseInputs:ComplexInterpPts'], ...
        'The interpolation points YI should be real.')
end
if ~isequal(size(xi),size(yi))
    error([mfilename,'parseInputs:YIXINotSameSize'], ...
        'YI must be the same size as XI');
end

% Process UI
ui = varargin{4};
if ~isreal(ui)
    error([mfilename,'parseInputs:ComplexInterpPts'], ...
        'The interpolation points UI should be real.')
end
if ~isequal(size(xi),size(ui))
    error([mfilename,'parseInputs:UIXINotSameSize'], ...
        'UI must be the same size as XI');
end

% Process VI
vi = varargin{5};
if ~isreal(vi)
    error([mfilename,'parseInputs:ComplexInterpPts'], ...
        'The interpolation points VI should be real.')
end
if ~isequal(size(xi),size(vi))
    error([mfilename,'parseInputs:VIXINotSameSize'], ...
        'VI must be the same size as XI');
end

% Process EXTRAPVAL
if nargs > 5
    extrapval = varargin{6};
else
    extrapval = [];
end
if isempty(extrapval)
    extrapval = NaN;
end
if ~isscalar(extrapval)
    error([mfilename,':NonScalarExtrapValue'],...
        'EXTRAP option must be a scalar.')
end
