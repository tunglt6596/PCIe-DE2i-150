v = VideoReader('D:\\test2\\video_in.mp4');
v.CurrentTime = 310;

fileID = fopen('D:\\test2\\video_in.bin', 'w');

for k=1:600
    vidFrame = readFrame(v);
    vidFrame = imresize(vidFrame, [480 640]);
    vidFrame = rgb2gray(vidFrame);
    for i=1:size(vidFrame, 1)
        for j=1:size(vidFrame, 2)
            tmp = sprintf('00000000%s%s%s', dec2bin(vidFrame(i,j),8), dec2bin(vidFrame(i,j),8), dec2bin(vidFrame(i,j),8));
            fwrite(fileID, bin2dec(tmp),'uint32');
        end
    end
end

fclose(fileID);