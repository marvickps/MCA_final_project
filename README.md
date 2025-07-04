# EezTour - Travel Itinerary Management System

EezTour is a comprehensive travel itinerary management application that allows users to create, customize, and share travel plans. The application consists of a Flutter mobile frontend and a FastAPI backend with Google Maps integration.

## 🚀 Features

### Frontend (Flutter)
- **User Authentication**: Login  system
- **Itinerary Creation**: Create detailed travel itineraries with dates and locations
- **Interactive Maps**: Google Maps integration for location selection and route visualization
- **Day-by-Day Planning**: Organize trips by days with specific locations and activities
- **Real-time Search**: Search for cities, hotels, and places using Google Places API
- **Route Planning**: Calculate distances and durations between stops
- **Share Functionality**: Generate share codes for itineraries

### Backend (FastAPI)
- **RESTful API**: Complete REST API for all travel planning operations
- **Database Management**: SQLAlchemy ORM with MySQL database
- **Google Maps Integration**: Places API, routing, and geocoding services
- **Authentication**: JWT-based user authentication
- **Booking System**: Hotel and accommodation booking functionality
- **Package Management**: Create and manage travel packages
- **Cost Calculation**: Transparent pricing and cost breakdown

## 📋 Prerequisites

### Frontend Requirements
- Flutter SDK ^3.7.2
- Dart
- Android Studio / VS Code
- Google Maps API Key

### Backend Requirements
- Python 3.8+
- MySQL Database
- Google Maps API Key
- AWS Account (for S3 storage)
- Razorpay Account (for payments)

## 🛠️ Installation

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd event_be-release
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Environment Configuration**
   Create a `.env` file in the root directory:
   ```env
   # Database
   DATABASE_URL=mysql+pymysql://username:password@localhost/eeztour_db
   
   # JWT
   SECRET_KEY=your-secret-key
   ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=30
   
   # Google Maps
   GOOGLE_MAPS_API_KEY=your-google-maps-api-key
   
   # AWS S3
   AWS_ACCESS_KEY_ID=your-aws-access-key
   AWS_SECRET_ACCESS_KEY=your-aws-secret-key
   AWS_BUCKET_NAME=your-bucket-name
   
   # Razorpay
   RAZORPAY_KEY_ID=your-razorpay-key
   RAZORPAY_KEY_SECRET=your-razorpay-secret
   
   # CORS
   CORS_ORIGINS=["http://localhost:3000", "http://127.0.0.1:3000"]
   ```

5. **Database Setup**
   ```bash
   # Create MySQL database
   mysql -u root -p
   CREATE DATABASE eeztour_db;
   
   # Tables will be created automatically on first run
   ```

6. **Run the server**
   ```bash
   cd app
   python main.py
   ```
   The API will be available at `http://localhost:8000`

### Frontend Setup

1. **Navigate to Flutter project**
   ```bash
   cd eeztour_ui-release
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   Create a `.env` file in the root directory:
   ```env
   GOOGLE_MAPS_API_KEY=your-google-maps-api-key
   API_BASE_URL=http://localhost:8000
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

### Backend Structure
```
event_be-release/
├── app/
│   ├── main.py                 # FastAPI application entry point
│   ├── models/
│   │   ├── itinerary_modal.py  # Itinerary database models
│   │   ├── location_modal.py   # Location database models
│   │   └── user.py            # User database models
│   ├── schemas/
│   │   └── itinerary.py       # Pydantic schemas
│   ├── api/
│   │   └── routes/            # API route definitions
│   ├── core/
│   │   ├── database.py        # Database configuration
│   │   └── config.py          # Application configuration
│   └── services/              # Business logic services
├── requirements.txt           # Python dependencies
└── README.md
```

### Frontend Structure
```
eeztour_ui-release/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── common/
│   │   ├── config.dart             # App configuration
│   │   └── user_session.dart       # User session management
│   ├── features/
│   │   ├── authentication/         # Login/Registration screens
│   │   ├── homescreen/            # Home and dashboard screens
│   │   └── itinerary/             # Itinerary management
│   │       ├── itinerary_Creation/ # Create new itineraries
│   │       ├── itineraryDay/      # Day-specific planning
│   │       ├── itineraryMap/      # Map integration
│   │       └── itinerary_Menu/    # Itinerary management
├── assets/                         # Images, icons, and assets
├── pubspec.yaml                   # Flutter dependencies
└── .env                          # Environment variables
```

## 📱 Key Features Breakdown

- Create multi-day travel itineraries
- Add hotels, restaurants, and tourist attractions
- Calculate routes and travel times
- Estimate costs and manage budgets
- Share itineraries with others via unique codes
- Google Places API integration
- Real-time location search
- Interactive map visualization
- Route optimization
- Distance and duration calculations
- Social sharing capabilities


## 🔧 API Documentation

Once the backend is running, visit `http://localhost:8000/docs` for interactive API documentation powered by Swagger UI.

### Key Endpoints
- `POST /api/auth/login` - User authentication
- `POST /api/itinerary/create` - Create new itinerary
- `GET /api/itinerary/{id}` - Get itinerary details
- `POST /api/itinerary/items` - Add items to itinerary
- `GET /api/places/search` - Search places
- `POST /api/booking/create` - Create booking

## 🧪 Testing

### Backend Testing
```bash
# Run tests (if test files exist)
pytest
```

### Frontend Testing
```bash
# Run Flutter tests
flutter test
```

## 🚀 Deployment

### Backend Deployment
1. Configure production environment variables
2. Set up MySQL database on production server
3. Deploy using Docker or cloud services (AWS, GCP, etc.)
4. Configure reverse proxy (Nginx)

### Frontend Deployment
1. Build the Flutter app for production
   ```bash
   flutter build apk --release  # For Android
   flutter build ios --release  # For iOS
   ```
2. Deploy to app stores or distribute APK

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


