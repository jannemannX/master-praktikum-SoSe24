# Deployment
1. Install the pip modules: `pip3 install -r requirements.txt`
2. Create .env file by copying .env.example and filling in the values
3. Run the server: `python3 data-service.py`
4. Optional: debug logging TODO

# Usage
- GET `/temperature`: Get the temperature data in JSON format
- GET `/`: Serves the temperature monitoring dashboard