<?php
require_once 'db.php';

$userId = $_GET['user_id'] ?? null;

if (!$userId) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "user_id is required", "data" => null]);
    exit();
}

try {
    $stmt = $pdo->prepare("
        SELECT
            r.registration_id,
            r.status AS registration_status,
            r.registered_at,
            a.activity_id,
            a.title,
            a.description,
            a.location,
            a.activity_date,
            a.capacity,
            a.status AS activity_status
        FROM registrations r
        INNER JOIN activities a ON r.activity_id = a.activity_id
        WHERE r.user_id = :user_id
        ORDER BY a.activity_date ASC
    ");
    $stmt->execute(['user_id' => $userId]);
    $registrations = $stmt->fetchAll();

    echo json_encode([
        "success" => true,
        "message" => "Registrations retrieved successfully",
        "data" => $registrations
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to retrieve registrations: " . $e->getMessage(),
        "data" => null
    ]);
}
?>
