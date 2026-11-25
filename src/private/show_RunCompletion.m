function show_RunCompletion(app, elapsedSeconds)
% Keep a timed-out pushover usable without presenting it as a completed run.
if isappdata(app.figure1,'FM2D_StaticRunOutcome')
    outcome=getappdata(app.figure1,'FM2D_StaticRunOutcome');
    if outcome.State=="TIMEOUT"
        app.ProgressText.FontColor=[1 .65 0];
        if outcome.HasResults
            app.VisualizeButton.Enable='on';
            app.ProgressText.Text='Analysis terminated due to runtime limit; results available.';
        else
            app.VisualizeButton.Enable='off';
            app.ProgressText.Text='Analysis terminated due to runtime limit; no pushover steps completed.';
        end
        return;
    end
end
app.ProgressText.FontColor=[0 1 0];
app.ProgressText.Text=['DONE! Analysis time is ',num2str(round(elapsedSeconds/6)/10),' minutes'];
end
