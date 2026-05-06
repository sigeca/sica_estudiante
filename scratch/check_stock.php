<?php
$mysqli = new mysqli("localhost", "root", "", "sica");
if ($mysqli->connect_errno) {
    echo "Failed to connect to MySQL: " . $mysqli->connect_error;
    exit();
}
$res = $mysqli->query("DESCRIBE producto1");
while ($row = $res->fetch_assoc()) {
    echo $row['Field'] . "\n";
}
