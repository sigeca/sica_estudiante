<?php
// Desactivar el reporte de errores para evitar que se impriman en la salida
error_reporting(0);

// Asegúrate de que el parámetro 'archivo' exista y no esté vacío
if (isset($_GET['archivo']) && !empty($_GET['archivo'])) {
    
    // Ruta segura para las fotos, evita ataques de directorio
    $base_path = '/var/www/repositorioeys/fotos/';
    $file_name = basename($_GET['archivo']); // Sanear el nombre del archivo
    $file_path = $base_path . $file_name;

    // Verificar si el archivo existe y es legible
    if (file_exists($file_path) && is_readable($file_path)) {
        
        // Determinar el tipo MIME del archivo
        $mime_type = 'image/jpeg';
        if (function_exists('mime_content_type')) {
            $mime_type = mime_content_type($file_path);
        }

        // Establecer los encabezados para servir el archivo como una imagen
        header('Content-Type: ' . $mime_type);
        header('Content-Length: ' . filesize($file_path));

        // Leer el archivo y enviar su contenido binario
        readfile($file_path);
        exit;
    }
}

// Si el archivo no se encuentra o la ruta es inválida, enviar un error 404
header("HTTP/1.0 404 Not Found");
exit;
?>
