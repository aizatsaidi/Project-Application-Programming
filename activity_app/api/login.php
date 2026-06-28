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

$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';

if ($email === '' || $password === '') {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Email and password are required",
        "data" => null
    ]);
    exit();
}

try {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = :email");
    $stmt->execute(['email' => $email]);
    $user = $stmt->fetch();

    // Check user exists AND password matches the hashed version stored in DB
    if (!$user || !password_verify($password, $user['password'])) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Invalid email or password",
            "data" => null
        ]);
        exit();
    }

    // Never send the password hash back to the app
    unset($user['password']);

    echo json_encode([
        "success" => true,
        "message" => "Login successful",
        "data" => $user
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Login failed: " . $e->getMessage(),
        "data" => null
    ]);
}
?>
