classdef RawSignals
    methods (Static)
        
        % --- 1. APPLY (AYARLARI UYGULA) ---
        function apply(app)
            try
                % Seçilen anten çiftini al
                selectedPairStr = app.Graph1DropDown.Value;
                
                if isempty(selectedPairStr)
                    uialert(app.UIFigure, 'Lütfen listeden bir anten çifti seçiniz.', 'Hata');
                    return;
                end
                
                % (Opsiyonel) Walabot profili yükleme işlemleri burada yapılabilir.
                % app.API.SetProfile('ShortRange'); vb.
                
                % Kullanıcıya bilgi ver
                uialert(app.UIFigure, ...
                    ['Ayarlar uygulandı. Seçilen Mod: ' selectedPairStr], ...
                    'Bilgi');
                    
            catch ME
                uialert(app.UIFigure, ['Apply Hatası: ' ME.message], 'Hata');
            end
        end

        % --- 2. START (BAŞLAT) ---
        function start(app)
            try
                % Timer zaten çalışıyorsa çık
                if ~isempty(app.RawSignalTimer) && isvalid(app.RawSignalTimer) && strcmp(app.RawSignalTimer.Running, 'on')
                    return;
                end

                % Yeni Timer oluştur
                % Period: 0.05 saniye (20 FPS)
                app.RawSignalTimer = timer('ExecutionMode', 'fixedRate', ...
                    'Period', 0.05, ...
                    'TimerFcn', @(~,~)RawSignals.update(app));
                
                start(app.RawSignalTimer);
                
                % Buton durumlarını güncelle
                app.Start_RS.Enable = 'off'; % Start'a tekrar basılamasın
                app.Stop_RS.Enable = 'on';   % Stop aktif olsun
                app.Graph1DropDown.Enable = 'off'; % Çalışırken anten değişmesin
                
            catch ME
                uialert(app.UIFigure, ['Başlatma Hatası: ' ME.message], 'Hata');
                % Hata olursa butonları resetle
                app.Start_RS.Enable = 'on';
                app.Stop_RS.Enable = 'off';
            end
        end

        % --- 3. STOP (DURDUR) ---
        function stop(app)
            try
                % Timer'ı durdur ve sil
                if ~isempty(app.RawSignalTimer) && isvalid(app.RawSignalTimer)
                    stop(app.RawSignalTimer);
                    delete(app.RawSignalTimer);
                end
                
                % Buton durumlarını güncelle
                app.Start_RS.Enable = 'on';  % Start tekrar aktif
                app.Stop_RS.Enable = 'off';  % Stop pasif
                app.Graph1DropDown.Enable = 'on'; % Anten seçimi tekrar açilsin
                
            catch ME
                uialert(app.UIFigure, ['Durdurma Hatası: ' ME.message], 'Hata');
            end
        end

        % --- 4. UPDATE (GRAFİK GÜNCELLEME) ---
        function update(app)
            try
                % A) Trigger
                app.API.Trigger();
                
                % B) Dropdown'dan seçilen antenleri parse et
                % "Antenna 1 -> Antenna 2" stringinden sayıları çekiyoruz
                strVal = app.Graph1DropDown.Value;
                tokens = regexp(strVal, '\d+', 'match'); % Sayıları bul
                
                if length(tokens) >= 2
                    tx = str2double(tokens{1});
                    rx = str2double(tokens{2});
                else
                    tx = 1; rx = 2; % Varsayılan
                end
                
                % C) Sinyali Al
                signalData = app.API.GetRawSignal(tx, rx);
                
                if isempty(signalData), return; end

                % D) Grafiği Çiz (Doğru Eksen: UIAxesAmplitudeTime)
                numSamples = length(signalData);
                dt = 1e-10; % Yaklaşık zaman adımı (ns'ye çevirmek için)
                timeAxis = (0:numSamples-1) * dt * 1e9; 
                
                plot(app.UIAxesAmplitudeTime, timeAxis, abs(signalData), 'b-');
                
                % (Opsiyonel: Başlığı her seferinde güncellemek yorabilir, Apply'da yapılabilir)
                % title(app.UIAxesAmplitudeTime, sprintf('Tx: %d -> Rx: %d', tx, rx));
                
            catch ME
                % Loop içinde hata olursa konsola yaz (UI donmasın)
                fprintf('RS Update Error: %s\n', ME.message);
            end
        end
    end
end