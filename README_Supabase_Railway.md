# NumberEgg - Supabase + Railway Integration

## Overview
This guide shows how to integrate Supabase database with Railway for the NumberEgg egg detection application.

## Setup Instructions

### 1. Supabase Setup

1. **Create a new Supabase project**
   - Go to [supabase.com](https://supabase.com)
   - Click "New Project"
   - Choose your organization and create a new project

2. **Get your credentials**
   - Go to Project Settings > API
   - Copy the Project URL and anon key

3. **Create database tables**
   - Go to SQL Editor
   - Run the SQL commands from `database_setup_fixed.sql`

### 2. Railway Setup

1. **Deploy the API**
   - Connect your GitHub repository to Railway
   - Railway will automatically detect the Python project

2. **Set environment variables**
   - Go to your Railway project settings
   - Add these environment variables:
     ```
     SUPABASE_URL=your_supabase_project_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     PORT=8000
     ```

### 3. Flutter App Configuration

The Flutter app already includes `supabase_flutter` package. Configure it in your app:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'your_supabase_url',
    anonKey: 'your_supabase_anon_key',
  );
  runApp(MyApp());
}
```

## API Endpoints

### Detection API (Railway)
- `POST /detect` - Upload image for egg detection
- `GET /health` - Check API health
- `GET /` - API information

### Database Tables (Supabase)
- `privileges` - User privilege levels
- `users` - User information
- `egg_session` - Detection session records
- `egg_item` - Individual egg detection results

## Features

### Railway API Features
- YOLO-based egg detection
- Image processing and analysis
- Automatic database storage
- Size classification (big, medium, small)
- Confidence scoring

### Supabase Features
- Real-time database
- Row Level Security (RLS)
- User authentication
- Automatic user creation
- Data persistence

## Security

- Row Level Security (RLS) enabled on all tables
- Users can only access their own data
- Environment variables for sensitive credentials
- CORS configuration for API access

## Deployment

### Railway Deployment
1. Push code to GitHub
2. Connect repository to Railway
3. Set environment variables
4. Deploy automatically

### Supabase Database
1. Create project at supabase.com
2. Run SQL setup script
3. Configure RLS policies
4. Test API connection

## Testing

Test the integration:
1. Upload an image to `/detect` endpoint
2. Check Supabase database for new records
3. Verify data integrity and security

## Troubleshooting

- Check environment variables are set correctly
- Verify Supabase URL and keys
- Ensure database tables exist
- Check RLS policies are working
- Monitor Railway logs for errors
