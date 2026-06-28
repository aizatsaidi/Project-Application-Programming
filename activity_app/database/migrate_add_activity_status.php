<?php
$dbPath = __DIR__ . '/activities.db';
$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

try {
    // Add status column to activities -- defaults to 'upcoming' for all existing activities
    $pdo->exec("ALTER TABLE activities ADD COLUMN status TEXT DEFAULT 'upcoming'");
    echo "Migration successful! 'status' column added to activities table.";
} catch (PDOException $e) {
    if (str_contains($e->getMessage(), 'duplicate column')) {
        echo "Column 'status' already exists -- no changes made.";
    } else {
        echo "Migration failed: " . $e->getMessage();
    }
}
?>
