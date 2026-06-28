<?php
require_once 'db.php';

try {
    // Only return upcoming activities -- completed ones are hidden from the list
    $stmt = $pdo->query(
        "SELECT * FROM activities WHERE status != 'completed' ORDER BY activity_date ASC"
    );
    $activities = $stmt->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Activities retrieved successfully",
        "data" => $activities
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to retrieve activities: " . $e->getMessage(),
        "data" => null
    ]);
}
?>
