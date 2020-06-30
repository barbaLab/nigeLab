classdef HighDimsUI < handle
    %HIGHDIMSUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ChannelSelector
        SpikeImage
        FeaturesUI
        
        Figure  matlab.ui.Figure
        panels
        
        btnPanel
        
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
            if isvalid(obj.Figure)
                return;
            end
            obj.Figure = figure('Color',nigeLab.defaults.nigelColors(0),...
                'ToolBar','none',...
                'MenuBar','none',...
                'CloseRequestFcn',@(~,~)obj.closeF,'Name','High-dimensional Navigator','numbertitle', 'off');
            
            p1 = nigeLab.libs.nigelPanel( obj.Figure,...
                'PanelColor',nigeLab.defaults.nigelColors(0.1),...
                'Position',[.01 .22 .48 .78]);
            
            p2 = nigeLab.libs.nigelPanel( obj.Figure,...
                'PanelColor',nigeLab.defaults.nigelColors(0.1),...
                'Position',[.51 .22 .48 .78]);
            
            p3 = nigeLab.libs.nigelPanel( obj.Figure,...
                'PanelColor',nigeLab.defaults.nigelColors(0.1),...
                'Position',[.01 .01 .98 .2],...
                'MinTitleBarHeightPixels',0);
            btnAx = axes('Position',[0 0 1 1],'Visible','off','XLim',[0 1],'YLim',[0 1]);
            p3.nestObj(btnAx,'btnAx');
            btn1 = nigeLab.libs.nigelButton(btnAx,[0.01 0.1 0.2 0.3],'Best proj.',...
                 {@(~,~)obj.setViewCallback},'FontSize',.8 );
            dropdown = uicontrol('Style','popupmenu',...
                'Units','normalized',...
                'Position',[0.02 0.5 0.18 0.3],...
                'String',{'LDA','PCA','Random'});
            
            p3.nestObj(dropdown,'projDropDown');
            
            for ii = 1:obj.maxDim % max 15 features
                ax1 = subplot(5,3,ii,'Parent',obj.Figure,'UserData',[ii],'xtick',[],'ytick',[],...
                    'ButtonDownFcn', {@obj.Panel_ButtonDownFcn});
                p1.nestObj(ax1);
                ax2 = copy(ax1);
                ax2.UserData = 15+ii;
                set(ax2,'ButtonDownFcn', {@obj.Panel_ButtonDownFcn});
                    p2.nestObj(ax2);
                ax(ii) = ax1;ax(ii+15) = ax2;
            end
             obj.panels = ax;
            InitUI(obj);
            obj.update_panels;
            
            obj.FeaturesUI.FeatX.Enable = 'off';
            obj.FeaturesUI.FeatY.Enable = 'off';
    
            obj.btnPanel = p3;
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
                  obj.panels(ii).Visible = 'off';
                  obj.panels(ii+15).Visible = 'off';                    
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
        
        function Panel_ButtonDownFcn(obj, hObject, evt)
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
            if evt.Button == 1, direction ='forward';
            elseif evt.Button == 3,direction ='backward';
            else return;end
                
            % continuously rotate the object
            if (panel_index <= 15)  % it is on the left
                obj.Continuously_Rotate_BigTraj(hObject, direction, 'left', obj.Q1, panel_index);
            else
                obj.Continuously_Rotate_BigTraj(hObject, direction, 'right', obj.Q2, panel_index - 15);
            end
            
        end
        
        function closeF(obj)
            if isvalid(obj.FeaturesUI.FeatX) && isvalid(obj.FeaturesUI.FeatY)
                obj.FeaturesUI.FeatX.Enable = 'on';
                obj.FeaturesUI.FeatY.Enable = 'on';
            end
            delete(obj.Figure);
        end
        
        function SetLDAproj(obj)
            % The desired vectors are from Fisher's linear discriminant analysis
            %
            % If only two conditions (should only be a one-d projection), qr gives us a
            % second projection vector (that can be considered random) anyway, so it's
            % ok
            
            D = obj.D;
            idx = ismember(obj.D.class,find(obj.selected_conds));
            conditions = unique(D.class(idx));
            if numel(conditions)==1
                return;
            end
            
            % TODO trajectories
            %             if (ismember('cluster', {D.type}))
            %                 D = D(ismember({D.type}, 'cluster')); % get rid of any trajs
            %
            %                 if (length(conditions) <= 1) % LDA should do nothing for one condition
            %                     return;
            %                 end
            %             else
            %                 if (length(conditions) == 1)  %  goal: only one cond, so make points in the traj far apart
            %                     if (length(D) == 1) % only one trajectory, so LDA will fail
            %                         return;
            %                     end
            %                     newData = [];
            %                     index = 1;
            %                     for itrial = 1:length(D)
            %                         D(itrial).epochStarts = [D(itrial).epochStarts size(D(itrial).data,2)];  %change epochStarts to include the end
            %                         for j = 1:length(D(1).epochStarts)
            %                             newData(index).condition = num2str(j);
            %                             newData(index).data = D(itrial).data(:,D(itrial).epochStarts(j));
            %                             index = index+1;
            %                         end
            %                     end
            %                     D = newData;
            %                     conditions = unique({D.condition});
            %                 end
            %                 % else, just use the full trajectory
            %             end
            %
            
            sigma = zeros(obj.num_dims);
            m = [];
            
            for cond = 1:length(conditions)
                thisCond = ismember(D.class, conditions(cond));
                sigma = sigma + cov(D.feat(thisCond,:),1);
                m(:,cond) = mean(D.feat(ismember(D.class, conditions(cond)),:),1);
            end
            
            Sigma_within = sigma ./ length(conditions);
            Sigma_between = cov(m',1);
            
            [w e] = eig(Sigma_within \ Sigma_between);
            
            % LDA does *not* return orthogonal eigenvectors
            % perform Gram-Schmidt to find nearest 2nd orthogonal vector
            
            [q r] = qr(w);
            
            rotate_to_desired(obj, q(:,1:2)');
            
        end
        
        function SetRandProj(obj)
            %  rotates to a random set of projection vectors
            
           
            [q r] = qr(randn(obj.num_dims));
            
            rotate_to_desired(obj, q(:,1:2)');
            
        end
        
        
        function SetPCAProj(obj)
            %  The desired vectors are the first two PCs of the data
            %  (trajectories' datapoints are concatenated)
            
            D = obj.D;
            
            idx = ismember(obj.D.class,find(obj.selected_conds));
            
            [u] = pca([D.feat(idx,:)]);
            
            rotate_to_desired(obj, u(:,1:2)');
            
        end
        
        
    end
    
    % Methods to precompute projections
    methods
        
        function setViewCallback(obj)
            dropdown = obj.btnPanel.Children{strcmp(obj.btnPanel.ChildName,'projDropDown')};
            switch dropdown.String{dropdown.Value}
                case 'LDA'
                    SetLDAproj(obj);
                case 'Random'
                    SetRandProj(obj)
                case 'PCA'
                    SetPCAProj(obj)
            end
            
        end
        

        % % Third idea, what GGobi uses
        function rotate_to_desired(obj, desired_vecs)
% helper function that modifies the current axes
%  rotates the current projection vectors by a small angle until that
%  the current vectors equal the desired vectors




    % idea:
    %  I found a nice idea in (Section 2.2 Cook, Buja, Lee, and Wickham: Grand Tours,
    %  Projection Pursuit Guided TOurs and Manual Controls) which
    %  calculates the principal angles between the projection matrices
    %
    % don't use qr here...we need to keep exact vectors, not just the span

    
    projVecs = obj.FeaturesUI.projVecs;
    

    
    % make sure desired_vecs are normalized
    desired_vecs(1,:) = desired_vecs(1,:) ./ norm(desired_vecs(1,:));
    desired_vecs(2,:) = desired_vecs(2,:) ./ norm(desired_vecs(2,:));
    
    check_desired = desired_vecs(1,:) * desired_vecs(2,:)';
    if (check_desired > 0) % desired vecs are not orthogonal
        desired_vecs(2,:) = desired_vecs(2,:) - desired_vecs(1,:)*desired_vecs(2,:)' * desired_vecs(1,:); % subtract the parallel component
        desired_vecs(2,:) = desired_vecs(2,:) ./ norm(desired_vecs(2,:));
    end

    check = projVecs * desired_vecs';
    if (check(1,1) > .99 && check(2,2) > .99) % this is the current view
        return; % so no need to move, do nothing
    end
    
    
    % Find shortest path between spaces using SVD
    [Va lambda Vz] = svd(projVecs * desired_vecs');


    % find principal directions in each space
    Ba = projVecs' * Va;
    Bz = desired_vecs' * Vz;


    % orthonormalize Bz to get B_star, ensuring projections are orthogonal
    % to Ba
    % don't use qr...screwed me up, as it negates some vectors
    B_star(:,1) = Bz(:,1) - Ba(:,1)'*Bz(:,1)*Ba(:,1) - Ba(:,2)'*Bz(:,1)*Ba(:,2);
    B_star(:,1) = B_star(:,1) ./ norm(B_star(:,1));
    B_star(:,2) = Bz(:,2) - B_star(:,1)'*Bz(:,2)*B_star(:,1) - Ba(:,1)'*Bz(:,2)*Ba(:,1) - Ba(:,2)'*Bz(:,2)*Ba(:,2);
    B_star(:,2) = B_star(:,2) ./ norm(B_star(:,2));

    % calculate the principal angles
    tau = acos(diag(lambda));

    % increment angles
    for t = linspace(0,1,60)
        
        % compute the rotation vector comprised of Ba and B_star
        % as t-->1, Bt should converge to Bz
        % also note that projection vectors are always orthogonal
        Bt = [];

        Bt(:,1) = cos(tau(1)*t)*Ba(:,1) + sin(tau(1)*t)*B_star(:,1);
        Bt(:,2) = cos(tau(2)*t)*Ba(:,2) + sin(tau(2)*t)*B_star(:,2);



        % need to rotate principal vectors back to original basis,
        % so that initial projection begins with the old projection vectors
        % (if not, you will still get same desired vectors, but the first
        % projection will start rotated from the original projection)
        projVecs = Va * Bt';  % transform back into the original coordinates

        % normalize projection vectors
        projVecs(1,:) = projVecs(1,:) ./ norm(projVecs(1,:));
        projVecs(2,:) = projVecs(2,:) ./ norm(projVecs(2,:));

        obj.FeaturesUI.projVecs = real(projVecs);
        obj.FeaturesUI.PlotFeatures;
    end

%     stop main axes from rotating
    % Set the projection to exactly the desired vecs
    obj.update_panels;
end


        
    end
end

