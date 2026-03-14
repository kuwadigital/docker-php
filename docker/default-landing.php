<?php

function checkMysql(string $host, string $user, string $pass, string $db): ?string
{
    try {
        $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass, [PDO::ATTR_TIMEOUT => 2]);
        $pdo = null;
        return null;
    } catch (PDOException $e) {
        return $e->getMessage();
    }
}

function checkPgsql(string $host, string $user, string $pass, string $db): ?string
{
    try {
        $pdo = new PDO("pgsql:host=$host;dbname=$db", $user, $pass, [PDO::ATTR_TIMEOUT => 2]);
        $pdo = null;
        return null;
    } catch (PDOException $e) {
        return $e->getMessage();
    }
}

function checkMongo(string $host, string $user, string $pass): ?string
{
    if (!class_exists('MongoDB\\Driver\\Manager')) {
        return 'Extension not installed';
    }
    try {
        $manager = new MongoDB\Driver\Manager("mongodb://$user:$pass@$host");
        $manager->executeCommand('admin', new MongoDB\Driver\Command(['ping' => 1]));
        return null;
    } catch (Exception $e) {
        return $e->getMessage();
    }
}

function checkRedis(string $host): ?string
{
    if (!class_exists('Redis')) {
        return 'Extension not installed';
    }
    try {
        $redis = new Redis();
        $redis->connect($host, 6379, 1);
        $redis->ping();
        return null;
    } catch (Exception $e) {
        return $e->getMessage();
    }
}

$services = [
    'MySQL' => fn() => checkMysql('mysql', getenv('MYSQL_USER') ?: 'app', getenv('MYSQL_PASSWORD') ?: 'app', getenv('MYSQL_DATABASE') ?: 'app_db'),
    'PostgreSQL' => fn() => checkPgsql('postgres', getenv('POSTGRES_USER') ?: 'app', getenv('POSTGRES_PASSWORD') ?: 'app', getenv('POSTGRES_DB') ?: 'app_db'),
    'MongoDB' => fn() => checkMongo('mongo:27017', getenv('MONGO_INITDB_ROOT_USERNAME') ?: 'root', getenv('MONGO_INITDB_ROOT_PASSWORD') ?: 'root'),
    'Redis' => fn() => checkRedis('redis'),
];

$results = [];
foreach ($services as $name => $check) {
    $error = $check();
    $results[$name] = ['ok' => $error === null, 'error' => $error];
}
?><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker PHP Environment</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #e2e8f0; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .container { max-width: 640px; width: 100%; padding: 2rem; }
        h1 { font-size: 1.5rem; margin-bottom: 0.25rem; color: #f8fafc; }
        .subtitle { color: #94a3b8; margin-bottom: 2rem; font-size: 0.875rem; }
        .section-title { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; margin-bottom: 0.75rem; }
        .services { display: grid; gap: 0.5rem; margin-bottom: 2rem; }
        .service { display: flex; justify-content: space-between; align-items: center; padding: 0.625rem 1rem; background: #1e293b; border-radius: 0.5rem; }
        .service-name { font-weight: 500; font-size: 0.875rem; }
        .badge { font-size: 0.75rem; padding: 0.125rem 0.5rem; border-radius: 9999px; font-weight: 500; }
        .badge-ok { background: #065f46; color: #6ee7b7; }
        .badge-err { background: #7f1d1d; color: #fca5a5; }
        .commands { background: #1e293b; border-radius: 0.5rem; padding: 1rem 1.25rem; }
        .commands h3 { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; margin-bottom: 0.75rem; }
        .cmd { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 0.8125rem; padding: 0.25rem 0; color: #7dd3fc; }
        .cmd span { color: #64748b; margin-left: 0.5rem; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
        .php-version { color: #64748b; font-size: 0.75rem; margin-top: 1.5rem; text-align: center; }
    </style>
</head>
<body>
<div class="container">
    <h1>Docker PHP Environment Ready</h1>
    <p class="subtitle">Your development environment is running. Install a framework to get started.</p>

    <p class="section-title">Service Status</p>
    <div class="services">
        <?php foreach ($results as $name => $r): ?>
        <div class="service">
            <span class="service-name"><?= htmlspecialchars($name) ?></span>
            <?php if ($r['ok']): ?>
                <span class="badge badge-ok">Connected</span>
            <?php else: ?>
                <span class="badge badge-err" title="<?= htmlspecialchars($r['error']) ?>">Unavailable</span>
            <?php endif; ?>
        </div>
        <?php endforeach; ?>
    </div>

    <div class="commands">
        <h3>Available Init Commands</h3>
        <div class="cmd">make init-laravel-app <span>Laravel</span></div>
        <div class="cmd">make init-laravel-api <span>Laravel API + API Platform</span></div>
        <div class="cmd">make init-symfony-app <span>Symfony</span></div>
        <div class="cmd">make init-symfony-api <span>Symfony API + API Platform</span></div>
        <div class="cmd">make init-codeigniter-app <span>CodeIgniter 4</span></div>
        <div class="cmd">make init-cakephp-app <span>CakePHP</span></div>
        <div class="cmd">make init-slim-app <span>Slim</span></div>
        <div class="cmd">make init-laminas-app <span>Laminas MVC</span></div>
        <div class="cmd">make init-reset <span>Reset to default</span></div>
    </div>

    <p class="php-version">PHP <?= phpversion() ?></p>
</div>
</body>
</html>
