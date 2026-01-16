classdef SensorBreathing
    % Sensor Breathing tab için tüm fonksiyonlar
    
    methods (Static)
        
        % Apply-Calibrate butonu
        function applyCalibrate(app)
            if ~WalabotUtils.checkConnection(app.ConnectionStatusLamp_SB)
                uialert(app.UIFigure, 'Cihaz bağlı değil!', 'Bağlantı Hatası');
                return;
            end
            
            try
                % Profil - SENSOR
                app.API.SetProfile(WalabotAPI_NET.SCAN_PROFILE.PROF_SENSOR);
                
                % Arena ayarları
                app.API.SetArenaR(app.R_Min_SB.Value, app.R_Max_SB.Value, app.R_Res_SB.Value);
                app.API.SetArenaTheta(-app.Theta_SB.Value, app.Theta_SB.Value, app.Theta_Res_SB.Value);
                app.API.SetArenaPhi(-app.Phi_SB.Value, app.Phi_SB.Value, app.Phi_Res_SB.Value);
                
                % MTI Filtre
                app.API.SetDynamicImageFilter(WalabotAPI_NET.FILTER_TYPE.FILTER_TYPE_MTI);
                
                % Başlat
                app.API.Start();
                app.API.StartCalibration();
                
                uialert(app.UIFigure, 'Kalibrasyon başlatıldı...', 'Başarılı');
                
            catch ME
                uialert(app.UIFigure, ['Hata: ', ME.message], 'Donanım Hatası');
            end
        end
        
        % Start butonu
        function start(app)
            if ~WalabotUtils.checkConnection(app.ConnectionStatusLamp_SB)
                uialert(app.UIFigure, 'Önce Apply-Calibrate yapın!', 'Uyarı');
                return;
            end
            
            if WalabotUtils.checkCalibration(app.API)
                uialert(app.UIFigure, 'Kalibrasyon devam ediyor...', 'Bekleyin');
                return;
            end
            
            try
                % Buffer başlat
                app.BreathingData = [];
                app.TimeData = [];
                app.BreathingStartTime = tic;
                
                % Timer başlat
                app.BreathingTimer = timer('ExecutionMode', 'fixedRate', ...
                                          'Period', 0.05, ...
                                          'TimerFcn', @(~,~)SensorBreathing.update(app));
                start(app.BreathingTimer);
                
                uialert(app.UIFigure, 'Breathing monitoring başlatıldı.', 'Başarılı');
                
            catch ME
                uialert(app.UIFigure, ['Hata: ', ME.message], 'Başlatma Hatası');
            end
        end
        
        % Güncelleme fonksiyonu
        function update(app)
            try
                app.API.Trigger();
                
                % Breathing energy al
                energy = app.API.GetBreathingEnergy();
                currentTime = toc(app.BreathingStartTime);
                
                % Verileri biriktir (son 10 saniye)
                app.BreathingData = [app.BreathingData, energy];
                app.TimeData = [app.TimeData, currentTime];
                
                keepIdx = app.TimeData > (currentTime - 10);
                app.BreathingData = app.BreathingData(keepIdx);
                app.TimeData = app.TimeData(keepIdx);
                
                % Grafik çiz
                plot(app.UIAxesBreathingActivity, app.TimeData, app.BreathingData, 'b-', 'LineWidth', 2);
                xlabel(app.UIAxesBreathingActivity, 'Time [s]');
                ylabel(app.UIAxesBreathingActivity, 'Breathing Energy');
                grid(app.UIAxesBreathingActivity, 'on');
                xlim(app.UIAxesBreathingActivity, [max(0, currentTime-10), currentTime]);
                
                % Y ekseni ölçeklendirme
                if app.AutoAdjustDisplayScaleCheckBox.Value
                    ylim(app.UIAxesBreathingActivity, 'auto');
                    title(app.UIAxesBreathingActivity, 'Breathing Activity (Auto Scale)');
                else
                    maxY = app.Slider.Value;
                    if maxY <1, maxY = 1;
                    end
                    ylim(app.UIAxesBreathingActivity, [0, maxY]); 
                end
                
            catch ME
                fprintf('Breathing güncelleme hatası: %s\n', ME.message);
            end
        end
        
        % Stop butonu
        function stop(app)
            try
                WalabotUtils.stopTimer(app.BreathingTimer);
                
                % Veriyi kaydet
                if ~isempty(app.BreathingData)
                    filename = sprintf('breathing_data_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));
                    breathingData = app.BreathingData;
                    timeData = app.TimeData;
                    save(filename, 'breathingData', 'timeData');
                    uialert(app.UIFigure, ['Veri kaydedildi: ', filename], 'Başarılı');
                end
                
                app.API.Stop();
                
            catch ME
                fprintf('SB Durdurma hatası: %s\n', ME.message);
            end
        end
        
    end
end