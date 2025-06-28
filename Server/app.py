from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import sqlite3
import hashlib
import os
import numpy as np
from tensorflow.keras.preprocessing import image
from tensorflow.keras.models import load_model
from tensorflow.keras.applications.efficientnet import preprocess_input
from flask_cors import CORS

app = Flask(__name__)

# Enable CORS for all routes
CORS(app)

# Ensure the directory for file uploads exists
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


def predict_image_class(img_path, model, threshold=0.6):
    """
    Predict the class of an image. If the model's confidence is below the threshold, classify as "Unknown"
    and recommend general advice. Otherwise, provide specific recommendations based on the class label.
    
    Args:
        img_path (str): Path to the input image.
        model (Model): Trained model to use for prediction.
        threshold (float): Confidence threshold for determining if the prediction is "Unknown".
    
    Returns:
        dict: Dictionary containing predicted class label and recommendation.
    """


    # Load and preprocess the image
    img = image.load_img(img_path, target_size=(224, 224))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)  # Add a batch dimension
    img_array = preprocess_input(img_array)  # Preprocess the image according to EfficientNet standards

    # Make prediction
    predictions = model.predict(img_array)
    predicted_class_index = np.argmax(predictions, axis=1)  # Index of the highest probability
    confidence = np.max(predictions)  # Highest probability value

    # Mapping class indices to labels and recommendations
    labels = {0: "Abnormal", 1: "Infection", 2: "Ischaemia", 3: "Normal"}
    recommendations = {
        "Abnormal": "Consult with a dermatologist immediately.",
        "Infection": "Keep the area clean and avoid touching. Consult with a doctor if condition persists.",
        "Ischaemia": "Seek immediate medical attention.",
        "Normal": "No action needed, continue regular foot care."
    }

    # Check confidence threshold
    if confidence < threshold:
        return {
            "label": "Unknown",
            "recommendation": "Cannot determine the condition accurately. " +
                              "Please try another image or consult with a healthcare provider."
        }
    else:
        label = labels[predicted_class_index[0]]
        recommendation = recommendations[label]
        return {"label": label, "recommendation": recommendation}


def init_db():
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS users (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        email TEXT UNIQUE NOT NULL,
                        password TEXT NOT NULL)''')
    conn.commit()
    conn.close()

init_db()

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    password = data['password']
    email = data['email']
    # Encrypt password
    password_hash = hashlib.sha256(password.encode()).hexdigest()

    # Insert new user
    try:
        conn = sqlite3.connect('users.db')
        cursor = conn.cursor()
        cursor.execute('INSERT INTO users (email, password) VALUES (?, ?)', (email, password_hash))
        conn.commit()
        user_id = cursor.lastrowid
        conn.close()
        return jsonify({'message': 'User registered successfully', 'user_id': user_id}), 201
    except sqlite3.IntegrityError:
        return jsonify({'error': 'User already exists'}), 409

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email']
    password = data['password']
    password_hash = hashlib.sha256(password.encode()).hexdigest()

    # Authenticate user
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users WHERE email = ? AND password = ?', (email, password_hash))
    user = cursor.fetchone()
    conn.close()

    if user:
        return jsonify({'message': 'Login successful'}), 200
    else:
        return jsonify({'error': 'Invalid username or password'}), 401

@app.route('/upload-image', methods=['POST'])
def upload_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    if file:
        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        
        # Load the saved model
        loaded_model = load_model("infer_model.keras")
        prediction = predict_image_class(file_path, loaded_model)

        return jsonify(prediction), 201

if __name__ == '__main__':
    app.run(host="0.0.0.0", debug=True)
