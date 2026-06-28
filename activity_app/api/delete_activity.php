<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Only POST requests are allowed", "data" => null]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);
$activityId = $input['activity_id'] ?? null;

if (!$activityId) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "activity_id is required", "data" => null]);
    exit();
}

try {
    // Also delete all registrations for this activity to keep DB clean
    $pdo->prepare("DELETE FROM registrations WHERE activity_id = :id")->execute(['id' => $activityId]);

    $stmt = $pdo->prepare("DELETE FROM activities WHERE activity_id = :id");
    $stmt->execute(['id' => $activityId]);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Activity not found", "data" => null]);
        exit();
    }

    echo json_encode([
        "success" => true,
        "message" => "Activity deleted successfully",
        "data" => null
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Failed to delete activity: " . $e->getMessage(), "data" => null]);
}
?>
