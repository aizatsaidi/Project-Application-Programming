<?php
require_once 'db.php';

$activityId = $_GET['activity_id'] ?? null;

if (!$activityId) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "activity_id is required", "data" => null]);
    exit();
}

try {
    // Count only active registrations (not cancelled)
    $stmt = $pdo->prepare(
        "SELECT COUNT(*) as count FROM registrations
         WHERE activity_id = :activity_id AND status = 'registered'"
    );
    $stmt->execute(['activity_id' => $activityId]);
    $result = $stmt->fetch();

    echo json_encode([
        "success" => true,
        "message" => "Registration count retrieved",
        "data" => ["count" => (int)$result['count']]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to get count: " . $e->getMessage(),
        "data" => null
    ]);
}
?>
