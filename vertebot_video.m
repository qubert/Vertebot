% %--------------------------------------------------------------------------
% %
% % vertebot_video.m
% % By Christopher Harris
% % Visit vertebot.com for more information
% %
% %--------------------------------------------------------------------------


%% Prepaare brain
neuron_xpos = zeros(nneurons, 1);
neuron_ypos = zeros(nneurons, 1);
for nneuron = 1:nneurons
    neuron_xpos(nneuron) = vertebot_brain.neuron(nneuron).center(1);
    neuron_ypos(nneuron) = vertebot_brain.neuron(nneuron).center(2);    
end
neuron_xpos_on = neuron_xpos;
neuron_ypos_on = neuron_ypos;


%% Prepare video
replayFPS = 10;
vidWriter = VideoWriter(horzcat('150214vertebot004_noexp'), 'MPEG-4');
set(vidWriter, 'FrameRate', replayFPS);
open(vidWriter);

%% Prepare figure
fig1 = figure('position', [100 200 854*fig_expand 480*fig_expand]);
clf
set(fig1, 'DoubleBuffer', 'on');

brain_title_ax = axes('position', [0.33 0.95 0.34 0.05], 'NextPlot', 'replace', 'xcolor', 'w', 'ycolor', 'w');
plot([1 3], [1 1], 'color', 'w')
hold on
text1 = text(2, 1, 'Brain', 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', 'color', 'k');
set(text1, 'FontSize', 10)
hold off
box on
set(gca, 'XTick', [], 'YTick', [],  'xcolor', 'w', 'ycolor', 'w')

brain_ax = axes('position', [0.33 0.05 0.34 0.9], 'NextPlot', 'replace');
image(vertebot_brain.vibez_slice);
hold on
plot(neuron_xpos_on, neuron_ypos_on, 'marker', '.', 'markersize', 25, 'color', [0.7 0.7 0.7], 'linestyle', 'none');
neuron_plot = plot(neuron_xpos_on, neuron_ypos_on, 'marker', '.', 'markersize', 25, 'color', [0 0.7 0], 'linestyle', 'none');
set(neuron_plot, 'XDataSource', 'neuron_xpos_on', 'YDataSource', 'neuron_ypos_on')
box on
set(gca, 'XTick', [], 'YTick', []')

left_title_ax = axes('position', [0 0.95 0.33 0.05], 'NextPlot', 'replace', 'xcolor', 'w', 'ycolor', 'w');
plot([1 3], [1 1], 'color', 'w')
hold on
text1 = text(2, 1, 'Left camera eye', 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', 'color', 'k');
set(text1, 'FontSize', 10)
hold off
box on
set(gca, 'XTick', [], 'YTick', [],  'xcolor', 'w', 'ycolor', 'w')

left_camera_ax = axes('position', [0 0.05 0.33 0.9], 'NextPlot', 'replace');
box on
set(gca, 'XTick', [], 'YTick', []')

right_title_ax = axes('position', [0.67 0.95 0.33 0.05], 'NextPlot', 'replace', 'xcolor', 'w', 'ycolor', 'w');
plot([1 3], [1 1], 'color', 'w')
hold on
text1 = text(2, 1, 'Right camera eye', 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', 'color', 'k');
set(text1, 'FontSize', 10)
hold off
box on
set(gca, 'XTick', [], 'YTick', [],  'xcolor', 'w', 'ycolor', 'w')

right_camera_ax = axes('position', [0.67 0.05 0.33 0.9], 'NextPlot', 'replace');
box on
set(gca, 'XTick', [], 'YTick', []')

reward_button_ax = axes('position', [0 0 0.499 0.049], 'NextPlot', 'replace');
box on
rew_btn = uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'String', 'Reward', 'Position', [0 0 0.5 0.05], 'Callback', 'reward_com = 1;');
rew_btn.FontSize = 10;
set(gca, 'XTick', [], 'YTick', []');

stop_button_ax = axes('position', [0.501 0 0.499 0.049], 'NextPlot', 'replace');
box on
stop_btn = uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'String', 'Stop', 'Position', [0.5 0 0.5 0.05], 'Callback', 'stop_com = 1;');
stop_btn.FontSize = 10;
set(gca, 'XTick', [], 'YTick', []');

%% First loop
left_cam_frame = left_cam_frame_log(:,:,:,1);
axes(left_camera_ax)
draw_left_cam = image(left_cam_frame);
set(gca, 'xtick', [], 'ytick', [])

right_cam_frame = right_cam_frame_log(:,:,:,1);
axes(right_camera_ax)
draw_right_cam = image(right_cam_frame);
set(gca, 'xtick', [], 'ytick', [])

cam_step = 0;
for t = 1:nsteps
    if ~rem(t, camera_interval)
        cam_step = cam_step + 1;
        fig1_name = horzcat('frame_', num2str(cam_step));
        
        %% Visualize brain
        for nneuron = 1:nneurons
            if ~isempty(find(spike_matrix(nneuron,t-camera_interval+1:t), 1))
                neuron_xpos_on(nneuron) = neuron_xpos(nneuron);
                neuron_ypos_on(nneuron) = neuron_ypos(nneuron);
            else
                neuron_xpos_on(nneuron) = 0;
                neuron_ypos_on(nneuron) = 0 ;
            end
        end

        refreshdata(neuron_plot, 'caller')
        neuron_xpos_on = [];
        neuron_ypos_on = [];
        
        left_cam_frame = left_cam_frame_log(:,:,:,cam_step);
        right_cam_frame = right_cam_frame_log(:,:,:,cam_step);
        
        draw_left_cam.CData = left_cam_frame;
        draw_right_cam.CData = right_cam_frame;
    
%         export_fig(fig1, fig1_name, '-r300', '-nocrop')
        writeVideo(vidWriter, getframe(figure(fig1)));  
        disp(horzcat('cam_step: ', num2str(cam_step)))
    end
    
end
close(vidWriter);


%% Second loop
% fig1 = figure('position', [100 200 854*fig_expand 480*fig_expand]);
% clf
% set(fig1, 'DoubleBuffer', 'on');
% ax1 = axes('position', [0 0 1 1]);
% 
% for nframe = 1:nsteps/camera_interval
%     frame_name = horzcat('frame_', num2str(nframe), '.png');
%     frame = imread(frame_name);
%     image(frame)
%     set(gca, 'xtick', [], 'ytick', [])
%     writeVideo(vidWriter, getframe(figure(fig1)));  
%     disp(horzcat('nframe: ', num2str(nframe)))
% end
% 
% close(vidWriter);

