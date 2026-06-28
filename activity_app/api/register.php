<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Only POST requests are allowed", "data" => null]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);

$name = trim($input['name'] ?? '');
$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';
$adminCode = trim($input['admin_code'] ?? '');

// Secret admin code -- only people who know this can register as admin
define('ADMIN_SECRET_CODE', 'UUMADMIN2026');

if ($name === '' || $email === '' || $password === '') {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Name, email, and password are required", "data" => null]);
    exit();
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid email format", "data" => null]);
    exit();
}

if (strlen($password) < 6) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Password must be at least 6 characters", "data" => null]);
    exit();
}

// Determine role based on admin code
$role = 'student';
if ($adminCode !== '') {
    if ($adminCode === ADMIN_SECRET_CODE) {
        $role = 'admin';
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Invalid admin code", "data" => null]);
        exit();
    }
}

try {
    $checkStmt = $pdo->prepare("SELECT user_id FROM users WHERE email = :email");
    $checkStmt->execute(['email' => $email]);
    if ($checkStmt->fetch()) {
        http_response_code(409);
        echo json_encode(["success" => false, "message" => "Email is already registered", "data" => null]);
        exit();
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    $stmt = $pdo->prepare(
        "INSERT INTO users (name, email, password, role) VALUES (:name, :email, :password, :role)"
    );
    $stmt->execute([
        'name' => $name,
        'email' => $email,
        'password' => $hashedPassword,
        'role' => $role
    ]);

    echo json_encode([
        "success" => true,
        "message" => "Registration successful as " . $role,
        "data" => [
            "user_id" => $pdo->lastInsertId(),
            "name" => $name,
            "email" => $email,
            "role" => $role
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Registration failed: " . $e->getMessage(), "data" => null]);
}
?>
