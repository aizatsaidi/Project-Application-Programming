<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Only POST requests are allowed", "data" => null]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);

$title = trim($input['title'] ?? '');
$description = trim($input['description'] ?? '');
$location = trim($input['location'] ?? '');
$activityDate = trim($input['activity_date'] ?? '');
$capacity = $input['capacity'] ?? 0;

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
        "INSERT INTO activities (title, description, location, activity_date, capacity)
         VALUES (:title, :description, :location, :activity_date, :capacity)"
    );
    $stmt->execute([
        'title' => $title,
        'description' => $description,
        'location' => $location,
        'activity_date' => $activityDate,
        'capacity' => (int)$capacity
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Activity added successfully",
        "data" => ["activity_id" => $pdo->lastInsertId()]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Failed to add activity: " . $e->getMessage(), "data" => null]);
}
?>
