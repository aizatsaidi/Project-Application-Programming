<?php
$dbPath = __DIR__ . '/activities.db';
$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

try {
    // Add role column -- defaults to 'student' for all existing users
    $pdo->exec("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'student'");
    echo "Migration successful! 'role' column added to users table.";
} catch (PDOException $e) {
    // If column already exists, SQLite throws an error -- safe to ignore
    if (str_contains($e->getMessage(), 'duplicate column')) {
        echo "Column 'role' already exists -- no changes made.";
    } else {
        echo "Migration failed: " . $e->getMessage();
    }
}
?>
