% %--------------------------------------------------------------------------
% %
% % vertebot_run.m
% % By Christopher Harris
% % Visit vertebot.com for more information
% %
% %--------------------------------------------------------------------------


%% Close all
close all


%% Vertebot settings
nsteps = 10000;
brain_on = 1;
motor_on = 1;
camera_on = 1;
vision_on = 1;
camera_interval = 100;
motor_interval = 1000;
mcr = motor_interval/camera_interval;
V_rest = -65;
V_threshold = -19.3;
V_cutoff = 50;
V_reset = -70;
a = 0.001;
synaptic_gain = 1.5;
motor_threshold = 100;
motor_gain = 0.025;
visual_gain = 0.05;
visual_reversal_threshold = 0.5;


%% Unpack and prepare brain
nneurons = length(vertebot_brain.neuron);
connectome = vertebot_brain.connectome;
neuron_xpos = zeros(nneurons, 1);
neuron_ypos = zeros(nneurons, 1);
for nneuron = 1:nneurons
    neuron_xpos(nneuron) = vertebot_brain.neuron(nneuron).center(1);
    neuron_ypos(nneuron) = vertebot_brain.neuron(nneuron).center(2);    
end
neuron_xpos_on = neuron_xpos;
neuron_ypos_on = neuron_ypos;
brain_im = vertebot_brain.vibez_slice;
spike_matrix = zeros(nneurons, nsteps);
voltage_matrix = repmat(V_rest, [nneurons, 2]);


%% Preallocation (proobably some unnecessary)
PSP = zeros(nneurons, 1);
motor_output = zeros(2,3);
left_hin_spikes = repmat(uint8(0), [10, 1]);
right_hin_spikes = repmat(uint8(0), [10, 1]);
synaptic_inputs = repmat(uint8(0), [nneurons, 1]);
motor_spikes = zeros(nsteps/motor_interval, 2);
timer1 = zeros(nsteps/camera_interval, 1);
timer2 = zeros(nsteps, 1);
left_cam_frame = repmat(uint8(0), [120, 160, 3]);
right_cam_frame = repmat(uint8(0), [120, 160, 3]);
last_left_cam_frame = repmat(uint8(0), [120, 160, 3]);
last_right_cam_frame = repmat(uint8(0), [120, 160, 3]);
left_cam_frame_log = repmat(uint8(0), [120, 160, 3, nsteps/camera_interval]);
right_cam_frame_log = repmat(uint8(0), [120, 160, 3, nsteps/camera_interval]);
left_cam_diff = 0;
right_cam_diff = 0;
left_visual_input = 0;
right_visual_input = 0;
reversing = 0;
reward_com = 0;
stop_com = 0;
fig_expand = 1.4;


%% Analytics
PSP_log = zeros(nneurons, nsteps);
motor_output_log = repmat(uint8(0), [nsteps/motor_interval 3]);
visual_input_log = zeros(nsteps/camera_interval, 2);
visual_movement_input_log = zeros(nsteps/camera_interval, 2);


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


%% Main loop
if camera_on
    start(left_cam)
    pause(0.5)
    trigger(left_cam)
    last_left_cam_frame = getdata(left_cam, 1);
end
axes(left_camera_ax)
draw_left_cam = image(last_left_cam_frame);
set(gca, 'xtick', [], 'ytick', [])

if camera_on
    start(right_cam)
    pause(0.5)
    trigger(right_cam)
    last_right_cam_frame = getdata(right_cam, 1);
end
axes(right_camera_ax)
draw_right_cam = image(last_right_cam_frame);
set(gca, 'xtick', [], 'ytick', [])
pause(1)

camera_step = 0;
motor_step = 0;
t = 0;
moving_count = 0;
reversal_count = 0;
while ~stop_com
    
    %% Time
    t = t+1;
    if ~rem(t, camera_interval)
        camera_step = camera_step + 1;
    end
    if ~rem(t, motor_interval)
        motor_step = motor_step + 1;
    end
    if ~rem(t, round(nsteps/10))
        disp(horzcat('t = ', num2str(t)))
    end

    
    %% Brain activity
    if brain_on
        
        tic

        
        %% Voltage change
        DV = (voltage_matrix(:,1) - V_rest) .* (voltage_matrix(:,1) - V_threshold) * a + rand(nneurons, 1);
        voltage_matrix(:,2) = voltage_matrix(:,1) + DV + PSP;
        
        voltage_matrix(1:10, 2) = voltage_matrix(1:10, 2) + left_visual_input;
        voltage_matrix(11:20, 2) = voltage_matrix(11:20, 2) + right_visual_input;

        spike_matrix(:,t) = voltage_matrix(:,2) > V_threshold;
            
        for nneuron = 1:nneurons
            if voltage_matrix(nneuron,2) > V_threshold;
                voltage_matrix(nneuron,2) = V_reset;
            end
        end
        
        voltage_matrix(:,1) = voltage_matrix(:,2);
        
        
        %% Synaptic output
        for npostsynaptic_neuron = 1:nneurons
            PSP(npostsynaptic_neuron) = sum(connectome(:, npostsynaptic_neuron) .* spike_matrix(:, t) * synaptic_gain);
        end
        PSP_log(:, t) = PSP;
      
        timer2(t) = toc;

    end
    
    
    %% Brain visualization
    if brain_on && (~rem(t, camera_interval) || ~rem(t, motor_interval))
 
        
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
        
    end
    
    
    %% Motor output
    if motor_on && ~rem(t, motor_interval);
                
        motor_spikes(t, 1) = sum(sum(spike_matrix(21:30, t-motor_interval+1:t)));
        motor_spikes(t, 2) = sum(sum(spike_matrix(31:40, t-motor_interval+1:t)));

        motor_output(2, 1) = (motor_spikes(t, 1) * motor_gain) * 255;
        motor_output(2, 2) = (motor_spikes(t, 2) * motor_gain) * 255;

        if motor_output(2, 1) < motor_threshold || motor_step == 1;
            motor_output(2, 1) = 0;
        end

        if motor_output(2, 2) < motor_threshold || motor_step == 1;
            motor_output(2, 2) = 0;
        end
        
        if reversal_count
            motor_output(2,3) = 1;
            reversal_count = reversal_count - 1;
        else
            motor_output(2,3) = 0;
        end
        
        if ~isempty(find(motor_output(1:2,1:2) >= motor_threshold, 1))
            moving_count = moving_count + 1;
        else
            moving_count = 0;
        end
        disp(num2str(moving_count))
        
        motor_output = round(motor_output);

        disp(horzcat(num2str(motor_output(2,:))))
        fwrite(bluetooth, motor_output(2,:), 'async');
        motor_output(1,:) = motor_output(2,:);
        motor_output_log(motor_step, :) = motor_output(2,:);
    end

    
    %% Camera input
    if camera_on && ~rem(t, camera_interval)
        
        tic
        
        
        %% Left eye
        trigger(left_cam)
        left_cam_frame = getdata(left_cam, 1);
        draw_left_cam.CData = left_cam_frame;
        left_cam_diff_frame = last_left_cam_frame - left_cam_frame;
        left_cam_diff_frame(left_cam_diff_frame < 10) = 0;
        last_left_cam_frame = left_cam_frame;
        left_cam_diff = mean2(left_cam_diff_frame);
        left_cam_frame_log(:,:,:,camera_step) = left_cam_frame;

        
        %% Right eye
        trigger(right_cam)
        right_cam_frame = getdata(right_cam, 1);
        draw_right_cam.CData = right_cam_frame;
        right_cam_diff_frame = last_right_cam_frame - right_cam_frame;
        right_cam_diff_frame(right_cam_diff_frame < 10) = 0;
        last_right_cam_frame = right_cam_frame;
        right_cam_diff = mean2(right_cam_diff_frame);
        right_cam_frame_log(:,:,:,camera_step) = right_cam_frame;        

        timer1(camera_step) = toc;
        
    end
    
    
    %% Visual input
    if vision_on && ~rem(t, camera_interval)
        
        
        if ~moving_count
            left_visual_input = left_cam_diff * visual_gain;
            right_visual_input = right_cam_diff * visual_gain;
        else
            left_visual_input = 0;
            right_visual_input = 0;
        end
        visual_input_log(camera_step, 1) = left_cam_diff * visual_gain;
        visual_input_log(camera_step, 2) = right_cam_diff * visual_gain;

    end
    
    
%     %% Reverse if stuck %% Maybe chaange to motor_output(1,1)&(1,2)
%     if moving_count > 1 && isempty(find(max(visual_movement_input_log(camera_step - mcr/4 + 1:camera_step, :) > visual_reversal_threshold), 1))
%         reversal_count = 1;
%     end


    %% Draw and save frame
    if brain_on && (~rem(t, camera_interval) || ~rem(t, motor_interval))
        drawnow
    end
    
    
    %% Time
    if t == nsteps
        stop_com = 1;
    end
        
end


 %% Stop devices
if motor_on
    fwrite(bluetooth, [0 0 0]);
end

if camera_on
    stop(left_cam)
    stop(right_cam)
end


%% Display analytics

% disp(horzcat('Spikes: ', num2str(sum(spike_log(:)))))
% left_tectum_spikes = spike_log(1:10, :);
% disp(horzcat('Left tectum spikes: ', num2str(sum(left_tectum_spikes(:)))))
% right_tectum_spikes = spike_log(11:20, :);
% disp(horzcat('Right tectum spikes: ', num2str(sum(right_tectum_spikes(:)))))
% left_hindbrain_spikes = spike_log(21:30, :);
% disp(horzcat('Left hindbrain spikes: ', num2str(sum(left_hindbrain_spikes(:)))))
% right_hindbrain_spikes = spike_log(31:40, :);
% disp(horzcat('Right hindbrain spikes: ', num2str(sum(right_hindbrain_spikes(:)))))
% reward_system_spikes = spike_log(41:44, :);
% disp(horzcat('Reward system spikes: ', num2str(sum(reward_system_spikes(:)))))
% disp('----')
% disp(horzcat('Motor output: ', num2str(mean2(motor_output_log(:,1:2)))))
% disp('----')


fig2 = figure('position', [150 250 854 * fig_expand 480 * fig_expand]);
clf

subplot(2,1,1)
plot(timer2(2:end) * 1000000, 'color', 'b', 'linewidth', 2)
xlim([1 nsteps])
title(horzcat('Brain step time: ', num2str(round(mean(timer2) * 1000000)), ' ± ', num2str(round(std(timer2 * 1000000))), ' us'))
xlabel('t')
ylabel('us')

subplot(2,1,2)
plot(timer1(2:end) * 1000, 'color', 'b', 'linewidth', 2)
xlim([1 nsteps/camera_interval])
title(horzcat('Camera step time: ', num2str(round(mean(timer1 * 1000))), ' ± ', num2str(round(std(timer1 * 1000))), ' ms'))
xlabel('Cam step')
ylabel('ms')


%% Fig3
fig3 = figure('position', [200 300 854 * fig_expand 480 * fig_expand]);
clf

subplot(3,1,1)
plot(motor_output_log(:,1), 'color', [0 0.7 0], 'linewidth', 2)
hold on
plot(motor_output_log(:,2), 'color', 'r', 'linewidth', 2)
plot(motor_output_log(:,3)*100, 'color', 'k', 'linewidth', 2)
xlim([0 nsteps/motor_interval])
title('Motor output')

subplot(3,1,2)
plot(visual_input_log(:,1), 'color', [0 0.7 0], 'linewidth', 2)
hold on
plot(visual_input_log(:,2), 'color', 'r', 'linewidth', 2)
xlim([0 nsteps/camera_interval])
title('Visul input')

subplot(3,1,3)
plot(visual_motion_input_log(:,1), 'color', [0 0.7 0], 'linewidth', 2)
hold on
plot(visual_motion_input_log(:,2), 'color', 'r', 'linewidth', 2)
xlim([0 nsteps/camera_interval])
title('Visul motion input')
