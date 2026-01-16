classdef ImagingShortRange
    % Imaging Short Range tab için tüm fonksiyonlar
    
    methods (Static)
        
        % Apply-Calibrate butonu
        function applyCalibrate(app)
            if ~WalabotUtils.checkConnection(app.ConnectionStatusLamp_ISR)
                uialert(app.UIFigure, 'Cihaz bağlı değil!', 'Bağlantı Hatası');
                return;
            end
            
            try
                % Profil - SHORT_RANGE_IMAGING
                app.API.SetProfile(WalabotAPI_NET.SCAN_PROFILE.PROF_SHORT_RANGE_IMAGING);
                
                % 3D Arena ayarları
                app.API.SetArenaR(app.Z_Min_ISR.Value, app.Z_Max_ISR.Value, app.Z_Res_ISR.Value);
                app.API.SetArenaX(app.X_Min_ISR.Value, app.X_Max_ISR.Value, app.X_Res_ISR.Value);
                app.API.SetArenaY(app.Y_Min_ISR.Value, app.Y_Max_ISR.Value, app.Y_Res_ISR.Value);
                
                % Threshold
                app.API.SetThreshold(app.Threshold_ISR.Value);
                
                % Filtre yok
                app.API.SetDynamicImageFilter(WalabotAPI_NET.FILTER_TYPE.FILTER_TYPE_NONE);
                
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
            if ~WalabotUtils.checkConnection(app.ConnectionStatusLamp_ISR)
                uialert(app.UIFigure, 'Önce Apply-Calibrate yapın!', 'Uyarı');
                return;
            end
            
            if WalabotUtils.checkCalibration(app.API)
                uialert(app.UIFigure, 'Kalibrasyon devam ediyor...', 'Bekleyin');
                return;
            end
            
            try
                % Timer başlat
                app.ImagingTimer = timer('ExecutionMode', 'fixedRate', ...
                                        'Period', 0.1, ...
                                        'TimerFcn', @(~,~)ImagingShortRange.update(app));
                start(app.ImagingTimer);
                
                uialert(app.UIFigure, 'Imaging başlatıldı.', 'Başarılı');
                
            catch ME
                uialert(app.UIFigure, ['Hata: ', ME.message], 'Başlatma Hatası');
            end
        end
        
        % Güncelleme fonksiyonu
        function update(app)
            try
                app.API.Trigger();
                
                % 3D raw image al
                [rasterImage, ~, ~, sizeZ, ~] = app.API.GetRawImage();
                
                % X/Y kesiti
                if ~isempty(rasterImage) && sizeZ > 0
                    midZ = round(sizeZ / 2);
                    xySlice = squeeze(rasterImage(:, :, midZ));
                    
                    % Raw image
                    imagesc(app.UIAxesRawImageSlice, xySlice);
                    colormap(app.UIAxesRawImageSlice, 'jet');
                    colorbar(app.UIAxesRawImageSlice);
                    xlabel(app.UIAxesRawImageSlice, 'X [cm]');
                    ylabel(app.UIAxesRawImageSlice, 'Y [cm]');
                    title(app.UIAxesRawImageSlice, sprintf('Raw Image Slice - X/Y (Z=%.1f cm)', midZ));
                    
                    % Pipe detector
                    detectedObjects = xySlice > app.Threshold_ISR.Value;
                    imagesc(app.UIAxesInWallPipeDet, detectedObjects);
                    colormap(app.UIAxesInWallPipeDet, [0 0 0; 1 0 0]);
                    title(app.UIAxesInWallPipeDet, 'In-Wall Pipe Detector');
                    xlabel(app.UIAxesInWallPipeDet, 'X [cm]');
                    ylabel(app.UIAxesInWallPipeDet, 'Y [cm]');
                end
                
            catch ME
                fprintf('Imaging güncelleme hatası: %s\n', ME.message);
            end
        end
        
        % Stop butonu
        function stop(app)
            try
                WalabotUtils.stopTimer(app.ImagingTimer);
                app.API.Stop();
                uialert(app.UIFigure, 'Imaging durduruldu.', 'Başarılı');
            catch ME
                fprintf('ISR Durdurma hatası: %s\n', ME.message);
            end
        end
        
    end
end