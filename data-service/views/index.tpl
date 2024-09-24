<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Temperature Monitor</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        #temperatureGrid { border: 1px solid #333; margin-top: 20px; }
        #legend { display: flex; align-items: center; margin-top: 20px; }
        .legend-label { font-size: 14px; padding: 0 10px; }
        .play-btn, .snapshot-btn, .apply-range-btn { margin-top: 20px; padding: 10px 20px; background-color: #007bff; color: white; border: none; cursor: pointer; }
        .play-btn.paused { background-color: #dc3545; }
        .snapshot-btn:disabled { background-color: #cccccc; cursor: not-allowed; }
        .slider-container { margin-top: 20px; }
        .slider-container label { margin-right: 10px; }
        .slider { display: flex; align-items: center; margin-top: 10px; }
        .slider input { margin-right: 10px; }
        #stats { margin-top: 20px; display: flex; justify-content: space-between; }
        #stats p { margin-right: 10px; }
        .error-message { color: red; margin-top: 10px; }
    </style>
</head>
<body>
    <h1>Temperature Monitoring Dashboard</h1>
    <div class="info">
        <p>Available endpoints:</p>
        <ul>
            <li><a href="/temperature">/temperature</a> - Get the latest temperature data as JSON</li>
        </ul>
        <p><strong>Ambient temperature:</strong> <span id="ambientTemp">Loading...</span> °C</p>
    </div>

    <canvas id="temperatureGrid" width="320" height="240"></canvas>

    <div id="legend">
        <span class="legend-label" id="minTempLabel">10°C</span>
        <canvas id="legendCanvas" width="200" height="20"></canvas>
        <span class="legend-label" id="maxTempLabel">30°C</span>
    </div>

    <div id="stats">
        <p><strong>Min:</strong> <span id="minTemp">N/A</span> °C</p>
        <p><strong>Max:</strong> <span id="maxTemp">N/A</span> °C</p>
        <p><strong>Avg:</strong> <span id="avgTemp">N/A</span> °C</p>
    </div>

    <div class="slider-container">
        <div class="slider">
            <label for="minTempInput">Min Temp:</label>
            <input type="number" id="minTempInput" value="10" step="0.1">
        </div>
        <div class="slider">
            <label for="maxTempInput">Max Temp:</label>
            <input type="number" id="maxTempInput" value="30" step="0.1">
        </div>
        <button id="applyRangeBtn" class="apply-range-btn">Apply Range</button>
        <div class="slider">
            <label for="intervalSlider">Update Interval (ms):</label>
            <input type="range" id="intervalSlider" min="100" max="2000" step="100" value="1000">
            <span id="intervalValue">1000</span> ms
        </div>
    </div>

    <div class="error-message" id="rangeError"></div>

    <button id="playPauseBtn" class="play-btn">Pause</button>
    <button id="snapshotBtn" class="snapshot-btn" disabled>Take Snapshot</button>

    <script>
        let fetchInterval;
        let isPaused = false;
        let updateInterval = 1000;
        let lastUpdate = Date.now();
        let minTemp = 10;
        let maxTemp = 30;

        function drawLegend() {
            const legendCanvas = document.getElementById('legendCanvas');
            const ctx = legendCanvas.getContext('2d');
            const width = legendCanvas.width;

            for (let i = 0; i < width; i++) {
                const temp = minTemp + (i / width) * (maxTemp - minTemp);
                ctx.fillStyle = getTemperatureColor(temp);
                ctx.fillRect(i, 0, 1, legendCanvas.height);
            }

            document.getElementById('minTempLabel').textContent = `${minTemp}°C`;
            document.getElementById('maxTempLabel').textContent = `${maxTemp}°C`;
        }

        function fetchTemperatureData() {
            fetch('/temperature')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('rangeError').textContent = '';

                    const now = Date.now();
                    console.log(`Update interval: ${now - lastUpdate} ms`);
                    lastUpdate = now;

                    const ambientTemp = data.ambient_temp;
                    document.getElementById('ambientTemp').textContent = (typeof ambientTemp === 'number' && !isNaN(ambientTemp)) ? ambientTemp.toFixed(2) : 'N/A';

                    if (Array.isArray(data.grid) && data.grid.length > 0) {
                        drawTemperatureGrid(data.grid);
                        updateStats(data.grid);
                    } else {
                        console.error("Invalid grid data");
                        document.getElementById('rangeError').textContent = 'Invalid grid data.';
                    }
                })
                .catch(err => {
                    console.error("Error fetching temperature data:", err);
                    document.getElementById('rangeError').textContent = 'Error fetching temperature data.';
                });
        }

        function drawTemperatureGrid(gridData) {
            const canvas = document.getElementById('temperatureGrid');
            const ctx = canvas.getContext('2d');

            if (!gridData || gridData.length === 0) {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                ctx.font = "20px Arial";
                ctx.fillText("No data available", 80, 120);
                return;
            }

            const cellWidth = canvas.width / 32;
            const cellHeight = canvas.height / 24;

            for (let row = 0; row < 24; row++) {
                const rowData = gridData[row];
                if (rowData) {
                    for (let col = 0; col < 32; col++) {
                        const temp = parseFloat(rowData[col]);
                        const color = getTemperatureColor(temp);
                        ctx.fillStyle = color;
                        ctx.fillRect(col * cellWidth, row * cellHeight, cellWidth, cellHeight);
                    }
                }
            }
        }

        function updateStats(gridData) {
            if (!gridData || gridData.length === 0) {
                document.getElementById('minTemp').textContent = 'N/A';
                document.getElementById('maxTemp').textContent = 'N/A';
                document.getElementById('avgTemp').textContent = 'N/A';
                return;
            }

            let minGridTemp = Infinity;
            let maxGridTemp = -Infinity;
            let totalTemp = 0;
            let count = 0;

            for (let row = 0; row < 24; row++) {
                const rowData = gridData[row];
                if (rowData) {
                    for (let col = 0; col < 32; col++) {
                        const temp = parseFloat(rowData[col]);
                        if (!isNaN(temp)) {
                            minGridTemp = Math.min(minGridTemp, temp);
                            maxGridTemp = Math.max(maxGridTemp, temp);
                            totalTemp += temp;
                            count++;
                        }
                    }
                }
            }

            const avgTemp = count > 0 ? totalTemp / count : 0;

            document.getElementById('minTemp').textContent = isFinite(minGridTemp) ? minGridTemp.toFixed(2) : 'N/A';
            document.getElementById('maxTemp').textContent = isFinite(maxGridTemp) ? maxGridTemp.toFixed(2) : 'N/A';
            document.getElementById('avgTemp').textContent = isFinite(avgTemp) ? avgTemp.toFixed(2) : 'N/A';
        }

        function getTemperatureColor(temp) {
            if (isNaN(temp)) {
                return 'rgb(0, 0, 0)';
            }

            let percent = (temp - minTemp) / (maxTemp - minTemp);
            percent = Math.min(1, Math.max(0, percent));

            const r = Math.floor(255 * percent);
            const b = Math.floor(255 * (1 - percent));
            return `rgb(${r}, 0, ${b})`;
        }

        function startFetching() {
            fetchTemperatureData();
            fetchInterval = setInterval(fetchTemperatureData, updateInterval);
        }

        function stopFetching() {
            clearInterval(fetchInterval);
            fetchInterval = null;
        }

        document.getElementById('playPauseBtn').addEventListener('click', function () {
            if (isPaused) {
                startFetching();
                this.textContent = 'Pause';
                this.classList.remove('paused');
                document.getElementById('snapshotBtn').disabled = true;
            } else {
                stopFetching();
                this.textContent = 'Play';
                this.classList.add('paused');
                document.getElementById('snapshotBtn').disabled = false;
            }
            isPaused = !isPaused;
        });

        document.getElementById('snapshotBtn').addEventListener('click', function () {
            fetchTemperatureData();
        });

        document.getElementById('intervalSlider').addEventListener('input', function () {
            updateInterval = parseInt(this.value);
            document.getElementById('intervalValue').textContent = updateInterval;

            if (!isPaused) {
                stopFetching();
                startFetching();
            }
        });

        document.getElementById('applyRangeBtn').addEventListener('click', function () {
            const minTempInputVal = document.getElementById('minTempInput').value;
            const maxTempInputVal = document.getElementById('maxTempInput').value;
            const minTempInput = parseFloat(minTempInputVal);
            const maxTempInput = parseFloat(maxTempInputVal);
            const errorMessage = document.getElementById('rangeError');

            if (minTempInputVal === '' || maxTempInputVal === '' || isNaN(minTempInput) || isNaN(maxTempInput)) {
                errorMessage.textContent = 'Please enter valid numbers for min and max temperatures.';
                return;
            }

            if (minTempInput >= maxTempInput) {
                errorMessage.textContent = 'Min Temp must be less than Max Temp.';
                return;
            }

            minTemp = minTempInput;
            maxTemp = maxTempInput;

            errorMessage.textContent = '';
            drawLegend();
            fetchTemperatureData();
        });

        drawLegend();
        startFetching();
    </script>
</body>
</html>
