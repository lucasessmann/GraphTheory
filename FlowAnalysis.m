%% --------------------------- FlowAnalysis -------------------------------

% -------------------- written by Lucas Essmann - 2020 --------------------
% ---------------------- lessmann@uni-osnabrueck.de -----------------------

% This script calculates the Maximum Flow both for unweighted and for
% weighted gaze graphs created through processing ET data. 

% Requirements:
% undirected, unweighted graphs with Edges and Nodes Table 
% undirected, weighted graphs with Edges and Nodes Table
% The Edges Table needs to contain an EndNodes column

% The flow between two nodes in a network is defined as the maximum amount
% of flow that can be pushed through all connections between these two
% nodes in dependence of the capacity of each edge. For a detailed
% description check out my GraphTheoryGuide or contact me. 

clear all;

plotting_wanted = false; %if you want to plot, set to true
saving_wanted = true; %if you want to save, set to true

% Decide whether you want to analyse the weighted or the unweighted graphs
% by changing the bool : weighted == 1 or unweighted == 0
to_analyse = 1;


%% -------------------------- Initialisation ------------------------------

path = what;
path = path.path;

%savepaths
savepath = strcat(path,'/Results/MaxFlow/');

% cd into graph folder location
if to_analyse == 0
    cd graphs;
elseif to_analyse == 1
    cd graphs_weighted;
else
    disp('Check what you want to analyse (line 26)');
end

% Partlist Creation 
graphfolder = dir();
graphfolder = struct2cell(graphfolder);
% reduce the folder to the graphs only
graphfolder = graphfolder(1,3:end);
% Create PartList

% Creating the weighted graph folder
for valid = 1:length(graphfolder)
PartList{1,valid}= str2num(graphfolder{valid}(1:2));
end

% Creating partlist
Number = length(PartList);

%% ----------------------------- Loading ----------------------------------

% loading the map 
map = imread(strcat(path,'/Dependencies/map5.png'));

% loading the House Coordinate List of the Map 
listname = strcat(path,'/Dependencies/CoordinateList.txt');
coordinateList = readtable(...
    listname,...
    'delimiter',{':',';'},...
    'Format','%s%f%f',...
    'ReadVariableNames',false);
coordinateList.Properties.VariableNames = {'House','X','Y'};
% the factor for realigning the coordinates on the new map
coordinateList.X = coordinateList.X.*0.215555;  
coordinateList.Y = coordinateList.Y.*0.215666;

% Due to format issues, I am loading the Task HouseLists in the two
% different formats, i.e. with housenames as integers and with housenames
% as strings - currently ugly and hardcoded, but it works 

% Interger Format:
% ABSOLUTE ORIENTATION TASK
houses_abs3s = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_abs3s.mat'));
houses_abs3s = houses_abs3s.houses_abs3s;
houses_absInf = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_absInf.mat'));
houses_absInf = houses_absInf.houses_absInf;
% RELATIVE ORIENTATION TASK
houses_rel3s = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_rel3s.mat'));
houses_rel3s = houses_rel3s.houses_rel3s;
houses_relInf = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_relInf.mat'));
houses_relInf = houses_relInf.houses_relInf;
% POINTING TASK
houses_poi3s = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_poi3s.mat'));
houses_poi3s = houses_poi3s.houses_poi3s;
houses_poiInf = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_poiInf.mat'));
houses_poiInf = houses_poiInf.houses_poiInf;

% String format:
% ABSOLUTE ORIENTATION TASK
houses_abs3s_format = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_abs3s_s.mat'));
houses_abs3s_format = houses_abs3s_format.houses_abs3s_format;
houses_absInf_format = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_absInf_s.mat'));
houses_absInf_format = houses_absInf_format.houses_absInf_format;
% RELATIVE ORIENTATION TASK
houses_rel3s_format = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_rel3s_s.mat'));
houses_rel3s_format = houses_rel3s_format.houses_rel3s_format;
houses_relInf_format = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_relInf_s.mat'));
houses_relInf_format = houses_relInf_format.houses_relInf_format;
% POINTING TASK
houses_poi3s_format = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_poi3s_s.mat'));
houses_poi3s_format = houses_poi3s_format.houses_poi3s_format;
houses_poiInf_format = ...
    load(strcat(path,'/Dependencies/TaskHouseLists/houses_poiInf_s.mat'));
houses_poiInf_format = houses_poiInf_format.houses_poiInf_format;


HouseNumber = length(houses_poi3s.Prime_Nr);
countMissingPart = [];

%% ----------------------------Main Part-----------------------------------

for sub = 1:Number 
    currentPart = cell2mat(PartList(sub));
    
    if to_analyse == 0
        file = strcat(num2str(currentPart),'_Graph.mat');
    elseif to_analyse == 1
        file = strcat(num2str(currentPart),'_Graph_weighted_V3.mat');
    else
        disp('Check what you want to analyse (line 26)');
    end
 
    % check for missing files
    if exist(file) == 0
        countMissingPart = countMissingPart+1;
        
        noFilePartList = [noFilePartList;currentPart];
        disp(strcat(file,' does not exist in folder'));
          
    elseif exist(file) == 2
        
        % loading the respective graph
        graphy = load(file);
        
        if to_analyse == 0
            graphy= graphy.graphy;
        elseif to_analyse == 1
            graphy= graphy.graphyW;
        else
            disp('Check what you want to analyse (line 26)');
        end
        
        % Calculating the flow for each house combination and each subject
        for house = 1:HouseNumber
            % Checking whether the house has been seen
            if any(strcmp(...
                    houses_rel3s_format.Prime_Nr(house),...
                    graphy.Nodes.Name)) ...
                    && any(strcmp(...
                    houses_rel3s_format.TargetNr_Correct(house),...
                    graphy.Nodes.Name))
                
                % Calculating the max flow for the Pointing task houses
                FlowRel3s(house,sub) = maxflow(...
                    graphy,houses_rel3s_format.Prime_Nr(house),...
                    houses_rel3s_format.TargetNr_Correct(house)); 
            else
                FlowRel3s(house,sub) = NaN; 
            end
            
            if any(strcmp(...
                    houses_relInf_format.Prime_Nr(house),...
                    graphy.Nodes.Name)) ...
                    && any(strcmp(...
                    houses_relInf_format.TargetNr_Correct(house),...
                    graphy.Nodes.Name))
                
                FlowRelInf(house,sub) = maxflow(...
                    graphy,houses_relInf_format.Prime_Nr(house),...
                    houses_relInf_format.TargetNr_Correct(house));
            else
                FlowRelInf(house,sub) = NaN;
            end
            
            if any(strcmp(...
                    houses_poi3s_format.Prime_Nr(house),...
                    graphy.Nodes.Name)) ...
                    && any(strcmp(...
                    houses_poi3s_format.TargetNr(house),...
                    graphy.Nodes.Name))
                
                FlowPoi3s(house,sub) = maxflow(...
                    graphy,houses_poi3s_format.Prime_Nr(house),...
                    houses_poi3s_format.TargetNr(house));
            else
                FlowPoi3s(house,sub) = NaN;
            end
            
            if any(strcmp(...
                    houses_poiInf_format.Prime_Nr(house),...
                    graphy.Nodes.Name)) ...
                    && any(strcmp(...
                    houses_poiInf_format.TargetNr(house), ...
                    graphy.Nodes.Name))
                
                FlowPoiInf(house,sub) = maxflow(...
                    graphy,houses_poiInf_format.Prime_Nr(house),...
                    houses_poiInf_format.TargetNr(house));
            else
                FlowPoiInf(house,sub) = NaN; 
            end
            
        end
        
    end
end

meanFlow_rel3s = nanmean(FlowRel3s,2); 
meanFlow_relInf = nanmean(FlowRelInf,2); 
meanFlow_poi3s = nanmean(FlowPoi3s,2); 
meanFlow_poiInf = nanmean(FlowPoiInf,2);


%% ----------------------- Creating beautiful tables ----------------------

% To be improved 

Flow_Poi_Inf = table();
Flow_Poi_3s = table();
Flow_Rel_Inf = table();
Flow_Rel_3s = table();

Flow_Poi_Inf.Prime_Nr = houses_poiInf.Prime_Nr;
Flow_Poi_Inf.Target_Nr = houses_poiInf.TargetNr;


%% ---------------------------- Saving ------------------------------------

if saving_wanted == true
    if to_analyse == 0
        save([savepath 'meanFlow_rel3s'],'meanFlow_rel3s');
        save([savepath 'meanFlow_relInf'],'meanFlow_relInf');
        save([savepath 'meanFlow_poi3s'],'meanFlow_poi3s');
        save([savepath 'meanFlow_poiInf'],'meanFlow_poiInf');
    elseif to_analyse == 1
        save([savepath 'meanFlow_rel3s_weighted'],'meanFlow_rel3s');
        save([savepath 'meanFlow_relInf_weighted'],'meanFlow_relInf');
        save([savepath 'meanFlow_poi3s_weighted'],'meanFlow_poi3s');
        save([savepath 'meanFlow_poiInf_weighted'],'meanFlow_poiInf');
    else
        disp('Check what you want to analyse (line 26)');
    end
end

%% --------------------------- Plotting -----------------------------------

if plotting_wanted == true
    figure();
    [mf,GF] = maxflow(graphy, '033_0', '009_0'); ...
    H = plot(graphy, 'LineStyle','--'); ...
    highlight(H,GF,'EdgeColor','r','LineWidth',1,'LineStyle','-'); ...
    highlight(H,[37,9],'NodeColor','g','MarkerSize',10);

    Idea for plotting map graphs 
    figure();
    imshow(map);
    alpha(0.1);
    hold on;
    [x,y] = gplot(...
        adjacency(graphy),...
        table2array(...
        coordinateList(...
        ismember(...
        coordinateList.House, graphy.Nodes.Name),2:end)),'o-');
    
    highlight(G,GF,'EdgeColor','r','LineWidth',1,'LineStyle','-'); ...
    highlight(G,[37,9],'NodeColor','g','MarkerSize',10);
end

%% --------------------------- Finalize -----------------------------------

clearvars '-except' ...
    meanFlow_poi3s...
    meanFlow_poiInf ...
    meanFlow_rel3s ...
    meanFlow_Inf ...
    to_analyse;

if to_analyse == 0
    disp('Done - Analysis: Unweighted');
elseif to_analyse == 1
    disp('Done - Analysis: Weighted');
else
    disp('Check what you want to analyse (line 26)');
end

