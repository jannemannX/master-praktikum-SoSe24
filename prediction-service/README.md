# Ice Detection Service

A simple microservice that analyzes temperature grid data to detect ice presence and coverage. It processes thermal sensor data by comparing temperature readings against the ambient temperature to identify cold spots that indicate the presence of ice. Can be fine-tuned by adjusting the temperature threshold and pixel threshold.

## Deployment

1. Install dependencies:
   ```
   pip3 install -r requirements.txt
   ```

2. Set up environment:
   - Copy `.env.example` to `.env`
   - Fill in the required values (primarily the service port)

3. Run the server:
   ```
   python3 prediction-service.py
   ```

## API Endpoints

### POST /ice
Determines if ice is present based on the temperature readings.

Request format:
```json
{
    "ambient_temp": 20,
    "grid": [[18, 19, 13], [17, 12, 14], [19, 18, 11]],
    "temp_threshold": 5,     // optional, default: 5
    "pixel_threshold": 0.03  // optional, default: 0.03
}
```

Response:
```json
{
    "ice_present": true
}
```

### POST /ice-percentage
Calculates the percentage of the surface area that might be covered in ice.

Request format:
```json
{
    "ambient_temp": 20,
    "grid": [[18, 19, 13], [17, 12, 14], [19, 18, 11]],
    "temp_threshold": 5  // optional, default: 5
}
```

Response:
```json
{
    "cold_pixel_percentage": 33.33
}
```

Note: The CPEE sends requests with Content-Type: application/x-www-form-urlencoded, the temperature data (JSON) must be send in a field named "data".