function [IncrDATA]= Save_Increment_Data(NStory,IncrNo, SAcurrent,DATA,IncrDATA,Recorders)

% Save SA level in Storage Vector "SA"
IncrDATA.SA (IncrNo) = SAcurrent;

if Recorders.SDR==1
    % Save SDR for Story i in Storage Vector "SDRi"
    for i=1:NStory
        evalc(strcat('IncrDATA.SDR',num2str(i),'(IncrNo) = max(abs (DATA.SDR', num2str(i), '(:,1)))'));
    end

    % Save Residual (Last value) SDR for Story i in Storage Vector "RDRi"
    for i=1:NStory
        evalc(strcat('IncrDATA.RDR',num2str(i),'(IncrNo) =     abs (DATA.SDR', num2str(i), '(end,1))'));
    end
end

if Recorders.RFA==1
    % Save Maximum Absolute Acceleration for Floor i in Storage Vector "PFAi"
    for i=1:NStory+1
        evalc(strcat('IncrDATA.PFA',num2str(i),'(IncrNo) = max(abs (DATA.PFA' , num2str(i), '))'));
    end
end

if Recorders.SDR==1
    % Save Maximum SDR for All Stories in Storage Vector "SDR_Max"
    IncrDATA.SDR_Max (IncrNo)=0.0;
    for i=1:NStory
        x = eval(['IncrDATA.SDR' num2str(i) '(IncrNo)']);
        if x >= IncrDATA.SDR_Max (IncrNo)
        IncrDATA.SDR_Max (IncrNo) = x;
        end
    end

    % Save Maximum RDR for All Stories in Storage Vector "RDR_Max"
    IncrDATA.RDR_Max (IncrNo)=0.0;
    for i=1:NStory
        x = eval(['IncrDATA.RDR' num2str(i) '(IncrNo)']);
        if x >= IncrDATA.RDR_Max (IncrNo)
        IncrDATA.RDR_Max (IncrNo) = x;
        end
    end
end
