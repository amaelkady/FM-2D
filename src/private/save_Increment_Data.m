function [IncrDATA]= save_Increment_Data(NStory,IncrNo, SAcurrent,DATA,IncrDATA,RECORDERS)

% Save SA level in Storage Vector "SA"
IncrDATA.SA (IncrNo) = SAcurrent;

if RECORDERS.SDR==1
    for i=1:NStory
        % Save SDR for Story i in Storage Vector "SDRi"
        IncrDATA.SDR(i,IncrNo) = max(abs (DATA.SDR{i}));

        % Save Residual (Last value) SDR for Story i in Storage Vector "RDRi"
        IncrDATA.RDR(i,IncrNo) =     abs (DATA.SDR{i}(end,1));
    end
end

if RECORDERS.RFA==1
    % Save Maximum Absolute Acceleration for Floor i in Storage Vector "PFAi"
    for i=1:NStory+1
        IncrDATA.PFA(i,IncrNo) = max(abs (DATA.PFA{i}));
    end
end

if RECORDERS.SDR==1
    % Save Maximum SDR for All Stories in Storage Vector "SDR_Max"
    IncrDATA.SDR_Max (IncrNo)=0.0;
    for i=1:NStory
        if IncrDATA.SDR(i,IncrNo) >= IncrDATA.SDR_Max (IncrNo)
        IncrDATA.SDR_Max (IncrNo) = IncrDATA.SDR(i,IncrNo);
        end
    end

    % Save Maximum RDR for All Stories in Storage Vector "RDR_Max"
    IncrDATA.RDR_Max (IncrNo)=0.0;
    for i=1:NStory
        if IncrDATA.RDR(i,IncrNo) >= IncrDATA.RDR_Max (IncrNo)
            IncrDATA.RDR_Max (IncrNo) = IncrDATA.RDR(i,IncrNo);
        end
    end
end
