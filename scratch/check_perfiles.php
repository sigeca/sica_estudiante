<?php
define('BASEPATH', 'TRUE');
require_once '/var/www/html/sica/application/config/database.php';
$db_config = $db['default'];
$conn = new mysqli($db_config['hostname'], $db_config['username'], $db_config['password'], $db_config['database']);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
$result = $conn->query("SELECT * FROM perfil");
while($row = $result->fetch_assoc()) {
    echo $row['idperfil'] . ": " . $row['nombre'] . "\n";
}
$conn->close();
?>
