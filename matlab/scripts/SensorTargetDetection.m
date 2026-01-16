classdef SensorTargetDetection
    % Sensor Target Detection tab için tüm fonksiyonlar
    
    methods (Static)
        
        % Apply-Calibrate butonu
        function applyCalibrate(app)
            % Bağlantı kontrolü
            if ~WalabotUtils.checkConnection(app.ConnectionStatusLamp_STD)
                uialert(app.UIFigure, 'Cihaz bağlı değil!', 'Bağlantı Hatası');
                return;
            end
            
            try
                % Profil ayarla
                app.API.SetProfile(WalabotAPI_NET.SCAN_PROFILE.PROF_SENSOR);
                
                % Arena ayarları
                app.API.SetArenaR(app.R_Min_STD.Value, app.R_Max_STD.Value, app.R_Res_STD.Value);
                app.API.SetArenaTheta(-app.Theta_STD.Value, app.Theta_STD.Value, app.Theta_Res_STD.Value);
                app.API.SetArenaPhi(-app.Phi_STD.Value, app.Phi_STD.Value, app.Phi_Res_STD.Value);
                
                % Threshold
                app.API.SetThreshold(app.Thresold_STD.Value);
                
                % MTI Filtre
                app.API.SetDynamicImageFilter(WalabotAPI_NET.FILTER_TYPE.FILTER_TYPE_MTI);
                
                % Başlat ve kalibre et
                app.API.Start();
                app.API.StartCalibration();
                
                uialert(app.UIFigure, 'Kalibrasyon başlatıldı.', 'Başarılı');
                
            catch ME
                uialert(app.UIFigure, ['Hata: ', ME.message], 'Donanım Hatası');
            end
        end
        
        % Start butonu
        function start(app)
            % Bağlantı kontrolü
            if ~WalabotUtils.checkConnection(app.ConnectionStatusLamp_STD)
                uialert(app.UIFigure, 'Önce Apply-Calibrate yapın!', 'Uyarı');
                return;
            end
            
            % Kalibrasyon kontrolü
            if WalabotUtils.checkCalibration(app.API)
                uialert(app.UIFigure, 'Kalibrasyon devam ediyor...', 'Bilgi');
                return;
            end
            
            try
                % Timer ile sürekli veri çekimi başlat
                app.SensorTimer = timer('ExecutionMode', 'fixedRate', ...
                                       'Period', 0.1, ...
                                       'TimerFcn', @(~,~)SensorTargetDetection.update(app));
                start(app.SensorTimer);
                
                uialert(app.UIFigure, 'Sensor Target Detection başlatıldı.', 'Başarılı');
                
            catch ME
                uialert(app.UIFigure, ['Hata: ', ME.message], 'Başlatma Hatası');
            end
        end
        
        % Güncelleme fonksiyonu
        function update(app)
            try
                app.API.Trigger();
                
                % Ham görüntü verisi al
                [rasterImage, ~, ~, ~, ~] = app.API.GetRawImageSlice();
                
                % Target verilerini al
                targets = app.API.GetSensorTargets();
                numTargets = length(targets);
                
                % UIAxes_RawImage'e raw image çiz
                if ~isempty(rasterImage)
                    imagesc(app.UIAxes_RawImage, rasterImage);
                    colormap(app.UIAxes_RawImage, 'jet');
                    colorbar(app.UIAxes_RawImage);
                    title(app.UIAxes_RawImage, 'Raw Image - Angle(Phi)/ Distance(R)');
                    xlabel(app.UIAxes_RawImage, 'Phi [°]');
                    ylabel(app.UIAxes_RawImage, 'R [cm]');
                end
                
                % UIAxesCartesianCoordinate'a Y/Z Cartesian koordinatları çiz
                cla(app.UIAxesCartesianCoordinate);
                
                if numTargets > 0
                    hold(app.UIAxesCartesianCoordinate, 'on');
                    
                    for i = 1:min(numTargets, 3)
                        target = targets(i);
                        xPos = target.xPosCm;
                        yPos = target.yPosCm;
                        zPos = target.zPosCm;
                        amp = target.amplitude;
                        
                        scatter(app.UIAxesCartesianCoordinate, yPos, zPos, 100, 'filled', ...
                               'MarkerFaceColor', 'red', ...
                               'MarkerEdgeColor', 'black', 'LineWidth', 2);
                        
                        text(app.UIAxesCartesianCoordinate, yPos, zPos, ...
                            sprintf('  T%d\n  X:%.1f Y:%.1f Z:%.1f\n  Amp:%.1f', ...
                                    i, xPos, yPos, zPos, amp), ...
                            'FontSize', 8, 'Color', 'white', ...
                            'FontWeight', 'bold', 'BackgroundColor', [0 0 0 0.5]);
                    end
                    
                    hold(app.UIAxesCartesianCoordinate, 'off');
                    title(app.UIAxesCartesianCoordinate, sprintf('Y/Z Cartesian - %d Target(s)', numTargets));
                else
                    title(app.UIAxesCartesianCoordinate, 'Y/Z Cartesian - No Targets');
                end
                
                xlabel(app.UIAxesCartesianCoordinate, 'Y [cm]');
                ylabel(app.UIAxesCartesianCoordinate, 'Z [cm]');
                grid(app.UIAxesCartesianCoordinate, 'on');
                axis(app.UIAxesCartesianCoordinate, 'equal');
                
            catch ME
                fprintf('STD Güncelleme hatası: %s\n', ME.message);
            end
        end
        
        % Stop butonu
        function stop(app)
            try
                WalabotUtils.stopTimer(app.SensorTimer);
                app.API.Stop();
                uialert(app.UIFigure, 'Sensor Target Detection durduruldu.', 'Başarılı');
            catch ME
                fprintf('STD Durdurma hatası: %s\n', ME.message);
            end
        end
        
    end
end