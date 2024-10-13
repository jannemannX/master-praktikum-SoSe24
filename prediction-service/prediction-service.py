from bottle import Bottle, request, response
import json
import logging
import urllib.parse
from dotenv import load_dotenv
import os

load_dotenv()

service_port = int(os.getenv("SERVICE_PORT"))

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

app = Bottle()

def count_cold_pixels(ambient_temp, grid, temp_threshold):
    threshold = float(ambient_temp) - temp_threshold
    cold_spots = sum(1 for row in grid for temp in row if float(temp) < threshold)
    total_points = len(grid) * len(grid[0])
    return cold_spots, total_points

@app.get('/')
def hello():
    return 'prediction service is running'

@app.post('/ice')
def predict_ice():
    data = log_request()
    ambient_temp = data.get('ambient_temp')
    grid = data.get('grid')
    temp_threshold = data.get('temp_threshold', 5)
    pixel_threshold = data.get('pixel_threshold', 0.03)

    if not isinstance(ambient_temp, (int, float)) or not isinstance(grid, list):
        response.status = 400
        return {'error': 'Invalid input type'}

    if not all(isinstance(row, list) and all(isinstance(temp, (int, float)) for temp in row) for row in grid):
        response.status = 400
        return {'error': 'Invalid grid structure'}

    cold_spots, total_points = count_cold_pixels(ambient_temp, grid, temp_threshold)
    ice_present = cold_spots / total_points > pixel_threshold
    logger.info(f'Prediction: ice_present={ice_present}')
    return {'ice_present': ice_present}

@app.post('/ice-percentage')
def predict_ice_percentage():
    data = log_request()
    ambient_temp = data.get('ambient_temp')
    grid = data.get('grid')
    temp_threshold = data.get('temp_threshold', 5)

    if not isinstance(ambient_temp, (int, float)) or not isinstance(grid, list):
        response.status = 400
        return {'error': 'Invalid input type'}

    if not all(isinstance(row, list) and all(isinstance(temp, (int, float)) for temp in row) for row in grid):
        response.status = 400
        return {'error': 'Invalid grid structure'}

    cold_spots, total_points = count_cold_pixels(ambient_temp, grid, temp_threshold)
    percentage = (cold_spots / total_points) * 100
    logger.info(f'Prediction: cold_pixel_percentage={percentage}')
    return {'cold_pixel_percentage': percentage}

def log_request():
    try:
        if request.headers.get('Content-Type') != 'application/x-www-form-urlencoded':
            response.status = 400
            return {'error': 'Unsupported Content-Type'}

        body = request.body.read().decode("utf-8")
        logger.info(f'Request Method: {request.method}')
        logger.info(f'Request URL: {request.url}')

        headers = dict(request.headers)
        if 'Authorization' in headers:
            headers['Authorization'] = '*****'
        logger.info(f'Request Headers: {headers}')

        decoded_body = urllib.parse.unquote(body)
        logger.info(f'Request Body: {decoded_body}')

        parsed_body = urllib.parse.parse_qs(body)
        if 'data' in parsed_body:
            try:
                data = json.loads(parsed_body['data'][0])
                if 'grid' in data:
                    data['grid'] = [[float(temp) for temp in row] for row in data['grid']]
                if 'temp_threshold' in data:
                    data['temp_threshold'] = float(data['temp_threshold'])
                if 'pixel_threshold' in data:
                    data['pixel_threshold'] = float(data['pixel_threshold'])
                return data
            except json.JSONDecodeError:
                logger.error('Failed to parse JSON from request body')
                response.status = 400
                return {'error': 'Invalid JSON format'}
        else:
            return {}
    except Exception as e:
        logger.error(f'Failed to log request: {e}')
        return {}

if __name__ == "__main__":
    app.run(host='::1', port=service_port)