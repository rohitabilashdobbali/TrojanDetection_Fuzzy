% Create a new fuzzy inference system
fis = mamfis('Name','TrojanDetection');

% Define Power Consumption input (in watts)
fis = addInput(fis,[8 20],'Name','PowerConsumption');
fis = addMF(fis,'PowerConsumption','trimf',[8 10 12],'Name','Low');
fis = addMF(fis,'PowerConsumption','trimf',[12 14 16],'Name','Normal');
fis = addMF(fis,'PowerConsumption','trimf',[15 18 20],'Name','High');

% Define Timing input (in nanoseconds of delay)
fis = addInput(fis,[0 5],'Name','Timing');
fis = addMF(fis,'Timing','trimf',[0 1 2],'Name','OnTime');
fis = addMF(fis,'Timing','trimf',[1 2 3],'Name','SlightlyDelayed');
fis = addMF(fis,'Timing','trimf',[3 4 5],'Name','SignificantlyDelayed');

% Define Suspicion output (ranging from 0 to 1)
fis = addOutput(fis,[0 1],'Name','Suspicion');
fis = addMF(fis,'Suspicion','trimf',[0 0.25 0.5],'Name','Safe');
fis = addMF(fis,'Suspicion','trimf',[0.25 0.5 0.75],'Name','Suspicious');
fis = addMF(fis,'Suspicion','trimf',[0.5 0.75 1],'Name','HighlySuspicious');

% Add rules (9 rules to cover different scenarios)
ruleList = [... 
    "If PowerConsumption is Low and Timing is OnTime then Suspicion is Safe";  % Rule 1
    "If PowerConsumption is Low and Timing is SlightlyDelayed then Suspicion is Safe"; % Rule 2
    "If PowerConsumption is Low and Timing is SignificantlyDelayed then Suspicion is Suspicious"; % Rule 3
    "If PowerConsumption is Normal and Timing is OnTime then Suspicion is Safe"; % Rule 4
    "If PowerConsumption is Normal and Timing is SlightlyDelayed then Suspicion is Suspicious"; % Rule 5
    "If PowerConsumption is Normal and Timing is SignificantlyDelayed then Suspicion is HighlySuspicious"; % Rule 6
    "If PowerConsumption is High and Timing is OnTime then Suspicion is Suspicious"; % Rule 7
    "If PowerConsumption is High and Timing is SlightlyDelayed then Suspicion is HighlySuspicious"; % Rule 8
    "If PowerConsumption is High and Timing is SignificantlyDelayed then Suspicion is HighlySuspicious"; % Rule 9
];

% Add all rules to the fuzzy inference system
for i = 1:length(ruleList)
    fis = addRule(fis,ruleList(i));
end

% Display the rules
disp(fis.Rules);

% Read the Excel sheet data
data = readtable('trojan_detection_data_no_label.xlsx');

% Extract the relevant columns (PowerConsumption, Timing)
inputData = data{:, {'PowerConsumption', 'Timing'}};

% Evaluate the fuzzy system with the data from the Excel sheet
suspicionLevels = evalfis(fis, inputData);

% Add the suspicion levels to the table
data.SuspicionLevel = suspicionLevels;

% Define a threshold for classifying Trojan-Free and Trojan-Present
threshold = 0.5;

% Add a new column 'Label' based on the suspicion levels
data.Label = repmat("Trojan-Free", height(data), 1); % Initialize with 'Trojan-Free'
data.Label(suspicionLevels > threshold) = "Trojan-Present"; % Assign 'Trojan-Present' for suspicion levels above threshold

% Count the number of Trojan-Free and Trojan-Present entries
numTrojanPresent = sum(suspicionLevels > threshold);
numTrojanFree = sum(suspicionLevels <= threshold);

% Display the counts in the output
disp(['Total number of Trojan-Free: ', num2str(numTrojanFree)]);
disp(['Total number of Trojan-Present: ', num2str(numTrojanPresent)]);

% Display the table with suspicion levels and labels
disp(data);

% Save the output with labels to a new Excel file
writetable(data, 'trojan_detection_results_with_labels.xlsx');

% Plot Power Consumption and Timing data with detected anomalies
figure;

% Power Data with Detected Anomalies
subplot(2,1,1);
plot(data.PowerConsumption, 'b', 'LineWidth', 1.5);
hold on;
anomalyIndices = find(suspicionLevels > threshold); % Example condition for anomalies
plot(anomalyIndices, data.PowerConsumption(anomalyIndices), 'ro', 'MarkerSize', 8, 'LineWidth', 2); % Mark anomalies
title('Power Data with Detected Anomalies');
xlabel('Samples');
ylabel('Power (Watts)');
grid on;

% Timing Data with Detected Anomalies
subplot(2,1,2);
plot(data.Timing, 'g', 'LineWidth', 1.5);
hold on;
plot(anomalyIndices, data.Timing(anomalyIndices), 'ro', 'MarkerSize', 8, 'LineWidth', 2); % Mark anomalies
title('Timing Data with Detected Anomalies');
xlabel('Samples');
ylabel('Timing (ns)');
grid on;

% Adjust figure size
set(gcf, 'Position', [100, 100, 1200, 800]); % Set the figure size
