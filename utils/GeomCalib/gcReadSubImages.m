function [ lf, H ] = gcReadSubImages( lfFilePath )
%GCREADSUBIMAGES Read sub-images generated by the geometric calibration
%code and assemble them to a 4D light field

[fpath,fname,~] = fileparts(lfFilePath);
template = fullfile(fpath,'SubAperture',[fname '_Sub_%d_%d.png']);
subIm = imread(sprintf(template, 1, 1));
lf = zeros([13 13 size(subIm)]);

for i = 1:13
    for j = 1:13
        subIm = imread(sprintf(template, i, j));
        lf(i,j,:,:,:) = im2double(subIm);
    end
end

if nargout > 1
    load(fullfile(fpath,'SubAperture',[fname '_Sub_1_1.mat']));
    SubExtParam1 = SubExtParam;
    load(fullfile(fpath,'SubAperture',[fname '_Sub_1_2.mat']));
    SubExtParam2 = SubExtParam;
    unitB = SubExtParam1(1,4) - SubExtParam2(1,4);
    
%     uStep = 1 / SubIntParam(1,1);
%     uCenter = ((1+size(lf,4))/2);
%     uOffset = (SubIntParam(1,3)-uCenter)*uStep;
%     vStep = 1 / SubIntParam(2,2);
%     vCenter = ((1+size(lf,3))/2);
%     vOffset = (SubIntParam(2,3)-vCenter)*vStep;
%     H = [unitB 0 0 0 -SubExtParam1(1,4)-unitB+uOffset;
%         0 unitB 0 0 -SubExtParam1(2,4)-unitB+vOffset;
%         0 0 uStep 0 -uStep*uCenter;
%         0 0 0 vStep -vStep*vCenter;
%         0 0 0 0 1];
    
    invInt = inv(SubIntParam);
    H = [unitB 0 0 0 -SubExtParam1(1,4)-unitB;
        0 unitB 0 0 -SubExtParam1(2,4)-unitB;
        0 0 invInt(1,1) 0 invInt(1,3);
        0 0 0 invInt(2,2) invInt(2,3);
        0 0 0 0 1];
end
    

end
