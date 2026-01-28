%Psychomotor Vigilance Task (PVT)
% 2 Minuten Version für UE Scientific Programming 
% Replikation inspiriert von Dinges & Powell (1985) & dem SloryMum Projekt
% des Schlaflabors Salzburg
%
% Autor: Vanessa Padinger
% ------------------------------------------------------------

clear all; close all; clc;        % Workspace leeren, Fenster schließen, Konsole leeren

%% ----------------- Parameter -----------------
experimentDuration = 120;        % Gesamtdauer des Experiments in Sekunden (2 Minuten)
minISI = 2;                      % minimale Wartezeit zwischen Stimuli in Sekunden
maxISI = 10;                     % maximale Wartezeit zwischen Stimuli in Sekunden 

stopKey = KbName('space');       % Reaktionstaste = Leertaste
exitKey = KbName('ESCAPE');      % Abbruchtaste = ESC

textColor = [455 455 455];       % Textfarbe (weiß)
bgColor   = [0 0 0];             % Hintergrundfarbe (schwarz)

%% ----------------- Psychtoolbox Setup ----------------

PsychDefaultSetup(2);            % Standard-Psychtoolbox-Einstellungen
Screen('Preference', 'SkipSyncTests', 1);  % Sync-Tests deaktivieren 

screens = Screen('Screens');     % verfügbare Bildschirme abfragen
screenNumber = max(screens);     % größten Bildschirm auswählen

[win, winRect] = PsychImaging('OpenWindow', screenNumber, bgColor); % Fenster öffnen
[xCenter, yCenter] = RectCenter(winRect); % Mittelpunkt berechnen

Screen('TextSize', win, 40);     % Standardschriftgröße
HideCursor;                      % Mauszeiger ausblenden

%% ----------------- Instruktion für VP -----------------

instructionText = [ ...
    'Psychomotor Vigilance Task (PVT)\n\n' ...
    'In diesem Experiment erscheint in zufälligen Abständen ein Zähler.\n' ...
    'Sobald der Zähler startet, beginnt er hochzuzählen.\n\n' ...
    'Ihre Aufgabe:\n' ...
    '- Drücken Sie die LEERTASTE (SPACE), so schnell wie möglich,\n' ...
    '  sobald der Zähler startet.\n\n' ...
    'Versuchen Sie aufmerksam zu bleiben und jederzeit bereit zu reagieren.\n\n' ...
    'Drücken Sie die LEERTASTE, um das Experiment zu starten.' ...
];                                % Instruktionstext für Versuchsperson

DrawFormattedText(win, instructionText, 'center', 'center', textColor); % Text einblenden
Screen('Flip', win);             % Instruktion wird angezeigt

KbReleaseWait;                   % alte Tastendrücke abwarten
KbWait([], 2);                   % Start bei neuer Taste -> Experiment startet 

%% ----------------- Experiment -----------------

startExpTime = GetSecs;          % Startzeit des Experiments
trial = 0;                       % Trial-Zähler für Ergebnisse 
results = [];                    % Datenstruktur für Ergebnisse 

% Klassifikation der Reaktionszeiten 

sleepAttack = 0;                 % >30s keine Reaktion - Eingeschlafen 
lapse = 0;                       % >5s Reaktionszeit - Aufmerksamkeitsausfall
good = 0;                        % 150–500ms - gute Vigilanz
tooFast = 0;                     % <100ms - Antizipation / Impulsivität
excessiveClick = 0;              % Klick ohne Stimulus

% Parameter für Fixationskreuz
crossSize = 40;                  % Länge der Kreuzarme
crossWidth = 4;                  % Linienstärke

while (GetSecs - startExpTime) < experimentDuration   % 2-Minuten-Schleife
    trial = trial + 1;           % Trial erhöhen
    
    %% Random ISI
    isi = minISI + (maxISI - minISI) * rand;  % Zufälliges Intervall zwischen 2 und 10 Sekunden 
    
    %% Fixationskreuz
    Screen('FillRect', win, bgColor);         % Bildschirm schwarz (Reset-Zustand)

    % horizontale Linie des Fixationskreuzes
    Screen('DrawLine', win, [355 355 0], ...
        xCenter - crossSize, yCenter, ...
        xCenter + crossSize, yCenter, crossWidth);

    % vertikale Linie des Fixationskreuzes
    Screen('DrawLine', win, [355 355 0], ...
        xCenter, yCenter - crossSize, ...
        xCenter, yCenter + crossSize, crossWidth);

    Screen('Flip', win);                      % Fixationskreuz anzeigen
    
    WaitSecs(isi - 1);                        % Wartezeit (Inter-Stimulus-Intervall)

    %% Stimulus (Counter)
    stimOnset = GetSecs;                      % Stimulus-Startzeit
    response = false;                        % Reaktionsmarker - Timer läuft bis Leertaste gedrückt wird
    rt = NaN;                                % Noch keine Reaktionszeit
    
    while ~response                          % Stimulusschleife läuft solange keine Reaktion kommt
        elapsed = (GetSecs - stimOnset) * 1000; % Zeit in ms seit Stimulusbeginn
        counterText = sprintf('%.0f', elapsed); % Hochzählender Timer (visueller Stimulus)
        
        Screen('TextSize', win, 65);          % große Schrift
        DrawFormattedText(win, counterText, 'center', 'center', [455 455 0]);
        Screen('Flip', win);                  % Counter anzeigen
        Screen('TextSize', win, 40);          % Schrift zurücksetzen

        [keyIsDown, ~, keyCode] = KbCheck;    % Tastenerfassung
        if keyIsDown
            if keyCode(stopKey)               % SPACE gedrückt - gültige Reaktion
                rt = GetSecs - stimOnset;     % Reaktionszeit berechnen
                response = true;              % Trial beenden
            elseif keyCode(exitKey)           % ESC -> Abbruch
                sca; ShowCursor; return;      % Screen schließen, Maus anzeigen, Skript beenden 
            else
                excessiveClick = excessiveClick + 1; % falsche Taste (Impulsivität)
            end
        end
        
        if (GetSecs - stimOnset) > 30          % >30s keine Reaktion
            sleepAttack = sleepAttack + 1;    % Sleep Attack (Mikroschlaf)
            response = true;                  % Trial beenden
            rt = NaN;                         % keine RT
        end
    end
   
    %% Klassifikation für die Ergebnisse
    if ~isnan(rt)
        rt_ms = rt*1000;                      % Umrechnung in ms
        if rt_ms < 100
            tooFast = tooFast + 1;            % antizipatorische Reaktion
        elseif rt_ms <= 500
            good = good + 1;                  % gute Vigilanz
        elseif rt_ms > 5000
            lapse = lapse + 1;                % Lapse (Aufmerksamkeitsausfall)
        else
            lapse = lapse + 1;                % verlangsamte Reaktion
        end
    end

    %% Feedback
    if ~isnan(rt)
        feedbackNumber = sprintf('%.0f', rt*1000); % RT in ms anzeigen
    else
        feedbackNumber = '---';               % keine Reaktion
    end

    Screen('TextSize', win, 65);
    DrawFormattedText(win, feedbackNumber, 'center', 'center', [455 455 0]);
    Screen('Flip', win);
    WaitSecs(1);                              % 1 Sekunde Feedback
    Screen('TextSize', win, 40);

    %% Fixationskreuz (Reset-Zustand für nächsten Trial)
    Screen('FillRect', win, bgColor);

    % horizontale Linie
    Screen('DrawLine', win, [455 455 0], ...
        xCenter - crossSize, yCenter, ...
        xCenter + crossSize, yCenter, crossWidth);

    % vertikale Linie
    Screen('DrawLine', win, [455 455 0], ...
        xCenter, yCenter - crossSize, ...
        xCenter, yCenter + crossSize, crossWidth);

    Screen('Flip', win);                      % Fixationskreuz anzeigen

    %% Speichern
    results(trial).trial = trial;             % Trialnummer
    results(trial).isi = isi;                 % ISI
    results(trial).rt = rt;                   % Reaktionszeit
end % Experiment ist vorbei 

%% Ende
endText = [ ...
    'Experiment beendet!\n\n' ...
    'Vielen Dank für Ihre Teilnahme :)!\n\n' ...
];

DrawFormattedText(win, endText, 'center', 'center', textColor);
Screen('Flip', win);
WaitSecs(3);                                 % Abschiedstext 3 Sekunden sichtbar 

sca;                                         % Screen schließen
ShowCursor;                                  % Maus anzeigen

%% Daten speichern
save('PVT_results.mat', 'results', ...
     'sleepAttack', 'lapse', 'good', 'tooFast', 'excessiveClick');

%% Auswertung
RTs = [results.rt];                           % alle RTs
RTs = RTs(~isnan(RTs));                       % NaNs entfernen

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
