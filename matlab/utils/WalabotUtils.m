classdef WalabotUtils
    % Walabot için ortak yardımcı fonksiyonlar
    
    methods (Static)
        
        % Bağlantı kontrolü
        function isConnected = checkConnection(lamp)
            isConnected = strcmp(lamp.Color, 'green');
        end
        
        % Kalibrasyon durumu kontrolü
        function isCalibrating = checkCalibration(api)
            try
                api.Trigger();
                status = api.GetStatus();
                isCalibrating = (status == WalabotAPI_NET.APP_STATUS.STATUS_CALIBRATING);
            catch
                isCalibrating = false;
            end
        end
        
        % Timer'ı güvenli şekilde durdur
        function stopTimer(timerObj)
            if ~isempty(timerObj) && isvalid(timerObj)
                stop(timerObj);
                delete(timerObj);
            end
        end
        
        % Anten çiftini parse et
        function pair = parseAntennaPair(str)
            tokens = regexp(str, '(\d+)\s*→\s*(\d+)', 'tokens');
            if ~isempty(tokens)
                pair = [str2double(tokens{1}{1}), str2double(tokens{1}{2})];
            else
                pair = [1, 2]; % Varsayılan
            end
        end
        
    end
end