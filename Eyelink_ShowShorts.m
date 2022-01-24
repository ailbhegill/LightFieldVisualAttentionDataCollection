function Eyelink_ShowShorts(subjNo)
%This function displays five light field renderings (the full 10 seconds long version) of 21 light fields in
%randomised order without any eyetracking

%This function takes as input an int 'subjNo' (the participant no.)

%The code below is modified code based on Psychtoolbox-3 EyelinkExample.m demo (free and open-source software) which can be found at:
%https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/master/Psychtoolbox/PsychHardware/EyelinkToolbox/EyelinkDemos/EyelinkShortDemos/EyelinkExample.m

% -- Start in NoJVM mode if there's video
if usejava('jvm') %&& strcmp(tParams.StimuliType,'video')
    cmd = sprintf(['"diary cmd-output.txt;',...
                  'try,%s(%s);catch e,',...
                  'msg=getReport(e,''extended'',''hyperlinks'',''on''); disp(msg); end;',...
                  'diary off; exit;"'], mfilename, num2str(subjNo));                
    system(['matlab -nosplash -minimize -nojvm -r ' cmd]);
    type('cmd-output.txt');
    evalc('delete(''cmd-output.txt'')'); 
    commandwindow
    return
end

% Short MATLAB example program that uses the Eyelink and Psychophysics
% Toolboxes to create a real-time gaze-dependent display.
% This is the example as shown in the EyelinkToolbox article in BRMIC
% Cornelissen, Peters and Palmer 2002), but updated to use new routines
% and functionality.
%
% History
% ~2006     fwc    created it, to use updated functions
% 15-06-10  fwc    updated to enable eye image display
% 17-06-10  fwc    made colour of the gaze dot change, just for fun
PsychDefaultSetup(1);
Screen('Preference','SkipSyncTests', 1);

% if ~exist('useEL','var')
%     useEL = false;
% else
%     if ~(isnumeric(useEL) || islogical(useEL))
%         error('useEL should be numeric or logical!');
%     end
%     if useEL ~= 0
%         useEL = true;
%     elseif useEL == 0
%         useEL = false;
%     end
% end
useEL = 0;

try
    fprintf('EyelinkToolbox Example\n\n\t');
    dummymode=0;       % set to 1 to initialize in dummymode (rather pointless for this example though)
    
    % STEP 1
    % Open a graphics window on the main screen
    % using the PsychToolbox's Screen function.
    screenNumber=max(Screen('Screens'));
    window=Screen('OpenWindow', screenNumber);
     
    % STEP 2
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    el=EyelinkInitDefaultsDummy(window,0);

    % Disable key output to Matlab window:
    ListenChar(2);

    Screen('FillRect', el.window, el.backgroundcolour);
    Screen('TextFont', el.window, el.msgfont);
    Screen('TextSize', el.window, el.msgfontsize);
    [width, height]=Screen('WindowSize', el.window);
    message='Press space to stop.';
    Screen('DrawText', el.window, message, 200, height-el.msgfontsize-20, el.msgfontcolour);
    Screen('Flip',  el.window, [], 1);
    
    %--------------------------
    %--------------------------
    
    % STEP 6.5
    % Find the user's stimuli
    fid = fopen(['stimuliLists_Short\randomAllInFocusList_participant' num2str(subjNo, '%02d') '.txt'],'r');
    textReadStr = textscan(fid,'%s');
    stimList = textReadStr{1};
    fclose(fid);
    
    % Show videos and record eye movements
    for indVid = 1:length(stimList)
        moviename = [pwd '\videos_Short\' stimList{indVid}];
        [moviePtr movieduration fps imgw imgh] = Screen('OpenMovie', window, moviename);
        fprintf('Movie: %s  : %f seconds duration, %f fps, w x h = %i x %i...\n', moviename, movieduration, fps, imgw, imgh);
        
        % Tag the event
        if useEL
            Eyelink('Message', ['begin_' stimList{indVid}]);
        end
        
        % Play the movie
        changingTime=0;
        Screen('PlayMovie', moviePtr, 1, 0, 0);
        
        while true
            % Wait for next movie frame, retrieve texture handle to it
            vidTexture = Screen('GetMovieImage', window, moviePtr);

            % Valid texture returned? A negative value means end of movie reached:
            if (vidTexture<=0)
                % We're done, break out of loop:
                break;
            end

            % Draw the new texture immediately to screen:
            Screen('DrawTexture', window, vidTexture, [], [], 0);

            % Update display:
            Screen('Flip', window);

%             % check if a key is pressed
%             % only keys specified in activeKeys are considered valid
%             [ keyIsDown, keyTime, keyCode ] = KbCheck;
%             if(keyIsDown)
%                 % store code for key pressed and reaction time
%                 rsp.RT      = keyTime - tStart;
%                 rsp.keyCode = keyCode;
%                 rsp.keyName = KbName(rsp.keyCode);
%                 break; 
%             end

            % Release texture:
            Screen('Close', vidTexture);
        end
        
        % Done. Stop playback:
        Screen('PlayMovie', moviePtr, 0);

        % Close movie object:
        Screen('CloseMovie', moviePtr);
        
%         % ---- Wait for 2 seconds
%         imageTexture = Screen('MakeTexture', window, uint8(ones(512,512,3)*127));
%         % Draw the image to the screen, unless otherwise specified PTB will 
%         % draw the texture full size in the center of the screen. We first draw 
%         % the image in its correct orientation.
%         Screen('DrawTexture', window, imageTexture, [], [], 0);

        % Flip to the screen
        Screen('Flip', window);
        % Tag the event
        if useEL
            Eyelink('Message', ['end_' stimList{indVid}]);
            Eyelink('Message', 'WAIT_HERE');
        end
        startTime = GetSecs;
        nowTime = GetSecs;
        
        while (nowTime - startTime) < 0.2
            nowTime = GetSecs;
        end
    end
    
    cleanup(useEL);
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    cleanup(useEL);
    psychrethrow(psychlasterror);
end %try..catch.

end % Function end

% Cleanup routine:
function cleanup(useEL)
    % Shutdown Eyelink:
    if useEL
        Eyelink('Shutdown');
    end

    % Close window:
    sca;

    % Restore keyboard output to Matlab:
    ListenChar(0);
end