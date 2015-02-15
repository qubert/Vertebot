% %--------------------------------------------------------------------------
% %
% % vertebot_startup.m
% % By Christopher Harris
% % Visit vertebot.com for more information
% %
% %--------------------------------------------------------------------------

 
%% Close and clear
close all
clear all
delete(imaqfind)
imaqreset

%% Load brain
load('vertebot_brain')
fig1 = figure(1);
clf
colormap('jet')
set(fig1, 'color', 'w')
imagesc(vertebot_brain.connectome)
h = colorbar;
h.Label.String = 'Synaptic strength';
xlabel('Postsynaptic')
ylabel('Presynaptic')
title('Vertebot connectome')

%% Bluetooth
bluetooth = serial('com4', 'BaudRate', 115200);
pause(3)
fopen(bluetooth);   

%% Left camera eye
left_cam = videoinput('winvideo', 3, 'MJPG_160x120');
triggerconfig(left_cam, 'manual');
left_cam.TriggerRepeat = Inf;
left_cam.FramesPerTrigger = 1;
left_cam.ReturnedColorspace = 'rgb';

%% Right camera eye
right_cam = videoinput('winvideo', 2, 'MJPG_160x120');
triggerconfig(right_cam, 'manual');
right_cam.TriggerRepeat = Inf;
right_cam.FramesPerTrigger = 1;
right_cam.ReturnedColorspace = 'rgb';

%% External camera
% ext_cam = videoinput('winvideo', 1, 'MJPG_640x360');
% triggerconfig(ext_cam, 'manual');
% ext_cam.TriggerRepeat = Inf;
% ext_cam.FramesPerTrigger = 1;
% ext_cam.ReturnedColorspace = 'rgb';

