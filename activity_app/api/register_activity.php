<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Only POST requests are allowed", "data" => null]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);
$userId = $input['user_id'] ?? null;
$activityId = $input['activity_id'] ?? null;

if (!$userId || !$activityId) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "user_id and activity_id are required", "data" => null]);
    exit();
}

try {
    // Check if activity is full
    $capacityStmt = $pdo->prepare(
        "SELECT a.capacity,
            COUNT(r.registration_id) as registered_count
         FROM activities a
         LEFT JOIN registrations r
            ON a.activity_id = r.activity_id AND r.status = 'registered'
         WHERE a.activity_id = :activity_id
         GROUP BY a.activity_id"
    );
    $capacityStmt->execute(['activity_id' => $activityId]);
    $capacityData = $capacityStmt->fetch();

    if ($capacityData && (int)$capacityData['registered_count'] >= (int)$capacityData['capacity']) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Sorry, this activity is already full",
            "data" => null
        ]);
        exit();
    }

    // Check if any registration exists (active or cancelled)
    $checkStmt = $pdo->prepare(
        "SELECT registration_id, status FROM registrations
         WHERE user_id = :user_id AND activity_id = :activity_id"
    );
    $checkStmt->execute(['user_id' => $userId, 'activity_id' => $activityId]);
    $existing = $checkStmt->fetch();

    if ($existing) {
        if ($existing['status'] === 'registered') {
            http_response_code(409);
            echo json_encode([
                "success" => false,
                "message" => "You are already registered for this activity",
                "data" => null
            ]);
            exit();
        } else {
            // Previously cancelled -- allow re-registration
            $stmt = $pdo->prepare(
                "UPDATE registrations SET status = 'registered', registered_at = CURRENT_TIMESTAMP
                 WHERE registration_id = :id"
            );
            $stmt->execute(['id' => $existing['registration_id']]);

            echo json_encode([
                "success" => true,
                "message" => "Successfully re-registered for the activity",
                "data" => ["registration_id" => $existing['registration_id']]
            ]);
            exit();
        }
    }

    // No existing registration -- insert new row
    $stmt = $pdo->prepare(
        "INSERT INTO registrations (user_id, activity_id, status)
         VALUES (:user_id, :activity_id, 'registered')"
    );
    $stmt->execute(['user_id' => $userId, 'activity_id' => $activityId]);

    echo json_encode([
        "success" => true,
        "message" => "Successfully registered for the activity",
        "data" => ["registration_id" => $pdo->lastInsertId()]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Registration failed: " . $e->getMessage(), "data" => null]);
}
?>
