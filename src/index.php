<?php
function check_mysql($host, $user, $pass, $db) {
    try {
        $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass, [PDO::ATTR_TIMEOUT => 2]);
        $pdo = null;
        return 'OK';
    } catch (PDOException $e) {
        return 'Erreur: ' . $e->getMessage();
    }
}

function check_pgsql($host, $user, $pass, $db) {
    try {
        $pdo = new PDO("pgsql:host=$host;dbname=$db", $user, $pass, [PDO::ATTR_TIMEOUT => 2]);
        $pdo = null;
        return 'OK';
    } catch (PDOException $e) {
        return 'Erreur: ' . $e->getMessage();
    }
}

function check_mongo($host, $user, $pass) {
    if (!class_exists('MongoDB\\Driver\\Manager')) {
        return 'Extension MongoDB non installée';
    }
    try {
        $manager = new MongoDB\Driver\Manager("mongodb://$user:$pass@$host");
        $manager->executeCommand('admin', new MongoDB\Driver\Command(['ping' => 1]));
        return 'OK';
    } catch (Exception $e) {
        return 'Erreur: ' . $e->getMessage();
    }
}

function check_redis($host) {
    if (!class_exists('Redis')) {
        return 'Extension Redis non installée';
    }
    try {
        $redis = new Redis();
        $redis->connect($host, 6379, 1);
        $pong = $redis->ping();
        return $pong ? 'OK' : 'Erreur';
    } catch (Exception $e) {
        return 'Erreur: ' . $e->getMessage();
    }
}

$results = [
    'MySQL Service' => check_mysql('mysql', getenv('MYSQL_USER') ?: 'user', getenv('MYSQL_PASSWORD') ?: 'password', getenv('MYSQL_DATABASE') ?: 'app'),
    'MySQL Test Service' => check_mysql('mysql_test', getenv('MYSQL_USER') ?: 'user', getenv('MYSQL_PASSWORD') ?: 'password', getenv('MYSQL_DATABASE') ?: 'app'),
    'PostgreSQL Service' => check_pgsql('postgres', getenv('POSTGRES_USER') ?: 'user', getenv('POSTGRES_PASSWORD') ?: 'password', getenv('POSTGRES_DB') ?: 'app'),
    'PostgreSQL Test Service' => check_pgsql('postgres_test', getenv('POSTGRES_USER') ?: 'user', getenv('POSTGRES_PASSWORD') ?: 'password', getenv('POSTGRES_DB') ?: 'app'),
    'MongoDB Service' => check_mongo('mongo:27017', getenv('MONGO_INITDB_ROOT_USERNAME') ?: 'root', getenv('MONGO_INITDB_ROOT_PASSWORD') ?: 'example'),
    'MongoDB Test Service' => check_mongo('mongo_test:27017', getenv('MONGO_INITDB_ROOT_USERNAME') ?: 'root', getenv('MONGO_INITDB_ROOT_PASSWORD') ?: 'example'),
    'Redis Service' => check_redis('redis'),
];
?><!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Status des connexions</title>
    <style>body{font-family:sans-serif;}table{border-collapse:collapse;}td,th{border:1px solid #ccc;padding:8px;}</style>
</head>
<body>
    <h1>Status des connexions aux bases de données</h1>
    <table>
        <tr><th>Service</th><th>Status</th></tr>
        <?php foreach ($results as $service => $status): ?>
        <tr>
            <td><?= htmlspecialchars($service) ?></td>
            <td><?= htmlspecialchars($status) ?></td>
        </tr>
        <?php endforeach; ?>
    </table>
    <p><small>Actualisez la page pour relancer les tests.</small></p>
</body>
</html>
