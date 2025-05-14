# flutter_my_dreamspace_app

# 🌙 MyDreamSpace - A Self-Reflection Journal App

**MyDreamSpace** is a polished, production-ready Flutter app that helps users **log dreams**, **track moods**, and **view insightful summaries**. It features smooth animations, dark mode, and real-time Supabase backend integration to create a seamless self-reflection experience.

---

> _“Track your inner world with elegance and insight.” — MyDreamSpace App_

---

## ✨ Features

### 📝 Dream Log
- Add dream entries with:
  - Title (required)
  - Description (optional)
  - Mood (emoji or color)
- Form validation and animated feedback
- Saves entries to Supabase

### 📘 Dream Journal
- Scrollable dream cards with:
  - Title
  - Mood indicator
  - Description preview
- Tap a card → Hero transition to detailed view
- Swipe to delete or edit

### 📊 Mood Tracker
- Dynamic mood trends shown as:
  - Bar / Pie 
- Updates in real-time as new entries are added

### 🌗 Dark Mode
- Toggle between light and dark themes

### 🚀 Onboarding
- First-time user walkthrough with basic lottie animation

### 🔐 Authentication
- Supabase email signup/login
- Optional guest login

---

## 🧪 Bonus Features (Optional)
- Pagination for dream cards
- Share a dream as message

---

## 💻 Tech Stack

| Layer         | Technology                         |
|---------------|-------------------------------------|
| Frontend      | Flutter                             |
| Backend       | Supabase (Auth + Database)          |
| Charts        | `fl_chart`|
| Design Pt.       | MVVM    |
| Animations    | Lottie, AnimatedBuilder      |
| State Mgmt    | Riverpod |
| Sharing       | `share_plus    |

---

## 🧭 App Screens

- **Onboarding** – First-time intro with animation  
- **Auth** – Sign up / login  
- **Home** – Bottom navigation to:  
  - Dream Log  
  - Dream Journal  
  - Mood Tracker  
  - Settings  
- **Dream Log Form**  
- **Dream Gallery**  
- **Detailed Dream View**  
- **Mood Insights**  
- **Settings**  

---

## 🧨 Animations & Feedback

| Location             | Type                         |
|----------------------|------------------------------|
| Onboarding           | Lottie                       |
| Dream Card Tap       | Hero Transition              |
| Mood Selector        | Scale-in / Tap effect        |
| Button Interactions  | Tap / Haptic Feedback      |
| Chart Load           | Fade             |

---

## 📁 Folder Structure

```
lib/
├── main.dart
├── models/
├── providers/
├── screens/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── dream_log/
│   ├── dream_journal/
|   ├── settings/
│   └── mood_tracker/
├── services/         # Supabase services
|── utils/
│   ├── app_config.dart/
│   ├── app_theme.dart/
│   ├── error_handler.dart/
```

---

## 🚀 Steps to follow

### 1. Clone the Repo

```bash
git clone https://github.com/tech-Ravi/flutter_my_dreamspace.git
cd flutter_my_dreamspace
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

- Create a [Supabase project](https://supabase.com)
- Enable:
  - **Auth** (Email) (Also do not forget to disable verify user email for Continue as a Guest button)
  - **Database** with the following table:

```sql
-- Create Dreams Table
create table dreams (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  title text not null,
  description text not null,
  mood text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone
);

alter table dreams enable row level security;

-- see dreams by userID
create policy "Users can only access their own dreams"
  on dreams for all
  using (auth.uid() = user_id);

```

- Add your Supabase `URL` and `Anon Key` to your environment variables (into your .env file or Create new one)

---

## 🔐 Environment Variables

Create a `.env` or secure config file:

```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

Use `flutter_dotenv` or similar package to load environment variables.

---

## 📸 Screenshots & App Screen recording

[![portfolio](https://img.shields.io/badge/screenshots-000?style=for-the-badge&logo=ko-fi&logoColor=white)](https://drive.google.com/drive/folders/1EMnisp7lkYBVDQx9rDqFrgz6kOn-Smta?usp=sharing)

[![portfolio](https://img.shields.io/badge/screen%20recording-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://drive.google.com/drive/folders/1wIohsNFtJR9M5pZkpC5-QkFF_WvTB0Yj?usp=sharing)

---

## 👤 Author

**Ravi Prakash**  
[LinkedIn](https://www.linkedin.com/in/ravi-prakash01/)  
[Portfolio](https://ravi-prakash-jaiswal-1.jimdosite.com/portfolio/)
