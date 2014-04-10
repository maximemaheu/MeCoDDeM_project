% MetaCoDDeM project

%%% ------------------------------------------------------------------------------------- %%%
%%% ------------------------------------------------------------------------------------- %%%
%%% -------------------------- SCRIPT OF THE METACODDEM PROJECT ------------------------- %%%
%%% --------------- ("METAcognitive COntrol During DEcision-Making" task) --------------- %%%
%%% ------------------------------------------------------------------------------------- %%%
%%% ------------------------------------------------------------------------------------- %%%

%%% Author: Maxime Maheu
%%% Copyright (C) 2014

%%% * M1 Cogmaster
%%% * Behavior, Emotion and Basal Ganglia team
%%% * Brain and Spine Institute

%%% This program was written to study the computational and behavioral determinants of
%%% metacognitive control during perceptual decision making (with multi-sampling)

%%% ------------------------------------------------------------------------------------- %%% 

%% Clear the workspace, set the diary and the recording file

% Clear the workspace and the command window, then set the diary
clc;
clear all;
diary 'MetaCoDDeM_diary.txt';

DATA.Subject.Number = randi(1000,1,1);
DATA.Subject.Date = datestr(now);
DATA.Subject.Group = HS; % upper(input('Subject group (HS/OCD/DLGG)? ', 's'));
DATA.Subject.Age = NaN; % str2double(input('Subject age? ', 's'));
DATA.Subject.Initials = 'LEEP'; % upper(input('Subject initials? ', 's'));
DATA.Subject.Handedness = 'NaN'; % upper(input('Subject handedness (L/R)? ', 's'));
DATA.Subject.Gender = 'NaN'; % upper(input('Subject gender (M/F)? ', 's'));

DATA.Subject.Design = input('Design (1 for 2AFC and 2 for clockFC)? ');
DATA.Subject.Optimization = input('Design optimization (1 for Yes and 0 for No)? ');

DATA.Subject.Phasis = input('Phasis (123,12,13,23,3)? ');
DATA.Subject.Phasis_list = char(num2str(sort(DATA.Subject.Phasis))) - 48;
if (any(DATA.Subject.Phasis_list == 1) == 0) % If the phasis 1 is skipped then provide psychometric parameters
    DATA.Fit.Psychometric.SigFit(1) = str2double(input('Mu? '));
    DATA.Fit.Psychometric.SigFit(2) = str2double(input('Sigma? '));
end

DATA.Files.Name = ['MetaCoDDeM_' num2str(DATA.Subject.Group) '_' DATA.Subject.Initials '_' num2str(DATA.Subject.Number)];
mkdir(DATA.Files.Name); % Create the subject folder

%% Define task parameters

% Set frequently used colors
colors.black = [0 0 0];
colors.white = [255 255 255];
colors.gray = [128 128 128];
colors.red = [255 0 0];

% Set frequently used keys
keys.up = KbName('UpArrow');
keys.down = KbName('DownArrow');
keys.right = KbName('RightArrow');
keys.left = KbName('LeftArrow');
keys.space = KbName('space');

% Set paradigm parameters 
DATA.Paradigm.Step = 15; % Margin between dots orientation and so between clock ticks  
display.scale = 10;

% Set display parameters
display.screenNum = min(Screen('Screens'));
display.bkColor = colors.black;
display.dist = 60; % cm
display.width = 30; % cm
display.skipChecks = 1; % Avoid Screen's timing checks and verbosity

% Set up dot parameters
dots.nDots = round(1.5*(2*pi*((display.scale/2)^2))); % Calculate the number of dots based on the aperture size
dots.speed = 5;
dots.lifetime = 12;
dots.apertureSize = [display.scale display.scale];
dots.center = [0 0];
dots.color = colors.white;
dots.size = 5;
dots.coherence = 0.7;
dots.duration = .750; % miliseconds

% Set a correponding table between dots angle (classic) and line angle (trigonometric)
if (DATA.Subject.Design == 1) % If it is a 2AFC design
    display.T1.line.table = [90, 270; 0, 180];
elseif (DATA.Subject.Design == 2) % If it is a "clock" design
    display.T1.line.table_a = 0:DATA.Paradigm.Step:359;
    display.T1.line.table_b = 90:-DATA.Paradigm.Step:0;
    display.T1.line.table_c = 360:-DATA.Paradigm.Step:91;
    display.T1.line.table_c(:,1) = [];
    display.T1.line.table = [display.T1.line.table_a;display.T1.line.table_b,display.T1.line.table_c];
end

% Set type I forms parameters
display.T1.tick = display.scale/2;
display.T1.circle.size = display.scale;
display.T1.circle.color = colors.white;
display.T1.line.size = display.scale;
display.T1.line.color = colors.red;
display.T1.triangle.size = display.scale;
display.T1.triangle.color = colors.red;

% Set type II forms parameters
display.T2.tick = display.scale/2;
display.T2.rect1.size = display.scale;
display.T2.rect1.color = colors.white;
display.T2.rect2.color = colors.red;

% Set the parameters for the phasis 1 (calibration phasis)
if (any(DATA.Subject.Phasis_list == 1) == 1) % If the phasis 1 has to be displayed
    DATA.Paradigm.Phasis1.Trials = 100; % Temporary define a certain number of trials (the bayesian optimization will reduce it later)
elseif (any(DATA.Subject.Phasis_list == 1) == 0) % If the phasis 1 do not have to be displayed
    DATA.Paradigm.Phasis1.Trials = 0; % Give 0 to the number of trials
end
if (DATA.Subject.Optimization == 0) % If the bayesian optimization is not activate, then screen the possible coherence levels window
    DATA.Paradigm.Phasis1.Coherences_margin = .1;
    DATA.Paradigm.Phasis1.Coherences_level = 0.1:DATA.Paradigm.Phasis1.Coherences_margin:(1 - DATA.Paradigm.Phasis1.Coherences_margin); % Define the list of coherence levels
    DATA.Paradigm.Phasis1.Coherences_level = transpose(DATA.Paradigm.Phasis1.Coherences_level); % Transform it into a column
    DATA.Paradigm.Phasis1.Coherences_number = 15; % Number of trials per coherence level
    DATA.Paradigm.Phasis1.Coherences = repmat(DATA.Paradigm.Phasis1.Coherences_level, DATA.Paradigm.Phasis1.Coherences_number, 1); % Repeat each coherence level a certain number of time
    DATA.Paradigm.Phasis1.Coherences = DATA.Paradigm.Phasis1.Coherences(randperm(length(DATA.Paradigm.Phasis1.Coherences)), 1); % Randomly shuffle it
    DATA.Paradigm.Phasis1.Trials = size(DATA.Paradigm.Phasis1.Coherences, 1); % The phasis 1 total number of trials is the size of this coherence list
end

% Set the parameters for the phasis 2 (evidence accumulation phasis)
if (any(DATA.Subject.Phasis_list == 2) == 1) % If the phasis 2 has to be displayed
    DATA.Paradigm.Phasis2.Viewing_number = 2; % Define the maximum number of time a RDK will be displayed
    DATA.Paradigm.Phasis2.Facility_levels = [NaN, 0,.05,.10,.15]; % Define the increasing facility indexes
    DATA.Paradigm.Phasis2.Accuracies_number = 1;%0; % Define the number of trials per accuracy level
    DATA.Paradigm.Phasis2.Accuracies_levels = [.10,.425,.75];  % Define the initial wanted performance (before increasing facility index) for one set of increasing difficulty indes
    DATA.Paradigm.Phasis2.Accuracies = repmat(DATA.Paradigm.Phasis2.Accuracies_levels, 1, size(DATA.Paradigm.Phasis2.Facility_levels, 2)*DATA.Paradigm.Phasis2.Accuracies_number); % Define the initial wanted performance (before increasing facility index) for the total number of trials
    DATA.Paradigm.Phasis2.Accuracies = transpose(DATA.Paradigm.Phasis2.Accuracies); % Transform it into a column
    DATA.Paradigm.Phasis2.Accuracies = DATA.Paradigm.Phasis2.Accuracies(randperm(length(DATA.Paradigm.Phasis2.Accuracies)), 1); % Randomly shuffle it
    DATA.Paradigm.Phasis2.Facilities = repmat(DATA.Paradigm.Phasis2.Facility_levels, 1, size(DATA.Paradigm.Phasis2.Accuracies_levels, 2)*DATA.Paradigm.Phasis2.Accuracies_number); % Define all the increasing facility index (for each trial)
    DATA.Paradigm.Phasis2.Facilities = transpose(DATA.Paradigm.Phasis2.Facilities); % Transform it into a column
    DATA.Paradigm.Phasis2.Facilities = DATA.Paradigm.Phasis2.Facilities(randperm(length(DATA.Paradigm.Phasis2.Facilities)), 1); % Randomly shuffle it
    DATA.Paradigm.Phasis2.Performances = [DATA.Paradigm.Phasis2.Accuracies DATA.Paradigm.Phasis2.Facilities (DATA.Paradigm.Phasis2.Accuracies + DATA.Paradigm.Phasis2.Facilities)]; % Make a table of (i) basal performance level, (ii) increasing facility index, and (iii) final performance 
    DATA.Paradigm.Phasis2.Trials = size(DATA.Paradigm.Phasis2.Performances, 1); % Get the total number of trials in the second phasis
elseif (any(DATA.Subject.Phasis_list == 2) == 0) % If the phasis 2 do not have to be displayed
    DATA.Paradigm.Phasis2.Trials = 0;
end

% Set the parameters for the phasis 3 (information seeking phasis)
if (any(DATA.Subject.Phasis_list == 3) == 1) % If the phasis 3 has to be displayed
    DATA.Paradigm.Phasis3.Gains = [100, -200; 80, -80; 70, -70; 60, -60; 50, -50]; % Define the gain matrix
    DATA.Paradigm.Phasis3.Accuracies_number = 1;%0; % Define the number of trials per accuracy level
    DATA.Paradigm.Phasis3.Accuracies_levels = 0.1:((1-((DATA.Paradigm.Phasis2.Viewing_number-1)*max(DATA.Paradigm.Phasis2.Facility_levels)))-0.1)/15:(1-((DATA.Paradigm.Phasis2.Viewing_number-1)*max(DATA.Paradigm.Phasis2.Facility_levels))); % Define the accuracy levels we want to test
    DATA.Paradigm.Phasis3.Accuracies = repmat(DATA.Paradigm.Phasis3.Accuracies_levels, 1, DATA.Paradigm.Phasis3.Accuracies_number); % Define the accuracy levels we want to test for the total number of trials
    DATA.Paradigm.Phasis3.Accuracies = transpose(DATA.Paradigm.Phasis3.Accuracies); % Transform it into a column
    DATA.Paradigm.Phasis3.Performances = DATA.Paradigm.Phasis3.Accuracies(randperm(length(DATA.Paradigm.Phasis3.Accuracies)), 1); % Randomly shuffle it
    DATA.Paradigm.Phasis3.Trials = size(DATA.Paradigm.Phasis3.Performances, 1); % Get the total number of trials in the third phasis
elseif (any(DATA.Subject.Phasis_list == 3) == 0) % If the phasis 3 do not have to be displayed
    DATA.Paradigm.Phasis3.Trials = 0; % Give 0 to the number of trials
end

% Get the total number of trials
DATA.Paradigm.Trials = DATA.Paradigm.Phasis1.Trials + DATA.Paradigm.Phasis2.Trials + DATA.Paradigm.Phasis3.Trials;

% Choose stimulus direction for each trial
for i = 1:1:DATA.Paradigm.Trials % Get random direction for each trial
DATA.Paradigm.Directions(i,1) = display.T1.line.table(1, randi(size(display.T1.line.table, 2))); % Choose an orientation among the possible ones
end

%% Start the trial
try    
    % Open a window, set the display matrix and get the center of the screen
    display = OpenWindow(display);
    display.center = display.resolution/2;
      
    % Set the first phasis
    Phasis_number = DATA.Subject.Phasis_list(1);
    
    for Trial_number = 1:1:DATA.Paradigm.Trials
        % Get the direction of the stimulus
        dots.direction = DATA.Paradigm.Directions(Trial_number, 1);
        
        % If it is the first trial of the phasis 1, display instructions
        if (Trial_number == 1) && ((any(DATA.Subject.Phasis_list == 1) == 1))
            DATA.Paradigm.Phasis1.Instructions = {'Vous allez voir un cercle dans lequel des points vont se d�placer. Apr�s' ...
                                                  'cela, vous aurez a indiquer la direction du mouvement des points en question' ...
                                                  'Attention, tous les points ne bougent pas dans la m�me direction : certains' ...
                                                  'bougent de fa�on totalement al�toire ! Vous devez donc essayez de deviner la' ...
                                                  'direction du mouvement global des points. Certains essais seront tr�s faciles tandis' ...
                                                  'que dans d''autres il sera, au contraire, plus difficile de percevoir le mouvement.' ...
                                                  'Vous devrez rapporter la direction du mouvement que vous avez per�u en d�placant' ...
                                                  '(� l''aide des touches "Fl�che droite" et "Fl�che gauche") puis valider votre r�ponse avec' ...
                                                  'la "Barre d''espace". Les points que vous gagnerez seront index�s sur vos performances.'};
            for i = 1:1:DATA.Paradigm.Phasis1.Instructions
               drawText(display, [0 -8+i], DATA.Paradigm.Phasis1.Instructions{i}, colors.white, display.scale*2); 
            end
            drawText(display, [0 -2], '(Appuyer sur n''importe quelle touche pour commencer)', colors.white, display.scale*2);
            Screen('Flip',display.windowPtr);
            while KbCheck; end
            KbWait;
        end
        
        % If it is the first trial of the phasis 2, display instructions
        if (Trial_number == DATA.Paradigm.Phasis2.Trials + 1) && ((any(DATA.Subject.Phasis_list == 2) == 1))
            DATA.Paradigm.Phasis2.Instructions = {'Cette fois, vous allez voir les m�mes jeux de points que pr�c�demment toutefois, dans' ...
                                                  'certains cas, ils seront suivis d''un autre jeu de point bougeant dans la m�me direction,' ...
                                                  'mais de fa�on plus coh�rente. Ainsi, 2 jeux de points seront parfois pr�sent�s avant' ...
                                                  'que ne vous soit demand� de juger de leur direction. Dans ces cas la direction est' ...
                                                  'bien �videmment la m�me (et ce m�me si le second jeu de point para�t plus facile).' ...
                                                  '� chaque fois que la direction des points changent, vous en serez averti par l''indication' ...
                                                  '"Nouveau stimulus". Apr�s 1 ou 2 jeux de points (ce qui varie au cours de l''exp�rience) il' ...
                                                  'vous sera donc demand� de juger de l''orientation des points en question et de donner' ...
                                                  'votre confiance associ�e � votre d�cision (� l''aide des touches "Fl�che droite" et' ...
                                                  '"Fl�che gauche") puis valider votre r�ponse avec la "Barre d''espace". De la m�me fa�on' ...
                                                  'que pr�c�demment, les points que vous gagnerez seront index�s sur vos performances. Attention' ...
                                                  'cependant, � chaque essai, si la confiance que vous donnez ne refl�te pas vos performances' ...
                                                  'cela retirera des points de votre compteur.'};
            for i = 1:1:DATA.Paradigm.Phasis1.Instructions
               drawText(display, [0 -8+i], DATA.Paradigm.Phasis1.Instructions{i}, colors.white, display.scale*2); 
            end
            drawText(display, [0 -2], '(Appuyer sur n''importe quelle touche pour commencer)', colors.white, display.scale*2);
            Screen('Flip',display.windowPtr);
            while KbCheck; end
            KbWait;
        end
        
        % If it is the first trial of the phasis 3, display instructions
        if (Trial_number == DATA.Paradigm.Phasis1.Trials + DATA.Paradigm.Phasis2.Trials + 1) && ((any(DATA.Subject.Phasis_list == 3) == 1))
            DATA.Paradigm.Phasis3.Instructions = {'Lors de cette derni�re phase, vous devrez choisir, apr�s chaque pr�sentation d''un jeu de points,' ...
                                                  'si vous souhaitez r�pondre maintenant (vous pensez avoir clairement per�u la direction des points)' ...
                                                  'ou si vous pr�f�rez revoir les m�mes points avec une certaine augmentation de la facilit� (c''est' ...
                                                  '� dire de la coh�rence globale du mouvement) de 0% (m�me jeu de points), de 5%, de 10% ou de 15%.' ...
                                                  'Apr�s cela, vous serez interrog�, comme pr�c�demment, sur la direction des points puis sur la' ...
                                                  'confiance que vous attribu� � cette d�cision. Les points que vous gagnerez sont fonction de vos' ...
                                                  'bonnes r�ponses et de votre choix de revoir ou non (avec un certain niveau de facilit� augment�)' ...
                                                  'un jeu de point. Comme pr�c�demment, � chaque essai, si la confiance que vous donnez ne refl�te' ...
                                                  'pas vos performances cela retirera des points de votre compteur.'};
            for i = 1:1:DATA.Paradigm.Phasis3.Instructions
               drawText(display, [0 -8+i], DATA.Paradigm.Phasis1.Instructions{i}, colors.white, display.scale*2); 
            end
            drawText(display, [0 -2], '(Appuyer sur n''importe quelle touche pour commencer)', colors.white, display.scale*2);
            % Load instructions image
            Screen('Flip',display.windowPtr);
            while KbCheck; end
            KbWait;
        end
        
        % Display the information that it is a new stimulus
        if (Phasis_number == 2 || 3)
            drawText(display, [0 2], 'NOUVEAU STIMULUS', colors.white, display.scale*4);
            drawText(display, [0 -2], '(Appuyer sur n''importe quelle touche pour commencer)', colors.white, display.scale*2);
            Screen('Flip',display.windowPtr);
            while KbCheck; end
            KbWait;
        end
        
        %% Display the stimulus

        % For the phasis 2, define dots motion coherence
        if (Phasis_number == 1)
            if (DATA.Subject.Optimization == 1) % If the bayesian optimization is activate
                DATA.Paradigm.Phasis1.Coherences(Trial_number) = OptimDesign([], g_fname, dim, opt, u(1),'parameters', DATA.Subject.Design); % Find the most informative coherence levels
            end
            dots.coherence = DATA.Paradigm.Phasis1.Coherences(Trial_number);
        
        % For the phasis 2, get a coherence level according to a given performance
        elseif (Phasis_number == 2)
            syms Target_coherence
            DATA.Paradigm.Phasis2.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials, 1) ...
                = double(solve((1./(1 + exp(-DATA.Fit.Psychometric.SigFit(1)*(Target_coherence - DATA.Fit.Psychometric.SigFit(2))))) ...
                == DATA.Paradigm.Phasis2.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials, 1)));
            dots.coherence = DATA.Paradigm.Phasis2.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials, 1);
        
        % For the phasis 3, get a coherence level according to a given performance
        elseif (Phasis_number == 3)
            syms Target_coherence
            DATA.Paradigm.Phasis3.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1) ...
                = double(solve((1./(1 + exp(-DATA.Fit.Psychometric.SigFit(1)*(Target_coherence - DATA.Fit.Psychometric.SigFit(2))))) ...
                == DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1)));
            dots.coherence = DATA.Paradigm.Phasis3.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1);
        end
        
        % Draw fixation cross during 2 seconds
        display = drawFixationCross(display);
        waitTill(2);

        % Show the stimulus
        movingDots_MxM(display, dots, dots.duration, DATA.Paradigm.Step, DATA.Subject.Design);

        % Black screen during 100 milisecond
        Screen('FillOval', display.windowPtr, display.bkColor);
        Screen('Flip',display.windowPtr);
        waitTill(.1);

        % If we are in phasis 2 and the we have to display a second sample of stimulus
        if (Phasis_number == 2) && (isnan(DATA.Paradigm.Phasis2.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials, 3)) == 1)
            % For each review
            for (Review = 2:1:DATA.Paradigm.Phasis2.Viewing_number)
                
                % Get again a coherence level according to a given performance
                syms Target_coherence
                DATA.Paradigm.Phasis2.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials, 3) ...
                    = double(solve((1./(1 + exp(-DATA.Fit.Psychometric.SigFit(1)*(Target_coherence - DATA.Fit.Psychometric.SigFit(2))))) ...
                    == DATA.Paradigm.Phasis2.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials, 3)));
                dots.coherence = DATA.Paradigm.Phasis2.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials, 3);
                % Save the difference between the first sample coherence and the second sample one
                DATA.Paradigm.Phasis2.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials, 2) ...
                    = DATA.Paradigm.Phasis2.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials, 3) - DATA.Paradigm.Phasis2.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials, 1);                
                
                % Draw fixation cross during 2 seconds
                display = drawFixationCross(display);
                waitTill(2);

                % Show the stimulus
                movingDots_MxM(display, dots, dots.duration, DATA.Paradigm.Step, DATA.Subject.Design);
                
                % Black screen during 100 milisecond
                Screen('FillOval', display.windowPtr, display.bkColor);
                Screen('Flip',display.windowPtr);
                waitTill(.1);
            end
        end
        
        %% Type II answer (control)
        
        if (Phasis_number == 3)
            % Display choice
            display.T3.index = 1;
            startTime = GetSecs;
            while true
                % Check the keys press and get the RT
                [keyIsDown, timeSecs, keyCode] = KbCheck;
                % Displat proactive information seeking window
                drawT3Info(display, display.T3.index, DATA.Paradigm.Phasis3.Gains);
                
                if keyIsDown
                        
                        % If subject needs additional information, get the easiness increasing level he choose
                        if keyCode(keys.left)
                            display.T3.index = display.T3.index - 1;
                        elseif keyCode(keys.right)
                            display.T3.index = display.T3.index + 1;
                        end
                        % Precautions about the cursor
                        if (display.T3.index < 1)
                            display.T3.index = 1;
                        elseif (display.T3.index > 5)
                            display.T3.index = 5;
                        end
                        waitTill(.1);
                            
                        % Get the information seeking level (easiness increasing)
                        if keyCode(keys.space)
                            if (display.T3.index == 1)
                                DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 2) = -1;
                                DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 3) = DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1);
                            elseif (display.T3.index == 2 || 3 || 4 || 5)
                                DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 2) = DATA.Paradigm.Phasis2.Facility_levels(display.T3.index - 1);
                                DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 3) ...
                                    = DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1) + DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 2);
                            end
                            break;
                        end
                        
                        % Wait during 5 ms to prvent from cursor switchs too quick
                        waitTill(.05);
                end
            end
            
            % Compute control RT (brut and weighted according to the initial position of the cursor)
            DATA.Answers.RT3brut(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1) = timeSecs - startTime;
            if (display.T3.index == 1)
                DATA.Answers.RT3corr(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1) = DATA.Answers.RT3brut(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1);
            elseif (display.T3.index ~= 1)
                DATA.Answers.RT3corr(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1) = DATA.Answers.RT3brut(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1)/abs(1 - display.T3.index);
            end
            
            % If the subject has chose to see a new stimulus sample
            if (any(DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 2) == DATA.Paradigm.Phasis2.Facility_levels) == 1)
               
                % Get a coherence level according to the performance we have to reach given the easiness increasing the subject choose
                DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 3) ...
                    = DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1) + DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 2);
                syms Target_coherence
                DATA.Paradigm.Phasis3.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 3) ...
                    = double(solve((1./(1 + exp(-DATA.Fit.Psychometric.SigFit(1)*(Target_coherence - DATA.Fit.Psychometric.SigFit(2))))) ...
                    == DATA.Paradigm.Phasis3.Performances(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 3)));
                dots.coherence = DATA.Paradigm.Phasis3.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 3);
                % Save the difference between the first sample coherence and the second sample one
                DATA.Paradigm.Phasis3.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 2) ...
                    = DATA.Paradigm.Phasis3.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 3) - DATA.Paradigm.Phasis3.Coherences(Trial_number - DATA.Paradigm.Phasis1.Trials - DATA.Paradigm.Phasis2.Trials, 1);

                % Draw fixation cross during 2 seconds
                display = drawFixationCross(display);
                waitTill(2);

                % Show the stimulus
                movingDots_MxM(display, dots, dots.duration, DATA.Paradigm.Step, DATA.Subject.Design);

                % Black screen during 100 milisecond
                Screen('FillOval', display.windowPtr, display.bkColor);
                Screen('Flip',display.windowPtr);
                waitTill(.1);
            end
        end
        
        %% Type I answer
                    
        % Get the response
        display.T1.line.index = 1; % Column number
        display.T1.line.angle = display.T1.line.table(2, display.T1.line.index); % Correspondant
        DATA.Answers.Initial_Direction(Trial_number, 1) = display.T1.line.angle;
        DATA.Answers.Direction(Trial_number, 1) = NaN;
        startTime = GetSecs;
            
        if (DATA.Subject.Design == 1)
            
            while true
                % Check the keys press
                [keyIsDown, timeSecs, keyCode] = KbCheck;
                % Update the arrow according to key press
                drawT1Binary(display);
                if keyIsDown
            
                    
                    
                    
                    
                    
                    
        
        elseif (DATA.Subject.Design == 2)

            while true
                % Check the keys press
                [keyIsDown, timeSecs, keyCode] = KbCheck;
                % Update the arrow according to key press
                drawT1Clock(display, DATA.Paradigm.Step);
                if keyIsDown

                        if keyCode(keys.down)
                            % Increase angle with 1 step
                            display.T1.line.index = display.T1.line.index + 1;
                            if display.T1.line.index > size(display.T1.line.table, 2)
                                display.T1.line.index = 1;  
                            end
                            display.T1.line.angle = display.T1.line.table(2, display.T1.line.index);  

                        elseif keyCode(keys.up)
                            % Decrease angle with minus 1 step
                            display.T1.line.index = display.T1.line.index - 1;
                            if display.T1.line.index == 0
                                display.T1.line.index = size(display.T1.line.table, 2);
                            end
                            display.T1.line.angle = display.T1.line.table(2, display.T1.line.index);

                        elseif keyCode(keys.space)
                            % Get the subject answer
                            DATA.Answers.Direction(Trial_number, 1) = display.T1.line.table(1, display.T1.line.index);
                            break;
                        end

                        waitTill(.05);
                end
            end

            % Compute perceptual RT (brut and weighted according to the initial direction)
            DATA.Answers.RT1brut(Trial_number, 1) = timeSecs - startTime;
            if DATA.Answers.Initial_Direction(Trial_number, 1) ~= DATA.Answers.Direction(Trial_number, 1)
                DATA.Answers.RT1corr(Trial_number, 1) = DATA.Answers.RT1brut(Trial_number, 1)/abs(DATA.Answers.Initial_Direction(Trial_number, 1) - DATA.Answers.Direction(Trial_number, 1));
            elseif DATA.Answers.Initial_Direction(Trial_number, 1) == DATA.Answers.Direction(Trial_number, 1)
                DATA.Answers.RT1corr(Trial_number, 1) = DATA.Answers.RT1brut(Trial_number, 1);
            end
        end
        
        
        
        
        
        
        
      
        
        % For 2AFC design, compute perceptual performance and classify the answer according to signal detection theory
        if (DATA.Subject.Design == 1)
            if (DATA.Paradigm.Directions(Trial_number, 1) == 270) && (DATA.Answers.Direction(Trial_number, 1) == 270) % If it was a leftward moving stimulus and the subject give a correct answer (left)
                DATA.Answers.Correction(Trial_number, 1) = 1; % Correct answer
                DATA.Answers.Label(Trial_number, 1) = 1 % Hit
            end
            if (DATA.Paradigm.Directions(Trial_number, 1) == 270) && (DATA.Answers.Direction(Trial_number, 1) == 90) % If it was a leftward moving stimulus and the subject give a wrong answer (right)
                DATA.Answers.Correction(Trial_number, 1) = 0; % Wrong answer
                DATA.Answers.Label(Trial_number, 1) = 2 % False alarm
            end
            if (DATA.Paradigm.Directions(Trial_number, 1) == 90) && (DATA.Answers.Direction(Trial_number, 1) == 270) % If it was a rightward moving stimulus and the subject give a wrong answer (left)
                DATA.Answers.Correction(Trial_number, 1) = 0; % Wrong answer
                DATA.Answers.Label(Trial_number, 1) = 3 % Miss
            end
            if (DATA.Paradigm.Directions(Trial_number, 1) == 90) && (DATA.Answers.Direction(Trial_number, 1) == 90) % If it was a rightward moving stimulus and the subject give a correct answer (right)
                DATA.Answers.Correction(Trial_number, 1) = 1; % Correct answer
                DATA.Answers.Label(Trial_number, 1) = 4 % Correct rejection
            end
        
        % For "clock" design, compute perceptual performance
        if (DATA.Subject.Design == 2)
            if DATA.Paradigm.Directions(Trial_number, 1) == DATA.Answers.Direction(Trial_number, 1)
                DATA.Answers.Correction(Trial_number, 1) = 1;
            elseif DATA.Paradigm.Directions(Trial_number, 1) ~= DATA.Answers.Direction(Trial_number, 1)
                DATA.Answers.Correction(Trial_number, 1) = 0;
            end

        % Get the amount of gain
        if (Phasis_number == 1)
            DATA.Answers.Gains(Trial_number, 1) = DATA.Answers.Correction(Trial_number, 1);
        end
        if (Phasis_number == 2)
            DATA.Answers.Gains(Trial_number, 1) = DATA.Answers.Correction(Trial_number, 1);
        end
        if (Phasis_number == 3)
            DATA.Answers.Gains(Trial_number, 1) = DATA.Paradigm.Phasis3.Gains(display.T3.index, DATA.Answers.Correction(Trial_number, 1) + 1);
        end
        
        % Black screen during 100 milisecond
        Screen('FillOval', display.windowPtr, display.bkColor);
        Screen('Flip',display.windowPtr);
        waitTill(.1);

        %% Type II answer (monitoring)

        display.T2.rect2.size = 0;
        DATA.Answers.Initial_Confidence(Trial_number, 1) = round(((display.T2.rect2.size + display.T2.rect1.size) / (2 * display.T2.rect1.size)) * 100);
        DATA.Answers.Confidence(Trial_number, 1) = NaN;
        startTime = GetSecs;
        
        while true
            % Check the keys press and get the RT
            [keyIsDown, timeSecs, keyCode] = KbCheck;
            
            % Display instructions
            drawText(display, [0, (display.T2.rect1.size - display.T2.rect1.size/4)], 'Veuillez donner votre niveau de confiance dans votre r�ponse', [255 255 255], display.scale*4);
            drawText(display, [0, (display.T2.rect1.size - display.T2.rect1.size/4)*-1], '(Appuyer sur ESPACE pour valider votre choix)', [255 255 255], display.scale*2);
            
            % Update the red rectangle according to key press
            drawT2Rect(display);
            if keyIsDown

                    if keyCode(keys.right)
                        % Increase confidence score with +1%
                        display.T2.rect2.size = display.T2.rect2.size + ((2*display.T2.rect1.size)/100);
                        if display.T2.rect2.size > display.T2.rect1.size
                        display.T2.rect2.size = display.T2.rect1.size;
                        end

                    elseif keyCode(keys.left)
                        % Decrease confidence score with -1%
                        display.T2.rect2.size = display.T2.rect2.size - ((2*display.T2.rect1.size)/100);
                        if display.T2.rect2.size < display.T2.rect1.size*-1
                        display.T2.rect2.size = display.T2.rect1.size*-1;
                        end

                    elseif keyCode(keys.space)
                        % Get the metacognitive monitoring reaction time
                        DATA.Answers.RT2brut(Trial_number, 1) = timeSecs - startTime;
                        DATA.Answers.RT2corr(Trial_number, 1) = DATA.Answers.RT2brut(Trial_number, 1)/abs(DATA.Answers.Initial_Confidence(Trial_number, 1) - DATA.Answers.Confidence(Trial_number, 1));
                        % Get the confidence score on a 100 scale
                        DATA.Answers.Confidence(Trial_number, 1) = round(((display.T2.rect2.size + display.T2.rect1.size) / (2 * display.T2.rect1.size)) * 100);
                        waitTill(.1);
                        break;
                    end
            end
        end
        
        % Compute monitoring RT (brut and weighted according to the initial confidence)
        DATA.Answers.RT2brut(Trial_number, 1) = timeSecs - startTime;
        if DATA.Answers.Initial_Confidence(Trial_number, 1) ~= DATA.Answers.Confidence(Trial_number, 1)
            DATA.Answers.RT2corr(Trial_number, 1) = DATA.Answers.RT2brut(Trial_number, 1)/abs(DATA.Answers.Initial_Confidence(Trial_number, 1) - DATA.Answers.Confidence(Trial_number, 1));
        elseif DATA.Answers.Initial_Confidence(Trial_number, 1) == DATA.Answers.Confidence(Trial_number, 1)
            DATA.Answers.RT2corr(Trial_number, 1) = DATA.Answers.RT2brut(Trial_number, 1);
        end
        
        % Display a break screen
        if ((Trial_number == (DATA.Paradigm.Phasis1.Trials/2)) || (Trial_number == (DATA.Paradigm.Phasis2.Trials/2)) || (Trial_number == (DATA.Paradigm.Phasis3.Trials/2)))
            drawText(display, [0 2], 'Fa�tes une pause d''une ou deux minutes', colors.white, display.scale*4);
            drawText(display, [0 -2], '(Appuyer sur n''importe quelle touche pour continuer)', colors.white, display.scale*2);
            Screen('Flip',display.windowPtr);
            while KbCheck; end
            KbWait;
        end

        %% Psychometric fit
        if Phasis_number == 1
            if Trial_number == DATA.Paradigm.Phasis1.Trials
                
                % Make the subject waits while fitting the psychometric curve
                drawText(display, [0 0], 'Veuillez patienter quelques secondes', colors.white, display.scale*4);
                
                % Make a coherence x performance table
                DATA.Fit.Psychometric.Coherence = unique(DATA.Paradigm.Phasis1.Coherences);
                DATA.Fit.Psychometric.Performance = grpstats(DATA.Answers.Correction, DATA.Paradigm.Phasis1.Coherences);
                % Insert born values (chance and 100% accuracy)
                DATA.Fit.Psychometric.Chance = 1/(360/DATA.Paradigm.Step);
                DATA.Fit.Psychometric.Coherence = [0; DATA.Fit.Psychometric.Coherence];
                DATA.Fit.Psychometric.Performance = [DATA.Fit.Psychometric.Chance; DATA.Fit.Psychometric.Performance];
                DATA.Fit.Psychometric.Coherence = [DATA.Fit.Psychometric.Coherence; 1];
                DATA.Fit.Psychometric.Performance = [DATA.Fit.Psychometric.Performance; 1];
                
                % Set the psychometric function
                DATA.Fit.Psychometric.SigFunc = @(F, x)(1./(1 + exp(-F(1)*(x-F(2)))));
                % Fit it
                DATA.Fit.Psychometric.SigFit = nlinfit(DATA.Fit.Psychometric.Coherence, DATA.Fit.Psychometric.Performance, DATA.Fit.Psychometric.SigFunc, [1 1]);
                
                % A SUPPRIMER
                DATA.Fit.Psychometric.SigFit(1) = 10;
                DATA.Fit.Psychometric.SigFit(2) = .50;
                
                % Draw the figure
                fig = figure(1);
                % Plot empirical points
                plot(DATA.Fit.Psychometric.Coherence, DATA.Fit.Psychometric.Performance, '*');
                hold on
                % Plot fit
                plot(DATA.Fit.Psychometric.Coherence, DATA.Fit.Psychometric.SigFunc(DATA.Fit.Psychometric.SigFit, DATA.Fit.Psychometric.Coherence), 'g');
                hold on
                % Draw theoretic curve based on fit
                DATA.Fit.Psychometric.Theoretical_x = 0:0.001:1;
                DATA.Fit.Psychometric.Theoretical_y = sigmf(DATA.Fit.Psychometric.Theoretical_x, DATA.Fit.Psychometric.SigFit);
                plot(DATA.Fit.Psychometric.Theoretical_x, DATA.Fit.Psychometric.Theoretical_y, 'r-.');
                hold on
                % Draw chance level
                plot(DATA.Fit.Psychometric.Theoretical_x, DATA.Fit.Psychometric.Chance, 'c');
                % Set legend, axis and labels
                legend('Human data', 'Fit', 'Model data', 'Chance', 'location', 'northwest');
                axis([0 1 0 1]);
                xlabel('Motion coherence'); 
                ylabel('Perceptual performance');
                
                % Get a coherence level according to a given performance
                syms Target_coherence
                DATA.Fit.Psychometric.C50 = double(solve((1./(1 + exp(-DATA.Fit.Psychometric.SigFit(1)*(Target_coherence - DATA.Fit.Psychometric.SigFit(2))))) == .5));
            end
        end
        
        % Switch to phasis 2 when all the phasis 1 trials have been displayed
        if Trial_number == DATA.Paradigm.Phasis1.Trials
            Phasis_number = 2;
        end
        
        % Switch to phasis 3 when all the phasis 2 trials have been displayed
        if Trial_number == DATA.Paradigm.Phasis1.Trials + DATA.Paradigm.Phasis2.Trials
            Phasis_number = 3;
        end
    end
     
    % Close all windows
    Screen('CloseAll');

% In case of error
catch error_message
Screen('CloseAll');
rethrow(error_message);
end

%% Get the compensation payment
if (sum(DATA.Answers.Gains)/1000) <= 0
    DATA.Answers.Money = 5;
elseif (sum(DATA.Answers.Gains)/1000) > 0
    DATA.Answers.Money = 5 + (sum(DATA.Answers.Gains)/1000);
end

%% Save a table for further import in DMAT

% For phasis 1
DATA.Paradigm.Phasis1.Conditions = sort(unique(DATA.Paradigm.Phasis1.Coherences)); % Make a list of all possible coherence levels
for i = 1:1:size(DATA.Paradigm.Phasis1.Conditions)
    DATA.Paradigm.Phasis1.Conditions(i,2) = i; % Attribute a condition to each of these coherence levels
end

for i = 1:1:size(DATA.Paradigm.Phasis1.Coherences,1)
    DATA.Fit.DMAT.Phasis1.Input(i,1) = find(DATA.Paradigm.Phasis1.Conditions(:,1) == DATA.Paradigm.Phasis1.Coherences(i)); % For each phasis 1 trial, get its associated condition based on its coherence level
end
DATA.Fit.DMAT.Phasis1.Input(:,2) = DATA.Answers.Correction(1:DATA.Paradigm.Phasis1.Trials); % For each phasis 1 trial, get its associated correction
DATA.Fit.DMAT.Phasis1.Input(:,3) = DATA.Answers.RT1corr(1:DATA.Paradigm.Phasis1.Trials); % For each phasis 1 trial, get its associated RT
DMAT1 = DATA.Fit.DMAT.Phasis1.Input;

% For phasis 2
DATA.Paradigm.Phasis2.Conditions(:,1) = repmat(unique(DATA.Paradigm.Phasis2.Performances(:,1)), size(DATA.Paradigm.Phasis2.Facility_levels, 2), 1); % Make a list of all possible performance levels ...
DATA.Paradigm.Phasis2.Conditions(:,2) = sort(repmat(transpose(DATA.Paradigm.Phasis2.Facility_levels), size(DATA.Paradigm.Phasis2.Accuracies_levels, 2), 1)); % ... and all possible increasing facility indexes
for i = 1:1:size(DATA.Paradigm.Phasis2.Conditions, 1)
    DATA.Paradigm.Phasis2.Conditions(i,3) = i; % Attribute a condition to each of these performance levels
end
for i = 1:1:size(DATA.Paradigm.Phasis2.Performances,1)
    DATA.Fit.DMAT.Phasis2.Input(i,1) = intersect(find(DATA.Paradigm.Phasis2.Conditions(:,1) == DATA.Paradigm.Phasis2.Performances(i,1)), find(DATA.Paradigm.Phasis2.Conditions(:,2) == DATA.Paradigm.Phasis2.Performances(i,2))); %
end
DATA.Fit.DMAT.Phasis2.Input(:,2) = DATA.Answers.Correction(DATA.Paradigm.Phasis1.Trials + 1 : DATA.Paradigm.Phasis1.Trials + DATA.Paradigm.Phasis2.Trials); % For each phasis 2 trial, get its associated correction
DATA.Fit.DMAT.Phasis2.Input(:,3) = DATA.Answers.RT1corr(DATA.Paradigm.Phasis1.Trials + 1 : DATA.Paradigm.Phasis1.Trials + DATA.Paradigm.Phasis2.Trials); % For each phasis 2 trial, get its associated RT
DMAT2 = DATA.Fit.DMAT.Phasis2.Input;

% For phasis 3
DATA.Paradigm.Phasis3.Conditions(:,1) = repmat(unique(DATA.Paradigm.Phasis3.Performances(:,1)), size(horzcat(DATA.Paradigm.Phasis2.Facility_levels, NaN), 2), 1); % Make a list of all possible performance levels ...
DATA.Paradigm.Phasis3.Conditions(:,2) = sort(repmat(transpose(horzcat(DATA.Paradigm.Phasis2.Facility_levels, -1)), size(DATA.Paradigm.Phasis3.Accuracies_levels, 2), 1)); % ... and all possible increasing facility indexes (including the case where there is no information seeking)
for i = 1:1:size(DATA.Paradigm.Phasis3.Conditions, 1)
    DATA.Paradigm.Phasis3.Conditions(i,3) = i; % Attribute a condition to each of these combinations
end
for i = 1:1:size(DATA.Paradigm.Phasis3.Performances, 1)
    DATA.Fit.DMAT.Phasis3.Input(i,1) = intersect(find(DATA.Paradigm.Phasis3.Conditions(:,1) == DATA.Paradigm.Phasis3.Performances(i,1)), find(DATA.Paradigm.Phasis3.Conditions(:,2) == DATA.Paradigm.Phasis3.Performances(i,2)));
end
DATA.Fit.DMAT.Phasis3.Input(:,2) = DATA.Answers.Correction(DATA.Paradigm.Phasis1.Trials + DATA.Paradigm.Phasis2.Trials + 1 : DATA.Paradigm.Trials);
DATA.Fit.DMAT.Phasis3.Input(:,3) = DATA.Answers.RT1corr(DATA.Paradigm.Phasis1.Trials + DATA.Paradigm.Phasis2.Trials + 1 : DATA.Paradigm.Trials);
DMAT3 = DATA.Fit.DMAT.Phasis3.Input;

%% Save a table for further import in R

% Define the table
Headers = {'Number', 'Date', 'Group', 'Age', 'Gender', ... % Subject information
    'Trials', 'Phasis', 'A_perf', 'A_coh', 'Inc_perf', 'Inc_coh', 'B_perf', 'B_coh', 'Direction', ... % Independant variables
    'Answer', 'Accuracy', 'RT1_brut', 'RT1_corr', 'Confidence', 'RT2_brut', 'RT2_corr', 'Seek', 'RT3_brut', 'RT3_corr', 'Gains'}; % Dependant variables
Rtable = cell(DATA.Paradigm.Trials+1,length(Headers));

Rtable(1,:) = Headers;
for i = 1:1:DATA.Paradigm.Trials
    Rtable{i+1,1} = strcat('#', num2str(DATA.Subject.Number)); % Number
    Rtable{i+1,2} = DATA.Subject.Date; % Date
    Rtable{i+1,3} = DATA.Subject.Group; % Group
    Rtable{i+1,4} = DATA.Subject.Age; % Age
    Rtable{i+1,5} = DATA.Subject.Gender; % Gender
    Rtable{i+1,6} = i; % Trials
    Rtable{i+1,14} = DATA.Paradigm.Directions(i); % Directions
    Rtable{i+1,15} = DATA.Answers.Direction(i); % Type I answers
    Rtable{i+1,16} = DATA.Answers.Correction(i); % Correction
    Rtable{i+1,17} = DATA.Answers.RT1brut(i); % Type I RT (brut)
    Rtable{i+1,18} = DATA.Answers.RT1corr(i); % Type I RT (corrected)
    Rtable{i+1,19} = DATA.Answers.Confidence(i); % Type II (monitoring) answers
    Rtable{i+1,20} = DATA.Answers.RT2brut(i); % Type II (monitoring) RT (brut)
    Rtable{i+1,21} = DATA.Answers.RT2corr(i); % Type II (monitoring) RT (corrected)
    Rtable{i+1,25} = DATA.Answers.Gains(i); % Gains
end
% For phasis 1
for i = 1:1:DATA.Paradigm.Phasis1.Trials
    Rtable{i+1,7} = 1; % Phasis
    Rtable{i+1,8} = NaN; % Performances 'A'
    Rtable{i+1,9} = DATA.Paradigm.Phasis1.Coherences(i); % Coherences 'A'
    Rtable{i+1,10} = NaN; % Increasing performances
    Rtable{i+1,11} = NaN; % Increasing coherences
    Rtable{i+1,12} = NaN; % Performances 'B'
    Rtable{i+1,13} = NaN; % Coherences 'B'
    Rtable{i+1,22} = NaN; % Type II (control) answers
    Rtable{i+1,23} = NaN; % Type II (control) RT (brut)
    Rtable{i+1,24} = NaN; % Type II (control) RT (corrected)
end
% For phasis 2
for i = 1:1:DATA.Paradigm.Phasis2.Trials
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,7} = 2; % Phasis
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,8} = DATA.Paradigm.Phasis2.Performances(i,1); % Performances 'A'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,9} = DATA.Paradigm.Phasis2.Coherences(i,1); % Coherences 'A'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,10} = DATA.Paradigm.Phasis2.Performances(i,2); % Increasing performances
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,11} = DATA.Paradigm.Phasis2.Coherences(i,2); % Increasing coherences
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,12} = DATA.Paradigm.Phasis2.Performances(i,3); % Performances 'B'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,13} = DATA.Paradigm.Phasis2.Coherences(i,3); % Coherences 'B'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,22} = NaN; % Type II (control) answers
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,23} = NaN; % Type II (control) RT (brut)
    Rtable{i+DATA.Paradigm.Phasis1.Trials+1,24} = NaN; % Type II (control) RT (corrected)
end
% For phasis 3
for i = 1:1:DATA.Paradigm.Phasis3.Trials
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,7} = 3; % Phasis
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,8} = DATA.Paradigm.Phasis3.Performances(i,1); % Performances 'A'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,9} = DATA.Paradigm.Phasis3.Coherences(i,1); % Coherences 'A'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,10} = NaN; % Increasing performances
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,11} = DATA.Paradigm.Phasis3.Coherences(i,2); % Increasing coherences
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,12} = DATA.Paradigm.Phasis3.Performances(i,3); % Performances 'B'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,13} = DATA.Paradigm.Phasis3.Coherences(i,3); % Coherences 'B'
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,22} = DATA.Paradigm.Phasis3.Performances(i,2); % Type II (control) answers
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,23} = DATA.Answers.RT3brut(i,1); % Type II (control) RT (brut)
    Rtable{i+DATA.Paradigm.Phasis1.Trials+DATA.Paradigm.Phasis2.Trials+1,24} = DATA.Answers.RT3corr(i,1); % Type II (control) RT (corrected)
end

%% Save files

% Go to the subject directory
cd(DATA.Files.Name);

% Save data for further import in DMAT
save(strcat(DATA.Files.Name, '_DMAT1'), 'DMAT1');
save(strcat(DATA.Files.Name, '_DMAT2'), 'DMAT2');
save(strcat(DATA.Files.Name, '_DMAT3'), 'DMAT3');

% Save data
save(DATA.Files.Name, 'DATA', 'display', 'dots');

% Save R table
cell2csv(strcat(DATA.Files.Name, '.csv'), Rtable);

% Save fit graph
saveas(fig, DATA.Files.Name, 'fig');

%% DMAT fit

% For phasis 1
DATA.Fit.DMAT.Phasis1.Input.Output = multiestv4(DATA.Fit.DMAT.Phasis1.Input.Input);
DATA.Fit.DMAT.Phasis1.Input.Parameters = namepars(DATA.Fit.DMAT.Phasis1.Input.Output);

% For phasis 2
DATA.Fit.DMAT.Phasis2.Input.Output = multiestv4(DATA.Fit.DMAT.Phasis2.Input.Input);
DATA.Fit.DMAT.Phasis2.Input.Parameters = namepars(DATA.Fit.DMAT.Phasis2.Input.Output);

% For phasis 3
DATA.Fit.DMAT.Phasis3.Input.Output = multiestv4(DATA.Fit.DMAT.Phasis3.Input.Input);
DATA.Fit.DMAT.Phasis3.Input.Parameters = namepars(DATA.Fit.DMAT.Phasis3.Input.Output);

%% Close all

% Return to the task directory
cd ..

% Clear some useless variables
clear Phasis_number and Trial_number and Target_coherence and ans and i and fig and Review and Headers;

% Close the diary
diary off;