from bottle import Bottle, request, response
import json

app = Bottle()

def count_cold_pixels(ambient_temp, grid):
    threshold = ambient_temp - 10
    cold_spots = 0
    total_points = len(grid) * len(grid[0])

    for row in grid:
        for temp in row:
            if float(temp) < threshold:
                cold_spots += 1

    return cold_spots, total_points

@app.post('/ice')
def predict_ice():
    data = request.json
    ambient_temp = data.get('ambient_temp')
    grid = data.get('grid')

    if not ambient_temp or not grid:
        response.status = 400
        return {'error': 'Invalid input'}

    cold_spots, total_points = count_cold_pixels(ambient_temp, grid)
    ice_present = cold_spots / total_points > 0.05

    return {'ice_present': ice_present}

@app.post('/ice-percentage')
def predict_ice_percentage():
    data = request.json
    ambient_temp = data.get('ambient_temp')
    grid = data.get('grid')

    if not ambient_temp or not grid:
        response.status = 400
        return {'error': 'Invalid input'}

    cold_spots, total_points = count_cold_pixels(ambient_temp, grid)
    percentage = (cold_spots / total_points) * 100

    return {'cold_pixel_percentage': percentage}

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=13337)