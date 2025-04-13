from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import random
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder

app = Flask(__name__)
CORS(app)

class HealthConditionDetector:
    def __init__(self):
        # Load dataset
        self.df = pd.read_csv("simulated_health_data.csv")

        # Extract BP components
        self.df[['Systolic_BP', 'Diastolic_BP']] = self.df['Blood Pressure'].str.extract(r'(\d+)/(\d+)').astype(float)
        self.df = self.df.drop(columns=['Blood Pressure'])

        # Encode labels
        self.label_encoder = LabelEncoder()
        self.df['Health Condition'] = self.label_encoder.fit_transform(self.df['Health Condition'])

        # Features and target
        self.X = self.df.drop(columns=['Health Condition'])
        self.y = self.df['Health Condition']

        # Scale features
        self.scaler = StandardScaler()
        self.X_scaled = self.scaler.fit_transform(self.X)

        # Train model
        self.model = self.train_model()

    def train_model(self):
        X_train, X_test, y_train, y_test = train_test_split(self.X_scaled, self.y, test_size=0.2, random_state=42)
        model = DecisionTreeClassifier(max_depth=7, random_state=42)
        model.fit(X_train, y_train)
        return model

    def assess_health(self, vitals_dict):
        try:
            expected_keys = ['Heart Rate', 'SpO2', 'Steps', 'Sleep', 'Calories Burnt', 'Systolic_BP', 'Diastolic_BP']
            defaults = {
                'Heart Rate': 75,
                'SpO2': 98,
                'Steps': 5000,
                'Sleep': 7.0,
                'Calories Burnt': 2000,
                'Systolic_BP': 120,
                'Diastolic_BP': 80
            }

            # Fill in any missing or null values
            for key in expected_keys:
                if key not in vitals_dict or vitals_dict[key] is None:
                    vitals_dict[key] = defaults[key]

            user_df = pd.DataFrame(vitals_dict, index=[0])
            user_scaled = self.scaler.transform(user_df)
            pred_encoded = self.model.predict(user_scaled)[0]
            label = self.label_encoder.inverse_transform([pred_encoded])[0]

            healthy_labels = ["Healthy", "Fit", "Normal"]
            return "Healthy" if label in healthy_labels else "Unhealthy"

        except Exception as e:
            print("Error in assess_health():", e)
            return "Unhealthy"

# Initialize detector
detector = HealthConditionDetector()

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    condition = detector.assess_health(data)
    return jsonify({"condition": condition})

@app.route('/live-data', methods=['GET'])
def live_data():
    data = {
        "Heart Rate": random.randint(60, 100),
        "SpO2": random.randint(95, 100),
        "Steps": random.randint(1000, 10000),
        "Sleep": round(random.uniform(6.0, 9.0), 1),
        "Calories Burnt": random.randint(1500, 3000),
        "Systolic_BP": random.randint(110, 130),
        "Diastolic_BP": random.randint(70, 85)
    }
    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True)
