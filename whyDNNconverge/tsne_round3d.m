% Initialize parameters
clear all
n = 2^15; L = 4; k = 50; N = 1100; R = 2;  % Generalize to R rounds
gens = [];
u = randn(1, k);
u = u / norm(u);  % Generate and normalize initial vector u
ii = 1;
inI = u(:);
RandomfieldM = eye(length(inI));  % Identity matrix for RandomfieldM
uvec = [];
vvec = [];

% Generate uvec for each L
while ii <= L
    [y1, frmat] = Encoding_mat(inI, n, length(inI));  % Encoding step
    inI = y1;
    y1 = y1 / norm(y1);  % Normalize the result
    frmatii{ii} = frmat;  % Store encoding matrix
    uvec = [uvec; y1'];  % Store vectors
    ii = ii + 1;
end

% Initialize vveccell for arbitrary rounds
vveccell = cell(R, 1);
vveccell{1} = cell(N, 1);  % Initialize first round

% Generate vveccell_1 for N iterations (First round)
for i = 1:N
    disp(['gen', num2str(i)]);
    v = randn(1, k);  % Generate random vector v
    vvec = [];
    vf = v;
    for ii = 1:L
        fmatii = frmatii{ii};
        y2 = fmatii * vf';  % Apply transformation
        y2 = y2 / norm(y2); vf = y2';  % Normalize and update vector
        vvec = [vvec; y2'];
    end
    vveccell{1}{i} = vvec;  % Store transformed vectors for first round
end

% Generate vveccell for R rounds
for r = 2:R
    vveccell{r} = cell(N, 1);  % Initialize next round
    for i = 1:N
        disp(['gen (round ', num2str(r), ') ', num2str(i)]);
        vvec = [];
        for ii = 1:L
            vvecjj = vveccell{r-1}{i};  % Use previous round's results
            vf = vvecjj(ii, :);  % Get corresponding vector
            fmatii = frmatii{ii};
            y2 = fmatii * vf';  % Apply transformation
            y2 = y2 / norm(y2);
            vvec = [vvec; y2'];
        end
        vveccell{r}{i} = vvec;  % Store transformed vectors
    end
end

% Combine all vveccell rounds into one for t-SNE
combined_vveccell = vertcat(vveccell{:});  % Concatenate all rounds

% Prepare data for t-SNE
for ll = 1:L
    uvL = uvec(ll, :);
    vv = [];
    for jj = 1:(R * N)  % Total entries across R rounds
        vvecjj = combined_vveccell{jj};
        vvecs = vvecjj(ll, :);
        vv = [vv; vvecs];
    end
    vvL{ll} = vv;  % Store vectors for t-SNE
end

x = uvL;  % Set up the 'x' vector for plotting

for i = 1:L
    y{i} = vvL{i};  % Prepare data for each subplot
end

% Number of rows and columns for subplots
cols = ceil(sqrt(L));
rows = ceil(L / cols);
% Marker size and edge thickness for plotting
markerSize1 = 1;
markerSize2 = 20;
lineWidth = 1.5;
fontSize = 12;

% Create a figure for t-SNE plots
figure('Position', [100, 100, 600, 600]);  % Square aspect ratio for the whole figure
sil_scores = [];  % Array to store silhouette scores
dbi_scores = [];  % Array to store Davies-Bouldin index
inter_cluster_distances = [];  % Store inter-cluster distances
intra_cluster_distances = [];  % Store intra-cluster distances

% Iterate over L to generate t-SNE plots for each dataset
for i = 1:L
    combined_data = [x; y{i}];  % Combine data (x and y{i}) for t-SNE
    rng('default');  % Set random seed for reproducibility
    Y = tsne(combined_data, 'NumDimensions', 3);  % Perform t-SNE in 3D

    % Create subplot
    subplot(rows, cols, i);
    hold on;

    % Plot the 3D t-SNE result
    scatter3(Y(:,1), Y(:,2), Y(:,3), markerSize1, 'filled', 'MarkerEdgeColor', '#0072BD', 'MarkerFaceColor', '#1E90FF', 'LineWidth', lineWidth);

    % Highlight the first point
    scatter3(Y(1, 1), Y(1, 2), Y(1, 3), markerSize2, 'MarkerEdgeColor', '#000000', 'MarkerFaceColor', '#D95319', 'LineWidth', lineWidth);

    hold off;

    % Set axes labels and other properties
    xlabel('D-1', 'FontSize', fontSize);
    ylabel('D-2', 'FontSize', fontSize);
    zlabel('D-3', 'FontSize', fontSize);
    grid on;
    set(gca, 'FontSize', fontSize, 'LineWidth', 1.2);
    axis equal;
    view(3);  % 3D view
    title(['$\ell$=' num2str(i)], 'Interpreter', 'latex');
end


% Initialize figure for t-SNE plots with K-Means clustering
figure('Position', [100, 100, 600, 600]);  % Square aspect ratio for the whole figure

% Iterate over L to generate t-SNE plots for each dataset
for i = 1:L
    combined_data = [x; y{i}];  % Combine data (x and y{i}) for t-SNE
    rng('default');  % Set random seed for reproducibility
    Y = tsne(combined_data, 'NumDimensions', 3);  % Perform t-SNE in 3D


    %     % Use a larger pool from the lines colormap
    clusterColors = [
        0.00, 0.45, 0.74;  % Blue
        0.85, 0.33, 0.10;  % Red
        0.93, 0.69, 0.13;  % Yellow
        0.49, 0.18, 0.56;  % Purple
        0.47, 0.67, 0.19;  % Green
        0.30, 0.75, 0.93;  % Cyan
        0.64, 0.08, 0.18;  % Dark Red
        0.00, 0.50, 0.00;  % Dark Green
        0.25, 0.25, 0.25;  % Gray
        0.75, 0.75, 0.75;  % Light Gray
        ];
    % Perform K-Means clustering into 2R clusters
    numClusters = 2*R;
    cluster_idx = kmeans(zscore(Y), numClusters, 'Replicates', 100,'Start', 'plus');

    % Create subplot
    subplot(rows, cols, i);
    hold on;


    % Plot each cluster in a different color
    for j = 1:numClusters
        scatter3(Y(cluster_idx == j, 1), Y(cluster_idx == j, 2), Y(cluster_idx == j, 3), ...
            markerSize1, 'filled', 'MarkerEdgeColor', clusterColors(j, :), 'MarkerFaceColor', clusterColors(j, :), 'LineWidth', lineWidth);
    end

    % Highlight the first point
    scatter3(Y(1, 1), Y(1, 2), Y(1, 3), markerSize2, 'MarkerEdgeColor', '#000000', 'MarkerFaceColor', '#D95319', 'LineWidth', lineWidth);

    hold off;

    % Set axes labels and other properties
    xlabel('D-1', 'FontSize', fontSize);
    ylabel('D-2', 'FontSize', fontSize);
    zlabel('D-3', 'FontSize', fontSize);
    grid on;
    set(gca, 'FontSize', fontSize, 'LineWidth', 1.2);
    axis equal;
    view(3);  % 3D view
    title(['$\ell$=' num2str(i)], 'Interpreter', 'latex');
end







% 
% 
% % Initialize figure for t-SNE plots with K-Means clustering
% figure;
% 
% % Define a color map for clusters with distinct colors
%     clusterColors = [
%         0.00, 0.45, 0.74;  % Blue
%         0.85, 0.33, 0.10;  % Red
%         0.93, 0.69, 0.13;  % Yellow
%         0.49, 0.18, 0.56;  % Purple
%         0.47, 0.67, 0.19;  % Green
%         0.30, 0.75, 0.93;  % Cyan
%         0.64, 0.08, 0.18;  % Dark Red
%         0.00, 0.50, 0.00;  % Dark Green
%         0.25, 0.25, 0.25;  % Gray
%         0.75, 0.75, 0.75;  % Light Gray
%         ];
% % Iterate over L to generate t-SNE plots for each dataset
% for i = 1:L
%     combined_data = [x; y{i}];  % Combine data (x and y{i}) for t-SNE
%     rng('default');  % Set random seed for reproducibility
%     Y = tsne(combined_data, 'NumDimensions', 3);  % Perform t-SNE in 3D
% 
%     % Scale the data to improve sensitivity
%     % Normalize each feature (optional but helps with clustering)
%     Y = normalize(Y);
% 
%     % Perform K-Means clustering with more sensitivity
%     numClusters = 2 * R;  % You can adjust this value if you want more clusters
%     cluster_idx = kmeans(Y, numClusters, 'Start', 'plus', 'MaxIter', 5000, 'Replicates', 10);  % Increased iterations and K-means++ initialization
% 
%     % Create subplot
%     subplot(rows, cols, i);
%     hold on;
% 
%     % Plot each cluster in a unique color
%     for j = 1:numClusters
%         scatter3(Y(cluster_idx == j, 1), Y(cluster_idx == j, 2), Y(cluster_idx == j, 3), ...
%             markerSize1, 'filled', 'MarkerEdgeColor', clusterColors(j, :), 'MarkerFaceColor', clusterColors(j, :), 'LineWidth', lineWidth);
%     end
% 
%     % Highlight the first point with a special color
%     scatter3(Y(1, 1), Y(1, 2), Y(1, 3), markerSize2, 'MarkerEdgeColor', '#000000', 'MarkerFaceColor', '#D95319', 'LineWidth', lineWidth);
% 
%     hold off;
% 
%     % Set axes labels and other properties
%     xlabel('t-SNE D-1', 'FontSize', fontSize);
%     ylabel('t-SNE D-2', 'FontSize', fontSize);
%     zlabel('t-SNE D-3', 'FontSize', fontSize);
%     grid on;
%     set(gca, 'FontSize', fontSize, 'LineWidth', 1.2);
%     axis equal;
%     view(3);  % 3D view
%     title(['$\ell$=' num2str(i)], 'Interpreter', 'latex');
% end
% 
% 
% 
% 
% 
% 
















%
%
%
%
% % Initialize figure for t-SNE plots
% figure;
%
% % Iterate over L to generate t-SNE plots for each dataset
% for i = 1:L
%     % Combine the data (x and y{i}) for t-SNE
%     combined_data = [x; y{i}];
%
%     rng('default'); % Set random seed for reproducibility
%     Y = tsne(combined_data, 'NumDimensions', 3); % Perform t-SNE in 3D
%
%     % Perform K-Means clustering into 6 clusters
%     numClusters = 6; % Number of clusters you want
%     cluster_idx = kmeans(Y, numClusters);
%
%     % Create subplot
%     subplot(rows, cols, i);
%     hold on;
%
%     % Define a set of 6 distinct colors for the clusters
%     clusterColors = lines(numClusters); % Generate 6 distinct colors
%
%     % Plot each cluster in a different color
%     for j = 1:numClusters
%         scatter3(Y(cluster_idx == j, 1), Y(cluster_idx == j, 2), Y(cluster_idx == j, 3), ...
%             markerSize1, 'filled', 'MarkerEdgeColor', clusterColors(j, :), 'MarkerFaceColor', clusterColors(j, :), 'LineWidth', lineWidth);
%     end
%
%     % Optionally, highlight the 'x' vector (or any specific point/points you want to emphasize)
%     scatter3(Y(1, 1), Y(1, 2), Y(1, 3), markerSize2, 'MarkerEdgeColor', '#000000', 'MarkerFaceColor', '#D95319', 'LineWidth', lineWidth); % Highlight first point
%
%     hold off;
%
%     % Set axes labels and other properties
%     xlabel('t-SNE D-1', 'FontSize', fontSize);
%     ylabel('t-SNE D-2', 'FontSize', fontSize);
%     zlabel('t-SNE D-3', 'FontSize', fontSize);
%
%     % Customize the grid and appearance
%     grid on;
%     set(gca, 'FontSize', fontSize, 'LineWidth', 1.2); % Set font size and axis thickness
%     axis equal; % Set aspect ratio to be equal
%
%     % Set the view to 3D explicitly
%     view(3); % 3D view
%
%     % Add title to each subplot
%     title(['$\ell$=' num2str(i)], 'Interpreter', 'latex');
% end














% Function to calculate Davies-Bouldin Index
function dbi_value = davies_bouldin_index(X, idx)
k = max(idx);
centroids = zeros(k, size(X, 2));
for i = 1:k
    centroids(i, :) = mean(X(idx == i, :), 1);
end

% Intra-cluster distances
intra_dist = zeros(k, 1);
for i = 1:k
    intra_dist(i) = mean(pdist(X(idx == i, :)));
end

% Inter-cluster distances
inter_dist = zeros(k, k);
for i = 1:k
    for j = i+1:k
        inter_dist(i, j) = norm(centroids(i, :) - centroids(j, :));
        inter_dist(j, i) = inter_dist(i, j);  % Symmetric
    end
end

% Davies-Bouldin index
dbi_value = 0;
for i = 1:k
    max_ratio = 0;
    for j = 1:k
        if i ~= j
            ratio = (intra_dist(i) + intra_dist(j)) / inter_dist(i, j);
            max_ratio = max(max_ratio, ratio);
        end
    end
    dbi_value = dbi_value + max_ratio;
end
dbi_value = dbi_value / k;
end

% Function to calculate inter-cluster distance
function inter_dist = inter_cluster_distance(X, idx)
k = max(idx);
centroids = zeros(k, size(X, 2));
for i = 1:k
    centroids(i, :) = mean(X(idx == i, :), 1);
end

% Calculate inter-cluster distances
inter_dist = 0;
for i = 1:k
    for j = i+1:k
        inter_dist = inter_dist + norm(centroids(i, :) - centroids(j, :));
    end
end
inter_dist = inter_dist / (k * (k - 1) / 2);  % Average inter-cluster distance
end

% Function to calculate intra-cluster distance
function intra_dist = intra_cluster_distance(X, idx)
k = max(idx);
intra_dist = 0;
for i = 1:k
    cluster_points = X(idx == i, :);
    centroid = mean(cluster_points, 1);
    intra_dist = intra_dist + mean(pdist(cluster_points));
end
intra_dist = intra_dist / k;  % Average intra-cluster distance
end


% sgtitle('3D t-SNE Visualization of x and Multiple y Sets'); % Overall title for the subplots

% Function definitions below remain unchanged
function read_and_save_csv_first_column(filename)
% Read the file into a table
T = readtable(filename, 'ReadVariableNames', false);

% Extract the first column
T_without_first_column = T(:, 1);

% Convert the table to a numeric matrix
index = table2array(T_without_first_column);

% Save data in .mat format
[~, index, ~] = fileparts(index);
save([index, 'index.mat'], 'index');
end

function [mat]=generate_m(n)
mat=randn(n,512);
end

function [ww] = LSH(w, mat)
v = mat * w';
ww = sign(v);
ww(ww == -1) = 0;
ww = ww';
end

function [frr, far] = getfarfrr(gen, imp, mine, maxe, dec)
gar = [];
for t = mine:dec:maxe
    gencal = gen(gen(:) <= t);
    if isempty(gencal)
        genrate = 0;
    else
        genrate = length(gencal) / length(gen);
    end
    gar = [gar; genrate];
end
frr = 1 - gar;

far = [];
for t = mine:dec:maxe
    impcal = imp(imp(:) <= t);
    if isempty(impcal)
        imprate = 0;
    else
        imprate = length(impcal) / length(imp);
    end
    far = [far; imprate];
end
end

function [yfil, frmat] = Encoding_mat(x, n, t)
k = size(x, 1);
rmat = randn(n, k);
y = rmat * x;
absy = abs(y);
[sorted_data, sortedindex] = sort(absy, 'descend');
topindex = (sortedindex(1:t));
frmat = rmat(topindex, :);
yfil = y(topindex);
end

function [RandomfieldM, yfil] = main_alg(Ib, n, L)
ii = 1;
inI = Ib(:);
RandomfieldM = eye(length(inI));
while ii <= L
    [yfil, frmat] = Encoding_mat(inI, n, length(inI));
    inI = yfil;
    RandomfieldM = frmat * RandomfieldM;
    ii = ii + 1;
end
end
