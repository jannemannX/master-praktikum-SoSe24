# Deployment
1. Install the pip modules: `pip3 install -r requirements.txt`
2. Create .env file by copying .env.example and filling in the values
3. Run the server: `python3 prediction-service.py`
4. Optional: debug logging TODO

# Usage
- POST `/ice`: get a prediction if ice is present
- POST `/ice-percentage`: get a prediction of the percentage of ice present in the image