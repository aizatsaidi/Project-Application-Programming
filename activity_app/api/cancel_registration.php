<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Only POST requests are allowed",
        "data" => null
    ]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);
$registrationId = $input['registration_id'] ?? null;

if (!$registrationId) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "registration_id is required",
        "data" => null
    ]);
    exit();
}

try {
    $stmt = $pdo->prepare("UPDATE registrations SET status = 'cancelled' WHERE registration_id = :id");
    $stmt->execute(['id' => $registrationId]);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Registration not found",
            "data" => null
        ]);
        exit();
    }

    echo json_encode([
        "success" => true,
        "message" => "Registration cancelled successfully",
        "data" => null
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to cancel registration: " . $e->getMessage(),
        "data" => null
    ]);
}
?>
