<?php
$dbPath = __DIR__ . '/activities.db';
$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Create tables
$pdo->exec("
CREATE TABLE IF NOT EXISTS users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
)");

$pdo->exec("
CREATE TABLE IF NOT EXISTS activities (
    activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    activity_date TEXT,
    capacity INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
)");

$pdo->exec("
CREATE TABLE IF NOT EXISTS registrations (
    registration_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    activity_id INTEGER NOT NULL,
    status TEXT DEFAULT 'registered',
    registered_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (activity_id) REFERENCES activities(activity_id)
)");

// Seed sample activities
$pdo->exec("
INSERT INTO activities (title, description, location, activity_date, capacity)
VALUES
('Futsal Tournament', 'Inter-faculty futsal competition, open to all students.', 'UUM Sports Complex', '2026-07-05', 40),
('AI & Digital Law Talk', 'A seminar exploring the intersection of AI and digital law.', 'Dewan Budaya', '2026-07-10', 100),
('Hackathon Prep Workshop', 'Tips and tricks for upcoming hackathons, hosted by senior students.', 'CAS Lab 3', '2026-07-15', 30)
");

// Seed one sample test user (plain text password here just for testing -- we will hash it properly in register.php)
$pdo->exec("
INSERT INTO users (name, email, password)
VALUES ('Test Student', 'test@uum.edu.my', 'test123')
");

echo "Database created successfully with tables and sample data!";
?>
