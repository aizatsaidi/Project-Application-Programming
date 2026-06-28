<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Only POST requests are allowed", "data" => null]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);
$activityId = $input['activity_id'] ?? null;
$status = trim($input['status'] ?? '');

if (!$activityId) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "activity_id is required", "data" => null]);
    exit();
}

$allowedStatuses = ['upcoming', 'completed'];
if (!in_array($status, $allowedStatuses)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Status must be 'upcoming' or 'completed'",
        "data" => null
    ]);
    exit();
}

try {
    $stmt = $pdo->prepare("UPDATE activities SET status = :status WHERE activity_id = :id");
    $stmt->execute(['status' => $status, 'id' => $activityId]);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Activity not found", "data" => null]);
        exit();
    }

    echo json_encode([
        "success" => true,
        "message" => "Activity status updated to '$status'",
        "data" => null
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Failed to update status: " . $e->getMessage(), "data" => null]);
}
?>
