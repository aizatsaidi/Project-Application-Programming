<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Only POST requests are allowed", "data" => null]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);

$activityId = $input['activity_id'] ?? null;
$title = trim($input['title'] ?? '');
$description = trim($input['description'] ?? '');
$location = trim($input['location'] ?? '');
$activityDate = trim($input['activity_date'] ?? '');
$capacity = $input['capacity'] ?? 0;

if (!$activityId) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "activity_id is required", "data" => null]);
    exit();
}

if ($title === '' || $location === '' || $activityDate === '') {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Title, location, and date are required", "data" => null]);
    exit();
}

if (!is_numeric($capacity) || (int)$capacity <= 0) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Capacity must be a positive number", "data" => null]);
    exit();
}

try {
    $stmt = $pdo->prepare(
        "UPDATE activities
         SET title = :title,
             description = :description,
             location = :location,
             activity_date = :activity_date,
             capacity = :capacity
         WHERE activity_id = :activity_id"
    );
    $stmt->execute([
        'title' => $title,
        'description' => $description,
        'location' => $location,
        'activity_date' => $activityDate,
        'capacity' => (int)$capacity,
        'activity_id' => $activityId
    ]);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Activity not found", "data" => null]);
        exit();
    }

    echo json_encode([
        "success" => true,
        "message" => "Activity updated successfully",
        "data" => null
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Failed to update activity: " . $e->getMessage(), "data" => null]);
}
?>
