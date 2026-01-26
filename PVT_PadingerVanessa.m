% Psychomotor Vigilance Task (PVT)
% 2 Minuten Version für UE Scientific Programming 
% Replikation inspiriert von Dinges & Powell (1985) & dem SloryMum Projekt
% des Schlaflabors Salzburg
%
% Autor: Vanessa Padinger
% ------------------------------------------------------------

clear all; close all; clc;

%% ----------------- Parameter -----------------
% experimentDuration = Gesamtdauer des Experiments
% minISI / maxISI = zufällige Wartezeit zwischen Stimuli (Inter-Stimulus-Intervall)
% stopKey = Leertaste um auf den Stimulus zu reagieren 
% exitKey = Escape Taste um das Experiment frühzeitig zu beenden 

experimentDuration = 120; % 2 Minuten in Sekunden
minISI = 2;               % minimale Wartezeit (Sekunden)
maxISI = 10;              % maximale Wartezeit (Sekunden)

stopKey = KbName('space');
exitKey = KbName('ESCAPE');

textColor = [455 455 455];
bgColor   = [0 0 0];

%% ----------------- Psychtoolbox Setup ----------------

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);

screens = Screen('Screens');
screenNumber = max(screens);

[win, winRect] = PsychImaging('OpenWindow', screenNumber, bgColor);
[xCenter, yCenter] = RectCenter(winRect);

Screen('TextSize', win, 40);
HideCursor;

%% ----------------- Instruktion für VP -----------------
% Instruktionsbildschirm

instructionText = [ ...
    'Psychomotor Vigilance Task (PVT)\n\n' ...
    'In diesem Experiment erscheint in zufälligen Abständen ein Zähler.\n' ...
    'Sobald der Zähler startet, beginnt er hochzuzählen.\n\n' ...
    'Ihre Aufgabe:\n' ...
    '- Drücken Sie die LEERTASTE (SPACE), so schnell wie möglich,\n' ...
    '  sobald der Zähler startet.\n\n' ...
    'Versuchen Sie aufmerksam zu bleiben und jederzeit bereit zu reagieren.\n\n' ...
    'Drücken Sie die LEERTASTE, um das Experiment zu starten.' ...
];

DrawFormattedText(win, instructionText, 'center', 'center', textColor);
Screen('Flip', win);

KbReleaseWait;
KbWait([], 2);

%% ----------------- Experiment -----------------
% Hauptschleife des Experiments
% Steuert Timing, Stimuluspräsentation, Reaktionserfassung
% und Datenspeicherung

startExpTime = GetSecs;
trial = 0;
results = [];

% Kategorisierung der Antworten (Vigilanz-Metriken)
sleepAttack = 0;   % >30s keine Reaktion
lapse = 0;         % >5s
good = 0;          % 150–500ms
tooFast = 0;       % <100ms
excessiveClick = 0;% Klick ohne Stimulus

flagStimulus = false;

while (GetSecs - startExpTime) < experimentDuration
    trial = trial + 1;
    
    %% ----------------- Random ISI -----------------
    % Zufälliges Inter-Stimulus-Intervall (2–10 Sekunden), damit die
    % Stimuli unvorhersehbar sind
    
    isi = minISI + (maxISI - minISI) * rand;
    
    %% ----------------- Fixationspunkt (gelber Kreis) -----------------
    % Gelber Punkt in der Mitte
    
    Screen('FillRect', win, bgColor);
    dotSize = 85; 
    Screen('FillOval', win, [455 455 0], ...
        CenterRectOnPoint([0 0 dotSize dotSize], xCenter, yCenter));
    Screen('Flip', win);
    
    % Wartezeit (minus 1 Sekunde Leerlaufphase nach Response)
    WaitSecs(isi - 1);

    
    %% ----------------- Start Counter (Stimulus) -----------------
    % Start des eigentlichen Stimulus
    % Fortlaufender Zahlen-Counter
    % RT wird relativ zu diesem Zeitpunkt gemessen


    stimOnset = GetSecs;
    response = false;
    rt = NaN;
    flagStimulus = true;
    
    while ~response
        
        % Fortlaufende Zahl (Counter)
        elapsed = (GetSecs - stimOnset) * 1000; % interne ms-Berechnung
        counterText = sprintf('%.0f', elapsed); % NUR ZAHL, kein \"ms\"
        
          % Darstellung des Counters
	Screen('TextSize', win, 65);   
	DrawFormattedText(win, counterText, 'center', 'center', [455 455 0]);
	Screen('Flip', win);
	Screen('TextSize', win, 40);  

        % Tastenerfassung
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(stopKey)
                rt = GetSecs - stimOnset;
                response = true;
            elseif keyCode(exitKey)
                sca; ShowCursor; return;
            else
                excessiveClick = excessiveClick + 1; % Klick ohne Stimulus
            end
        end
        
        % Sleep-Attack Detection (>30s keine Reaktion)
        if (GetSecs - stimOnset) > 30
            sleepAttack = sleepAttack + 1;
            response = true;
            rt = NaN;
        end
    end
    
    flagStimulus = false;
    
    %% ----------------- Klassifikation -----------------
    % Einteilung der Reaktion in Vigilanz-Kategorien
    
    if ~isnan(rt)
        rt_ms = rt*1000;
        if rt_ms < 100
            tooFast = tooFast + 1;
        elseif rt_ms <= 500
            good = good + 1;
        elseif rt_ms > 5000
            lapse = lapse + 1;
        else
            lapse = lapse + 1;
        end
    end

% VP sieht die Reaktionszeit für ca. 1 Sekunde
if ~isnan(rt)
    feedbackNumber = sprintf('%.0f', rt*1000);  
else
    feedbackNumber = '---'; % falls keine Reaktion
end

Screen('TextSize', win, 65);   
DrawFormattedText(win, feedbackNumber, 'center', 'center', [455 455 0]);
Screen('Flip', win);
WaitSecs(1);   % Anzeige ca. 1 Sekunde
Screen('TextSize', win, 40);   

% Danach zurück zum Fixationspunkt
Screen('FillRect', win, bgColor);
Screen('FillOval', win, [455 455 0], ...
    CenterRectOnPoint([0 0 dotSize dotSize], xCenter, yCenter));
Screen('Flip', win);

    %% ----------------- Speichern -----------------
    % Speichert Trial-Daten
    
    results(trial).trial = trial;
    results(trial).isi = isi;
    results(trial).rt = rt;
end

%% ----------------- Ende -----------------

endText = [ ...
    'Experiment beendet!\n\n' ...
    'Vielen Dank für Ihre Teilnahme :)!\n\n' ...
];

DrawFormattedText(win, endText, 'center', 'center', textColor);
Screen('Flip', win);
WaitSecs(3);

sca;
ShowCursor;

%% ----------------- Daten speichern -----------------

save('PVT_results.mat', 'results', ...
     'sleepAttack', 'lapse', 'good', 'tooFast', 'excessiveClick');

%% ----------------- Einfache Auswertung -----------------

RTs = [results.rt];
RTs = RTs(~isnan(RTs));

fprintf('\n===== PVT Auswertung =====\n');
fprintf('Trials: %d\n', length(results));
fprintf('Mittlere RT: %.3f s\n', mean(RTs));
fprintf('Min RT: %.3f s\n', min(RTs));
fprintf('Max RT: %.3f s\n', max(RTs));
fprintf('tooFast: %d\n', tooFast);
fprintf('good: %d\n', good);
fprintf('lapse: %d\n', lapse);
fprintf('sleepAttack: %d\n', sleepAttack);
fprintf('excessiveClick: %d\n', excessiveClick);
fprintf('==========================\n');