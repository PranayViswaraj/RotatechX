from flask import Flask, jsonify, request
import sqlite3

app = Flask(__name__)

# Create a new SQLite database (or connect to an existing one)
def get_db():
    conn = sqlite3.connect('health.db')
    conn.row_factory = sqlite3.Row
    return conn

# Create table if not exists
def create_table():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sensor_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            temperature REAL,
            heartRate REAL,
            spo2 INTEGER,
            ecgStatus TEXT,
            steps INTEGER,
            bpSystolic INTEGER,
            bpDiastolic INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

create_table()

# Endpoint to insert sensor data (POST request)
@app.route('/data', methods=['POST'])
def insert_data():
    data = request.get_json()

    temperature = data.get('temperature')
    heartRate = data.get('heartRate')
    spo2 = data.get('spo2')
    ecgStatus = data.get('ecgStatus')
    steps = data.get('steps')
    bpSystolic = data.get('bpSystolic')
    bpDiastolic = data.get('bpDiastolic')

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO sensor_data (temperature, heartRate, spo2, ecgStatus, steps, bpSystolic, bpDiastolic)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (temperature, heartRate, spo2, ecgStatus, steps, bpSystolic, bpDiastolic))
    conn.commit()
    conn.close()

    return jsonify({"status": "stored"}), 201
@app.route('/live_website')
def live_website_page():
    return app.send_static_file('live_website.html')
# Endpoint to get the latest sensor data (GET request)
@app.route('/data/latest', methods=['GET'])
def get_latest_data():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM sensor_data ORDER BY timestamp DESC LIMIT 1')
    row = cursor.fetchone()
    conn.close()

    if row is None:
        return jsonify({"message": "No data found"}), 404

    # Convert the row to a dictionary
    data = {key: row[key] for key in row.keys()}
    return jsonify(data)

# Serve static HTML (this will serve the live_website.html file)
@app.route('/')
def serve_static_file():
    return app.send_static_file('login.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)
