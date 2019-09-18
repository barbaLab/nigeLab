classdef HighDimsUI < handle
    %HIGHDIMSUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ChannelSelector
        SpikeImage
        FeaturesUI
        
        Figure  matlab.ui.Figure
        panels
        
        alpha
        num_dims
        selected_conds
        axesMain
        Q1
        Q2
        Colors
        D
        
        maxDim = 15
    end
    
    methods
        
        function obj = HighDimsUI(featuresUI,Visible)
            
            obj.ChannelSelector = featuresUI.ChannelSelector;
            obj.SpikeImage = featuresUI.SpikeImage;
            obj.FeaturesUI = featuresUI;
            
            addlistener(obj.SpikeImage,'MainWindowClosed',@(~,~)obj.closeF);
            addlistener(obj.ChannelSelector,'NewChannel',@(~,~)obj.InitUI);
            addlistener(obj.SpikeImage,'ClassAssigned',@(~,~) obj.InitUI);
            addlistener(obj.SpikeImage,'VisionToggled',@(~,~)obj.InitUI);
        end
        
        function PlotFig(obj)
            obj.Figure = figure('Color',nigeLab.defaults.nigelColors(0),...
                'ToolBar','none',...
                'MenuBar','none',...
                'CloseRequestFcn',@(~,~)obj.closeF);
            
            p1 = uipanel( obj.Figure,...
                'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
                'Position',[.01 .01 .48 .98],...
                'BorderType','none');
            
            p2 = uipanel( obj.Figure,...
                'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
                'Position',[.51 .01 .48 .98],...
                'BorderType','none');
            
            for ii = 1:obj.maxDim % max 15 features
                ax1 = subplot(5,3,ii,'Parent',p1,'UserData',[ii],'xtick',[],'ytick',[],...
                    'ButtonDownFcn', {@obj.Panel_ButtonDownFcn});
                ax2 = subplot(5,3,ii,'Parent',p2,'UserData',[15+ii],'xtick',[],'ytick',[],...
                    'ButtonDownFcn', {@obj.Panel_ButtonDownFcn});
                ax(ii) = ax1;ax(ii+15) = ax2;
            end
            obj.panels = ax;
            InitUI(obj);
            obj.update_panels;
            
            obj.FeaturesUI.FeatX.Enable = 'off';
            obj.FeaturesUI.FeatY.Enable = 'off';

        end
        
        function InitUI(obj)
            
            iCh = obj.ChannelSelector.Channel;
            obj.alpha = 0.2;  % beginning rotation alpha...user can change it
            obj.num_dims = size(obj.FeaturesUI.Data.feat{iCh},2);
            
                       
            [obj.Q1,obj.Q2] = obj.calculateQ();
            obj.axesMain = obj.FeaturesUI.Features2D;
            
            obj.D.class = obj.FeaturesUI.Data.class{iCh};
            obj.D.feat = obj.FeaturesUI.Data.feat{iCh};
            obj.Colors = obj.FeaturesUI.COLS;
            
           if isvalid(obj.Figure),obj.update_panels();end
            stopRot = @(~,~,x) set(x,'UserData',1);

            
            if ~isempty(obj.panels) && all(isvalid(obj.panels))
               for ii = (obj.num_dims-1):obj.maxDim
                  obj.panels(ii).Visible = false;
                  obj.panels(ii+15).Visible = false;                    
               end
               
               obj.Figure.WindowButtonUpFcn = {stopRot,obj.axesMain };
            end
        end
        
        function [Q1,Q2] = calculateQ(obj)
            % calculates Q1 and Q2, the null spaces of v2 and v1, respectively
            %  projVecs 2x#numdims
            
            Q = randn(obj.num_dims,obj.num_dims - 1);  % 15x14 matrix, concatenate vecs now
            Q1 = [obj.FeaturesUI.projVecs(2,:)' Q];
            Q = randn(obj.num_dims,obj.num_dims - 1);  % re-randomize Q
            Q2 = [obj.FeaturesUI.projVecs(1,:)' Q];
            
            % perform gram-schmidt to make it a null space
            [Q1 R] = qr(Q1);
            [Q2 R] = qr(Q2);
            
            % now take out v2 and v1 (we just want the null space)
            Q1 = Q1(:, 2:obj.num_dims);
            Q2 = Q2(:, 2:obj.num_dims);
        end
        
        
        function R = get_rotation_matrix(obj, alpha, angle_number)
            % return the rotation matrix based on the angle_number
            
            R = eye(obj.num_dims - 1, obj.num_dims - 1);
            R(angle_number, angle_number) = cos(alpha);
            R(angle_number, angle_number+1) = -sin(alpha);
            R(angle_number+1, angle_number) = sin(alpha);
            R(angle_number+1, angle_number+1) = cos(alpha);
        end
        
        
        function update_panels(obj)
            % update all the outer panels with the new projection vectors
            %  update_panels calls guidata(hObject, handles)... so be sure *not* to
            %  call guidata after calling update_panels!  call
            %  handles = guidata(hObject)
            obj.selected_conds = cellfun(@(x) x.Value,obj.SpikeImage.VisibleToggle);
            
            if (~any(obj.selected_conds)) %if no selected conds, don't update
                return;
            end
            
            preview_alpha = pi;   %%% can change the preview alpha
            
            
            
            % for each panel, plot all the trajs with particular angles
            for panel = 1:length(obj.panels)
                
                % first check that the panel is ok to update
                if (~obj.checkPanel(panel))
                    continue;
                end
                
                
                if (panel <= 15) %panel is on left side
                    
                    % fix v2, change v1
                    R = obj.get_rotation_matrix(preview_alpha, panel);
                    v1 = obj.Q1 * R * obj.Q1' * obj.FeaturesUI.projVecs(1,:)';
                    v2 = obj.FeaturesUI.projVecs(2,:)';
                    
                    plot_panel( obj, obj.panels(panel), [v1 v2]');
                    
                else  %panel is on right side
                    % fix v1, change v2
                    
                    R = obj.get_rotation_matrix(preview_alpha, panel - 15);
                    v2 = obj.Q2 * R * obj.Q2' * obj.FeaturesUI.projVecs(2,:)';
                    v1 = obj.FeaturesUI.projVecs(1,:)';
                    
                    plot_panel( obj, obj.panels(panel), [v1 v2]');
                    
                end
            end
            
            
            % Plot the percent variance as seen by the main display
            %     conditions = unique({params.D.condition});
            % %     [u sc lat] = princomp([handles.D(ismember({handles.D.condition}, conditions(handles.selected_conds))).data]');
            % %     [up scp latp] = princomp((handles.projVecs*[handles.D(ismember({handles.D.condition}, conditions(handles.selected_conds))).data])');
            % %     percVar = sum(latp)/sum(lat)*100;
            %     Sigma_highd = cov([params.D(ismember({params.D.condition}, conditions(params.selected_conds))).data]');
            %     Sigma_projected = params.projVecs * Sigma_highd * params.projVecs';
            %     percVar = trace(Sigma_projected)/trace(Sigma_highd) * 100;
            %
            %     set(params.PercentVarianceText, 'String', [sprintf('%.2f', percVar) '% var']);
            %
            %
        end
        
        % user may use less than 15 dims...
        % returns 1 if panel is ok, 0 else
        function panelIsOk = checkPanel(obj,panel_index)
            
            if (panel_index <= 15 && panel_index <= obj.num_dims - 2)
                panelIsOk = 1;
            elseif (panel_index >= 16 && panel_index - 15 <= obj.num_dims - 2)
                panelIsOk = 1;
            else
                panelIsOk = 0;
            end
        end
        
        % Plot the panels
        function plot_panel( obj, ha, vecs)
            % plot trajs on given axes for panel
            cla(ha);
            createLines( obj, ha, vecs);
        end
        
        function createLines( obj, panel, vecs)
            % create lines on the plot (lines are much faster)
            
            %     set(get(panel, 'Parent'), 'CurrentAxes', panel);
            hold(panel, 'on');
            conditions = unique(obj.D.class);
            activeCond = find(obj.selected_conds);
            conditions = conditions(ismember(conditions,activeCond))';
            for cond =  conditions
                indx = obj.D.class == cond;
                p = ellipse(vecs, cov(obj.D.feat(indx,:)), mean(obj.D.feat(indx,:),1)');
                hp = line(panel,p(1,:), p(2,:), 'Color', obj.Colors{cond},...
                'HitTest', 'off'); 
            end
            
        end
        
        function Continuously_Rotate_BigTraj(obj, ~, direction, side, Q, angle_number)
            
            % direction: string, 'forward' 'backward', which direction to rotate
            % side: string, 'left', 'right', which side the panel is on
            %       determines which vector is fixed (if left, proj_vec(1,:) is
            %       fixed, proj_vec(2,:) is fixed if right)
            % Q: matrix 15x14, previously calculated
            % angle_number: scalar, which angle to rotate by (determines R)
            %         note angle numbers repeat depending on left or right
            
            
            
            % you can change any of these variables to influence the rate
            pause_length = .1;
            
            if (strcmp(direction, 'backward'))
                alpha = -obj.alpha;
            else
                alpha = obj.alpha;
            end
            
            
            while (get(obj.axesMain, 'UserData') == 0)
                R = obj.get_rotation_matrix(alpha, angle_number);
                
                % update the projVecsThe d
                if (strcmp(side, 'left'))
                    obj.FeaturesUI.projVecs(1,:) = (Q * R * Q' * obj.FeaturesUI.projVecs(1,:)')';
                else
                    obj.FeaturesUI.projVecs(2,:) = (Q * R * Q' * obj.FeaturesUI.projVecs(2,:)')';
                end
                
                % compute the projections and plot the trajectories and clusters
                obj.FeaturesUI.PlotFeatures;
            end
            
            
            % loop is exited, but now we need to update Q1 and Q2 (depending on
            % which vector changed
            %  need to keep the same Q1/Q2 if user wants to go backwards
            if (strcmp(side, 'left'))  %v2 didn't change, so Q1 shouldn't change
                %but v1 did change, so Q2 needs to change
                [~, obj.Q2] = calculateQ(obj);
                
            else
                [obj.Q1, ~] = calculateQ(obj);
            end
            
            % you're done rotating, so update all the panels with the new previews
            % (done here to avoid concurrency issues)
          update_panels(obj);
        end
        
        function Panel_ButtonDownFcn(obj, hObject, ~)
            % PANEL background click
            % Make sure user hasn't disabled all the conditions
            if isempty(get(obj.axesMain, 'children'))
                return;
            end
            
            %     if params.instructions == 1
            %       set(params.txtInstructions, 'Visible', 'off');
            %       params.instructions = 0;
            %     end
            
            % find out which panel it is
            panel_index = hObject.UserData;
            
            
            % if user has less than 15 dims, some panels won't be used
            if (~obj.checkPanel(panel_index))
                return;
            end
            
            % panels 1 to 15 are on the left, 16 to 30 are on the right
            % which side depends on which fixed vector
            
            % set the flag to keep the while loop running
            set(obj.axesMain, 'UserData', 0);
            
            % continuously rotate the object
            if (panel_index <= 15)  % it is on the left
                obj.Continuously_Rotate_BigTraj(hObject, 'forward', 'left', obj.Q1, panel_index);
            else
                obj.Continuously_Rotate_BigTraj(hObject, 'forward', 'right', obj.Q2, panel_index - 15);
            end
            
        end
        
        function closeF(obj)
            if isvalid(obj.FeaturesUI.FeatX) && isvalid(obj.FeaturesUI.FeatY)
                obj.FeaturesUI.FeatX.Enable = 'on';
                obj.FeaturesUI.FeatY.Enable = 'on';
            end
            delete(obj.Figure);
        end
        
    end
end

