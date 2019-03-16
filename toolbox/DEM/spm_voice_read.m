function spm_voice_read(wfile)
% Reads and translates a sound file 
% FORMAT spm_voice_read(wfile)
%
% wfile  - .wav file or audio object

% requires the following in the global variable VOX:
% LEX    - lexical structure array
% PRO    - prodidy structure array
% WHO    - speaker structure array
%
%  This routine takes a sound file has an input and infers the lexical
%  content, prosody and speaker. In then particulates the phrase or
%  sequence of words
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_voice_read.m 7545 2019-03-16 11:57:13Z karl $

% get timeseries from audio recorder(or from a path
%--------------------------------------------------------------------------


%% get data features from a wav file or audiorecorder object
%==========================================================================
if isa(wfile,'audiorecorder')
    stop(wfile);
    record(wfile,8);

end

%% run through sound file and evaluate likelihoods
%==========================================================================
global VOX
VOX.I0 = 1;

str   = {};
for s = 1:16
    
    % find next word
    %----------------------------------------------------------------------
    L   = spm_voice_get_word(wfile);
        
    % break if EOF
    %----------------------------------------------------------------------
    if isempty(L), break, end
    
    % identify the most likely word and prosody
    %----------------------------------------------------------------------
    [d,w]  = max(L{1});                        % most likely word
    [d,p]  = max(L{2});                        % most likely prosody
    [d,r]  = max(L{3});                        % most likely identity
    W(1,s) = w(:);                             % lexical class
    P(:,s) = p(:);                             % prosody classes
    R(:,s) = r(:);                             % speaker classes
    
    % string
    %----------------------------------------------------------------------
    str{s} = VOX.LEX(w,1).word                 % lexical string
    
end

% stop recording audiorecorder object
%--------------------------------------------------------------------------
if isa(wfile,'audiorecorder')
    stop(wfile);
end

%% articulate: with lexical content and prosody
%--------------------------------------------------------------------------
spm_voice_speak(W,P,R);


